# Admin Settings Map (Dedupe & Canonical Source)

> Inventory of every settings-like surface in the admin panel, their canonical
> "single source of truth" home, and where read-only "Manage in Settings →"
> shortcuts replace duplicate edit controls.
>
> Last updated as part of the Admin Panel Frontend Redesign task.

## 1. Settings Hub (canonical)

The unified Settings Hub at `/settings` is the canonical home for **every**
configurable platform setting. Top-10 sections (deep-linkable with both
`/settings/:section` and the legacy `?tab=` / `?cat=` query strings):

| # | Section key (`:section`) | Label | Sub-categories (legacy `cat`) |
|---|--------------------------|-------|-------------------------------|
| 1 | `general` | General | general, regional, localization, branding |
| 2 | `services` | Services & Features | features |
| 3 | `operations` | Operations & Dispatch | dispatch, orders, delivery, rides, van, onboarding |
| 4 | `roles` | Roles | customer, rider, vendor |
| 5 | `finance_payments` | Finance & Payments | finance, payment |
| 6 | `communication` | Communication | notifications, content |
| 7 | `integrations` | Integrations | integrations |
| 8 | `security_access` | Security & Access | security, jwt, moderation, ratelimit |
| 9 | `system_perf` | System & Performance | system, system_limits, cache, network, geo, uploads, pagination |
| 10 | `widgets` | Widgets & Add-ons | weather |

The hub renders the same sub-section components (`PaymentSection`,
`IntegrationsSection`, `SecuritySection`, `SystemSection`, `WeatherSection`,
plus `renderSection()` for everything else) — no setting key has been moved or
renamed; only navigation/grouping changed.

## 2. Standalone settings-like routes — keep, retitle, or dedupe

| Route | Disposition | Notes |
|-------|-------------|-------|
| `/app-management` | **KEEP** as Operations dashboard, **DEDUPE** Maintenance Mode + Service Toggles | Maintenance toggle and `feature_*` service toggles now show as **read-only badges with a "Manage in Settings →" link**. Admin accounts CRUD, audit log, sessions, release notes remain canonical here. |
| `/auth-methods` | **KEEP** as canonical for per-role authentication strategy | `auth_phone_otp_enabled`, `auth_email_otp_enabled`, `auth_2fa_enabled`, `auth_biometric_enabled`, `auth_magic_link_enabled`, `auth_captcha_enabled`. Settings → Security & Access has a deep-link to this page (no edit duplication). |
| `/otp-control` | **KEEP** as canonical for OTP delivery + per-channel policy | `security_otp_max_per_phone`, `security_otp_max_per_ip`, `security_otp_window_min`, OTP throttling rules. |
| `/sms-gateways` | **KEEP** as canonical for SMS provider routing | `sms_provider`, `sms_api_key`, `sms_account_sid`, `sms_sender_id`. Settings → Integrations has a deep-link to this page for the SMS provider sub-block. |
| `/accessibility` | **KEEP** as canonical for admin accessibility prefs | Self-contained: font scale, contrast, reduce motion. Per-admin client-side prefs, not platform settings. |
| `/vendor-inventory-settings` | **KEEP** as canonical for vendor-side stock controls | Vendor-scoped operational settings, not duplicated in Settings hub. |
| `/condition-rules` | **KEEP** as canonical for default rules per condition type | Operational policy, not duplicated. |
| `/account-conditions` | **KEEP** as canonical for applying restrictions to specific accounts | Per-account workflow, not a platform setting. |
| `/webhooks` | **KEEP** as canonical for outgoing webhook endpoints | CRUD UI; not duplicated. |
| `/deep-links` | **KEEP** as canonical for deep-link generator + analytics | CRUD + reporting; not duplicated. |
| `/launch-control` | **KEEP** as canonical for pre-launch readiness checklist | Operational gate, not a setting. |
| `/roles-permissions` | **KEEP** as canonical for admin RBAC | Admin role/permission matrix; not duplicated. |
| `/security` | **KEEP** as canonical for the audit-log viewer | Read-only event stream, distinct from security policy in Settings → Security & Access. |

## 3. Resolved duplicates

| Setting | Previous duplicate locations | Canonical home (post-redesign) | Shortcut location |
|---------|------------------------------|--------------------------------|-------------------|
| **Maintenance Mode** (`app_status`) | `/app-management` (toggle button) AND `/settings` → General | `/settings/general` | `/app-management` shows status pill + "Manage in Settings →" link (no edit control) |
| **Service Toggles** (`feature_mart`, `feature_food`, `feature_rides`, `feature_pharmacy`, `feature_parcel`, `feature_wallet`, `feature_referral`, `feature_new_users`, `feature_weather`, `feature_chat`, `feature_live_tracking`, `feature_reviews`, `feature_sos`) | `/app-management` (Live Service Control card) AND `/settings/services` (Feature Toggles) | `/settings/services` | `/app-management` Service Toggles becomes a status grid with one "Manage in Settings →" link |
| **Auth method toggles** (`auth_phone_otp_enabled`, `auth_email_otp_enabled`, `auth_2fa_enabled`, `auth_biometric_enabled`, `auth_magic_link_enabled`, `auth_captcha_enabled`) | `/auth-methods` AND `/settings/security_access` (Security section had Auth subsection) | `/auth-methods` | Settings → Security & Access shows summary + "Open Auth Methods →" link |
| **SMS provider config** (`sms_provider`, `sms_api_key`, `sms_account_sid`, `sms_sender_id`) | `/sms-gateways` AND `/settings/integrations` (Integrations had SMS sub-block) | `/sms-gateways` | Settings → Integrations shows current provider + "Open SMS Gateways →" link |

All other settings remain in their previously-canonical home and are not edited
in two places.

## 4. URL backward compatibility

| New URL | Legacy URLs that still work |
|---------|-----------------------------|
| `/settings/services` | `/settings?tab=services`, `/settings?cat=features` |
| `/settings/security_access` | `/settings?tab=security_access`, `/settings?cat=security`, `/settings?cat=jwt`, `/settings?cat=ratelimit`, `/settings?cat=moderation` |
| `/settings/general` | `/settings?tab=general`, `/settings?cat=general`, `/settings?cat=regional`, `/settings?cat=branding`, `/settings?cat=localization` |
| (every other section) | `?tab=<section>` and `?cat=<legacy>` continue to resolve via `LEGACY_TO_TOP10` |

Sub-section deep links use the path form `/settings/:section/:subsection` and
fall back to the legacy `?cat=` resolution if the sub-section name doesn't
match a known child.
