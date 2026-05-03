-- Add GIN index for products full-text search to avoid per-query tsvector recomputation.
-- The expression matches the to_tsvector call used in routes/products.ts /search.
-- CREATE INDEX CONCURRENTLY is not allowed inside a transaction; the migration runner
-- executes each file as a single query, so we use plain CREATE INDEX IF NOT EXISTS
-- which is safe to re-run (idempotent via IF NOT EXISTS).
CREATE INDEX IF NOT EXISTS products_fts_gin_idx
  ON products
  USING gin (
    to_tsvector(
      'english',
      coalesce(name, '') || ' ' || coalesce(description, '')
    )
  );
