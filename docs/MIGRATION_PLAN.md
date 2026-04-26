# Kazitu Rails Backend Migration Plan

## Target

Rails owns the backend completely:

```text
Next.js web app   -> Rails API
Worker mobile app -> Rails API
Admin UI          -> Rails API

Rails API         -> Postgres
Rails API         -> Redis
Sidekiq           -> Redis
Deployment        -> Capistrano
```

Supabase will be removed. Rails will own auth, sessions, persistence, authorization, validation, background jobs, audit logs, and the public API contract.

## Principles

- Move behavior by product domain, not by file copy.
- Rails is the source of truth for product rules.
- Postgres stores durable state.
- Redis stores sessions, rate-limit state, short-lived challenges, cache, and Sidekiq queues.
- OpenAPI documents the server contract before clients cut over.
- The Next.js app becomes a frontend client only.

## Phases

1. Backend foundation: app structure, auth primitives, CORS, rate limiting, error format, health endpoint.
2. Data model: users, profiles, jobs, applications, interviews, notifications, reviews, reports, invites, audit events.
3. Worker API: auth, profile, job search, job details, apply, withdraw, application history.
4. Employer API: company profile, verification state, jobs, applicants, status transitions.
5. Admin API: admin sessions, employer approvals, invite codes, fraud tooling, audit feed.
6. Persistence replacement: move mock web state into Postgres-backed Rails models.
7. Web cutover: replace browser Supabase calls with Rails API calls.
8. Supabase removal: delete Supabase client code, migrations, and environment variables from the web app.
9. Deployment: Capistrano, Puma, Nginx, Postgres, Redis, Sidekiq, SSL.

## First Cutover Slice

The first production-shaped slice should be worker-only:

```text
POST /api/v1/auth/otp/start
POST /api/v1/auth/otp/verify
POST /api/v1/auth/logout
GET  /api/v1/me
GET  /api/v1/reference/trades
GET  /api/v1/reference/locations
GET  /api/v1/workers/me/profile
PUT  /api/v1/workers/me/profile
GET  /api/v1/jobs
GET  /api/v1/jobs/:id
POST /api/v1/jobs/:id/applications
GET  /api/v1/applications
PATCH /api/v1/applications/:id
```

## Standard Error Shape

```json
{
  "ok": false,
  "error": {
    "code": "string",
    "message": "string",
    "request_id": "string"
  }
}
```
