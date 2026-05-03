# AJKMart Admin — Settings Tracker
# AJKMart ایڈمن — سیٹنگز ٹریکر

> **Last updated:** 2026-04-26 (Top-10 reorganization, Test-Connection audit, Weather test endpoint)
> **Scope:** Every setting key surfaced through `/admin/settings`. Live status per item.
>
> **Status legend (Final Status column):**
> - ✅ **Working** — UI renders, save persists, API consumes the value, optional Test button passes.
> - ⚠️ **Operator-supplied** — UI/API plumbing is complete, but the value itself is a third-party credential that must come from the operator. No code work pending.
> - 🐛 **Bug** — known fault that needs a code fix.
> - ❌ **Missing** — UI or API is not implemented yet.
>
> The **UI status** column = does the field render & save in the admin UI?
> The **API/persistence status** column = does the API actually read & enforce the saved value?

---

## How navigation maps to the database

The DB column `platform_settings.category` still holds **30 fine-grained legacy
categories** (`general`, `features`, `dispatch`, …). The admin UI groups them
into **10 top-level tabs** via the `LEGACY_TO_TOP10` constant in
`artifacts/admin/src/pages/settings.tsx`. No migration is required — the DB
column is unchanged.

| # | Top-10 Tab (`?tab=`)    | Legacy categories grouped into it                                                  |
|---|--------------------------|------------------------------------------------------------------------------------|
| 1 | `general`                | general, regional, localization, branding                                          |
| 2 | `services`               | features                                                                           |
| 3 | `operations`             | dispatch, orders, delivery, rides, van, onboarding                                 |
| 4 | `roles`                  | customer, rider, vendor                                                            |
| 5 | `finance_payments`       | finance, payment                                                                   |
| 6 | `communication`          | notifications, content                                                             |
| 7 | `integrations`           | integrations                                                                       |
| 8 | `security_access`        | security, jwt, moderation, ratelimit                                               |
| 9 | `system_perf`            | system, system_limits, cache, network, geo, uploads, pagination                    |
| 10| `widgets`                | weather                                                                            |

Both old and new deep links work:

- `?tab=finance_payments`  ✅
- `?tab=payment`           ✅ (legacy → resolves to `finance_payments`)
- `?cat=integrations`      ✅ (legacy alias)

After load the URL is normalized to the canonical `?tab=<top10>`.

---

## 1. General  (`?tab=general`)

| Label                  | Key                  | Sub-section  | UI status | API/persistence status | Notes                              | Final Status |
|------------------------|----------------------|--------------|-----------|------------------------|------------------------------------|--------------|
| App Name               | `app_name`           | general      | ✅        | ✅ read by /platform-config | Branding header              | ✅           |
| App Status             | `app_status`         | general      | ✅        | ✅                     | live / maintenance                 | ✅           |
| App Version            | `app_version`        | general      | ✅        | ✅                     | Surfaced to clients                 | ✅           |
| App Logo URL           | `app_logo_url`       | general      | ✅        | ✅                     | Used by all client apps             | ✅           |
| Support Phone          | `support_phone`      | general      | ✅        | ✅                     | Contact data                        | ✅           |
| Support Email          | `support_email`      | general      | ✅        | ✅                     | Contact data                        | ✅           |
| Support WhatsApp       | `support_whatsapp`   | general      | ✅        | ✅                     | Contact data                        | ✅           |
| Support Address        | `support_address`    | general      | ✅        | ✅                     | Contact data                        | ✅           |
| Facebook URL           | `social_facebook`    | general      | ✅        | ✅                     | Footer/contact                      | ✅           |
| Instagram URL          | `social_instagram`   | general      | ✅        | ✅                     | Footer/contact                      | ✅           |
| Phone Format           | `phone_format`       | regional     | ✅        | ✅                     | Validation hint                     | ✅           |
| Country Code           | `country_code`       | regional     | ✅        | ✅                     | ISO-3166                            | ✅           |
| Timezone               | `timezone`           | regional     | ✅        | ✅                     | Server defaults                     | ✅           |
| Date Format            | `date_format`        | regional     | ✅        | ✅                     | Client formatter                    | ✅           |
| Currency Code          | `currency_code`      | localization | ✅        | ✅                     | PKR                                 | ✅           |
| Currency Symbol        | `currency_symbol`    | localization | ✅        | ✅                     | Rs.                                 | ✅           |
| Default Language       | `default_language`   | localization | ✅        | ✅                     | ur / en                             | ✅           |
| Brand Color · Mart     | `brand_color_mart`   | branding     | ✅        | ✅                     | Theme accent                        | ✅           |
| Brand Color · Food     | `brand_color_food`   | branding     | ✅        | ✅                     | Theme accent                        | ✅           |
| Brand Color · Rides    | `brand_color_rides`  | branding     | ✅        | ✅                     | Theme accent                        | ✅           |
| Brand Color · Pharmacy | `brand_color_pharmacy`| branding    | ✅        | ✅                     | Theme accent                        | ✅           |
| Map Center Lat         | `brand_map_center_lat`| branding    | ✅        | ✅                     | Default map center                  | ✅           |
| Map Center Lng         | `brand_map_center_lng`| branding    | ✅        | ✅                     | Default map center                  | ✅           |
| Map Label              | `brand_map_label`    | branding     | ✅        | ✅                     | Header text                         | ✅           |

