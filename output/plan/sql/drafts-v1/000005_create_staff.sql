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

-- Create staff-related tables: staff, staff_branch_assignments, staff_working_hours, staff_time_off

-- ============================================================================
-- STAFF
-- ============================================================================
CREATE TABLE public.staff (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  user_id     uuid NOT NULL REFERENCES auth.users(id),
  job_title   text,
  initials    text,
  color       text,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_staff_tenant ON public.staff(tenant_id);
CREATE INDEX idx_staff_user ON public.staff(user_id);

CREATE TRIGGER set_updated_at_staff
  BEFORE UPDATE ON public.staff
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- STAFF_BRANCH_ASSIGNMENTS
-- ============================================================================
CREATE TABLE public.staff_branch_assignments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id    uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  branch_id   uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  UNIQUE (staff_id, branch_id)
);

CREATE INDEX idx_sba_staff ON public.staff_branch_assignments(staff_id);
CREATE INDEX idx_sba_branch ON public.staff_branch_assignments(branch_id);
CREATE INDEX idx_sba_tenant ON public.staff_branch_assignments(tenant_id);

-- ============================================================================
-- STAFF_WORKING_HOURS
-- ============================================================================
CREATE TABLE public.staff_working_hours (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id     uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  branch_id    uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  tenant_id    uuid NOT NULL REFERENCES public.tenants(id),
  day_of_week  smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  starts_at    time NOT NULL,
  ends_at      time NOT NULL,
  valid_from   date NOT NULL DEFAULT CURRENT_DATE,
  valid_until  date,
  UNIQUE (staff_id, branch_id, day_of_week, valid_from),
  CHECK (ends_at > starts_at)
);

CREATE INDEX idx_swh_staff ON public.staff_working_hours(staff_id);
CREATE INDEX idx_swh_branch ON public.staff_working_hours(branch_id);
CREATE INDEX idx_swh_tenant ON public.staff_working_hours(tenant_id);

-- ============================================================================
-- STAFF_TIME_OFF
-- ============================================================================
CREATE TABLE public.staff_time_off (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id    uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  starts_at   timestamptz NOT NULL,
  ends_at     timestamptz NOT NULL,
  reason      text,
  is_paid     boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);

CREATE INDEX idx_sto_staff ON public.staff_time_off(staff_id);
CREATE INDEX idx_sto_tenant ON public.staff_time_off(tenant_id);