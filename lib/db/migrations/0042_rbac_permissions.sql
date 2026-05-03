-- RBAC: fine-grained permission system. Coexists with legacy admin_accounts.role.

CREATE TABLE IF NOT EXISTS rbac_permissions (
  id          TEXT PRIMARY KEY,
  label       TEXT NOT NULL,
  category    TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rbac_roles (
  id           TEXT PRIMARY KEY,
  slug         TEXT NOT NULL UNIQUE,
  name         TEXT NOT NULL,
  description  TEXT,
  is_built_in  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rbac_role_permissions (
  role_id       TEXT NOT NULL,
  permission_id TEXT NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (role_id, permission_id)
);
CREATE INDEX IF NOT EXISTS rbac_role_permissions_role_idx ON rbac_role_permissions (role_id);

CREATE TABLE IF NOT EXISTS rbac_admin_role_assignments (
  admin_id   TEXT NOT NULL,
  role_id    TEXT NOT NULL,
  granted_by TEXT,
  granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (admin_id, role_id)
);
CREATE INDEX IF NOT EXISTS rbac_admin_role_assignments_admin_idx
  ON rbac_admin_role_assignments (admin_id);

CREATE TABLE IF NOT EXISTS rbac_user_role_assignments (
  user_id    TEXT NOT NULL,
  role_id    TEXT NOT NULL,
  scope_type TEXT NOT NULL DEFAULT 'global',
  scope_id   TEXT,
  granted_by TEXT,
  granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id, scope_type)
);
CREATE INDEX IF NOT EXISTS rbac_user_role_assignments_user_idx
  ON rbac_user_role_assignments (user_id);
