require "test_helper"

class ApiV1ReportsNotificationsTest < ActionDispatch::IntegrationTest
  test "job reports can be submitted anonymously or by a signed in user" do
    employer = create_employer(verified: true)
    worker = create_worker
    job = create_job(employer: employer)

    post "/api/v1/reports/jobs",
      params: { jobId: job.id, reason: "fake_company", details: "Looks wrong" },
      as: :json

    assert_response :created
    assert_nil data["reporterId"]
    assert_equal job.id, data["jobId"]
    assert_equal "fake_company", data["reason"]

    post "/api/v1/reports/jobs",
      headers: auth_headers(worker),
      params: { jobId: job.id, reason: "unsafe" },
      as: :json

    assert_response :created
    assert_equal worker.id, data["reporterId"]
  end

  test "user reports require authentication" do
    worker = create_worker
    target = create_employer

    post "/api/v1/reports/users",
      headers: auth_headers(worker),
      params: { targetType: "User", targetId: target.id, reason: "spam", details: "Bad behavior" },
      as: :json

    assert_response :created
    assert_equal worker.id, data["reporterId"]
    assert_equal target.id, data["targetId"]
  end

  test "admins can list and moderate reports" do
    admin = create_admin
    report = Report.create!(reason: "other", status: "pending")

    get "/api/v1/admin/reports", headers: auth_headers(admin), as: :json

    assert_response :success
    assert data.any? { |item| item["id"] == report.id }

    patch "/api/v1/admin/reports/#{report.id}",
      headers: auth_headers(admin),
      params: { status: "actioned", adminNotes: "Removed" },
      as: :json

    assert_response :success
    assert_equal "actioned", data["status"]
    assert_equal "Removed", data["adminNotes"]
    assert data["reviewedAt"].present?
  end

  test "notifications can be listed and marked read" do
    worker = create_worker
    job = create_job(employer: create_employer(verified: true))
    notification = worker.notifications.create!(
      notification_type: "application_update",
      title: "Application Update",
      message: "Your application changed",
      job: job,
      company_id: job.employer_id
    )

    get "/api/v1/notifications", headers: auth_headers(worker), as: :json

    assert_response :success
    assert_equal notification.id, data.first["id"]
    assert_equal false, data.first["read"]

    patch "/api/v1/notifications/#{notification.id}/read",
      headers: auth_headers(worker),
      as: :json

    assert_response :success
    assert_equal true, data["read"]

    worker.notifications.create!(notification_type: "new_job", title: "New job")
    patch "/api/v1/notifications/read_all", headers: auth_headers(worker), as: :json

    assert_response :success
    assert_equal 0, worker.notifications.unread.count
  end

  test "notification preferences can be shown and updated" do
    worker = create_worker

    get "/api/v1/notification_preferences", headers: auth_headers(worker), as: :json

    assert_response :success
    assert_equal true, data["newJobs"]
    assert_equal true, data["applicationUpdates"]
    assert_equal true, data["sms"]

    put "/api/v1/notification_preferences",
      headers: auth_headers(worker),
      params: { newJobs: false, applicationUpdates: false, sms: false, email: true },
      as: :json

    assert_response :success
    assert_equal false, data["newJobs"]
    assert_equal false, data["applicationUpdates"]
    assert_equal false, data["sms"]
    assert_equal true, data["email"]
  end
end
