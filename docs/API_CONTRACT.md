# API Contract

The API is versioned under `/api/v1`.

## Authentication

Web sessions use secure HttpOnly cookies backed by Redis.

Mobile sessions use bearer tokens issued by Rails. Tokens are backed by server-side session records so they can be revoked.

## Response Envelope

Success:

```json
{
  "ok": true,
  "data": {}
}
```

Failure:

```json
{
  "ok": false,
  "error": {
    "code": "auth_required",
    "message": "Authentication required.",
    "request_id": "uuid"
  }
}
```

## Initial Route Groups

```text
/api/v1/auth/*
/api/v1/me
/api/v1/reference/*
/api/v1/workers/*
/api/v1/employers/*
/api/v1/jobs/*
/api/v1/applications/*
/api/v1/interviews/*
/api/v1/notifications/*
/api/v1/work-history/*
/api/v1/reviews/*
/api/v1/reports/*
/api/v1/admin/*
```
