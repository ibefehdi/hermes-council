-- Enable required PostgreSQL extensions for MVP
-- btree_gist: required for exclusion constraints (GiST index on scalar types)
-- pgcrypto: provides gen_random_uuid() for UUID generation (available by default in Supabase)

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verify extensions are available
DO $$
BEGIN
  RAISE NOTICE 'Extensions enabled: btree_gist, pgcrypto';
END $$;