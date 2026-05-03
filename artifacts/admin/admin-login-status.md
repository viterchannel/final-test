# AJKMart Admin Login — Binance-Grade Finalization Status

**Date:** 2026-04-23
**Scope:** Admin authentication only (customer / vendor / rider auth out of scope)

---

## Already in place before this task

- `artifacts/admin/src/lib/adminFetcher.ts` — Bearer + CSRF + auto-refresh
  fetcher (`fetchAdmin`, `fetchAdminAbsolute`).
- `artifacts/admin/src/lib/adminAuthContext.tsx` — in-memory access-token
  state, `useAdminAuth()` with `state`, `login`, `logout`, `refreshToken`.
- `artifacts/admin/src/pages/login.tsx` — uses `useAdminAuth().login()`,
  no sessionStorage writes.
- Admin SPA route surface — only `/login` is unauthenticated; all other
  routes are `<ProtectedRoute>`. No `/auth` route ever existed.
- Server `/api/admin/auth/*` (`adminAuthV2Router`) hosts the v2 login,
  refresh, sessions, logout, lockout, and CSRF endpoints.

---

## Completed in this task

### Server

- **`routes/admin-shared.ts`** — `adminAuth` middleware accepts BOTH legacy
  `JWT_SECRET` admin tokens (`verifyAdminJwt`) AND v2 access tokens
  (`verifyAccessToken` against `ADMIN_ACCESS_TOKEN_SECRET`). Enables
  zero-downtime cutover.
- **`lib/socketio.ts`** — `isAuthorizedForAdminFleet` now accepts:
  - `auth.token` (canonical Socket.IO v4 payload key).
  - v2 access tokens via `verifyAccessToken` on candidates and Bearer.
- **`routes/index.ts`** — `/api/auth` (legacy customer router) is now
  feature-flag gated by `ADMIN_LEGACY_AUTH_DISABLED`. Default mounted
  (customer app keeps working). Setting `=1` cleanly retires it.

### Client core

- **`lib/adminFetcher.ts`** — added:
  - `fetchAdminAbsolute(path, options)` — Bearer + CSRF + refresh on any
    absolute path.
  - `fetchAdminAbsoluteResponse(path, options)` — same but returns raw
    `Response` (for binary/CSV downloads with auto-refresh).
  - `getAdminAccessToken()` — reads in-memory access token (for Socket.IO
    `auth` payloads and bootstrap gates).
- **`lib/api.ts`** — re-exports `apiAbsoluteFetch`, `apiAbsoluteFetchRaw`,
  `fetchAdminAbsoluteResponse`, `getAdminAccessToken`.

### Pages migrated

| File | Notes |
|---|---|
| `pages/kyc.tsx` | adminFetcher |
| `pages/support-chat.tsx` | adminFetcher |
| `pages/faq-management.tsx` | adminFetcher |
| `pages/search-analytics.tsx` | adminFetcher |
| `pages/settings-system.tsx` | adminFetcher; backup + CSV-export blob downloads via `fetchAdminAbsoluteResponse` (with auto-refresh) |
| `pages/settings-security.tsx` | adminFetcher |
| `pages/security.tsx` | adminFetcher |
| `pages/settings-payment.tsx` | adminFetcher |
| `pages/otp-control.tsx` | local `api()` rewritten on `fetcher()` |
| `pages/reviews.tsx` | CSV export via `fetchAdminAbsoluteResponse` |
| `pages/launch-control.tsx` | `apiCall` wraps `apiAbsoluteFetchRaw` |
| `pages/popups.tsx` | role from `useAdminAuth().state.user?.role` (no JWT decode) |
| `pages/van.tsx` | `vanFetch` & `adminFetch` wrap `apiAbsoluteFetch` |
| `pages/users.tsx` | "Re-Login" button calls `useAdminAuth().logout()` then redirects |
| `pages/communication.tsx` | dashboard socket migrated to `auth: { token }` |
| `pages/sos-alerts.tsx` | socket → `auth: { token }` |
| `pages/live-riders-map.tsx` | socket → `auth: { token }` |
| `pages/rides.tsx` | both sockets → `auth: { token }` |

### Components migrated

| File | Notes |
|---|---|
| `components/MapsMgmtSection.tsx` | `mapsApiFetch` wraps `apiAbsoluteFetch`; `loadMapConfig` also routed through it (no raw fetch left) |
| `components/CommandPalette.tsx` | command-execute and AI-search via `apiAbsoluteFetchRaw` |
| `components/layout/AdminLayout.tsx` | admin-fleet socket auth payload changed from `{ adminToken }` to `{ token }` |

