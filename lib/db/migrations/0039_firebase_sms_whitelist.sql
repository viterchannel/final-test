-- Migration 0039: Firebase UID + SMS Gateways + OTP Whitelist
-- All statements are idempotent (IF NOT EXISTS / DO NOTHING).

/* ── 1. firebase_uid on users ─────────────────────────────── */
ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;

/* ── 2. sms_gateways — priority-based SMS provider config ── */
CREATE TABLE IF NOT EXISTS sms_gateways (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  provider     TEXT NOT NULL,
  priority     INTEGER NOT NULL DEFAULT 10,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,

  /* Twilio */
  account_sid  TEXT,
  auth_token   TEXT,
  from_number  TEXT,

  /* MSG91 */
  msg91_key    TEXT,
  sender_id    TEXT,

  /* Generic */
  api_key      TEXT,
  api_url      TEXT,

  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

/* Seed a default console gateway so the table is never empty */
INSERT INTO sms_gateways (id, name, provider, priority, is_active)
VALUES ('default-console', 'Console (Dev)', 'console', 99, TRUE)
ON CONFLICT (id) DO NOTHING;

/* ── 3. whitelist_users — per-identity OTP bypass ─────────── */
CREATE TABLE IF NOT EXISTS whitelist_users (
  id           TEXT PRIMARY KEY,
  identifier   TEXT NOT NULL UNIQUE,
  label        TEXT,
  bypass_code  TEXT NOT NULL DEFAULT '000000',
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  expires_at   TIMESTAMP,
  created_by   TEXT,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

/* ── 4. platform_settings: seed auth config keys ─────────── */
INSERT INTO platform_settings (key, value, label, category)
VALUES
  ('auth_mode',             'OTP',     'Auth Mode (OTP | EMAIL | FIREBASE)', 'auth'),
  ('firebase_enabled',      'off',     'Enable Firebase Auth Layer',         'auth'),
  ('otp_whitelist_enabled', 'on',      'Enable OTP Whitelist',               'auth'),
  ('sms_failover_enabled',  'on',      'Enable SMS Gateway Failover',        'auth')
ON CONFLICT (key) DO NOTHING;
