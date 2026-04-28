require "test_helper"

class PushReceiptPollJobTest < ActiveJob::TestCase
  def with_stubbed_receipts(receipts_by_call)
    calls = Array(receipts_by_call)
    captured = []
    PushSender.singleton_class.alias_method(:__orig_fetch_receipts, :fetch_receipts)
    PushSender.singleton_class.define_method(:fetch_receipts) do |ids|
      captured << ids
      calls.shift || {}
    end
    yield captured
  ensure
    PushSender.singleton_class.alias_method(:fetch_receipts, :__orig_fetch_receipts)
    PushSender.singleton_class.send(:remove_method, :__orig_fetch_receipts)
  end

  test "all-ok receipts do not enqueue a retry" do
    receipts = { "tk-1" => { "status" => "ok" }, "tk-2" => { "status" => "ok" } }

    with_stubbed_receipts([ receipts ]) do |_captured|
      assert_no_enqueued_jobs only: PushReceiptPollJob do
        PushReceiptPollJob.perform_now([ "tk-1", "tk-2" ])
      end
    end
  end

  test "pending receipts enqueue a retry with the pending subset and incremented attempt" do
    receipts = { "tk-1" => { "status" => "ok" } } # tk-2 missing -> pending

    with_stubbed_receipts([ receipts ]) do |_captured|
      assert_enqueued_with(job: PushReceiptPollJob, args: [ [ "tk-2" ], 2 ]) do
        PushReceiptPollJob.perform_now([ "tk-1", "tk-2" ], 1)
      end
    end
  end

  test "no further retry is enqueued after MAX_ATTEMPTS" do
    receipts = {} # all pending

    with_stubbed_receipts([ receipts ]) do |_captured|
      assert_no_enqueued_jobs only: PushReceiptPollJob do
        PushReceiptPollJob.perform_now([ "tk-1" ], PushReceiptPollJob::MAX_ATTEMPTS)
      end
    end
  end

  test "MAX_ATTEMPTS cleanup removes pending push ticket mappings" do
    user = User.create!(phone: "4165550009", role: "worker", phone_verified: true)
    device_token = user.device_tokens.create!(expo_push_token: "ExponentPushToken[pending]", platform: "ios", active: true)
    PushTicket.create!(ticket_id: "tk-pending", device_token: device_token, sent_at: Time.current)

    with_stubbed_receipts([ {} ]) do |_captured|
      assert_no_enqueued_jobs only: PushReceiptPollJob do
        PushReceiptPollJob.perform_now([ "tk-pending" ], PushReceiptPollJob::MAX_ATTEMPTS)
      end
    end

    assert_nil PushTicket.find_by(ticket_id: "tk-pending")
    assert device_token.reload.active
  end

  test "non-DeviceNotRegistered error path is exercised without raising" do
    receipts = {
      "tk-1" => { "status" => "error", "details" => { "error" => "MessageRateExceeded" } }
    }

    with_stubbed_receipts([ receipts ]) do |_captured|
      assert_nothing_raised do
        PushReceiptPollJob.perform_now([ "tk-1" ])
      end
    end
  end

  test "DeviceNotRegistered receipt deactivates the mapped device token" do
    user = User.create!(phone: "4165550002", role: "worker", phone_verified: true)
    device_token = user.device_tokens.create!(expo_push_token: "ExponentPushToken[receipt]", platform: "ios", active: true)
    PushTicket.create!(ticket_id: "tk-1", device_token: device_token, sent_at: Time.current)

    receipts = {
      "tk-1" => { "status" => "error", "details" => { "error" => "DeviceNotRegistered" } }
    }

    with_stubbed_receipts([ receipts ]) do |_captured|
      PushReceiptPollJob.perform_now([ "tk-1" ])
    end

    refute device_token.reload.active
    assert_nil PushTicket.find_by(ticket_id: "tk-1")
  end
end