---

## 2. Services & Features  (`?tab=services`)

| Label              | Key               | Sub-section | UI status | API/persistence status                               | Notes                          | Final Status |
|--------------------|-------------------|-------------|-----------|------------------------------------------------------|--------------------------------|--------------|
| Mart Service       | `feature_mart`    | features    | ✅        | ✅ enforced in routes/categories, /products gating   | Master toggle                  | ✅           |
| Food Service       | `feature_food`    | features    | ✅        | ✅ enforced                                          | Master toggle                  | ✅           |
| Rides Service      | `feature_rides`   | features    | ✅        | ✅ enforced in routes/rides                          | Master toggle                  | ✅           |
| Pharmacy Service   | `feature_pharmacy`| features    | ✅        | ✅ enforced                                          | Master toggle                  | ✅           |
| Parcel Service     | `feature_parcel`  | features    | ✅        | ✅ enforced                                          | Master toggle                  | ✅           |
| Van Service        | `feature_van`     | features    | ✅        | ✅ enforced                                          | Master toggle                  | ✅           |
| Wallet             | `feature_wallet`  | features    | ✅        | ✅ enforced in wallet routes                         | Master toggle                  | ✅           |
| Referrals          | `feature_referral`| features    | ✅        | ✅                                                    | Surface in customer app         | ✅           |
| New User Signup    | `feature_new_users`| features   | ✅        | ✅ enforced in /auth                                 | Allows blocking signups         | ✅           |
| Chat               | `feature_chat`    | features    | ✅        | ✅ enforced in chat router                           | Master toggle                  | ✅           |
| Live Tracking      | `feature_live_tracking`| features| ✅        | ✅                                                    | Map widget                      | ✅           |
| Reviews            | `feature_reviews` | features    | ✅        | ✅                                                    | Reviews UI                      | ✅           |
| SOS                | `feature_sos`     | features    | ✅        | ✅                                                    | Safety button                   | ✅           |
| Weather Widget     | `feature_weather` | features    | ✅        | ✅                                                    | Widget toggle                   | ✅           |
| Platform Mode      | `platform_mode`   | features    | ✅        | ✅                                                    | live / staging / maintenance    | ✅           |
| Demo Mode          | `demo_mode_enabled`| features   | ✅        | ✅ enforced (demo seed/restore)                      | Demo data toggle                | ✅           |

---

## 3. Operations & Dispatch  (`?tab=operations`)

### 3.1 Dispatch
| Label                   | Key                          | UI | API | Final |
|-------------------------|------------------------------|----|-----|-------|
| Min Radius (km)         | `dispatch_min_radius_km`     | ✅ | ✅ enforced in dispatch matcher | ✅ |
| Max Radius (km)         | `dispatch_max_radius_km`     | ✅ | ✅ | ✅ |
| Avg Speed (km/h)        | `dispatch_avg_speed_kmh`     | ✅ | ✅ used by ETA estimator | ✅ |
| Timeout (sec)           | `dispatch_timeout_sec`       | ✅ | ✅ | ✅ |
| Max Offers              | `dispatch_max_offers`        | ✅ | ✅ | ✅ |
| Broadcast Radius (km)   | `dispatch_broadcast_radius`  | ✅ | ✅ | ✅ |

### 3.2 Order Rules
| Label                   | Key                       | UI | API | Final |
|-------------------------|---------------------------|----|-----|-------|
| Min Order Amount        | `min_order_amount`        | ✅ | ✅ enforced at checkout | ✅ |
| Schedule Orders         | `order_schedule_enabled`  | ✅ | ✅ | ✅ |
| Refund Window (days)    | `order_refund_days`       | ✅ | ✅ | ✅ |
| Auto-Cancel (min)       | `order_auto_cancel_min`   | ✅ | ✅ background cron | ✅ |
| GPS Proof Required      | `order_proof_gps_required`| ✅ | ✅ enforced at delivery confirm | ✅ |

### 3.3 Delivery Charges
| Label                | Key                    | UI | API | Final |
|----------------------|------------------------|----|-----|-------|
| Mart Fee             | `delivery_fee_mart`    | ✅ | ✅ | ✅ |
| Food Fee             | `delivery_fee_food`    | ✅ | ✅ | ✅ |
| Pharmacy Fee         | `delivery_fee_pharmacy`| ✅ | ✅ | ✅ |
| Parcel Fee           | `delivery_fee_parcel`  | ✅ | ✅ | ✅ |
| Free Delivery Above  | `free_delivery_above`  | ✅ | ✅ | ✅ |
| Free Delivery On     | `delivery_free_enabled`| ✅ | ✅ | ✅ |

