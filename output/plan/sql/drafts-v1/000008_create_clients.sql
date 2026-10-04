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

-- Create clients and client_notes tables

-- ============================================================================
-- CLIENTS
-- ============================================================================
CREATE TABLE public.clients (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL REFERENCES public.tenants(id),
  first_name         text NOT NULL,
  last_name          text,
  email              text,
  phone              text,
  phone_country_code text DEFAULT '+965',
  birthday           date,
  gender             text CHECK (gender IN ('female', 'male', 'non_binary', 'prefer_not_to_say')),
  pronouns           text,
  source             text DEFAULT 'walk_in',
  referred_by        text,
  preferred_locale   text DEFAULT 'en',
  occupation         text,
  country            text,
  tags               jsonb DEFAULT '[]',
  is_blocked         boolean NOT NULL DEFAULT false,
  is_deleted         boolean NOT NULL DEFAULT false,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  created_by         uuid REFERENCES auth.users(id),
  updated_by         uuid REFERENCES auth.users(id)
);

-- Partial unique indexes: only enforce uniqueness among non-deleted clients
CREATE UNIQUE INDEX idx_clients_tenant_email_unique
  ON public.clients(tenant_id, email)
  WHERE email IS NOT NULL AND is_deleted = false;

CREATE UNIQUE INDEX idx_clients_tenant_phone_unique
  ON public.clients(tenant_id, phone)
  WHERE phone IS NOT NULL AND is_deleted = false;

CREATE INDEX idx_clients_tenant ON public.clients(tenant_id);
CREATE INDEX idx_clients_name ON public.clients(tenant_id, first_name, last_name);
CREATE INDEX idx_clients_created ON public.clients(tenant_id, created_at DESC);

CREATE TRIGGER set_updated_at_clients
  BEFORE UPDATE ON public.clients
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- CLIENT_NOTES
-- ============================================================================
CREATE TABLE public.client_notes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  client_id   uuid NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  content     text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  uuid REFERENCES auth.users(id)
);

CREATE INDEX idx_cn_tenant ON public.client_notes(tenant_id);
CREATE INDEX idx_cn_client ON public.client_notes(client_id);