ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "require_password_change" boolean NOT NULL DEFAULT false;