### 3.4 Ride Pricing & Rules
| Label                  | Key                         | UI | API | Final |
|------------------------|-----------------------------|----|-----|-------|
| Bike Base Fare         | `ride_bike_base_fare`       | ✅ | ✅ | ✅ |
| Bike Per-km            | `ride_bike_per_km`          | ✅ | ✅ | ✅ |
| Car Base Fare          | `ride_car_base_fare`        | ✅ | ✅ | ✅ |
| Car Per-km             | `ride_car_per_km`           | ✅ | ✅ | ✅ |
| Surge Enabled          | `ride_surge_enabled`        | ✅ | ✅ | ✅ |
| Surge Multiplier       | `ride_surge_multiplier`     | ✅ | ✅ | ✅ |
| Bargaining Enabled     | `ride_bargaining_enabled`   | ✅ | ✅ | ✅ |
| Bargain Min %          | `ride_bargaining_min_pct`   | ✅ | ✅ | ✅ |
| Cancellation Fee       | `ride_cancellation_fee`     | ✅ | ✅ | ✅ |
| Cancel Grace (sec)     | `ride_cancel_grace_sec`     | ✅ | ✅ | ✅ |
| COD Allowed (rides)    | `cod_allowed_rides`         | ✅ | ✅ | ✅ |
| Wallet Allowed (rides) | `wallet_allowed_rides`      | ✅ | ✅ | ✅ |
| JazzCash Allowed (rides)| `jazzcash_allowed_rides`   | ✅ | ✅ filtered in /payments?serviceType=ride | ✅ |
| EasyPaisa Allowed (rides)| `easypaisa_allowed_rides` | ✅ | ✅ | ✅ |

### 3.5 Van
| Label                  | Key                       | UI | API | Final |
|------------------------|---------------------------|----|-----|-------|
| Seat Hold (min)        | `van_seat_hold_min`       | ✅ | ✅ | ✅ |
| Advance Book (days)    | `van_advance_book_days`   | ✅ | ✅ | ✅ |
| Refund %               | `van_refund_pct`          | ✅ | ✅ | ✅ |
| Driver Rest (hours)    | `van_driver_rest_hours`   | ✅ | ✅ | ✅ |
| Notify on Cancel       | `van_auto_notify_cancel`  | ✅ | ✅ | ✅ |
| Require Start Trip     | `van_require_start_trip`  | ✅ | ✅ | ✅ |

### 3.6 Onboarding & UX
| Label                  | Key                          | UI | API | Final |
|------------------------|------------------------------|----|-----|-------|
| Slide 1 Title          | `onboard_slide_1_title`      | ✅ | ✅ served by /platform-config | ✅ |
| Slide 1 Body           | `onboard_slide_1_body`       | ✅ | ✅ | ✅ |
| Slide 2 Title          | `onboard_slide_2_title`      | ✅ | ✅ | ✅ |
| Slide 2 Body           | `onboard_slide_2_body`       | ✅ | ✅ | ✅ |
| Slide 3 Title          | `onboard_slide_3_title`      | ✅ | ✅ | ✅ |
| Slide 3 Body           | `onboard_slide_3_body`       | ✅ | ✅ | ✅ |
| Show Skip Button       | `onboard_show_skip`          | ✅ | ✅ | ✅ |

---

## 4. Roles  (`?tab=roles`)

### 4.1 Customer App
| Label                  | Key                         | UI | API | Final |
|------------------------|-----------------------------|----|-----|-------|
| Signup Bonus           | `customer_signup_bonus`     | ✅ (also rendered on Payment) | ✅ credited at signup | ✅ |
| Referral Bonus         | `customer_referral_bonus`   | ✅ (also rendered on Payment) | ✅ credited on referral | ✅ |
| Referrals Enabled      | `customer_referral_enabled` | ✅ | ✅ | ✅ |
| Loyalty Enabled        | `customer_loyalty_enabled`  | ✅ | ✅ | ✅ |
| Wallet Max Balance     | `wallet_max_balance`        | ✅ | ✅ enforced in wallet topup | ✅ |
| Wallet MPIN            | `wallet_mpin_enabled`       | ✅ | ✅ | ✅ |
| Wallet P2P             | `wallet_p2p_enabled`        | ✅ | ✅ | ✅ |
| Wallet KYC Required    | `wallet_kyc_required`       | ✅ | ✅ | ✅ |
| Min Online Payment     | `payment_min_online`        | ✅ | ✅ | ✅ |
| Max Online Payment     | `payment_max_online`        | ✅ | ✅ | ✅ |

