ALTER TABLE "admin_accounts" ADD COLUMN IF NOT EXISTS "username" text;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'admin_accounts_username_unique'
  ) THEN
    ALTER TABLE "admin_accounts" ADD CONSTRAINT "admin_accounts_username_unique" UNIQUE ("username");
  END IF;
END $$;
