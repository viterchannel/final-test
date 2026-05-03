-- Add dedicated status column to wallet_transactions
-- Previously status was embedded as a prefix in the reference column (e.g. "pending:txid:...")
ALTER TABLE wallet_transactions
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS wallet_txn_status_idx ON wallet_transactions(status);

-- Back-fill status from the reference column prefix convention
UPDATE wallet_transactions
SET status = CASE
  WHEN reference LIKE 'approved:%' OR reference = 'approved' THEN 'approved'
  WHEN reference LIKE 'rejected:%' OR reference = 'rejected' THEN 'rejected'
  ELSE 'pending'
END
WHERE status = 'pending';
