-- Migration 0040: Add error_hash and occurrence_count to error_reports
-- All statements are idempotent (ADD COLUMN IF NOT EXISTS).

ALTER TABLE error_reports ADD COLUMN IF NOT EXISTS error_hash TEXT;
ALTER TABLE error_reports ADD COLUMN IF NOT EXISTS occurrence_count INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_error_reports_hash ON error_reports(error_hash)
  WHERE error_hash IS NOT NULL;
