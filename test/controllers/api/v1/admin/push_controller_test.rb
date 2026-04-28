require "test_helper"

class ApiV1AdminPushTest < ActionDispatch::IntegrationTest
  def post_broadcast(actor, params: {})
    headers = actor ? auth_headers(actor) : {}
    post "/api/v1/admin/push/broadcast", headers: headers, params: params, as: :json
  end

  def get_history(actor, params: {})
    headers = actor ? auth_headers(actor) : {}
    get "/api/v1/admin/push/history", headers: headers, params: params
  end

  def with_stubbed_send(result)
    captured = {}
    PushSender.singleton_class.alias_method(:__orig_send_to_tokens, :send_to_tokens)
    PushSender.singleton_class.define_method(:send_to_tokens) do |tokens, **kwargs|
      captured[:tokens] = tokens
      captured[:kwargs] = kwargs
      result
    end
    yield captured
  ensure
    PushSender.singleton_class.alias_method(:send_to_tokens, :__orig_send_to_tokens)
    PushSender.singleton_class.send(:remove_method, :__orig_send_to_tokens)
  end

  test "broadcast requires authentication" do
    post_broadcast(nil, params: { title: "Hi", body: "There" })

    assert_response :unauthorized
    assert_equal "auth_required", error["code"]
  end

  test "history requires authentication" do
    get_history(nil)

    assert_response :unauthorized
    assert_equal "auth_required", error["code"]
  end

  test "broadcast forbids non-admin actors" do
    employer = create_employer

    post_broadcast(employer, params: { title: "Hi", body: "There" })

    assert_response :forbidden
    assert_equal "wrong_role", error["code"]
  end

  test "history returns paginated broadcast audit logs" do
    admin = create_admin
    other_admin = create_admin
    oldest = AuditLog.create!(
      actor: admin,
      action: "admin.push.broadcast",
      subject_type: "User",
      subject_id: admin.id,
      metadata: { recipient_count: 2, sent_count: 2, failed_count: 0, ticket_count: 2, filter: { role: "worker" } },
      created_at: 3.minutes.ago,
      updated_at: 3.minutes.ago
    )
    middle = AuditLog.create!(
      actor: other_admin,
      action: "admin.push.broadcast",
      subject_type: "User",
      subject_id: other_admin.id,
      metadata: { recipient_count: 1, sent_count: 1, failed_count: 0, ticket_count: 1, filter: { user_ids: [ other_admin.id ] } },
      created_at: 2.minutes.ago,
      updated_at: 2.minutes.ago
    )
    newest = AuditLog.create!(
      actor: admin,
      action: "admin.push.broadcast",
      subject_type: "User",
      subject_id: admin.id,
      metadata: { recipient_count: 5, sent_count: 3, failed_count: 2, ticket_count: 3, filter: { suspended: false } },
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago
    )
    AuditLog.create!(
      actor: admin,
      action: "user.suspend",
      subject_type: "User",
      subject_id: admin.id,
      metadata: {},
      created_at: Time.current,
      updated_at: Time.current
    )

    get_history(admin, params: { per_page: 2, page: 1 })

    assert_response :success
    assert_equal [ newest.id, middle.id ], data["history"].map { |entry| entry["id"] }
    assert_equal 1, data["meta"]["page"]
    assert_equal 2, data["meta"]["per_page"]
    assert_equal 3, data["meta"]["total"]
    assert_equal 2, data["meta"]["total_pages"]
    assert_equal 5, data["history"].first["recipient_count"]
    assert_equal 3, data["history"].first["sent_count"]
    assert_equal 2, data["history"].first["failed_count"]
    assert_equal({ "suspended" => false }, data["history"].first["filter"])
    assert_equal admin.id, data["history"].first["actor"]["id"]

    get_history(admin, params: { per_page: 2, page: 2 })

    assert_response :success
    assert_equal [ oldest.id ], data["history"].map { |entry| entry["id"] }
    assert_equal 2, data["meta"]["page"]
  end

  test "history uses stable id tiebreak ordering for identical timestamps" do
    admin = create_admin
    created_at = Time.zone.parse("2026-04-27 12:00:00")

    first = AuditLog.create!(
      actor: admin,
      action: "admin.push.broadcast",
      subject_type: "User",
      subject_id: admin.id,
      metadata: { recipient_count: 1, sent_count: 1, failed_count: 0, ticket_count: 1, filter: {} },
      created_at: created_at,
      updated_at: created_at
    )
    second = AuditLog.create!(
      actor: admin,
      action: "admin.push.broadcast",
      subject_type: "User",
      subject_id: admin.id,
      metadata: { recipient_count: 2, sent_count: 2, failed_count: 0, ticket_count: 2, filter: {} },
      created_at: created_at,
      updated_at: created_at
    )

    get_history(admin, params: { per_page: 10, page: 1 })

    assert_response :success
    expected_ids = AuditLog.where(id: [ first.id, second.id ]).order(created_at: :desc, id: :desc).pluck(:id)
    assert_equal expected_ids, data["history"].first(2).map { |entry| entry["id"] }
  end

  test "broadcast returns 422 missing_message when title or body missing" do
    admin = create_admin

    post_broadcast(admin, params: { body: "no title" })

    assert_response :unprocessable_entity
    assert_equal "missing_message", error["code"]
  end

  test "broadcast returns 422 no_active_devices when filter yields zero tokens" do
    admin = create_admin
    create_worker # no device tokens

    post_broadcast(admin, params: { title: "Hi", body: "There" })

    assert_response :unprocessable_entity
    assert_equal "no_active_devices", error["code"]
  end

  test "broadcast returns 422 too_many_recipients when over the safety cap" do
    admin = create_admin
    worker = create_worker
    worker.device_tokens.create!(expo_push_token: "ExponentPushToken[t]", platform: "ios", active: true)

    over_cap = Array.new(Api::V1::Admin::PushController::MAX_RECIPIENTS + 1) { |i| "ExponentPushToken[#{i}]" }
    DeviceToken.singleton_class.alias_method(:__orig_active, :active)
    DeviceToken.singleton_class.define_method(:active) do
      Class.new do
        define_singleton_method(:where) { |*| self }
        define_singleton_method(:pluck) { |*| over_cap }
      end
    end

    begin
      post_broadcast(admin, params: { title: "Hi", body: "There" })
    ensure
      DeviceToken.singleton_class.alias_method(:active, :__orig_active)
      DeviceToken.singleton_class.send(:remove_method, :__orig_active)
    end

    assert_response :unprocessable_entity
    assert_equal "too_many_recipients", error["code"]
  end

  test "broadcast success path delegates to PushSender and audits" do
    admin = create_admin
    worker_a = create_worker
    worker_b = create_worker
    worker_a.device_tokens.create!(expo_push_token: "ExponentPushToken[a]", platform: "ios", active: true)
    worker_b.device_tokens.create!(expo_push_token: "ExponentPushToken[b]", platform: "android", active: true)

    fake = PushSender::Result.new(sent_count: 2, failed_count: 0, ticket_ids: %w[t1 t2], errors: [])

    with_stubbed_send(fake) do |captured|
      post_broadcast(admin, params: { title: "Hello", body: "World", data: { kind: "announcement" } })

      assert_response :success
      assert_equal 2, data["recipient_count"]
      assert_equal 2, data["sent_count"]
      assert_equal 0, data["failed_count"]
      assert_equal 2, data["ticket_count"]
      assert_equal [], data["errors"]

      assert_equal "Hello", captured[:kwargs][:title]
      assert_equal "World", captured[:kwargs][:body]
      assert_equal({ "kind" => "announcement" }, captured[:kwargs][:data])
      assert_equal 2, captured[:tokens].length
    end

    assert_equal 1, AuditLog.where(action: "admin.push.broadcast", actor_id: admin.id).count
  end

  test "broadcast respects user_ids filter and ignores default role" do
    admin = create_admin
    employer = create_employer
    employer.device_tokens.create!(expo_push_token: "ExponentPushToken[e]", platform: "ios", active: true)

    fake = PushSender::Result.new(sent_count: 1, failed_count: 0, ticket_ids: [ "t1" ], errors: [])

    with_stubbed_send(fake) do |captured|
      post_broadcast(admin, params: { title: "Hi", body: "There", filter: { user_ids: [ employer.id ] } })

      assert_response :success
      assert_equal [ "ExponentPushToken[e]" ], captured[:tokens]
    end
  end
end
