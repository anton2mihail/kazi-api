require "test_helper"

class ApiV1DevicesControllerTest < ActionDispatch::IntegrationTest
  test "register requires authentication" do
    post "/api/v1/devices",
      params: { expo_push_token: "ExponentPushToken[abc]", platform: "ios" },
      as: :json

    assert_response :unauthorized
  end

  test "register creates a new device" do
    worker = create_worker

    post "/api/v1/devices",
      headers: auth_headers(worker),
      params: {
        expo_push_token: "ExponentPushToken[new1]",
        platform: "ios",
        app_version: "1.0.0",
        locale: "en-CA"
      },
      as: :json

    assert_response :created
    device = data.fetch("device")
    assert_equal "ExponentPushToken[new1]", device["expo_push_token"]
    assert_equal "ios", device["platform"]
    assert_equal true, device["active"]
    assert device["last_seen_at"].present?
    assert_equal worker.id, DeviceToken.find(device["id"]).user_id
  end

  test "register updates an existing device for the same user and advances last_seen_at" do
    worker = create_worker
    record = DeviceToken.create!(
      user: worker,
      expo_push_token: "ExponentPushToken[same]",
      platform: "ios",
      active: true,
      last_seen_at: 1.hour.ago
    )
    earlier = record.last_seen_at

    post "/api/v1/devices",
      headers: auth_headers(worker),
      params: {
        expo_push_token: "ExponentPushToken[same]",
        platform: "ios",
        app_version: "1.0.1",
        locale: "fr-CA"
      },
      as: :json

    assert_response :success
    record.reload
    assert_equal "1.0.1", record.app_version
    assert_equal "fr-CA", record.locale
    assert record.last_seen_at > earlier
  end

  test "register reassigns an existing device to the current user" do
    original = create_worker
    new_owner = create_worker
    record = DeviceToken.create!(
      user: original,
      expo_push_token: "ExponentPushToken[reassign]",
      platform: "android",
      active: true,
      last_seen_at: 1.day.ago
    )

    post "/api/v1/devices",
      headers: auth_headers(new_owner),
      params: {
        expo_push_token: "ExponentPushToken[reassign]",
        platform: "android"
      },
      as: :json

    assert_response :success
    record.reload
    assert_equal new_owner.id, record.user_id
    assert_equal true, record.active
  end

  test "register returns 422 when required fields are missing" do
    worker = create_worker

    post "/api/v1/devices",
      headers: auth_headers(worker),
      params: { platform: "ios" },
      as: :json

    assert_response :unprocessable_entity
    assert_equal "validation_failed", error["code"]
  end

  test "destroy deactivates the device for the current user" do
    worker = create_worker
    record = DeviceToken.create!(
      user: worker,
      expo_push_token: "ExponentPushToken[del]",
      platform: "ios",
      active: true
    )

    delete "/api/v1/devices/#{CGI.escape(record.expo_push_token)}",
      headers: auth_headers(worker),
      as: :json

    assert_response :no_content
    assert_equal false, record.reload.active
  end

  test "destroy returns 404 for an unknown token" do
    worker = create_worker

    delete "/api/v1/devices/#{CGI.escape("ExponentPushToken[nope]")}",
      headers: auth_headers(worker),
      as: :json

    assert_response :not_found
  end
end
