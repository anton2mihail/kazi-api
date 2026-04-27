# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

default_origins = [
  "http://localhost:3000",
  "http://127.0.0.1:3000",
  "http://localhost:3001",
  "http://127.0.0.1:3001",
  "http://localhost:3201",
  "http://127.0.0.1:3201"
]

allowed_origins = ENV.fetch("KAZITU_ALLOWED_ORIGINS", default_origins.join(",")).split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      credentials: true,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
