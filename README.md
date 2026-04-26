# Kazitu API

Rails API backend for Kazitu.

## Stack

- Rails 8 API mode
- PostgreSQL
- Redis-backed sessions
- Sidekiq
- Pundit authorization
- Rack::Attack rate limiting
- Capistrano deployment target

## Local Setup

```bash
mise install
mise exec -- bundle install
mise exec -- bin/rails db:prepare
mise exec -- bin/rails server
```

Health checks:

```text
GET /up
GET /api/v1/health
```

## Migration Context

This app replaces the Supabase-backed browser data layer in the existing Next.js app. Rails will own auth, sessions, data persistence, authorization, and API contracts.

See `docs/MIGRATION_PLAN.md`.
