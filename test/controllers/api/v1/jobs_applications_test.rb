require "test_helper"

class ApiV1JobsApplicationsTest < ActionDispatch::IntegrationTest
  test "unverified employers cannot create jobs" do
    employer = create_employer(verified: false)

    post "/api/v1/jobs",
      headers: auth_headers(employer),
      params: job_params,
      as: :json

    assert_response :forbidden
    assert_equal "employer_not_verified", error["code"]
  end

  test "verified employers can create update repost and archive jobs" do
    employer = create_employer(verified: true)

    post "/api/v1/jobs",
      headers: auth_headers(employer),
      params: job_params.merge(urgent: true),
      as: :json

    assert_response :created
    job_id = data["id"]
    assert_equal "Mason needed", data["title"]
    assert_equal true, data["urgent"]

    patch "/api/v1/jobs/#{job_id}",
      headers: auth_headers(employer),
      params: { title: "Senior mason", trade: "Carpenter", location: "Hamilton", payMin: 45, type: "Contract", duration: "3 months", description: "Updated" },
      as: :json

    assert_response :success
    assert_equal "Senior mason", data["title"]
    assert_equal "Hamilton", data["location"]

    patch "/api/v1/jobs/#{job_id}/repost", headers: auth_headers(employer), as: :json
    assert_response :success
    assert_equal "active", data["status"]
    assert data["expiresAt"].present?

    patch "/api/v1/jobs/#{job_id}/archive", headers: auth_headers(employer), as: :json
    assert_response :success
    assert_equal "closed", data["status"]

    get "/api/v1/jobs/#{job_id}", headers: auth_headers(employer), as: :json
    assert_response :not_found
  end

  test "job index returns applicant counts and supports search filters" do
    employer = create_employer(verified: true)
    worker = create_worker
    job = create_job(employer: employer, title: "Finish Carpenter")
    job.job_applications.create!(worker: worker, status: "pending")

    get "/api/v1/jobs?q=Finish&trade=Carpenter&payRange=%2430%2B",
      headers: auth_headers(worker),
      as: :json

    assert_response :success
    assert_equal 1, data.length
    assert_equal job.id, data.first["id"]
    assert_equal 1, data.first["applicantCount"]
  end

  test "workers can apply once and employers receive rich applicant payloads" do
    employer = create_employer(verified: true)
    worker = create_worker(email: "worker@example.com")
    worker.update!(email_verified: true)
    worker.create_worker_profile!(
      first_name: "Wendy",
      last_name: "Worker",
      primary_trade: "Carpenter",
      city: "Toronto",
      certifications: [ "WHMIS 2015" ],
      custom_certifications: [ "Forklift" ],
      skills: [ "Framing" ],
      hourly_rate_min_cents: 3_500,
      has_transportation: true,
      has_own_tools: true,
      driving_licenses: [ "G" ]
    )
    job = create_job(employer: employer)

    post "/api/v1/jobs/#{job.id}/applications",
      headers: auth_headers(worker),
      params: { coverNote: "Interested" },
      as: :json

    assert_response :created
    assert_equal job.id, data["jobId"]

    post "/api/v1/jobs/#{job.id}/applications",
      headers: auth_headers(worker),
      params: { coverNote: "Again" },
      as: :json

    assert_response :conflict
    assert_equal "duplicate_application", error["code"]

    get "/api/v1/jobs/#{job.id}/applications", headers: auth_headers(employer), as: :json

    assert_response :success
    applicant = data.first
    assert_equal "Wendy Worker", applicant["workerName"]
    assert_equal "Carpenter", applicant["trade"]
    assert_equal [ "WHMIS 2015", "Forklift" ], applicant["certifications"]
    assert_equal [ "G" ], applicant["drivingLicenses"]
    assert_equal true, applicant["emailVerified"]

    patch "/api/v1/applications/#{applicant['applicationId']}",
      headers: auth_headers(employer),
      params: { status: "shortlisted" },
      as: :json

    assert_response :success
    assert_equal "shortlisted", data["status"]
  end

  private

  def job_params
    {
      title: "Mason needed",
      trade: "Carpenter",
      location: "Toronto - Central",
      payMin: 35,
      payMax: 45,
      type: "Full-time",
      hoursPerWeek: "40+ hrs/week",
      duration: "Ongoing",
      description: "Build walls",
      requiredCerts: [ "WHMIS 2015" ],
      preferredCerts: [ "First Aid/CPR" ],
      requiredSkills: [ "Framing" ],
      preferredSkills: [ "Blueprint reading" ],
      benefits: [ "Health & Dental" ]
    }
  end
end
