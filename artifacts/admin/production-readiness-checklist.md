# AJKMart — Manual Production-Readiness Checklist (Operator Runbook)

> **Audience:** the live-environment operator turning on AJKMart for the first time.
> **Why this exists:** the admin-panel QA pass (`artifacts/admin/admin-test.md`) verified every admin page works, but it intentionally did **not** exercise external integrations end-to-end (no real OTP SMS, no real password-reset email, no real push to a phone, no real payment round-trip, no real OAuth sign-in). Every item below requires a real provider credential, a real device, or a real money round-trip — so it can only be done by a human operator on the live system.
>
> **How to use:** work top to bottom. For each item, set the credentials in the admin panel, run the listed test, then record the result in the **Result** column with a short evidence note (timestamp, message id, transaction id, screenshot path, etc.). The whole list must be ✅ before flipping the production launch flag.
>
> **Scope:** the checks below are exactly the items left open in `admin-test.md` → "Items NOT verified end-to-end here". Nothing outside that list is in scope here.

---

## 0 · Prerequisites

Before you start the per-channel checks, confirm:

| # | Prereq | Where | Result |
|---|---|---|---|
| 0.1 | You can sign in to the admin panel as a user with `system.secrets.manage` (super-admin works). | `/admin/login` | ☐ |
| 0.2 | The seeded super-admin password has been rotated away from the bootstrap value (set fresh `ADMIN_SEED_PASSWORD` in Replit Secrets, or use *Settings → Security → Reset password*). | Replit Secrets / `/admin/settings-security` | ☐ |
| 0.3 | `JWT_SECRET`, `ADMIN_ACCESS_TOKEN_SECRET`, `ADMIN_REFRESH_TOKEN_SECRET` are set per environment. | Replit Secrets | ☐ |
| 0.4 | A real test phone (PK number, can receive SMS + WhatsApp), a real test email inbox you control, and a real device with the AJKMart customer app installed are all available for this session. | Operator desk | ☐ |

---

## 1 · SMS provider — real OTP to a real phone

**Why:** proves `sms_provider` + provider credentials are correct end-to-end. The smoke-send button on `/admin/sms-gateways` is *not* a real send when `sms_provider=console`.

**Steps**

1. Open `/admin/settings-integrations` → **SMS** tab.
2. Set `integration_sms = on` and pick a real `sms_provider` (`twilio` / `msg91` / generic). **Do not leave it on `console`.**
3. Fill the provider-specific credentials:
   - **Twilio:** `sms_account_sid`, `sms_api_key` (Auth Token), `sms_sender_id` (From number).
   - **MSG91:** `sms_msg91_key`, `sms_sender_id`.
   - **Generic:** `sms_api_key`, `sms_sender_id`.
4. **Save.**
5. In the same page, scroll to the **Integration Health** panel → row **SMS Gateway** → enter your real test phone in the inline phone box (format `03xxxxxxxxx`) → click **Test**. This calls `POST /api/admin/system/test-integration/sms` which sends a real OTP-style SMS through the configured provider.
6. Confirm the SMS lands on the real phone within ~30 s.
7. Cross-check the **audit log** at `/admin/security` for an `sms.test` (or equivalent) entry from your admin user.

**Done criterion:** the test phone received the SMS, *and* the audit log shows the send. Record the provider name, the message preview, and the audit-log timestamp.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | Provider: ______ · Phone: ______ · Time: ______ |

---

## 2 · Email / SMTP — real password-reset email

**Why:** proves SMTP credentials are correct and the password-reset flow can actually deliver.

**Steps**

