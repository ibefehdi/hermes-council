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

-- Create cancellation_reasons, settings, and audit_log

-- ============================================================================
-- CANCELLATION_REASONS
-- ============================================================================
CREATE TABLE public.cancellation_reasons (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES public.tenants(id),
  name           text NOT NULL,
  display_order  int NOT NULL DEFAULT 0,
  is_active      boolean NOT NULL DEFAULT true
);

CREATE INDEX idx_cr_tenant ON public.cancellation_reasons(tenant_id);

-- ============================================================================
-- SETTINGS (key-value, tenant-scoped)
-- ============================================================================
CREATE TABLE public.settings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  branch_id   uuid REFERENCES public.branches(id),  -- NULL = tenant-wide
  key         text NOT NULL,
  value       jsonb NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  uuid REFERENCES auth.users(id),
  UNIQUE (tenant_id, branch_id, key)
);

CREATE INDEX idx_settings_tenant ON public.settings(tenant_id);
CREATE INDEX idx_settings_branch ON public.settings(branch_id);

-- ============================================================================
-- AUDIT_LOG
-- ============================================================================
CREATE TABLE public.audit_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid NOT NULL REFERENCES public.tenants(id),
  actor_id      uuid NOT NULL REFERENCES auth.users(id),
  action        text NOT NULL,
  entity_type   text NOT NULL,
  entity_id     uuid NOT NULL,
  changes       jsonb,
  performed_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_tenant ON public.audit_log(tenant_id);
CREATE INDEX idx_audit_entity ON public.audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_time ON public.audit_log(tenant_id, performed_at DESC);