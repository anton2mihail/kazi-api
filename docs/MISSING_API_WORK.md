# Missing API Work

This file tracks product and platform behavior that was removed from the frontend or still lives as local UI state. The Rails API should own these before production launch.

## Contract And Client Support

- Generate and commit an OpenAPI 3.1 spec for all `/api/v1` routes.
- Add request/response schemas for auth, users, profiles, jobs, applications, admin actions, notifications, reports, reviews, and work history.
- Add a worker-only tag/group for the mobile app so generated mobile clients can ignore employer and admin surfaces.
- Add stable error codes and include `request_id` in every error envelope.
- Add API integration/request specs that validate the OpenAPI examples against real responses.

## Authentication And Sessions

- Wire OTP delivery to Twilio in non-development environments.
- Move OTP challenge storage/rate-limit counters to Redis or add explicit cleanup jobs for database-backed challenges.
- Add resend throttles, max daily challenge limits per phone/IP, and lockout behavior.
- Decide whether the web client should use bearer tokens or HttpOnly cookie sessions; implement one canonical web session strategy.
- Add account deletion, logout-all-sessions, and session listing/revocation endpoints.

## Worker Domain

- Persist every worker profile field currently represented in the web UI: custom certifications, verified certifications, work radius, transportation, own tools, driving licenses, profile update timestamp, gender, followed companies, and email verification state.
- Add email verification and backup email flows.
- Add phone change flow with OTP verification.
- Add saved/followed companies endpoints.
- Add profile completeness calculation on the server or document that it remains client-only.

## Employer Domain

- Persist every employer profile field currently represented in the web UI: job title, email, phone, office locations, service areas, social media links, verification step, verification state, and benefits.
- Add employer verification submission state and timestamps.
- Add admin-controlled verification transitions: approve, reject, request more information, suspend, unsuspend.
- Add invite code models/endpoints with pre-approved status, intended company/contact, usage tracking, expiration, and audit events.
- Add employer notification hooks for verification decisions.

## Jobs And Applications

- Add support for job archiving/soft deletion, reposting, expiration renewal, and fraud flagging.
- Add server-side filtering/sorting for trade, location, pay range, following-only jobs, and search query.
- Add duplicate application handling with a stable error code.
- Add application withdrawal by workers.
- Add application status transition rules for employers and workers.
- Add applicant counts optimized on the server instead of requiring the web client to tally all applications.

## Interviews, Contact Exchange, And Messaging

- Add interview request models/endpoints with status values: pending, accepted, declined, cancelled.
- Enforce monthly interview request limits for employers.
- Reveal contact details only after an accepted interview request.
- Add message/body storage for interview requests and retention policy.
- Add notification fanout for interview requests and responses.

## Work History And Reviews

- Add work history records for completed jobs.
- Implement worker marks complete, employer confirms, employer disputes, auto-verify after no response, and resolution states.
- Add worker and employer reviews tied to verified work history.
- Add rating aggregates and verified-job counts.
- Add moderation/audit trail for disputed reviews and work history.

## Fraud Reports And Compliance

- Add report endpoints for fraudulent job postings and user complaints.
- Add anonymous report support where legally appropriate.
- Add admin review queue, decision outcomes, and retained evidence records.
- Add soft-delete/archive behavior for retained records.
- Add data export, correction, and deletion request workflows for PIPEDA support.

## Notifications

- Add notification models and read/unread endpoints.
- Add preference endpoints for job alerts, application updates, SMS, and email.
- Add SMS/email dispatch jobs with provider failure/retry handling.
- Add notification templates for OTP, verification decisions, interview requests, application status changes, and fraud report outcomes.

## Admin API

- Add admin authentication and authorization.
- Add audit logging for every admin mutation.
- Add employer verification queue endpoints.
- Add invite code endpoints.
- Add fraud report moderation endpoints.
- Add dashboard counters for pending, approved, rejected, reports, and invite usage.

## Operations

- Add Capistrano deployment scripts and environment documentation.
- Configure Puma, Nginx, SSL, Postgres backups, Redis, and Sidekiq.
- Add health checks for database, Redis, and background jobs.
- Add structured logging and error reporting.
- Add recurring cleanup jobs for expired OTP challenges, expired sessions, expired jobs, and old soft-deleted records after retention windows.
