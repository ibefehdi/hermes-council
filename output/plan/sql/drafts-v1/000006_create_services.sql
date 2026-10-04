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

-- Create service-related tables: service_categories, services, branch_services

-- ============================================================================
-- SERVICE_CATEGORIES
-- ============================================================================
CREATE TABLE public.service_categories (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES public.tenants(id),
  name           text NOT NULL,
  display_order  int NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, name)
);

CREATE INDEX idx_sc_tenant ON public.service_categories(tenant_id);

CREATE TRIGGER set_updated_at_service_categories
  BEFORE UPDATE ON public.service_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- SERVICES
-- ============================================================================
CREATE TABLE public.services (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id                uuid NOT NULL REFERENCES public.tenants(id),
  category_id              uuid NOT NULL REFERENCES public.service_categories(id),
  name                     text NOT NULL,
  description              text,
  default_duration_minutes int NOT NULL CHECK (default_duration_minutes > 0),
  default_price            numeric(12,3) NOT NULL CHECK (default_price >= 0),
  color                    text,
  is_active                boolean NOT NULL DEFAULT true,
  created_at               timestamptz NOT NULL DEFAULT now(),
  updated_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_services_tenant ON public.services(tenant_id);
CREATE INDEX idx_services_category ON public.services(category_id);

CREATE TRIGGER set_updated_at_services
  BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- BRANCH_SERVICES
-- ============================================================================
CREATE TABLE public.branch_services (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id                uuid NOT NULL REFERENCES public.tenants(id),
  branch_id                uuid NOT NULL REFERENCES public.branches(id),
  service_id               uuid NOT NULL REFERENCES public.services(id),
  price_override           numeric(12,3),  -- NULL = use service.default_price
  duration_override_minutes int,           -- NULL = use service.default_duration_minutes
  is_available             boolean NOT NULL DEFAULT true,
  created_at               timestamptz NOT NULL DEFAULT now(),
  updated_at               timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, service_id)
);

CREATE INDEX idx_bs_tenant ON public.branch_services(tenant_id);
CREATE INDEX idx_bs_branch ON public.branch_services(branch_id);
CREATE INDEX idx_bs_service ON public.branch_services(service_id);

CREATE TRIGGER set_updated_at_branch_services
  BEFORE UPDATE ON public.branch_services
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();