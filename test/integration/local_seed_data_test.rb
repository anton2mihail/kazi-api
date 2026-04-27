require "test_helper"

class LocalSeedDataTest < ActionDispatch::IntegrationTest
  test "local seed data loads idempotently with usable demo accounts" do
    2.times { load Rails.root.join("db/seeds.rb") }

    worker = User.find_by!(phone: "4165550101")
    employer = User.find_by!(phone: "4165550201")
    pending_employer = User.find_by!(phone: "4165550203")

    assert_equal "worker", worker.role
    assert_equal "Nadia", worker.worker_profile.first_name
    assert_includes worker.worker_profile.followed_company_ids, employer.id

    assert_equal "employer", employer.role
    assert_predicate employer.employer_profile, :verified?
    assert_equal "approved", employer.employer_profile.verification_status

    refute_predicate pending_employer.employer_profile, :verified?
    assert_equal "pending", pending_employer.employer_profile.verification_status

    assert Job.current.where(title: "Finish Carpenter - Condo Lobby").exists?
    assert JobApplication.joins(:job).where(jobs: { title: "Finish Carpenter - Condo Lobby" }, worker: worker).exists?
    assert InterviewRequest.accepted.where(employer: employer, worker: worker).exists?
    assert InviteCode.active.where(code: "MAPLE1").exists?
  end

  test "seeded accounts can exercise frontend-facing API flows" do
    load Rails.root.join("db/seeds.rb")

    nadia = User.find_by!(phone: "4165550101")
    marco = User.find_by!(phone: "4165550102")
    maple = User.find_by!(phone: "4165550201")
    finish_job = Job.find_by!(title: "Finish Carpenter - Condo Lobby")

    get "/api/v1/jobs", headers: auth_headers(nadia), as: :json

    assert_response :success
    titles = data.map { |job| job.fetch("title") }
    assert_includes titles, "Finish Carpenter - Condo Lobby"
    assert_includes titles, "Licensed Electrician - Tenant Improvements"
    refute_includes titles, "Service Plumber - Completed Local Seed"

    get "/api/v1/applications", headers: auth_headers(nadia), as: :json

    assert_response :success
    nadia_application = data.find { |application| application.dig("job", "title") == finish_job.title }
    assert_equal "shortlisted", nadia_application.fetch("status")

    get "/api/v1/jobs/#{finish_job.id}/applications", headers: auth_headers(maple), as: :json

    assert_response :success
    revealed_applicant = data.find { |application| application.fetch("workerId") == nadia.id }
    assert_equal nadia.phone, revealed_applicant.fetch("workerPhone")
    assert_equal nadia.email, revealed_applicant.fetch("workerEmail")

    get "/api/v1/workers/candidates",
      params: { trade: "Electrician (Licensed)", location: "Toronto - West" },
      headers: auth_headers(maple)

    assert_response :success
    candidate = data.find { |worker| worker.fetch("workerId") == marco.id }
    assert_equal "Marco Rivera", candidate.fetch("workerName")
    assert_nil candidate["workerPhone"]
  end
end
