-- Migration: Rider API critical bug fixes
-- 1. OTP attempt counter table (replaces in-memory Map — survives restarts, multi-instance safe)
CREATE TABLE IF NOT EXISTS otp_attempts (
  key        TEXT        PRIMARY KEY,
  count      INTEGER     NOT NULL DEFAULT 0,
  first_at   TIMESTAMP   NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP   NOT NULL
);

-- 2. acceptedAt column on orders (powers ElapsedBadge timer in rider app)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP;

-- 3. Composite index on orders(status, rider_id) — covers rider feed poll and active-delivery count
CREATE INDEX IF NOT EXISTS orders_status_rider_id_idx ON orders (status, rider_id);

-- 4. Composite index on rides(status, rider_id) — covers rider feed poll and active-ride count
CREATE INDEX IF NOT EXISTS rides_status_rider_id_idx ON rides (status, rider_id);
