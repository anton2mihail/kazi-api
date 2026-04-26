class Rack::Attack
  throttle("requests/ip", limit: 300, period: 5.minutes) do |request|
    request.ip
  end

  throttle("auth/ip", limit: 20, period: 10.minutes) do |request|
    request.ip if request.path.start_with?("/api/v1/auth/")
  end

  throttle("otp/start/phone", limit: 5, period: 10.minutes) do |request|
    next unless request.post? && request.path == "/api/v1/auth/otp/start"

    request.params["phone"].to_s.gsub(/\D/, "").delete_prefix("1").presence
  end

  throttle("otp/verify/phone", limit: 10, period: 10.minutes) do |request|
    next unless request.post? && request.path == "/api/v1/auth/otp/verify"

    request.ip
  end

  self.throttled_responder = lambda do |request|
    [
      429,
      { "Content-Type" => "application/json" },
      [
        {
          ok: false,
          error: {
            code: "rate_limited",
            message: "Too many requests. Please try again later.",
            request_id: request.env["action_dispatch.request_id"]
          }
        }.to_json
      ]
    ]
  end
end
