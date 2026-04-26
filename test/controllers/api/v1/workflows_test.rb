require "test_helper"

class ApiV1WorkflowsTest < ActionDispatch::IntegrationTest
  test "verified employers can browse candidates" do
    employer = create_employer(verified: true)
    worker = create_worker
    worker.create_worker_profile!(
      first_name: "Cal",
      last_name: "Candidate",
      primary_trade: "Carpenter",
      city: "Toronto - Central",
      certifications: [ "WHMIS 2015" ]
    )

    get "/api/v1/workers/candidates?trade=Carpenter&location=Toronto%20-%20Central",
      headers: auth_headers(employer),
      as: :json

    assert_response :success
    assert_equal 1, data.length
    assert_equal worker.id, data.first["workerId"]
    assert_equal "Cal Candidate", data.first["workerName"]
  end

  test "unverified employers cannot browse candidates or create interview requests" do
    employer = create_employer(verified: false)
    worker = create_worker

    get "/api/v1/workers/candidates", headers: auth_headers(employer), as: :json
    assert_response :forbidden
    assert_equal "employer_not_verified", error["code"]

    post "/api/v1/interview_requests",
      headers: auth_headers(employer),
      params: { workerId: worker.id, message: "Talk?" },
      as: :json

    assert_response :forbidden
    assert_equal "employer_not_verified", error["code"]
  end

  test "interview requests hide contact info until accepted" do
    employer = create_employer(verified: true)
    worker = create_worker(email: "worker@example.com")
    worker.create_worker_profile!(first_name: "Ivy", last_name: "Interview", primary_trade: "Carpenter")
    job = create_job(employer: employer)

    post "/api/v1/interview_requests",
      headers: auth_headers(employer),
      params: { workerId: worker.id, jobId: job.id, message: "Can we talk?" },
      as: :json

    assert_response :created
    request_id = data["id"]
    assert_nil data["workerPhone"]
    assert_equal "pending", data["status"]

    patch "/api/v1/interview_requests/#{request_id}/respond",
      headers: auth_headers(worker),
      params: { status: "accepted" },
      as: :json

    assert_response :success
    assert_equal "accepted", data["status"]
    assert_equal worker.phone, data["workerPhone"]
    assert_equal "worker@example.com", data["workerEmail"]
    assert data["employerPhone"].present?
  end

  test "browse interview requests enforce monthly limit" do
    employer = create_employer(verified: true)
    InterviewRequest::MONTHLY_BROWSE_LIMIT.times do
      worker = create_worker
      worker.create_worker_profile!(first_name: "Worker", primary_trade: "Carpenter")
      employer.employer_interview_requests.create!(worker: worker, status: "pending")
    end

    extra_worker = create_worker
    extra_worker.create_worker_profile!(first_name: "Extra", primary_trade: "Carpenter")

    post "/api/v1/interview_requests",
      headers: auth_headers(employer),
      params: { workerId: extra_worker.id, message: "Talk?" },
      as: :json

    assert_response :forbidden
    assert_equal "monthly_limit_reached", error["code"]
  end

  test "work history can be created confirmed disputed and reviewed" do
    employer = create_employer(verified: true)
    worker = create_worker
    job = create_job(employer: employer)

    post "/api/v1/work_history",
      headers: auth_headers(worker),
      params: { jobId: job.id },
      as: :json

    assert_response :created
    history_id = data["id"]
    assert_equal "pending_employer", data["status"]
    assert_equal job.title, data["jobTitle"]

    patch "/api/v1/work_history/#{history_id}/confirm",
      headers: auth_headers(employer),
      params: { confirmed: true },
      as: :json

    assert_response :success
    assert_equal "verified", data["status"]
    assert_equal true, data["employerConfirmed"]

    post "/api/v1/work_history/#{history_id}/review",
      headers: auth_headers(employer),
      params: { rating: 5, review: "Great work" },
      as: :json

    assert_response :success
    assert_equal 5, data["employerRating"]
    assert_equal "Great work", data["employerReview"]

    patch "/api/v1/work_history/#{history_id}/dispute",
      headers: auth_headers(worker),
      params: { reason: "incorrect", details: "Need correction" },
      as: :json

    assert_response :success
    assert_equal "disputed", data["status"]
    assert_equal "incorrect", data["disputeReason"]
  end
end
