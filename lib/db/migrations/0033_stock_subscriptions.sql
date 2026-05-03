CREATE TABLE IF NOT EXISTS "stock_subscriptions" (
  "id" text PRIMARY KEY NOT NULL,
  "user_id" text NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "product_id" text NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
  "created_at" timestamp DEFAULT now() NOT NULL,
  CONSTRAINT "stock_subscriptions_user_product_uniq" UNIQUE ("user_id", "product_id")
);

CREATE INDEX IF NOT EXISTS "stock_subscriptions_user_id_idx" ON "stock_subscriptions" ("user_id");
CREATE INDEX IF NOT EXISTS "stock_subscriptions_product_id_idx" ON "stock_subscriptions" ("product_id");
