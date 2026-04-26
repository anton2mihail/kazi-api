require "test_helper"

class ApiV1AuthOtpTest < ActionDispatch::IntegrationTest
  test "signup OTP start and verify creates a bearer-token session" do
    post "/api/v1/auth/otp/start",
      params: { phone: "+1 416 555 0199", purpose: "signup", role: "worker" },
      as: :json

    assert_response :created
    assert_equal true, json["ok"]
    assert data["challenge_id"].present?
    assert data["development_code"].present?

    post "/api/v1/auth/otp/verify",
      params: { challenge_id: data["challenge_id"], code: data["development_code"] },
      as: :json

    assert_response :success
    assert data["token"].present?
    assert_equal true, data["is_new_user"]
    assert_equal "worker", data.dig("user", "role")
    assert_equal "4165550199", data.dig("user", "phone")
  end

  test "login OTP rejects unknown phone numbers" do
    post "/api/v1/auth/otp/start",
      params: { phone: "+1 416 555 0198", purpose: "login" },
      as: :json

    assert_response :not_found
    assert_equal false, json["ok"]
    assert_equal "account_not_found", error["code"]
  end

  test "OTP verify rejects incorrect codes" do
    worker = create_worker(phone: "4165550197")

    post "/api/v1/auth/otp/start",
      params: { phone: worker.phone, purpose: "login" },
      as: :json

    assert_response :created

    post "/api/v1/auth/otp/verify",
      params: { challenge_id: data["challenge_id"], code: "000000" },
      as: :json

    assert_response :unauthorized
    assert_equal "incorrect_code", error["code"]
  end
end
