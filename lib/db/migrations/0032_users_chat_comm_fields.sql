ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "chat_muted" boolean NOT NULL DEFAULT false;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "comm_blocked" boolean NOT NULL DEFAULT false;
