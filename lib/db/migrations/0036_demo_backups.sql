CREATE TABLE IF NOT EXISTS demo_backups (
  id          TEXT PRIMARY KEY,
  label       TEXT NOT NULL,
  tables_json TEXT NOT NULL,
  rows_total  INTEGER NOT NULL DEFAULT 0,
  size_kb     INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
