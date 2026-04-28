require "test_helper"

class PushSenderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class FakeResponse
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  def with_stubbed_post(responses)
    captured = []
    responses = Array(responses)
    PushSender.class_eval do
      alias_method :__orig_post_json, :post_json
      define_method(:post_json) do |url, payload|
        captured << { url: url, payload: payload }
        body = responses.shift || { "data" => [] }
        raise body if body.is_a?(Exception)

        FakeResponse.new(JSON.generate(body))
      end
    end
    yield captured
  ensure
    PushSender.class_eval do
      remove_method :post_json
      alias_method :post_json, :__orig_post_json
      remove_method :__orig_post_json
    end
  end

  test "empty token list returns zero counts and makes no HTTP call" do
    with_stubbed_post([]) do |captured|
      result = PushSender.send_to_tokens([], title: "T", body: "B")

      assert_equal 0, result.sent_count
      assert_equal 0, result.failed_count
      assert_equal [], result.ticket_ids
      assert_equal [], result.errors
      assert_empty captured
    end
  end

  test "single batch posts one request, collects ticket ids, and persists device mappings" do
    tokens = %w[ExponentPushToken[a] ExponentPushToken[b] ExponentPushToken[c]]
    user = User.create!(phone: "4165550001", role: "worker", phone_verified: true)
    device_a = user.device_tokens.create!(expo_push_token: "ExponentPushToken[a]", platform: "ios", active: true)
    device_b = user.device_tokens.create!(expo_push_token: "ExponentPushToken[b]", platform: "ios", active: true)
    response = {
      "data" => [
        { "status" => "ok", "id" => "tk-1" },
        { "status" => "ok", "id" => "tk-2" },
        { "status" => "ok", "id" => "tk-3" }
      ]
    }

    with_stubbed_post([ response ]) do |captured|
      assert_enqueued_with(job: PushReceiptPollJob) do
        result = PushSender.send_to_tokens(tokens, title: "Hello", body: "World", data: { kind: "x" })

        assert_equal 3, result.sent_count
        assert_equal 0, result.failed_count
        assert_equal %w[tk-1 tk-2 tk-3], result.ticket_ids
        assert_equal [], result.errors
      end

      assert_equal 1, captured.length
      call = captured.first
      assert_equal PushSender::EXPO_SEND_ENDPOINT, call[:url]
      assert_equal 3, call[:payload].length
      assert_equal "Hello", call[:payload].first[:title]

      mappings = PushTicket.order(:ticket_id)
      assert_equal [ "tk-1", "tk-2" ], mappings.pluck(:ticket_id)
      assert_equal [ device_a.id, device_b.id ], mappings.pluck(:device_token_id)
      assert mappings.all? { |mapping| mapping.sent_at.present? }
    end
  end

  test "250 tokens are split into three batches" do
    tokens = Array.new(250) { |i| "ExponentPushToken[#{i}]" }
    responses = [
      { "data" => Array.new(100) { |i| { "status" => "ok", "id" => "a-#{i}" } } },
      { "data" => Array.new(100) { |i| { "status" => "ok", "id" => "b-#{i}" } } },
      { "data" => Array.new(50)  { |i| { "status" => "ok", "id" => "c-#{i}" } } }
    ]

    with_stubbed_post(responses) do |captured|
      result = PushSender.send_to_tokens(tokens, title: "T", body: "B")

      assert_equal 3, captured.length
      assert_equal [ 100, 100, 50 ], captured.map { |c| c[:payload].length }
      assert_equal 250, result.sent_count
      assert_equal 250, result.ticket_ids.length
    end
  end

  test "batch exceptions do not abort later batches and surface partial errors" do
    tokens = Array.new(150) { |i| "ExponentPushToken[#{i}]" }
    responses = [
      StandardError.new("expo timeout"),
      { "data" => Array.new(50) { |i| { "status" => "ok", "id" => "b-#{i}" } } }
    ]

    with_stubbed_post(responses) do |captured|
      result = PushSender.send_to_tokens(tokens, title: "T", body: "B")

      assert_equal 2, captured.length
      assert_equal 50, result.sent_count
      assert_equal 100, result.failed_count
      assert_equal 50, result.ticket_ids.length
      assert_equal 100, result.errors.length
      assert result.errors.all? { |error| error[:message].include?("expo timeout") }
      assert_equal tokens.first(100), result.errors.map { |error| error[:token] }
    end
  end

  test "short Expo batch responses count missing tickets as failures" do
    tokens = %w[ExponentPushToken[a] ExponentPushToken[b] ExponentPushToken[c]]
    response = {
      "data" => [
        { "status" => "ok", "id" => "tk-1" },
        { "status" => "ok", "id" => "tk-2" }
      ]
    }

    with_stubbed_post([ response ]) do |_captured|
      result = PushSender.send_to_tokens(tokens, title: "T", body: "B")

      assert_equal 2, result.sent_count
      assert_equal 1, result.failed_count
      assert_equal %w[tk-1 tk-2], result.ticket_ids
      assert_equal [ "ExponentPushToken[c]" ], result.errors.map { |error| error[:token] }
      assert_equal "Expo returned fewer tickets than messages sent", result.errors.first[:message]
      assert_equal({ "error" => "ShortResponse" }, result.errors.first[:details])
    end
  end

  test "DeviceNotRegistered ticket error deactivates the matching device token" do
    user = User.create!(phone: "4165550987", role: "worker", phone_verified: true)
    user.device_tokens.create!(expo_push_token: "ExponentPushToken[bad]", platform: "ios", active: true)

    response = {
      "data" => [
        {
          "status" => "error",
          "message" => "device not registered",
          "details" => { "error" => "DeviceNotRegistered" }
        }
      ]
    }

    with_stubbed_post([ response ]) do |_captured|
      result = PushSender.send_to_tokens([ "ExponentPushToken[bad]" ], title: "T", body: "B")

      assert_equal 0, result.sent_count
      assert_equal 1, result.failed_count
      assert_equal 1, result.errors.length
      assert_equal "DeviceNotRegistered", result.errors.first[:details]["error"]
    end

    refute user.device_tokens.first.reload.active
  end

  test "PushReceiptPollJob is not enqueued when there are no successful tickets" do
    response = {
      "data" => [
        { "status" => "error", "message" => "boom", "details" => { "error" => "MessageRateExceeded" } }
      ]
    }

    with_stubbed_post([ response ]) do |_captured|
      assert_no_enqueued_jobs only: PushReceiptPollJob do
        PushSender.send_to_tokens([ "ExponentPushToken[x]" ], title: "T", body: "B")
      end
    end
  end

  test "fetch_receipts batches and merges responses" do
    ticket_ids = Array.new(150) { |i| "tk-#{i}" }
    responses = [
      { "data" => ticket_ids.first(100).index_with { |_id| { "status" => "ok" } } },
      { "data" => ticket_ids.last(50).index_with  { |_id| { "status" => "ok" } } }
    ]

    with_stubbed_post(responses) do |captured|
      receipts = PushSender.fetch_receipts(ticket_ids)

      assert_equal 2, captured.length
      assert_equal ticket_ids.first(100), captured[0][:payload][:ids]
      assert_equal ticket_ids.last(50), captured[1][:payload][:ids]
      assert_equal 150, receipts.size
    end
  end
end
