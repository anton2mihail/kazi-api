require "test_helper"

class CorsTest < ActionDispatch::IntegrationTest
  test "allows local frontend development origins" do
    process :options,
      "/api/v1/auth/otp/start",
      headers: {
        "Origin" => "http://127.0.0.1:3001",
        "Access-Control-Request-Method" => "POST",
        "Access-Control-Request-Headers" => "content-type"
      }

    assert_response :success
    assert_equal "http://127.0.0.1:3001", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "POST"
  end

  test "allows live e2e frontend origin" do
    process :options,
      "/api/v1/auth/otp/start",
      headers: {
        "Origin" => "http://127.0.0.1:3201",
        "Access-Control-Request-Method" => "POST",
        "Access-Control-Request-Headers" => "content-type"
      }

    assert_response :success
    assert_equal "http://127.0.0.1:3201", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "POST"
  end
end
