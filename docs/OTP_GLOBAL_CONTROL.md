# OTP Global Control — Setup & Usage Guide

## Overview

AJKMart uses a unified **OTP Global Control** panel in the admin dashboard to manage all OTP-related settings from a single place. This eliminates duplicate toggles across the codebase.

### Middleware Priority (enforced in `auth.ts`)

```
1. Per-user bypass  →  otpBypassUntil on the users row
2. Global suspension  →  otp_global_disabled_until setting
3. Legacy danger-zone toggle  →  security_otp_bypass setting
4. Normal OTP flow
```

---

## OTP in Demo / Development

When no SMS or email provider is configured, OTPs are printed to the **server console** (stdout). Look for lines like:

```
[OTP] user@example.com → 481920  (expires in 5 min)
```

This is intentional for development. Configure an SMS/SMTP/WhatsApp provider in **Settings → Integrations** for production delivery.

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` / `NEON_DATABASE_URL` | Yes | PostgreSQL connection string |
| `JWT_SECRET` | Yes | Signs customer/vendor/rider JWTs |
| `ADMIN_SECRET` | Yes | Admin panel secret key |
| `OTP_EXPIRY_MINUTES` | No | OTP validity window (default: 5) |

---

## Admin Panel — OTP Global Control Page

Access via **Sidebar → OTP Global Control**.

### Card 1: Global Suspension

Suspend OTP for **all users** system-wide:

- **Toggle** the suspension on/off immediately.
- **Duration** (optional): enter minutes. The server sets `otp_global_disabled_until` and auto-resumes at expiry.
- While suspended:
  - **New user registration** skips OTP entirely and sets the account active.
  - **Existing user login** skips the OTP step and issues a JWT directly.
  - All skipped logins are written to the audit log with reason `global_suspension`.

### Card 2: Per-User OTP Bypass

Grant an individual user a temporary OTP-free login window:

1. Search by name, email, or phone.
2. Select a user from the results.
3. Choose a bypass duration (15 min → 24 h).
4. Click **Grant Bypass**.

The bypass is stored on the `users.otp_bypass_until` column and auto-expires — no cron job needed; the middleware checks the timestamp on every login.

To cancel early, click **Cancel Bypass** on the active bypass chip.

### Card 3: No-OTP Login Audit Log

Every login that skipped OTP (for any reason) is logged with:

- Timestamp, user name, email, role
- Reason: `per_user_bypass` | `global_suspension` | `danger_zone_bypass`
- The 50 most recent events are shown (newest first).

---

## API Endpoints

### Global Suspension

| Method | Path | Description |
|---|---|---|
| `GET` | `/admin/otp/status` | Current suspension state + remaining seconds |
| `POST` | `/admin/otp/disable` | Suspend OTP. Body: `{ minutes?: number }` |
| `DELETE` | `/admin/otp/disable` | Restore OTP immediately |

### Per-User Bypass

| Method | Path | Description |
|---|---|---|
| `POST` | `/admin/users/:id/otp/bypass` | Grant bypass. Body: `{ minutes: number }` |
| `DELETE` | `/admin/users/:id/otp/bypass` | Cancel bypass immediately |

### Audit Log

| Method | Path | Description |
|---|---|---|
| `GET` | `/admin/otp/audit` | Last 50 no-OTP login events |

### Authentication

All `/admin/*` routes require the `x-admin-token` header containing the `ADMIN_SECRET` value.

---

## Email/Password Login with OTP (Two-step)

1. `POST /auth/login` → `{ email, password }` → returns `{ requiresOtp: true, tempToken: "..." }`
2. OTP is printed to server console (or sent via configured provider).
3. `POST /auth/login/verify-otp` → `{ tempToken, otp }` → returns `{ token: "JWT..." }`

The `tempToken` is a short-lived JWT (5 min) that can only be exchanged for an auth token via the OTP step.

---

## What Was Removed / Consolidated

| Location | Removed |
|---|---|
| `settings-security.tsx` | `security_otp_bypass` danger-zone toggle |
| `security.tsx` | Same `security_otp_bypass` toggle |
| OTP channels, rate limits tabs | Removed from OTP page (5 tabs → 3 cards) |

OTP delivery channels and rate limits are still configurable in **Settings → Integrations** and **Settings → Security** respectively.