1. Open `/admin/settings-integrations` → **Email** tab.
2. Set `integration_email = on`. Fill `smtp_host`, `smtp_port`, `smtp_user`, `smtp_password`, `smtp_from`, and `smtp_admin_alert_email` (use a real inbox you control).
3. **Save.**
4. **Smoke test the SMTP plumbing first:** in the **Integration Health** panel → row **Email / SMTP** → click **Test**. This calls `POST /api/admin/system/test-integration/email` which sends a real test email to `smtp_admin_alert_email`. Confirm it lands in that inbox within ~1 minute. If it does not, re-check credentials before continuing.
5. **Now exercise the real password-reset flow** (this is the canonical Done criterion):
   1. Sign out of the admin panel.
   2. Go to `/admin/forgot-password`.
   3. Enter the email of an existing admin you control. (For anti-enumeration the page always shows the success screen — that's expected.)
   4. Confirm the reset email lands in that inbox within ~1 minute.
   5. Click the link, land on `/admin/reset-password?token=…`, set a new password, confirm you can log in with it.

**Done criterion:** both the SMTP smoke test email *and* the real `/forgot-password` email landed in the test inbox, and the reset link successfully changed the password.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | SMTP host: ______ · From: ______ · Reset email received at: ______ |

---

## 3 · Push notifications (FCM) — real push to a real device

**Why:** proves `fcm_server_key` + `fcm_project_id` are correct and that the device's Expo push token round-trip works.

**Steps**

1. On the real customer device, open the AJKMart customer app, sign in once, accept the push-notification permission. The app registers its Expo push token with the API server on login.
2. Capture that device's Expo push token. The two easiest ways:
   - From the customer app's *Profile → Debug → Push token* screen (if available in your build).
   - Or query the DB: `SELECT id, push_token FROM users WHERE id = '<your test user id>';`.
3. In the admin panel, open `/admin/settings-integrations` → **Firebase** tab.
4. Set `integration_push_notif = on`. Fill `fcm_server_key` and `fcm_project_id`. **Save.**
5. Scroll to the **Integration Health** panel → row **Firebase FCM** → paste the Expo push token into the inline token box → click **Test**. This calls `POST /api/admin/system/test-integration/fcm`.
6. Confirm the test push lands on the real device within ~10 s, with title *"AJKMart — Test Push Notification ✅"*.

**Done criterion:** the test device received the push notification.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | Device: ______ · Push token (last 8 chars): …______ · Time delivered: ______ |

---

## 4 · WhatsApp Business — real template message

**Why:** proves `wa_phone_number_id` + `wa_access_token` are correct and a template message can actually land in WhatsApp.

**Steps**

1. Open `/admin/settings-integrations` → **WhatsApp** tab.
2. Set `integration_whatsapp = on`, fill `wa_phone_number_id` and `wa_access_token`, and turn on `wa_send_otp` so OTP-style templates are eligible to send. **Save.**
3. In the **Integration Health** panel → row **WhatsApp Business** → enter your real test phone (the one bound to the test WhatsApp account) → click **Test**. This calls `POST /api/admin/system/test-integration/whatsapp`.
4. Confirm a WhatsApp message arrives in the test phone's WhatsApp inbox within ~30 s.

**Done criterion:** the template message landed in the test phone's WhatsApp.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | Phone: ______ · Message id: ______ |

---

## 5 · Maps API — markers + reverse-geocoding

**Why:** proves the configured Maps key is valid and reverse-geocoding works on the live-riders map.

**Steps**

1. Open `/admin/settings-integrations` → **Maps** tab.
2. Set `integration_maps = on`, pick `maps_provider` (`google` / `mapbox` / `locationiq`) and fill the matching key (`google_maps_api_key`, `mapbox_api_key`, or `locationiq_api_key`). **Save.**
3. **Smoke test the key:** in the **Integration Health** panel → row **Maps API** → click **Test**. This calls `POST /api/admin/system/test-integration/maps`, which forward-geocodes "Muzaffarabad, Azad Kashmir" through the chosen provider. Expected response: `{ ok: true }` with a `location`/`center` payload.
4. **Live map check:** navigate to `/admin/live-riders-map`. The base map tiles must render (no grey blocks, no "for development purposes only" overlay), at least one rider marker must appear if any rider is online, and clicking a marker should open the rider popup with a reverse-geocoded address.
5. **Customer/rider PWA check:** open the rider PWA on a real device, confirm the same map renders and that the address auto-fills correctly when you drop a pin.

**Done criterion:** the smoke test returns `ok: true`, the admin map tiles render with markers, and reverse-geocoding works on `/live-riders-map`.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | Provider: ______ · Smoke-test result: ______ · Map render: ______ |

---

## 6 · Payment gateways — JazzCash + EasyPaisa round-trip

**Why:** proves money can actually move (API mode) or that the manual deposit-verification UI works (manual mode). Both gateways must be exercised.

### 6a · JazzCash

**Steps**

1. Open `/admin/settings-payment` → **JazzCash** section.
2. Set `jazzcash_enabled = on` and choose `jazzcash_type`:
   - **`api` mode:** fill `jazzcash_merchant_id`, `jazzcash_password`, `jazzcash_salt`. Save.
     - In the **Integration Health** panel on `/admin/settings-integrations`, row **JazzCash (API)** → click **Test** (calls `GET /api/payments/test-connection/jazzcash`). Expected: `{ ok: true }`.
     - On a real customer device, open the customer app → Wallet → *Top up via JazzCash* → complete a small real top-up (e.g. PKR 10). Confirm the wallet balance increases and the entry shows on `/admin/transactions` with the correct gateway reference.
   - **`manual` mode:** fill the manual-mode account fields (account title, account number, instructions). Save.
     - On a real customer device, file a manual top-up request from the customer app → it should land on `/admin/deposit-requests`. Open the request, click **Verify**, confirm the customer's wallet credits and the request flips to `verified`. Then file a second request and **Reject** it; confirm the customer sees the rejection.

**Done criterion:** in API mode, one real round-trip credited the wallet. In manual mode, one verify-and-credit *and* one reject were both exercised on `/deposit-requests`.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | Mode: API/Manual · Txn id / request id: ______ · Wallet delta: ______ |

### 6b · EasyPaisa

**Steps**

Same procedure as JazzCash above, but in `/admin/settings-payment` → **EasyPaisa** section, with `easypaisa_enabled`, `easypaisa_type`, `easypaisa_store_id`, `easypaisa_hash_key`. Smoke-test endpoint: `GET /api/payments/test-connection/easypaisa`.

**Done criterion:** same as JazzCash — one real round-trip in API mode, or one verify + one reject in manual mode.

| Result | Evidence |
|---|---|
| ☐ PASS / ☐ FAIL | Mode: API/Manual · Txn id / request id: ______ · Wallet delta: ______ |

---

## 7 · OAuth — Google + Facebook from the customer app

**Why:** proves the OAuth client IDs are wired and that real social sign-in works from a real device.

**Steps**

1. Open `/admin/security` → **Social Login** section. Fill `google_client_id` (xxxx.apps.googleusercontent.com) and `facebook_app_id`. **Save.**
2. On the real customer device:
   1. Sign out of the customer app.
   2. Tap **Continue with Google** → complete the consent screen → confirm you land back in the app, signed in, with your profile populated. Cross-check `/admin/users` to see the user record was created/linked with `provider=google`.
   3. Sign out again. Tap **Continue with Facebook** → complete the consent screen → confirm you land back in the app, signed in. Cross-check `/admin/users` shows `provider=facebook`.

**Done criterion:** both Google and Facebook social sign-in completed end-to-end from the real device, and both produced/linked a user row visible in `/admin/users`.

| Result | Evidence |
|---|---|
| ☐ Google PASS / ☐ FAIL | Email returned: ______ · User id: ______ |
| ☐ Facebook PASS / ☐ FAIL | Email returned: ______ · User id: ______ |

---

## Sign-off

When every row above is ✅, the production-readiness checklist is complete and the integration-dependent features can be considered live-ready.

| Field | Value |
|---|---|
| Operator name | ______ |
| Date completed | ______ |
| Production environment | ______ |
| Notes / deviations | ______ |

> Once signed off, append a note to `artifacts/admin/admin-test.md` → "Items NOT verified end-to-end here" section pointing at this completed checklist (date + operator name) so future audits have a single trail.
