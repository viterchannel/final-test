CREATE TABLE IF NOT EXISTS vendor_plans (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,
  description     TEXT NOT NULL DEFAULT '',
  features_json   TEXT NOT NULL DEFAULT '[]',
  commission_rate REAL NOT NULL DEFAULT 15,
  monthly_fee     REAL NOT NULL DEFAULT 0,
  max_products    INTEGER NOT NULL DEFAULT 50,
  max_orders      INTEGER NOT NULL DEFAULT 500,
  is_default      BOOLEAN NOT NULL DEFAULT FALSE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_role_presets (
  id               TEXT PRIMARY KEY,
  name             TEXT NOT NULL,
  slug             TEXT NOT NULL UNIQUE,
  description      TEXT NOT NULL DEFAULT '',
  permissions_json TEXT NOT NULL DEFAULT '[]',
  role             TEXT NOT NULL DEFAULT 'manager',
  is_built_in      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMP NOT NULL DEFAULT NOW()
);
