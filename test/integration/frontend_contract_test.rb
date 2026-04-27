require "test_helper"

class FrontendContractTest < ActionDispatch::IntegrationTest
  test "worker can filter jobs down to followed companies only" do
    worker = create_worker
    worker.create_worker_profile!(followed_company_ids: [])

    followed_employer = create_employer(verified: true)
    other_employer = create_employer(verified: true)
    followed_job = create_job(employer: followed_employer, title: "Followed job")
    create_job(employer: other_employer, title: "Other job")

    worker.worker_profile.update!(followed_company_ids: [ followed_employer.id ])

    get "/api/v1/jobs", params: { followingOnly: true }, headers: auth_headers(worker)

    assert_response :success
    assert_equal [ followed_job.id ], data.map { |job| job.fetch("id") }
  end

  test "candidate browse matches secondary trades and only reveals contact after acceptance" do
    employer = create_employer(verified: true)
    worker = create_worker(email: "worker@example.com")
    worker.update!(email_verified: true)
    worker.create_worker_profile!(
      first_name: "Ava",
      last_name: "Stone",
      primary_trade: "Carpenter",
      secondary_trades: [ "Electrician" ],
      city: "Toronto - Central"
    )

    get "/api/v1/workers/candidates", params: { trade: "Electrician" }, headers: auth_headers(employer)

    assert_response :success
    assert_equal 1, data.length
    assert_equal worker.id, data.first.fetch("workerId")
    assert_nil data.first["workerPhone"]
    assert_nil data.first["workerEmail"]

    employer.employer_interview_requests.create!(worker: worker, status: "accepted", responded_at: Time.current)

    get "/api/v1/workers/candidates", params: { trade: "Electrician" }, headers: auth_headers(employer)

    assert_response :success
    assert_equal worker.phone, data.first.fetch("workerPhone")
    assert_equal worker.email, data.first.fetch("workerEmail")
  end

  test "employer applications reveal worker contact only after an accepted interview request" do
    employer = create_employer(verified: true)
    job = create_job(employer: employer)
    worker = create_worker(email: "worker@example.com")
    worker.update!(email_verified: true)
    worker.create_worker_profile!(first_name: "Maya", last_name: "Lee")
    application = job.job_applications.create!(worker: worker, status: "pending")

    get "/api/v1/jobs/#{job.id}/applications", headers: auth_headers(employer)

    assert_response :success
    assert_equal application.id, data.first.fetch("id")
    assert_nil data.first["workerPhone"]
    assert_nil data.first["workerEmail"]

    employer.employer_interview_requests.create!(worker: worker, job: job, status: "accepted", responded_at: Time.current)

    get "/api/v1/jobs/#{job.id}/applications", headers: auth_headers(employer)

    assert_response :success
    assert_equal worker.phone, data.first.fetch("workerPhone")
    assert_equal worker.email, data.first.fetch("workerEmail")
  end

  test "employer verification payload includes submittedAt alias for admin queue state" do
    employer = create_employer(verified: false)
    submitted_at = 2.hours.ago.change(usec: 0)
    employer.employer_profile.update!(verification_submitted_at: submitted_at)

    get "/api/v1/employers/profile", headers: auth_headers(employer)

    assert_response :success
    assert_equal submitted_at.as_json, data.fetch("submittedAt")
    assert_equal submitted_at.as_json, data.fetch("verificationSubmittedAt")
  end
end
