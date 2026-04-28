require "test_helper"

class UserTest < ActiveSupport::TestCase
  def make_user(role: "worker")
    User.create!(phone: unique_phone, role: role, phone_verified: true)
  end

  def unique_phone
    "416#{SecureRandom.random_number(10_000_000).to_s.rjust(7, "0")}"
  end

  test "suspended? reflects presence of suspended_at" do
    user = make_user
    refute user.suspended?

    user.update!(suspended_at: Time.current)
    assert user.suspended?
  end

  test "suspend! sets suspended_at, reason, and actor" do
    actor = make_user(role: "admin")
    user = make_user

    freeze = Time.utc(2026, 4, 27, 12, 0, 0)
    user.suspend!(reason: "Repeated no-shows", by: actor, at: freeze)

    user.reload
    assert user.suspended?
    assert_equal freeze, user.suspended_at
    assert_equal "Repeated no-shows", user.suspension_reason
    assert_equal actor.id, user.suspended_by_id
  end

  test "suspend! treats blank reason as nil" do
    user = make_user
    user.suspend!(reason: "")

    assert_nil user.reload.suspension_reason
    assert user.suspended?
  end

  test "unsuspend! clears all suspension fields" do
    actor = make_user(role: "admin")
    user = make_user
    user.suspend!(reason: "x", by: actor)

    user.unsuspend!
    user.reload

    refute user.suspended?
    assert_nil user.suspended_at
    assert_nil user.suspension_reason
    assert_nil user.suspended_by_id
  end

  test "suspended scope returns only suspended users" do
    a = make_user
    b = make_user
    a.suspend!

    assert_includes User.suspended, a
    refute_includes User.suspended, b
  end

  test "destroying a user destroys associated device tokens" do
    user = make_user
    user.device_tokens.create!(expo_push_token: "ExponentPushToken[xyz#{SecureRandom.hex(4)}]", platform: "ios", active: true)
    assert_equal 1, user.device_tokens.count

    assert_difference -> { DeviceToken.count }, -1 do
      user.destroy!
    end
  end

  test "not_suspended scope returns only active users" do
    a = make_user
    b = make_user
    a.suspend!

    refute_includes User.not_suspended, a
    assert_includes User.not_suspended, b
  end
end