### 4.2 Rider App
| Label                  | Key                       | UI | API | Final |
|------------------------|---------------------------|----|-----|-------|
| Rider Keep %           | `rider_keep_pct`          | ✅ | ✅ used in payout calc | ✅ |
| Acceptance Radius (km) | `rider_acceptance_km`     | ✅ | ✅ | ✅ |
| Min Payout             | `rider_min_payout`        | ✅ | ✅ enforced on withdrawal | ✅ |
| Cash Allowed           | `rider_cash_allowed`      | ✅ | ✅ | ✅ |
| Auto-Approve Riders    | `rider_auto_approve`      | ✅ | ✅ | ✅ |
| Withdrawal Enabled     | `rider_withdrawal_enabled`| ✅ | ✅ | ✅ |
| Deposit Enabled        | `rider_deposit_enabled`   | ✅ | ✅ | ✅ |
| Require Approval (all) | `user_require_approval`   | ✅ (danger) | ✅ enforced in /auth | ✅ |

### 4.3 Vendor Portal
| Label                  | Key                       | UI | API | Final |
|------------------------|---------------------------|----|-----|-------|
| Commission %           | `vendor_commission_pct`   | ✅ | ✅ used in payouts | ✅ |
| Settlement Days        | `vendor_settlement_days`  | ✅ | ✅ | ✅ |
| Min Payout             | `vendor_min_payout`       | ✅ (also shown in Finance) | ✅ | ✅ |
| Auto-Approve           | `vendor_auto_approve`     | ✅ | ✅ | ✅ |
| Promotions Enabled     | `vendor_promo_enabled`    | ✅ | ✅ | ✅ |

---

## 5. Finance & Payments  (`?tab=finance_payments`)

### 5.1 Finance & Tax
| Label                  | Key                       | UI | API | Final |
|------------------------|---------------------------|----|-----|-------|
| Platform Commission %  | `platform_commission_pct` | ✅ | ✅ deducted from payouts | ✅ |
| GST %                  | `finance_gst_pct`         | ✅ | ✅ added at checkout | ✅ |
| GST Enabled            | `finance_gst_enabled`     | ✅ | ✅ | ✅ |
| Cashback Enabled       | `finance_cashback_enabled`| ✅ | ✅ | ✅ |
| Invoice Enabled        | `finance_invoice_enabled` | ✅ | ✅ | ✅ |
| Vendor Min Payout      | `vendor_min_payout`       | ✅ display override | ✅ | ✅ |

### 5.2 Payment Methods (`PaymentSection.tsx`)
Each gateway has manual + API mode and a **Test Connection** button hitting
`GET /api/payments/test-connection/:gateway`. Failure modes now surface a
specific error (Unauthorized / Endpoint not found / Server error / Network),
not a generic "connection failed" — see `settings-payment.tsx` `handleTest`.

| Label                  | Key                        | Provider  | UI | API | Notes | Final |
|------------------------|----------------------------|-----------|----|-----|-------|-------|
| COD Enabled            | `cod_enabled`              | COD       | ✅ | ✅  | No external creds | ✅ |
| JazzCash Enabled       | `jazzcash_enabled`         | JazzCash  | ✅ | ✅  | Test button wired | ✅ |
| JazzCash Mode          | `jazzcash_mode`            | JazzCash  | ✅ | ✅  | sandbox/live      | ✅ |
| Manual Name            | `jazzcash_manual_name`     | JazzCash  | ✅ | ✅  | Manual mode       | ✅ |
| Manual Number          | `jazzcash_manual_number`   | JazzCash  | ✅ | ✅  | Manual mode       | ✅ |
| Merchant ID            | `jazzcash_merchant_id`     | JazzCash  | ✅ | ✅  | Operator-supplied | ⚠️ |
| Password               | `jazzcash_password`        | JazzCash  | ✅ | ✅  | Operator-supplied | ⚠️ |
| Salt                   | `jazzcash_salt`            | JazzCash  | ✅ | ✅  | Operator-supplied | ⚠️ |
| Return URL             | `jazzcash_return_url`      | JazzCash  | ✅ | ✅  | Operator-supplied | ⚠️ |
| EasyPaisa Enabled      | `easypaisa_enabled`        | EasyPaisa | ✅ | ✅  | Test button wired | ✅ |
| EasyPaisa Mode         | `easypaisa_mode`           | EasyPaisa | ✅ | ✅  |                  | ✅ |
| Manual Name            | `easypaisa_manual_name`    | EasyPaisa | ✅ | ✅  |                  | ✅ |
| Manual Number          | `easypaisa_manual_number`  | EasyPaisa | ✅ | ✅  |                  | ✅ |
| Store ID               | `easypaisa_store_id`       | EasyPaisa | ✅ | ✅  | Operator-supplied | ⚠️ |
| Hash Key               | `easypaisa_hash_key`       | EasyPaisa | ✅ | ✅  | Operator-supplied | ⚠️ |
| Bank Enabled           | `bank_enabled`             | Bank      | ✅ | ✅  |                  | ✅ |
| Bank Account Name      | `bank_account_name`        | Bank      | ✅ | ✅  | Operator-supplied | ⚠️ |
| Bank Account Number    | `bank_account_number`      | Bank      | ✅ | ✅  | Operator-supplied | ⚠️ |
| Bank Branch            | `bank_branch`              | Bank      | ✅ | ✅  | Operator-supplied | ⚠️ |
| Bank IBAN              | `bank_iban`                | Bank      | ✅ | ✅  | Operator-supplied | ⚠️ |
| Payment Timeout (min)  | `payment_timeout_mins`     | global    | ✅ | ✅  |                  | ✅ |

