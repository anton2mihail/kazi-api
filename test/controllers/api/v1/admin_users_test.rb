require "test_helper"

class ApiV1AdminUsersTest < ActionDispatch::IntegrationTest
  def list(admin, params: {})
    get "/api/v1/admin/users",
      headers: auth_headers(admin),
      params: params
  end

  test "requires authentication" do
    get "/api/v1/admin/users", as: :json

    assert_response :unauthorized
    assert_equal "auth_required", error["code"]
  end

  test "forbids non-admin users" do
    employer = create_employer

    get "/api/v1/admin/users",
      headers: auth_headers(employer),
      as: :json

    assert_response :forbidden
    assert_equal "wrong_role", error["code"]
  end

  test "returns paginated users with meta for admin" do
    admin = create_admin
    create_worker(email: "alpha@example.com")
    create_worker(email: "beta@example.com")

    list(admin)

    assert_response :success
    assert_kind_of Array, data["users"]
    assert data["users"].length >= 3 # admin + two workers
    meta = data["meta"]
    assert_equal 1, meta["page"]
    assert_equal 20, meta["per_page"]
    assert meta["total"] >= 3
    assert meta["total_pages"] >= 1

    sample = data["users"].first
    %w[id name email phone role suspended suspended_at suspension_reason created_at updated_at].each do |key|
      assert sample.key?(key), "expected user record to expose #{key}"
    end
  end

  test "q filter matches across email, phone, and profile names" do
    admin = create_admin
    worker = create_worker(email: "needle@example.com")
    worker.create_worker_profile!(first_name: "Needle", last_name: "Smith", province: "ON")
    create_worker(email: "other@example.com")

    list(admin, params: { q: "needle" })

    assert_response :success
    ids = data["users"].map { |u| u["id"] }
    assert_includes ids, worker.id
    refute(data["users"].any? { |u| u["email"] == "other@example.com" })
  end

  test "role filter narrows results" do
    admin = create_admin
    create_worker
    create_employer

    list(admin, params: { role: "worker" })

    assert_response :success
    assert data["users"].any?
    assert(data["users"].all? { |u| u["role"] == "worker" })
  end

  test "suspended=true returns suspended users regardless of role" do
    admin = create_admin
    employer = create_employer(verified: true)
    employer.suspend!(reason: "Policy review", by: admin)
    worker = create_worker(email: "ws@example.com")
    worker.suspend!(reason: "Abuse", by: admin)
    create_employer(verified: true) # not suspended
    create_worker # not suspended

    list(admin, params: { suspended: "true" })

    assert_response :success
    ids = data["users"].map { |u| u["id"] }
    assert_includes ids, employer.id
    assert_includes ids, worker.id
    assert(data["users"].all? { |u| u["suspended"] == true })
    assert(data["users"].all? { |u| u["suspended_at"].present? })
  end

  test "suspended=false excludes suspended users" do
    admin = create_admin
    suspended = create_employer(verified: true)
    suspended.suspend!(reason: "Policy review", by: admin)
    healthy = create_employer(verified: true)

    list(admin, params: { suspended: "false" })

    assert_response :success
    ids = data["users"].map { |u| u["id"] }
    refute_includes ids, suspended.id
    assert_includes ids, healthy.id
  end

  test "suspension_reason is exposed when set" do
    admin = create_admin
    worker = create_worker(email: "reason@example.com")
    worker.suspend!(reason: "Spamming employers", by: admin)

    list(admin, params: { q: "reason@example.com" })

    assert_response :success
    record = data["users"].find { |u| u["id"] == worker.id }
    assert_equal true, record["suspended"]
    assert_equal "Spamming employers", record["suspension_reason"]
    assert record["suspended_at"].present?
  end

  test "pagination respects page and per_page" do
    admin = create_admin
    5.times { create_worker }

    list(admin, params: { per_page: 2, page: 1 })

    assert_response :success
    assert_equal 2, data["users"].length
    assert_equal 1, data["meta"]["page"]
    assert_equal 2, data["meta"]["per_page"]
    total = data["meta"]["total"]
    assert total >= 6
    assert_equal (total.to_f / 2).ceil, data["meta"]["total_pages"]

    list(admin, params: { per_page: 2, page: 2 })
    assert_response :success
    assert_equal 2, data["meta"]["page"]
    assert_equal 2, data["users"].length
  end

  test "per_page is capped at 100" do
    admin = create_admin

    list(admin, params: { per_page: 500 })

    assert_response :success
    assert_equal 100, data["meta"]["per_page"]
  end

  test "suspend marks any role as suspended and returns the updated user" do
    admin = create_admin
    worker = create_worker(email: "tosuspend@example.com")

    patch "/api/v1/admin/users/#{worker.id}/suspend",
      headers: auth_headers(admin),
      params: { reason: "Repeated no-shows" },
      as: :json

    assert_response :success
    user = data["user"]
    assert_equal worker.id, user["id"]
    assert_equal true, user["suspended"]
    assert_equal "Repeated no-shows", user["suspension_reason"]
    assert user["suspended_at"].present?

    worker.reload
    assert worker.suspended?
    assert_equal admin.id, worker.suspended_by_id
    assert_equal 1, AuditLog.where(action: "user.suspend", subject_id: worker.id).count
  end

  test "suspended users lose access on their next authenticated request" do
    admin = create_admin
    worker = create_worker(email: "active-session@example.com")
    token, session = UserSession.issue_for!(worker, user_agent: "test", ip_address: "127.0.0.1")

    patch "/api/v1/admin/users/#{worker.id}/suspend",
      headers: auth_headers(admin),
      params: { reason: "Repeated no-shows" },
      as: :json

    assert_response :success

    get "/api/v1/me",
      headers: { "Authorization" => "Bearer #{token}" },
      as: :json

    assert_response :forbidden
    assert_equal "account_suspended", error["code"]
    assert_not_nil session.reload.revoked_at
  end

  test "suspend requires authentication" do
    worker = create_worker

    patch "/api/v1/admin/users/#{worker.id}/suspend", as: :json

    assert_response :unauthorized
    assert_equal "auth_required", error["code"]
  end

  test "suspend forbids non-admin actors" do
    employer = create_employer
    target = create_worker

    patch "/api/v1/admin/users/#{target.id}/suspend",
      headers: auth_headers(employer),
      as: :json

    assert_response :forbidden
    assert_equal "wrong_role", error["code"]
  end

  test "suspend refuses to suspend admins" do
    admin = create_admin
    other_admin = create_admin

    patch "/api/v1/admin/users/#{other_admin.id}/suspend",
      headers: auth_headers(admin),
      as: :json

    assert_response :unprocessable_entity
    assert_equal "cannot_suspend_admin", error["code"]
    refute other_admin.reload.suspended?
  end

  test "suspend refuses when user already suspended" do
    admin = create_admin
    worker = create_worker
    worker.suspend!(reason: "Old reason", by: admin)

    patch "/api/v1/admin/users/#{worker.id}/suspend",
      headers: auth_headers(admin),
      as: :json

    assert_response :unprocessable_entity
    assert_equal "already_suspended", error["code"]
  end

  test "unsuspend clears fields and returns the updated user" do
    admin = create_admin
    worker = create_worker
    worker.suspend!(reason: "tmp", by: admin)

    patch "/api/v1/admin/users/#{worker.id}/unsuspend",
      headers: auth_headers(admin),
      as: :json

    assert_response :success
    user = data["user"]
    assert_equal false, user["suspended"]
    assert_nil user["suspended_at"]
    assert_nil user["suspension_reason"]

    worker.reload
    refute worker.suspended?
    assert_nil worker.suspended_by_id
    assert_equal 1, AuditLog.where(action: "user.unsuspend", subject_id: worker.id).count
  end

  test "test_push requires authentication" do
    worker = create_worker

    post "/api/v1/admin/users/#{worker.id}/test_push", as: :json

    assert_response :unauthorized
    assert_equal "auth_required", error["code"]
  end

  test "test_push forbids non-admin actors" do
    employer = create_employer
    target = create_worker

    post "/api/v1/admin/users/#{target.id}/test_push",
      headers: auth_headers(employer),
      as: :json

    assert_response :forbidden
    assert_equal "wrong_role", error["code"]
  end

  test "test_push returns 422 when user has no active device tokens" do
    admin = create_admin
    worker = create_worker

    post "/api/v1/admin/users/#{worker.id}/test_push",
      headers: auth_headers(admin),
      as: :json

    assert_response :unprocessable_entity
    assert_equal "no_active_devices", error["code"]
  end

  test "test_push delegates to PushSender and returns receipts envelope" do
    admin = create_admin
    worker = create_worker
    worker.device_tokens.create!(
      expo_push_token: "ExponentPushToken[abc123]",
      platform: "ios",
      active: true
    )

    fake_result = PushSender::Result.new(
      sent_count: 1,
      failed_count: 0,
      ticket_ids: [ "receipt-1" ],
      errors: []
    )

    captured = {}
    original = PushSender.method(:send_to_user)
    PushSender.singleton_class.send(:remove_method, :send_to_user)
    PushSender.define_singleton_method(:send_to_user) do |user, **kwargs|
      captured[:user_id] = user.id
      captured[:kwargs] = kwargs
      fake_result
    end

    begin
      post "/api/v1/admin/users/#{worker.id}/test_push",
        headers: auth_headers(admin),
        params: { title: "Hello", body: "World", data: { kind: "smoke" } },
        as: :json
    ensure
      PushSender.singleton_class.send(:remove_method, :send_to_user)
      PushSender.define_singleton_method(:send_to_user, original)
    end

    assert_response :success
    assert_equal worker.id, captured[:user_id]
    assert_equal "Hello", captured[:kwargs][:title]
    assert_equal "World", captured[:kwargs][:body]
    assert_equal({ "kind" => "smoke" }, captured[:kwargs][:data])

    assert_equal 1, data["sent_count"]
    assert_equal 0, data["failed_count"]
    assert_equal [ "receipt-1" ], data["ticket_ids"]
    assert_equal [], data["errors"]
    assert_equal 1, AuditLog.where(action: "user.test_push", subject_id: worker.id).count
  end

  test "unsuspend refuses when user is not suspended" do
    admin = create_admin
    worker = create_worker

    patch "/api/v1/admin/users/#{worker.id}/unsuspend",
      headers: auth_headers(admin),
      as: :json

    assert_response :unprocessable_entity
    assert_equal "not_suspended", error["code"]
  end
end
