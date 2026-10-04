-- ============================================================================
-- SUPERSEDED ROUND-1 DRAFT (quarantined in round 2, finding F-1).
-- This file is NOT an active migration and must never be applied by any
-- tooling (`supabase db reset`, CI, or hand). The active migration set is
-- written fresh under supabase/migrations/ in Phase 0/1 from the binding
-- ADRs (decisions.md) and CONVENTIONS.md.
-- Known defects in this draft (numeric money, 'started' status, sentinel
-- branch UUID, separate refunds table, tenant-only RLS, missing
-- security_invoker, race-prone booking trigger, rejected table names,
-- service_charge_total column) are catalogued in review2/adjudication.md
-- and REVISION_LOG.md.
-- ============================================================================

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