---

## 6. Communication  (`?tab=communication`)

### 6.1 Notifications
| Label                  | Key                       | UI | API | Final |
|------------------------|---------------------------|----|-----|-------|
| New-order Push         | `notif_new_order`         | ✅ | ✅ checked by notification dispatcher | ✅ |
| Order-ready Push       | `notif_order_ready`       | ✅ | ✅ | ✅ |
| Ride-request Push      | `notif_ride_request`      | ✅ | ✅ | ✅ |
| Promotional Push       | `notif_promo`             | ✅ | ✅ | ✅ |
| WhatsApp OTP           | `wa_send_otp`             | ✅ | ✅ wired in /auth/otp | ✅ |
| Email Alert · New Vendor| `email_alert_new_vendor` | ✅ | ✅ wired via sendAdminAlert | ✅ |

Plus dynamic `comm_*` keys seeded by `routes/admin/communication.ts` (channel
templates and AI assist toggles).

### 6.2 Content & Banners
| Label                  | Key                          | UI | API | Final |
|------------------------|------------------------------|----|-----|-------|
| Announcement           | `content_announcement`       | ✅ | ✅ served by /platform-config | ✅ |
| Banner                 | `content_banner`             | ✅ | ✅ | ✅ |
| Maintenance Message    | `content_maintenance_msg`    | ✅ | ✅ shown when app_status=maintenance | ✅ |
| Support Message        | `content_support_msg`        | ✅ | ✅ | ✅ |
| Vendor Notice          | `content_vendor_notice`      | ✅ | ✅ | ✅ |
| Rider Notice           | `content_rider_notice`       | ✅ | ✅ | ✅ |
| Refund Policy URL      | `content_refund_policy_url`  | ✅ | ✅ | ✅ |
| FAQ URL                | `content_faq_url`            | ✅ | ✅ | ✅ |
| About URL              | `content_about_url`          | ✅ | ✅ | ✅ |

---

## 7. Integrations  (`?tab=integrations`)

Single screen rendered by `IntegrationsSection.tsx`. Health is computed by
`computeHealth()`. Each provider carries a **Test** button.

### 7.1 Push (FCM)
| Label                 | Key                       | UI | API | Notes | Final |
|-----------------------|---------------------------|----|-----|-------|-------|
| Push Enabled          | `integration_push_notif`  | ✅ | ✅ | Master toggle | ✅ |
| Server Key            | `fcm_server_key`          | ✅ | ✅ used by `/test-integration/fcm` (legacy HTTP API) | Operator-supplied. Test now reports HTTP-v1 incompatibility clearly when 401/404 | ⚠️ |
| Project ID            | `fcm_project_id`          | ✅ | ✅ | Operator-supplied | ⚠️ |

### 7.2 SMS
| Label                 | Key                  | UI | API | Notes | Final |
|-----------------------|----------------------|----|-----|-------|-------|
| SMS Enabled           | `integration_sms`    | ✅ | ✅ | Master toggle | ✅ |
| Provider              | `sms_provider`       | ✅ | ✅ | console / twilio / msg91 | ✅ |
| Twilio SID            | `sms_account_sid`    | ✅ | ✅ | Operator-supplied | ⚠️ |
| Twilio Auth Token     | `sms_api_key`        | ✅ | ✅ | Operator-supplied | ⚠️ |
| MSG91 Auth Key        | `sms_msg91_key`      | ✅ | ✅ | Operator-supplied | ⚠️ |
| Sender ID             | `sms_sender_id`      | ✅ | ✅ | Operator-supplied | ⚠️ |

### 7.3 WhatsApp
| Label                 | Key                       | UI | API | Notes | Final |
|-----------------------|---------------------------|----|-----|-------|-------|
| WhatsApp Enabled      | `integration_whatsapp`    | ✅ | ✅ | Master toggle | ✅ |
| Phone Number ID       | `wa_phone_number_id`      | ✅ | ✅ | Operator-supplied | ⚠️ |
| Business Account ID   | `wa_business_account_id`  | ✅ | ✅ | Operator-supplied | ⚠️ |
| Access Token          | `wa_access_token`         | ✅ | ✅ | Operator-supplied | ⚠️ |
| Verify Token          | `wa_verify_token`         | ✅ | ✅ | Operator-supplied | ⚠️ |
| OTP Template          | `wa_otp_template`         | ✅ | ✅ | Default acceptable | ✅ |
| Order Template        | `wa_order_template`       | ✅ | ✅ | Default acceptable | ✅ |

