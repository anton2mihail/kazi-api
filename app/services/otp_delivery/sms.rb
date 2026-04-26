require "net/http"

module OtpDelivery
  class Sms
    class DeliveryError < StandardError; end

    TWILIO_MESSAGES_PATH = "/2010-04-01/Accounts/%<account_sid>s/Messages.json"

    def self.deliver!(phone:, code:)
      new(phone: phone, code: code).deliver!
    end

    def initialize(phone:, code:)
      @phone = phone
      @code = code
    end

    def deliver!
      return true unless Rails.env.production?

      validate_config!

      uri = URI::HTTPS.build(
        host: "api.twilio.com",
        path: format(TWILIO_MESSAGES_PATH, account_sid: account_sid)
      )
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(account_sid, auth_token)
      request.set_form_data(
        "From" => from_number,
        "To" => e164_phone,
        "Body" => "Your Kazitu verification code is #{@code}."
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      return true if response.is_a?(Net::HTTPSuccess)

      raise DeliveryError, "Twilio rejected OTP delivery with HTTP #{response.code}"
    rescue Timeout::Error, SocketError, SystemCallError => error
      raise DeliveryError, error.message
    end

    private

    attr_reader :phone, :code

    def validate_config!
      missing = {
        "TWILIO_ACCOUNT_SID" => account_sid,
        "TWILIO_AUTH_TOKEN" => auth_token,
        "TWILIO_FROM_NUMBER" => from_number
      }.filter_map { |key, value| key if value.blank? }

      raise DeliveryError, "Missing #{missing.join(', ')}" if missing.any?
    end

    def account_sid
      ENV["TWILIO_ACCOUNT_SID"]
    end

    def auth_token
      ENV["TWILIO_AUTH_TOKEN"]
    end

    def from_number
      ENV["TWILIO_FROM_NUMBER"]
    end

    def e164_phone
      "+1#{phone}"
    end
  end
end
