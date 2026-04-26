class Rack::Attack
  throttle("requests/ip", limit: 300, period: 5.minutes) do |request|
    request.ip
  end

  throttle("auth/ip", limit: 20, period: 10.minutes) do |request|
    request.ip if request.path.start_with?("/api/v1/auth/")
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