### 7.4 Email / SMTP
| Label                 | Key                       | UI | API | Notes | Final |
|-----------------------|---------------------------|----|-----|-------|-------|
| Email Enabled         | `integration_email`       | ✅ | ✅ | Master toggle | ✅ |
| SMTP Host             | `smtp_host`               | ✅ | ✅ | Operator-supplied | ⚠️ |
| SMTP Port             | `smtp_port`               | ✅ | ✅ | Operator-supplied | ⚠️ |
| SMTP Secure           | `smtp_secure`             | ✅ | ✅ | tls / ssl / none | ✅ |
| SMTP User             | `smtp_user`               | ✅ | ✅ | Operator-supplied | ⚠️ |
| SMTP Password         | `smtp_password`           | ✅ | ✅ | Operator-supplied | ⚠️ |
| From Email            | `smtp_from_email`         | ✅ | ✅ | Operator-supplied | ⚠️ |
| From Name             | `smtp_from_name`          | ✅ | ✅ | Default `AJKMart` | ✅ |
| Admin Alert Email     | `smtp_admin_alert_email`  | ✅ | ✅ used by sendAdminAlert | Operator-supplied | ⚠️ |

### 7.5 Maps
| Label                 | Key                              | UI | API | Notes | Final |
|-----------------------|----------------------------------|----|-----|-------|-------|
| Maps Enabled          | `integration_maps`               | ✅ | ✅ | Master toggle | ✅ |
| Maps Provider         | `maps_provider`                  | ✅ | ✅ | google / mapbox / osm | ✅ |
| Primary Tile          | `map_provider_primary`           | ✅ | ✅ | | ✅ |
| Secondary Tile        | `map_provider_secondary`         | ✅ | ✅ | failover | ✅ |
| Search Provider       | `map_search_provider`            | ✅ | ✅ | | ✅ |
| Routing Engine        | `routing_engine`                 | ✅ | ✅ | osrm / google / mapbox | ✅ |
| OSM Enabled           | `osm_enabled`                    | ✅ | ✅ | Free | ✅ |
| Mapbox Enabled / Key  | `mapbox_enabled` / `mapbox_api_key` | ✅ | ✅ | Operator-supplied | ⚠️ |
| Google Maps Enabled / Key| `google_maps_enabled` / `google_maps_api_key` | ✅ | ✅ | Operator-supplied | ⚠️ |
| LocationIQ Enabled / Key| `locationiq_enabled` / `locationiq_api_key` | ✅ | ✅ | Operator-supplied | ⚠️ |
| Failover Enabled      | `map_failover_enabled`           | ✅ | ✅ | | ✅ |
| Test Status (per-provider)| `map_test_status_*`         | ✅ auto | ✅ written by Test button | | ✅ |
| Last Tested (per-provider)| `map_last_tested_*`         | ✅ auto | ✅ | | ✅ |

### 7.6 Analytics
| Label                 | Key                          | UI | API | Notes | Final |
|-----------------------|------------------------------|----|-----|-------|-------|
| Analytics Enabled     | `integration_analytics`      | ✅ | ✅ | Master toggle | ✅ |
| Platform              | `analytics_platform`         | ✅ | ✅ | none/ga4/mixpanel | ✅ |
| Tracking ID           | `analytics_tracking_id`      | ✅ | ✅ | Operator-supplied | ⚠️ |
| API Secret            | `analytics_api_secret`       | ✅ | ✅ | Operator-supplied | ⚠️ |

### 7.7 Sentry
| Label                 | Key                          | UI | API | Notes | Final |
|-----------------------|------------------------------|----|-----|-------|-------|
| Sentry Enabled        | `integration_sentry`         | ✅ | ✅ | Master toggle | ✅ |
| DSN                   | `sentry_dsn`                 | ✅ | ✅ | Operator-supplied | ⚠️ |
| Environment           | `sentry_environment`         | ✅ | ✅ | production/staging | ✅ |
| Sample Rate           | `sentry_sample_rate`         | ✅ | ✅ | | ✅ |
| Traces Sample Rate    | `sentry_traces_sample_rate`  | ✅ | ✅ | | ✅ |

---

## 8. Security & Access  (`?tab=security_access`)

### 8.1 Authentication & OTP
| Label                            | Key                              | UI | API | Final |
|----------------------------------|----------------------------------|----|-----|-------|
| Require Manual Approval (all)    | `user_require_approval`          | ✅ (danger) | ✅ enforced in /auth | ✅ |
| Phone Verification               | `security_phone_verify`          | ✅ | ✅ | ✅ |
| Strong Password                  | `security_pwd_strong`            | ✅ | ✅ | ✅ |
| MFA Required                     | `security_mfa_required`          | ✅ | ✅ | ✅ |
| OTP Bypass (DANGER)              | `security_otp_bypass`            | ✅ (danger) | ✅ | ✅ |
| OTP Cooldown (sec)               | `security_otp_cooldown_sec`      | ✅ | ✅ | ✅ |
| OTP Max per Phone                | `security_otp_max_per_phone`     | ✅ | ✅ | ✅ |
| OTP Max per IP                   | `security_otp_max_per_ip`        | ✅ | ✅ | ✅ |
| OTP Window (min)                 | `security_otp_window_min`        | ✅ | ✅ | ✅ |
| Login Max Attempts               | `security_login_max_attempts`    | ✅ | ✅ | ✅ |
| Lockout (min)                    | `security_lockout_minutes`       | ✅ | ✅ | ✅ |
| Session (days)                   | `security_session_days`          | ✅ | ✅ | ✅ |
| Trusted Device (days)            | `auth_trusted_device_days`       | ✅ | ✅ | ✅ |

