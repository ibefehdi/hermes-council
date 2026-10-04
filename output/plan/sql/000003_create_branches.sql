-- Create branches and branch_hours

-- ============================================================================
-- BRANCHES
-- ============================================================================
CREATE TABLE public.branches (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  name        text NOT NULL,
  address     text,
  timezone    text NOT NULL DEFAULT 'Asia/Kuwait',
  phone       text,
  email       text,
  is_active   boolean NOT NULL DEFAULT true,
  settings    jsonb NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_branches_tenant ON public.branches(tenant_id);

CREATE TRIGGER set_updated_at_branches
  BEFORE UPDATE ON public.branches
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- BRANCH_HOURS
-- ============================================================================
CREATE TABLE public.branch_hours (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  day_of_week  smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  opens_at     time,   -- NULL = closed
  closes_at    time,   -- NULL = closed
  tenant_id    uuid NOT NULL REFERENCES public.tenants(id),
  UNIQUE (branch_id, day_of_week)
);

CREATE INDEX idx_branch_hours_branch ON public.branch_hours(branch_id);
CREATE INDEX idx_branch_hours_tenant ON public.branch_hours(tenant_id);