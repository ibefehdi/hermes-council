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

-- Create sales, sale_items, payments, refunds, and invoice_sequences

-- ============================================================================
-- INVOICE_SEQUENCES
-- ============================================================================
CREATE TABLE public.invoice_sequences (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES public.tenants(id),
  branch_id   uuid NOT NULL REFERENCES public.branches(id),
  prefix      text DEFAULT '',
  next_number int NOT NULL DEFAULT 1,
  UNIQUE (branch_id)
);

CREATE INDEX idx_is_tenant ON public.invoice_sequences(tenant_id);

-- ============================================================================
-- SALES
-- ============================================================================
CREATE TABLE public.sales (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid NOT NULL REFERENCES public.tenants(id),
  branch_id           uuid NOT NULL REFERENCES public.branches(id),
  client_id           uuid REFERENCES public.clients(id),
  sale_number         text NOT NULL,
  status              text NOT NULL DEFAULT 'completed'
                      CHECK (status IN ('unpaid', 'part_paid', 'completed', 'voided', 'refunded')),
  subtotal            numeric(12,3) NOT NULL CHECK (subtotal >= 0),
  discount_total      numeric(12,3) NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
  tax_total           numeric(12,3) NOT NULL DEFAULT 0 CHECK (tax_total >= 0),
  tip_total           numeric(12,3) NOT NULL DEFAULT 0 CHECK (tip_total >= 0),
  service_charge_total numeric(12,3) NOT NULL DEFAULT 0 CHECK (service_charge_total >= 0),
  gross_total         numeric(12,3) NOT NULL CHECK (gross_total >= 0),
  amount_paid         numeric(12,3) NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
  amount_due          numeric(12,3) GENERATED ALWAYS AS (gross_total - amount_paid) STORED,
  sale_date           timestamptz NOT NULL DEFAULT now(),
  source_type         text DEFAULT 'checkout' CHECK (source_type IN ('checkout', 'quick_sale', 'pos')),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES auth.users(id),
  updated_by          uuid REFERENCES auth.users(id)
);

CREATE INDEX idx_sales_tenant ON public.sales(tenant_id);
CREATE INDEX idx_sales_branch ON public.sales(branch_id);
CREATE INDEX idx_sales_client ON public.sales(client_id);
CREATE INDEX idx_sales_date ON public.sales(tenant_id, sale_date DESC);
CREATE UNIQUE INDEX idx_sales_number ON public.sales(tenant_id, sale_number);

CREATE TRIGGER set_updated_at_sales
  BEFORE UPDATE ON public.sales
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- SALE_ITEMS
-- ============================================================================
CREATE TABLE public.sale_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL REFERENCES public.tenants(id),
  sale_id          uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  item_type        text NOT NULL CHECK (item_type IN ('service', 'product', 'package', 'gift_card')),
  item_id          uuid,
  description      text NOT NULL,
  staff_id         uuid REFERENCES public.staff(id),
  quantity         int NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price       numeric(12,3) NOT NULL CHECK (unit_price >= 0),
  total_price      numeric(12,3) NOT NULL CHECK (total_price >= 0),
  discount_amount  numeric(12,3) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  tax_amount       numeric(12,3) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  appointment_id   uuid REFERENCES public.appointments(id),
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_si_sale ON public.sale_items(sale_id);
CREATE INDEX idx_si_tenant ON public.sale_items(tenant_id);
CREATE INDEX idx_si_appointment ON public.sale_items(appointment_id);
CREATE INDEX idx_si_type ON public.sale_items(tenant_id, item_type);

-- ============================================================================
-- PAYMENTS
-- ============================================================================
CREATE TABLE public.payments (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       uuid NOT NULL REFERENCES public.tenants(id),
  branch_id       uuid NOT NULL REFERENCES public.branches(id),
  sale_id         uuid NOT NULL REFERENCES public.sales(id),
  client_id       uuid REFERENCES public.clients(id),
  payment_type    text NOT NULL CHECK (payment_type IN ('sale', 'refund', 'prepayment')),
  payment_method  text NOT NULL CHECK (payment_method IN ('cash', 'other')),
  amount          numeric(12,3) NOT NULL CHECK (amount > 0),
  ref_number      text NOT NULL,
  payment_date    timestamptz NOT NULL DEFAULT now(),
  received_by     uuid REFERENCES auth.users(id),
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_tenant ON public.payments(tenant_id);
CREATE INDEX idx_payments_sale ON public.payments(sale_id);
CREATE INDEX idx_payments_date ON public.payments(tenant_id, payment_date DESC);
CREATE INDEX idx_payments_method ON public.payments(tenant_id, payment_method, payment_date);

-- ============================================================================
-- REFUNDS
-- ============================================================================
CREATE TABLE public.refunds (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL REFERENCES public.tenants(id),
  branch_id    uuid NOT NULL REFERENCES public.branches(id),
  sale_id      uuid NOT NULL REFERENCES public.sales(id),
  payment_id   uuid NOT NULL REFERENCES public.payments(id),
  amount       numeric(12,3) NOT NULL CHECK (amount > 0),
  reason       text,
  refund_date  timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES auth.users(id)
);

CREATE INDEX idx_refunds_tenant ON public.refunds(tenant_id);
CREATE INDEX idx_refunds_sale ON public.refunds(sale_id);