### 8.2 GPS / Geo / Network Security
| Label                            | Key                              | UI | API | Final |
|----------------------------------|----------------------------------|----|-----|-------|
| GPS Tracking                     | `security_gps_tracking`          | ✅ | ✅ | ✅ |
| Spoof Detection                  | `security_spoof_detection`       | ✅ | ✅ | ✅ |
| Geo Fence                        | `security_geo_fence`             | ✅ | ✅ | ✅ |
| Block Tor                        | `security_block_tor`             | ✅ | ✅ enforced in middleware | ✅ |
| Block VPN                        | `security_block_vpn`             | ✅ | ✅ enforced | ✅ |
| Audit Log                        | `security_audit_log`             | ✅ | ✅ gate `addAuditEntry` | ✅ |
| Fake Order Detection             | `security_fake_order_detect`     | ✅ | ✅ | ✅ |
| Auto-block IP                    | `security_auto_block_ip`         | ✅ | ✅ | ✅ |
| Admin IP Whitelist               | `security_admin_ip_whitelist`    | ✅ | ✅ enforced | ✅ |

### 8.3 JWT & Sessions
| Label                            | Key                              | UI | API | Final |
|----------------------------------|----------------------------------|----|-----|-------|
| Access TTL (min)                 | `jwt_access_ttl_min`             | ✅ | ✅ | ✅ |
| Refresh TTL (days)               | `jwt_refresh_ttl_days`           | ✅ | ✅ | ✅ |
| 2FA Challenge TTL (min)          | `jwt_2fa_challenge_min`          | ✅ | ✅ | ✅ |

### 8.4 Content Moderation
| Label                            | Key                              | UI | API | Final |
|----------------------------------|----------------------------------|----|-----|-------|
| Mask Phone                       | `mod_mask_phone`                 | ✅ | ✅ in chat sanitizer | ✅ |
| Mask CNIC                        | `mod_mask_cnic`                  | ✅ | ✅ | ✅ |
| Flag Keywords                    | `mod_flag_keywords`              | ✅ | ✅ | ✅ |
| Custom Regex                     | `mod_custom_regex`               | ✅ | ✅ | ✅ |

### 8.5 Endpoint Rate Limits
| Label                            | Key                              | UI | API | Final |
|----------------------------------|----------------------------------|----|-----|-------|
| Bargain (per min)                | `rate_bargain_per_min`           | ✅ | ✅ | ✅ |
| Booking (per min)                | `rate_book_per_min`              | ✅ | ✅ | ✅ |
| Cancellation (per min)           | `rate_cancel_per_min`            | ✅ | ✅ | ✅ |
| Estimate (per min)               | `rate_estimate_per_min`          | ✅ | ✅ | ✅ |

---

## 9. System & Performance  (`?tab=system_perf`)

### 9.1 System & Data (`SystemSection.tsx`)
- Database stats (read-only)
- Backup / Restore controls
- Demo backup snapshot endpoints

| Label                          | Key                              | UI | API | Final |
|--------------------------------|----------------------------------|----|-----|-------|
| Backup Retention (days)        | `system_backup_retention_days`   | ✅ | ✅ | ✅ |
| Audit Retain (days)            | `system_audit_retain_days`       | ✅ | ✅ | ✅ |
| Log Retention (days)           | `system_log_retention_days`      | ✅ | ✅ | ✅ |

### 9.2 System Limits
| Label                          | Key                              | UI | API | Final |
|--------------------------------|----------------------------------|----|-----|-------|
| Body Limit (MB)                | `sys_body_limit_mb`              | ✅ | ✅ enforced in express | ✅ |
| Upload Limit (MB)              | `sys_upload_limit_mb`            | ✅ | ✅ enforced in upload guard | ✅ |
| Log Retention (days)           | `sys_log_retention_days`         | ✅ | ✅ | ✅ |

### 9.3 Cache TTLs
| Label                  | Key                  | UI | API | Final |
|------------------------|----------------------|----|-----|-------|
| Settings TTL (sec)     | `cache_settings_sec` | ✅ | ✅ used by getCachedSettings | ✅ |
| VPN Cache (sec)        | `cache_vpn_sec`      | ✅ | ✅ | ✅ |
| TOR Cache (sec)        | `cache_tor_sec`      | ✅ | ✅ | ✅ |
| Zone Cache (sec)       | `cache_zone_sec`     | ✅ | ✅ | ✅ |

