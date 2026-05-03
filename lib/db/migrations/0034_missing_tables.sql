-- ── A/B Experiments ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "ab_experiments" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL DEFAULT '',
  "status" text NOT NULL DEFAULT 'draft',
  "variants" jsonb NOT NULL DEFAULT '[]',
  "traffic_pct" integer NOT NULL DEFAULT 100,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "ab_experiments_status_idx" ON "ab_experiments" ("status");

CREATE TABLE IF NOT EXISTS "ab_assignments" (
  "id" text PRIMARY KEY NOT NULL,
  "experiment_id" text NOT NULL REFERENCES "ab_experiments"("id"),
  "user_id" text NOT NULL,
  "variant" text NOT NULL,
  "converted" boolean NOT NULL DEFAULT false,
  "assigned_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "ab_assignments_experiment_idx" ON "ab_assignments" ("experiment_id");
CREATE INDEX IF NOT EXISTS "ab_assignments_user_idx" ON "ab_assignments" ("user_id");
CREATE INDEX IF NOT EXISTS "ab_assignments_variant_idx" ON "ab_assignments" ("variant");
CREATE UNIQUE INDEX IF NOT EXISTS "ab_assignments_exp_user_unique" ON "ab_assignments" ("experiment_id", "user_id");

-- ── Chat Reports ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "chat_reports" (
  "id" text PRIMARY KEY NOT NULL,
  "reporter_id" text NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "reported_user_id" text NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "message_id" text REFERENCES "chat_messages"("id") ON DELETE SET NULL,
  "reason" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending',
  "resolved_by" text,
  "resolved_at" timestamp,
  "created_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "chat_reports_reporter_idx" ON "chat_reports" ("reporter_id");
CREATE INDEX IF NOT EXISTS "chat_reports_reported_idx" ON "chat_reports" ("reported_user_id");
CREATE INDEX IF NOT EXISTS "chat_reports_status_idx" ON "chat_reports" ("status");

-- ── Deep Links ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "deep_links" (
  "id" text PRIMARY KEY NOT NULL,
  "short_code" text NOT NULL UNIQUE,
  "target_screen" text NOT NULL,
  "params" jsonb NOT NULL DEFAULT '{}',
  "label" text NOT NULL DEFAULT '',
  "click_count" integer NOT NULL DEFAULT 0,
  "created_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "deep_links_short_code_idx" ON "deep_links" ("short_code");
CREATE INDEX IF NOT EXISTS "deep_links_target_idx" ON "deep_links" ("target_screen");

-- ── QR Codes ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "qr_codes" (
  "id" text PRIMARY KEY NOT NULL,
  "code" text NOT NULL UNIQUE,
  "type" text NOT NULL DEFAULT 'payment',
  "label" text NOT NULL,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_by" text REFERENCES "users"("id"),
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "qr_codes_type_idx" ON "qr_codes" ("type");
CREATE INDEX IF NOT EXISTS "qr_codes_is_active_idx" ON "qr_codes" ("is_active");
CREATE INDEX IF NOT EXISTS "qr_codes_code_idx" ON "qr_codes" ("code");

-- ── Weather Config ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "weather_config" (
  "id" text PRIMARY KEY NOT NULL DEFAULT 'default',
  "widget_enabled" boolean NOT NULL DEFAULT true,
  "cities" text NOT NULL DEFAULT 'Muzaffarabad,Rawalakot,Mirpur,Bagh,Kotli,Neelum',
  "updated_at" timestamp DEFAULT now() NOT NULL
);

INSERT INTO "weather_config" ("id") VALUES ('default') ON CONFLICT DO NOTHING;

-- ── Webhook Registrations & Logs ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "webhook_registrations" (
  "id" text PRIMARY KEY NOT NULL,
  "url" text NOT NULL,
  "events" jsonb NOT NULL DEFAULT '[]',
  "secret" text,
  "is_active" boolean NOT NULL DEFAULT true,
  "description" text NOT NULL DEFAULT '',
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "webhook_registrations_active_idx" ON "webhook_registrations" ("is_active");

CREATE TABLE IF NOT EXISTS "webhook_logs" (
  "id" text PRIMARY KEY NOT NULL,
  "webhook_id" text NOT NULL REFERENCES "webhook_registrations"("id"),
  "event" text NOT NULL,
  "url" text NOT NULL,
  "status" integer,
  "request_body" jsonb,
  "response_body" text,
  "success" boolean NOT NULL DEFAULT false,
  "error" text,
  "duration_ms" integer,
  "created_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "webhook_logs_webhook_idx" ON "webhook_logs" ("webhook_id");
CREATE INDEX IF NOT EXISTS "webhook_logs_event_idx" ON "webhook_logs" ("event");
CREATE INDEX IF NOT EXISTS "webhook_logs_created_idx" ON "webhook_logs" ("created_at");

-- ── Vendor Schedules ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "vendor_schedules" (
  "id" text PRIMARY KEY NOT NULL,
  "vendor_id" text NOT NULL,
  "day_of_week" integer NOT NULL,
  "open_time" text NOT NULL DEFAULT '09:00',
  "close_time" text NOT NULL DEFAULT '21:00',
  "is_enabled" boolean NOT NULL DEFAULT true,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "vendor_schedules_vendor_day_idx" ON "vendor_schedules" ("vendor_id", "day_of_week");