### Libraries migrated

| File | Change |
|---|---|
| `lib/push.ts` | Push subscribe via `apiAbsoluteFetchRaw` |
| `lib/platformConfig.ts` | Bootstrap gate keyed on `getAdminAccessToken()` |
| `lib/useLanguage.ts` | Bootstrap gate keyed on `getAdminAccessToken()` |

### Strict grep gate (acceptance invariant)

```
$ rg "sessionStorage|x-admin-token|ajkmart_admin_token" artifacts/admin/src/ \
    | rg -v "lib/api.ts"
(no matches)
```

The only references to the legacy storage key remaining are inside
`lib/api.ts` itself, which keeps a backward-compat probe for in-flight
sessions during the rollout window.

---

## Smoke-test results

Manual browser smoke tests against the running dev server
(`artifacts/admin: web` workflow + `artifacts/api-server`):

| Scenario | Result | Notes |
|---|---|---|
| No-MFA login | PASS | `useAdminAuth().login()` stores access token in memory; refresh-token cookie + CSRF cookie set; redirect to `/dashboard`. |
| MFA login | PASS | TOTP step prompts after credentials; second-step submits `mfaCode`; access token issued only after MFA verifies. |
| Silent refresh on stale access token | PASS | `fetchAdmin` 401 → `refreshToken()` succeeds via `/api/admin/auth/refresh` cookie → request retried transparently; user sees no logout flicker. |
| 401 retry across all migrated callers | PASS | Verified by manually expiring the access token in DevTools and triggering: settings-system save, kyc list, popups list, communication dashboard. All retried once and succeeded. |
| Logout | PASS | `useAdminAuth().logout()` POSTs `/api/admin/auth/logout`, clears in-memory token, redirects to `/login`. Subsequent fetcher call short-circuits to login redirect. |
| Revoke-all sessions | PASS | `app-management.tsx` "Revoke all" calls `DELETE /api/admin/auth/sessions`; user is bounced to login on next request. |
| Missing CSRF → 403 | PASS | Manually deleted CSRF cookie; next mutating request returned `403 invalid CSRF`; refresh restored cookie and request succeeded. |
| Lockout after 5 failed logins | PASS | 5 wrong passwords on the same admin → server returns `423 Locked`; correct password is rejected until `LOGIN_LOCKOUT_WINDOW_MS` elapses. |
| Hard refresh restores session | PASS | `AdminAuthProvider` mount calls `refreshToken()` against the refresh-cookie; access token is rehydrated in memory; protected routes render without re-login. |
| Socket.IO admin-fleet (`auth: { token }`) | PASS | Verified with sos-alerts, live-riders-map, rides, communication, AdminLayout — all connect; `isAuthorizedForAdminFleet` accepts v2 access token via `auth.token` and Bearer. |
| Blob/CSV downloads with token rotation | PASS | settings-system backup + CSV exports and reviews CSV export tested via `fetchAdminAbsoluteResponse`; auto-refresh on 401 kept downloads working without manual re-login. |

---

## Out of scope / left in place

- **Customer-facing `/api/auth` router (`routes/auth.ts`)** — purely OTP /
  login / refresh / 2FA / social endpoints for AJKMart users. No admin
  endpoints. Kept mounted by default; gated behind
  `ADMIN_LEGACY_AUTH_DISABLED` for the eventual cutover.
- **`ADMIN_TOKEN_KEY` constant inside `lib/api.ts`** — kept for the
  rollout window so a freshly-saved legacy token isn't nuked by an
  in-flight 401. Safe to delete after the legacy admin-token branch is
  removed from `routes/admin-shared.ts`.
- Customer / vendor / rider auth flows.

## Follow-ups

1. Remove the legacy admin-token branch from `routes/admin-shared.ts`
   once all admin sessions have rotated to v2 access tokens, then set
   `ADMIN_LEGACY_AUTH_DISABLED=1` in production.
2. Drop `ADMIN_TOKEN_KEY` storage probing from `lib/api.ts` after (1).
3. Fix unrelated pre-existing typo in `pages/app-management.tsx`
   (`useState` used where `useEffect` is intended on line 99) — out of
   scope for this task but flagged here so it isn't lost.
