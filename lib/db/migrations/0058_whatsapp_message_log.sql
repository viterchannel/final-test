-- WhatsApp message delivery tracking log
-- Records every outbound WhatsApp message (sent by the platform) together
-- with status updates received via the Meta webhook (sent/delivered/read/failed).
-- The wa_message_id is the ID returned by the Graph API when the message is sent
-- and is used to correlate status updates arriving via POST /webhooks/whatsapp.

CREATE TABLE IF NOT EXISTS whatsapp_message_log (
  id                TEXT        PRIMARY KEY,
  wa_message_id     TEXT        UNIQUE,           -- Meta message ID ("wamid.xxx")
  recipient_phone   TEXT        NOT NULL,
  status            TEXT        NOT NULL DEFAULT 'sent',  -- sent | delivered | read | failed
  error_code        TEXT,
  error_message     TEXT,
  notification_id   TEXT,                         -- FK to notifications table (nullable)
  context_type      TEXT,                         -- e.g. "otp" | "order" | "ride" | "generic"
  context_id        TEXT,                         -- order_id / ride_id / etc.
  fallback_sent     BOOLEAN     NOT NULL DEFAULT FALSE,
  fallback_channel  TEXT,                         -- "sms" | "push" | null
  raw_payload       JSONB,
  sent_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wml_wa_message_id     ON whatsapp_message_log (wa_message_id);
CREATE INDEX IF NOT EXISTS idx_wml_recipient_phone   ON whatsapp_message_log (recipient_phone);
CREATE INDEX IF NOT EXISTS idx_wml_status            ON whatsapp_message_log (status);
CREATE INDEX IF NOT EXISTS idx_wml_notification_id   ON whatsapp_message_log (notification_id);
CREATE INDEX IF NOT EXISTS idx_wml_sent_at           ON whatsapp_message_log (sent_at DESC);
