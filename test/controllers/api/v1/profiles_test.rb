require "test_helper"

class ApiV1ProfilesTest < ActionDispatch::IntegrationTest
  test "worker profile persists frontend fields and user email state" do
    worker = create_worker

    put "/api/v1/workers/profile",
      headers: auth_headers(worker),
      params: {
        firstName: "Ada",
        lastName: "Trades",
        email: "ADA@example.com",
        emailVerified: true,
        trades: [ "Carpenter", "Framer" ],
        startMonth: "04",
        startYear: "2020",
        location: "Toronto - Central",
        workAreas: [ "Hamilton" ],
        availability: [ "Weekdays" ],
        certifications: [ "WHMIS 2015" ],
        customCertifications: [ "Forklift" ],
        verifiedCerts: [ "WHMIS 2015" ],
        skills: [ "Framing" ],
        skillsAddedAt: "2026-04-26T12:00:00Z",
        hourlyRate: "42",
        workRadius: "50",
        hasTransportation: true,
        hasOwnTools: true,
        drivingLicenses: [ "G", "Forklift" ],
        gender: "female",
        followedCompanies: [ create_employer.id ]
      },
      as: :json

    assert_response :success
    assert_equal "Ada", data["firstName"]
    assert_equal [ "Carpenter", "Framer" ], data["trades"]
    assert_equal [ "Forklift" ], data["customCertifications"]
    assert_equal [ "WHMIS 2015" ], data["verifiedCerts"]
    assert_equal true, data["hasTransportation"]
    assert_equal true, data["hasOwnTools"]
    assert_equal [ "G", "Forklift" ], data["drivingLicenses"]
    assert_equal "ada@example.com", data["email"]
    assert_equal true, data["emailVerified"]
    assert_equal 42, data["hourlyRate"]
  end

  test "employer profile persists verification-adjacent frontend fields" do
    employer = create_employer

    put "/api/v1/employers/profile",
      headers: auth_headers(employer),
      params: {
        companyName: "Kazitu Build",
        contactName: "Morgan",
        jobTitle: "Owner",
        email: "owner@kazitu.test",
        phone: "+1 (416) 555-0201",
        headquarters: "Toronto - Central",
        officeLocations: [ "Hamilton" ],
        serviceAreas: [ "Toronto - Central", "Hamilton" ],
        companySize: "6-10",
        industryType: "Residential Construction",
        website: "https://example.test",
        benefits: [ "Health & Dental" ],
        socialMedia: { linkedin: "linkedin.com/company/kazitu" },
        description: "Residential projects"
      },
      as: :json

    assert_response :success
    assert_equal "Kazitu Build", data["companyName"]
    assert_equal "Owner", data["jobTitle"]
    assert_equal "owner@kazitu.test", data["email"]
    assert_equal "4165550201", data["phone"]
    assert_equal [ "Hamilton" ], data["officeLocations"]
    assert_equal "linkedin.com/company/kazitu", data.dig("socialMedia", "linkedin")
    assert_equal "pending", data["verificationStatus"]
    assert_equal 3, data["verificationStep"]
    assert data["verificationSubmittedAt"].present?
  end
end
