-- 0041_auth_audit_indexes.sql
-- Indexes added during Task #1 (Auth audit & admin control fix).
-- All statements are idempotent (IF NOT EXISTS).

-- auth_audit_log: filtered by user, action, ip, and time-windows in the admin UI
CREATE INDEX IF NOT EXISTS auth_audit_log_user_id_idx     ON auth_audit_log (user_id);
CREATE INDEX IF NOT EXISTS auth_audit_log_event_idx       ON auth_audit_log (event);
CREATE INDEX IF NOT EXISTS auth_audit_log_ip_idx          ON auth_audit_log (ip);
CREATE INDEX IF NOT EXISTS auth_audit_log_created_at_idx  ON auth_audit_log (created_at DESC);

-- refresh_tokens: lookups by user_id (logout-everywhere, session list) and
-- expires_at (cron cleanup)
CREATE INDEX IF NOT EXISTS refresh_tokens_user_id_idx     ON refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_expires_at_idx  ON refresh_tokens (expires_at);

-- pending_otps: cron deletes expired rows by otp_expiry
CREATE INDEX IF NOT EXISTS pending_otps_otp_expiry_idx    ON pending_otps (otp_expiry);

-- magic_link_tokens: filter by user + cleanup
CREATE INDEX IF NOT EXISTS magic_link_tokens_user_id_idx     ON magic_link_tokens (user_id);
CREATE INDEX IF NOT EXISTS magic_link_tokens_expires_at_idx  ON magic_link_tokens (expires_at);
