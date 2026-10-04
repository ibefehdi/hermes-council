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

-- Create memberships table and RLS helper functions

-- ============================================================================
-- MEMBERSHIPS
-- ============================================================================
CREATE TABLE public.memberships (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  role        text NOT NULL DEFAULT 'staff'
              CHECK (role IN ('platform_admin', 'tenant_owner', 'branch_manager', 'receptionist', 'staff')),
  branch_id   uuid REFERENCES public.branches(id) ON DELETE SET NULL,  -- NULL = all branches
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, tenant_id)
);

CREATE INDEX idx_memberships_user ON public.memberships(user_id);
CREATE INDEX idx_memberships_tenant ON public.memberships(tenant_id);
CREATE INDEX idx_memberships_user_tenant ON public.memberships(user_id, tenant_id);

CREATE TRIGGER set_updated_at_memberships
  BEFORE UPDATE ON public.memberships
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- RLS HELPER FUNCTIONS
-- ============================================================================

-- Returns tenant_ids the current user belongs to
CREATE OR REPLACE FUNCTION public.get_user_tenant_ids()
RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT tenant_id FROM public.memberships
  WHERE user_id = (SELECT auth.uid())
  AND is_active = true;
$$;

-- Returns (tenant_id, branch_id) pairs for branch-scoped checks
CREATE OR REPLACE FUNCTION public.get_user_branch_scope()
RETURNS TABLE(tenant_id uuid, branch_id uuid)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT tenant_id, branch_id FROM public.memberships
  WHERE user_id = (SELECT auth.uid())
  AND is_active = true;
$$;

-- Check if user has a specific role in a tenant
CREATE OR REPLACE FUNCTION public.has_tenant_role(p_tenant_id uuid, VARIADIC p_roles text[])
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = (SELECT auth.uid())
    AND tenant_id = p_tenant_id
    AND role = ANY(p_roles)
    AND is_active = true
  );
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_tenant_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_branch_scope() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_tenant_role(uuid, text[]) TO authenticated;