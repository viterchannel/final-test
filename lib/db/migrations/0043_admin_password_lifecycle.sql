-- Admin password lifecycle: seeded super-admin, force-change, and reset tokens.
-- Adds:
--   * admin_accounts.email                       (nullable, unique) — used as the
--                                                 password-reset lookup key.
--   * admin_accounts.must_change_password        (default false)    — gates the
--                                                 force-change-password flow.
--   * admin_accounts.password_changed_at         (nullable)         — stamped on
--                                                 every successful password change.
--   * admin_password_reset_tokens                (new table)        — stores the
--                                                 sha256 of single-use, time-limited
--                                                 reset tokens. The raw token
--                                                 itself is never persisted.

ALTER TABLE "admin_accounts"
  ADD COLUMN IF NOT EXISTS "email" text;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public' AND indexname = 'admin_accounts_email_unique'
  ) THEN
    CREATE UNIQUE INDEX "admin_accounts_email_unique"
      ON "admin_accounts" ("email")
      WHERE "email" IS NOT NULL;
  END IF;
END $$;

ALTER TABLE "admin_accounts"
  ADD COLUMN IF NOT EXISTS "must_change_password" boolean NOT NULL DEFAULT false;

ALTER TABLE "admin_accounts"
  ADD COLUMN IF NOT EXISTS "password_changed_at" timestamp;

CREATE TABLE IF NOT EXISTS "admin_password_reset_tokens" (
  "id"                text PRIMARY KEY,
  "admin_id"          text NOT NULL REFERENCES "admin_accounts"("id") ON DELETE CASCADE,
  "token_hash"        text NOT NULL UNIQUE,
  "expires_at"        timestamp NOT NULL,
  "used_at"           timestamp,
  "requested_by"      text NOT NULL DEFAULT 'self',     -- 'self' | 'super_admin'
  "requester_admin_id" text REFERENCES "admin_accounts"("id") ON DELETE SET NULL,
  "requester_ip"      varchar(45) NOT NULL DEFAULT 'unknown',
  "requester_user_agent" text,
  "created_at"        timestamp NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "admin_password_reset_tokens_admin_idx"
  ON "admin_password_reset_tokens" ("admin_id");

CREATE INDEX IF NOT EXISTS "admin_password_reset_tokens_expires_idx"
  ON "admin_password_reset_tokens" ("expires_at");
