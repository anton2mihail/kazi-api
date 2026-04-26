require "test_helper"

class ApiV1AdminTest < ActionDispatch::IntegrationTest
  test "admins can approve reject and request more info for employer verification" do
    admin = create_admin
    employer = create_employer(verified: false)
    profile_id = employer.employer_profile.id

    get "/api/v1/admin/employer_verifications",
      headers: auth_headers(admin),
      as: :json

    assert_response :success
    assert data.any? { |profile| profile["id"] == profile_id }

    patch "/api/v1/admin/employer_verifications/#{profile_id}/approve",
      headers: auth_headers(admin),
      params: { notes: "Looks good" },
      as: :json

    assert_response :success
    assert_equal true, data["verified"]
    assert_equal "approved", data["verificationStatus"]
    assert_equal 4, data["verificationStep"]
    assert_equal 1, AuditLog.where(action: "employer_verification.approve").count

    patch "/api/v1/admin/employer_verifications/#{profile_id}/request_more_info",
      headers: auth_headers(admin),
      params: { notes: "Need registry" },
      as: :json

    assert_response :success
    assert_equal "more_info_requested", data["verificationStatus"]
    assert_equal 2, data["verificationStep"]

    patch "/api/v1/admin/employer_verifications/#{profile_id}/reject",
      headers: auth_headers(admin),
      params: { notes: "Could not verify" },
      as: :json

    assert_response :success
    assert_equal false, data["verified"]
    assert_equal "rejected", data["verificationStatus"]
  end

  test "admins can suspend and unsuspend employers" do
    admin = create_admin
    employer = create_employer(verified: true)

    patch "/api/v1/admin/employers/#{employer.id}/suspend",
      headers: auth_headers(admin),
      params: { notes: "Policy review" },
      as: :json

    assert_response :success
    assert_equal false, data["verified"]
    assert_equal "suspended", data["verificationStatus"]

    patch "/api/v1/admin/employers/#{employer.id}/unsuspend",
      headers: auth_headers(admin),
      as: :json

    assert_response :success
    assert_equal true, data["verified"]
    assert_equal "approved", data["verificationStatus"]
  end

  test "admins can create and update invite codes" do
    admin = create_admin

    post "/api/v1/admin/invite_codes",
      headers: auth_headers(admin),
      params: { companyName: "Target Co", contactEmail: "owner@example.com", preApproved: true },
      as: :json

    assert_response :created
    invite_id = data["id"]
    assert data["code"].present?
    assert_equal "Target Co", data["companyName"]
    assert_equal true, data["preApproved"]

    patch "/api/v1/admin/invite_codes/#{invite_id}",
      headers: auth_headers(admin),
      params: { companyName: "Target Co Updated", preApproved: false },
      as: :json

    assert_response :success
    assert_equal "Target Co Updated", data["companyName"]
    assert_equal false, data["preApproved"]
  end

  test "non admins cannot access admin endpoints" do
    employer = create_employer

    get "/api/v1/admin/employer_verifications",
      headers: auth_headers(employer),
      as: :json

    assert_response :forbidden
    assert_equal "wrong_role", error["code"]
  end
end