### 9.4 Network & Retry
| Label                          | Key                       | UI | API | Final |
|--------------------------------|---------------------------|----|-----|-------|
| API Timeout (ms)               | `net_api_timeout_ms`      | ✅ | ✅ | ✅ |
| Retry Attempts                 | `net_retry_attempts`      | ✅ | ✅ | ✅ |
| Backoff (ms)                   | `net_backoff_ms`          | ✅ | ✅ | ✅ |
| GPS Queue Size                 | `net_gps_queue_size`      | ✅ | ✅ | ✅ |
| Dismissed TTL (sec)            | `net_dismissed_ttl_sec`   | ✅ | ✅ | ✅ |

### 9.5 Geo & Zones
| Label                          | Key                              | UI | API | Final |
|--------------------------------|----------------------------------|----|-----|-------|
| Default Zone Radius (km)       | `geo_default_zone_radius_km`     | ✅ | ✅ | ✅ |
| Open-World Fallback            | `geo_open_world_fallback`        | ✅ | ✅ | ✅ |

### 9.6 Upload Limits
| Label                  | Key                          | UI | API | Final |
|------------------------|------------------------------|----|-----|-------|
| Max Image (MB)         | `upload_max_image_mb`        | ✅ | ✅ | ✅ |
| Max Video (MB)         | `upload_max_video_mb`        | ✅ | ✅ | ✅ |
| Image Formats          | `upload_image_formats`       | ✅ | ✅ | ✅ |
| Video Formats          | `upload_video_formats`       | ✅ | ✅ | ✅ |
| KYC Required Docs      | `upload_kyc_required_docs`   | ✅ | ✅ | ✅ |

### 9.7 Pagination
| Label                  | Key                          | UI | API | Final |
|------------------------|------------------------------|----|-----|-------|
| Products per Page      | `page_products_per_page`     | ✅ | ✅ | ✅ |
| Trending Limit         | `page_trending_limit`        | ✅ | ✅ | ✅ |
| Flash Deals            | `page_flash_deals`           | ✅ | ✅ | ✅ |
| Orders per Page        | `page_orders_per_page`       | ✅ | ✅ | ✅ |

---

## 10. Widgets & Add-ons  (`?tab=widgets`)

### 10.1 Weather Widget (`WeatherSection.tsx` + `weatherConfigTable`)
| Label             | Storage                            | UI | API | Notes | Final |
|-------------------|------------------------------------|----|-----|-------|-------|
| Widget Enabled    | `weatherConfigTable.widgetEnabled` | ✅ | ✅ served by /platform-config | | ✅ |
| Cities list       | `weatherConfigTable.cities`        | ✅ | ✅ | Comma-separated | ✅ |
| Provider          | Open-Meteo (no key required)       | ✅ | ✅ POST /api/admin/weather-config/test | New Test button verifies geocoding + forecast | ✅ |

---

## Test-Connection / Health endpoints (verified)

| Endpoint                                          | Verb | Used by                       |
|---------------------------------------------------|------|-------------------------------|
| `/api/payments/test-connection/jazzcash`          | GET  | Payment → JazzCash            |
| `/api/payments/test-connection/easypaisa`         | GET  | Payment → EasyPaisa           |
| `/api/payments/test-connection/cod`               | GET  | Payment → COD                 |
| `/api/admin/system/test-integration/email`        | POST | Integrations → Email          |
| `/api/admin/system/test-integration/sms`          | POST | Integrations → SMS            |
| `/api/admin/system/test-integration/whatsapp`     | POST | Integrations → WhatsApp       |
| `/api/admin/system/test-integration/fcm`          | POST | Integrations → Push (FCM)     |
| `/api/admin/system/test-integration/maps`         | POST | Integrations → Maps           |
| `/api/maps/admin/test`                            | POST | Maps → per-provider Test (key override supported) |
| `/api/admin/weather-config/test`                  | POST | **NEW** Weather widget Test    |

### Recent fixes captured by this revision

| Item                                              | Before                              | After                                              |
|---------------------------------------------------|-------------------------------------|----------------------------------------------------|
| Payment Test Connection error swallowing          | "Connection failed" for everything   | Surfaces 401/403/404/5xx/network with real detail  |
| FCM legacy endpoint failure on new Firebase apps  | Generic `FCM HTTP 401` toast        | Explicit message instructing operator to use HTTP v1 + service-account JSON |
| Weather widget had no way to verify connectivity  | No Test button                      | "Test Connection" button + new `/admin/weather-config/test` endpoint pinging Open-Meteo geocoder + forecast |

---

## How to keep this file fresh

1. After adding/removing a setting key from any settings page, add or remove
   the row above and tag the **Final Status** (✅/⚠️/🐛/❌).
2. After changing the navigation grouping, also update `LEGACY_TO_TOP10` in
   `artifacts/admin/src/pages/settings.tsx` and the table at the top of this
   file.
3. After fixing a known bug, flip 🐛 → ✅ and add a row to "Recent fixes".
4. Regenerate `admin-config.md` § 4.9 (Settings) so it references the same
   Top-10 tabs.
