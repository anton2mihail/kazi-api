require "redis-session-store"

session_options = {
  key: "_kazitu_api_session",
  expire_after: 30.days,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  serializer: :json,
  redis: {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    key_prefix: "kazitu:sessions:",
    expire_after: 30.days
  }
}

Rails.application.config.session_store(:redis_session_store, **session_options)
Rails.application.config.middleware.use RedisSessionStore, session_options
