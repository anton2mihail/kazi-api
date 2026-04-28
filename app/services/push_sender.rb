require "net/http"
require "uri"
require "json"

class PushSender
  EXPO_SEND_ENDPOINT = "https://exp.host/--/api/v2/push/send".freeze
  EXPO_RECEIPTS_ENDPOINT = "https://exp.host/--/api/v2/push/getReceipts".freeze
  BATCH_SIZE = 100
  RECEIPT_POLL_DELAY = 30.seconds

  Result = Struct.new(:sent_count, :failed_count, :ticket_ids, :errors, keyword_init: true)

  def self.send_to_user(user, title:, body:, data: {})
    tokens = user.device_tokens.active.pluck(:expo_push_token)
    new.send_to_tokens(tokens, title: title, body: body, data: data)
  end

  def self.send_to_tokens(tokens, title:, body:, data: {})
    new.send_to_tokens(tokens, title: title, body: body, data: data)
  end

  def self.fetch_receipts(ticket_ids)
    new.fetch_receipts(ticket_ids)
  end

  def send_to_tokens(tokens, title:, body:, data: {})
    tokens = Array(tokens).compact
    return Result.new(sent_count: 0, failed_count: 0, ticket_ids: [], errors: []) if tokens.empty?

    sent = 0
    failed = 0
    ticket_ids = []
    errors = []
    device_tokens_by_token = DeviceToken.where(expo_push_token: tokens).index_by(&:expo_push_token)

    tokens.each_slice(BATCH_SIZE) do |batch|
      messages = batch.map { |token| message_for(token, title, body, data) }

      begin
        response = post_json(EXPO_SEND_ENDPOINT, messages)
        tickets = parse_data(response)
      rescue StandardError => e
        failed += batch.length
        errors.concat(batch.map { |token| batch_error(token, e) })
        next
      end

      tickets.each_with_index do |ticket, idx|
        token = batch[idx]
        next if token.nil?

        if ticket["status"] == "ok"
          sent += 1
          if ticket["id"]
            ticket_ids << ticket["id"]
            persist_push_ticket(ticket["id"], device_tokens_by_token[token])
          end
        else
          failed += 1
          errors << {
            token: token,
            message: ticket["message"],
            details: ticket["details"]
          }
          handle_immediate_error(token, ticket["details"])
        end
      end

      if tickets.length < batch.length
        batch[tickets.length..].to_a.each do |token|
          failed += 1
          errors << short_response_error(token)
        end
      end
    end

    PushReceiptPollJob.set(wait: RECEIPT_POLL_DELAY).perform_later(ticket_ids) if ticket_ids.any?

    Result.new(sent_count: sent, failed_count: failed, ticket_ids: ticket_ids, errors: errors)
  end

  def fetch_receipts(ticket_ids)
    ticket_ids = Array(ticket_ids).compact
    return {} if ticket_ids.empty?

    receipts = {}
    ticket_ids.each_slice(BATCH_SIZE) do |batch|
      response = post_json(EXPO_RECEIPTS_ENDPOINT, { ids: batch })
      body = parse_body(response)
      receipts.merge!(body["data"] || {})
    end
    receipts
  end

  private

  def message_for(token, title, body, data)
    { to: token, sound: "default", title: title, body: body, data: data }
  end

  def post_json(url, payload)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      req["Accept-Encoding"] = "gzip, deflate"
      req.body = JSON.generate(payload)
      http.request(req)
    end
  end

  def parse_body(response)
    JSON.parse(response.body)
  rescue StandardError
    {}
  end

  def parse_data(response)
    body = parse_body(response)
    body["data"] || []
  end

  def batch_error(token, error)
    {
      token: token,
      message: error.message,
      details: { "error" => error.class.name }
    }
  end

  def short_response_error(token)
    {
      token: token,
      message: "Expo returned fewer tickets than messages sent",
      details: { "error" => "ShortResponse" }
    }
  end

  def persist_push_ticket(ticket_id, device_token)
    return if device_token.nil?

    PushTicket.create!(ticket_id: ticket_id, device_token: device_token, sent_at: Time.current)
  end

  def handle_immediate_error(token, details)
    return unless details.is_a?(Hash) && details["error"] == "DeviceNotRegistered"

    DeviceToken.where(expo_push_token: token).find_each(&:deactivate!)
  end
end
