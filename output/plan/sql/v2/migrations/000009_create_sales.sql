-- ADRs implemented: ADR-2 (manual_item in sale_items.item_type),
--   ADR-6 (register_sessions), ADR-7 (sale status: unpaid, part_paid, completed, voided),
--   ADR-10 (refunds owner/manager only), ADR-14 (invoice_counters per branch),
--   ADR-15 (glossary names), ADR-17 (money _minor bigint),
--   ADR-20 rule 5 (composite FKs), ADR-31 (idempotency_keys),
--   ADR-34 (payment_type = payment|refund, positive amounts, refund cap trigger),
--   ADR-44 (uuid PKs), ADR-46 (status-based retention)

-- ============================================================================
-- INVOICE_COUNTERS (ADR-14: per-branch, gap-tolerant, row-locked UPDATE...RETURNING)
-- ============================================================================
create table public.invoice_counters (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  branch_id   uuid not null,
  kind        text not null default 'invoice' check (kind in ('invoice', 'appointment_ref')),
  counter     int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- ADR-20 rule 5: composite FK
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id),
  unique (branch_id, kind)
);

create index idx_ic_branch on public.invoice_counters(branch_id);

create trigger set_updated_at_invoice_counters
  before update on public.invoice_counters
  for each row execute function public.set_updated_at();

-- ============================================================================
-- TAX_RATES
-- ============================================================================
create table public.tax_rates (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  name_en     text not null,
  name_ar     text,
  rate_bp     int not null check (rate_bp >= 0),          -- basis points (500=5%)
  is_default  boolean not null default false,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_tr_tenant on public.tax_rates(tenant_id);

create trigger set_updated_at_tax_rates
  before update on public.tax_rates
  for each row execute function public.set_updated_at();

-- ============================================================================
-- REGISTER_SESSIONS (ADR-6)
-- ============================================================================
create table public.register_sessions (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  branch_id       uuid not null,
  opened_at       timestamptz not null default now(),
  closed_at       timestamptz,
  opening_cash_minor   bigint not null default 0 check (opening_cash_minor >= 0),
  closing_cash_minor   bigint check (closing_cash_minor >= 0),
  expected_cash_minor  bigint,
  difference_minor     bigint,
  notes           text,
  opened_by       uuid,
  closed_by       uuid,
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)
);

create index idx_rs_branch on public.register_sessions(branch_id);
create unique index idx_rs_one_open on public.register_sessions(branch_id) where closed_at is null;

-- ============================================================================
-- SALES
-- ============================================================================
create table public.sales (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  branch_id       uuid not null,
  client_id       uuid,
  appointment_id  uuid references public.appointments(id),
  invoice_seq     int,                                            -- ADR-14: assigned by checkout RPC
  subtotal_minor  bigint not null default 0 check (subtotal_minor >= 0),   -- ADR-17
  discount_minor  bigint not null default 0 check (discount_minor >= 0),
  tax_minor       bigint not null default 0 check (tax_minor >= 0),
  tip_minor       bigint not null default 0 check (tip_minor >= 0),
  total_minor     bigint not null default 0 check (total_minor >= 0),      -- ADR-17
  -- ADR-7: sale status enum
  status          text not null default 'unpaid'
                  check (status in ('unpaid', 'part_paid', 'completed', 'voided')),
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id),
  updated_by      uuid references auth.users(id),
  -- ADR-20 rule 5: composite FKs
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id),
  foreign key (client_id, tenant_id) references public.clients(id, tenant_id),
  -- ADR-14: per-branch unique invoice_seq
  unique (branch_id, invoice_seq),
  unique (id, tenant_id)
);

create index idx_sales_tenant on public.sales(tenant_id);
create index idx_sales_branch on public.sales(branch_id);
create index idx_sales_client on public.sales(client_id);
create index idx_sales_appointment on public.sales(appointment_id);
create index idx_sales_status on public.sales(tenant_id, branch_id, status);
create index idx_sales_date on public.sales(branch_id, created_at);

create trigger set_updated_at_sales
  before update on public.sales
  for each row execute function public.set_updated_at();

-- ============================================================================
-- SALE_ITEMS (ADR-2: item_type includes manual_item for MVP)
-- ============================================================================
create table public.sale_items (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  sale_id         uuid not null references public.sales(id) on delete cascade,
  -- ADR-2: item_type = service | manual_item in MVP; product/package/gift_card later
  item_type       text not null check (item_type in ('service', 'manual_item')),
  item_id         uuid,                                            -- FK to services when item_type = 'service'
  staff_id        uuid,
  appointment_id  uuid references public.appointments(id),
  name_en         text,                                            -- snapshotted name
  name_ar         text,
  quantity        int not null default 1 check (quantity > 0),
  unit_price_minor bigint not null check (unit_price_minor >= 0),  -- ADR-17
  discount_minor  bigint not null default 0 check (discount_minor >= 0),
  tax_rate_bp     int not null default 0 check (tax_rate_bp >= 0),
  tax_minor       bigint not null default 0 check (tax_minor >= 0),
  line_total_minor bigint not null check (line_total_minor >= 0),   -- ADR-17
  created_at      timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (item_id, tenant_id) references public.services(id, tenant_id),
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id),
  foreign key (appointment_id, tenant_id) references public.appointments(id, tenant_id)
);

create index idx_si_sale on public.sale_items(sale_id);
create index idx_si_staff on public.sale_items(staff_id);
create index idx_si_appointment on public.sale_items(appointment_id);
create index idx_si_item on public.sale_items(item_id, item_type);

-- ============================================================================
-- TIPS (ADR-10: receptionist-gated, staff-scoped)
-- ============================================================================
create table public.tips (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  sale_id         uuid not null references public.sales(id) on delete cascade,
  staff_id        uuid not null,
  amount_minor    bigint not null check (amount_minor > 0),         -- ADR-17
  created_at      timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (sale_id, tenant_id) references public.sales(id, tenant_id),
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id)
);

create index idx_tips_sale on public.tips(sale_id);
create index idx_tips_staff on public.tips(staff_id);

-- ============================================================================
-- PAYMENTS (ADR-34: single ledger, payment_type = payment|refund)
-- ============================================================================
create table public.payments (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references public.tenants(id),
  branch_id             uuid not null,
  sale_id               uuid not null references public.sales(id),
  client_id             uuid,
  register_session_id   uuid references public.register_sessions(id),  -- ADR-6
  -- ADR-34: payment_type = payment | refund (positive amounts only)
  payment_type          text not null check (payment_type in ('payment', 'refund')),
  payment_method        text not null check (payment_method in ('cash', 'card_terminal', 'knet_terminal', 'bank_transfer', 'other')),
  amount_minor          bigint not null check (amount_minor >= 0),     -- ADR-17: always positive
  refunds_payment_id    uuid references public.payments(id),           -- ADR-34: refund references original
  reason                text,                                          -- required for refunds
  created_at            timestamptz not null default now(),
  created_by            uuid references auth.users(id),
  -- ADR-20 rule 5: composite FKs
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id),
  foreign key (sale_id, tenant_id) references public.sales(id, tenant_id),
  foreign key (client_id, tenant_id) references public.clients(id, tenant_id),
  foreign key (refunds_payment_id, tenant_id) references public.payments(id, tenant_id),
  unique (id, tenant_id)
);

create index idx_payments_sale on public.payments(sale_id);
create index idx_payments_branch on public.payments(branch_id);
create index idx_payments_tenant on public.payments(tenant_id);
create index idx_payments_register on public.payments(register_session_id);
create index idx_payments_date on public.payments(branch_id, created_at);
create index idx_payments_refund on public.payments(refunds_payment_id);

-- ============================================================================
-- REFUND_CAP TRIGGER (ADR-34: sum(refunds) ≤ original payment amount)
--   ADR-20 rule 10: SECURITY DEFINER with search_path
-- ============================================================================
create or replace function public.check_refund_cap()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_original_amount  bigint;
  v_total_refunded   bigint;
begin
  if new.payment_type = 'refund' and new.refunds_payment_id is not null then
    select p.amount_minor into v_original_amount
    from public.payments p
    where p.id = new.refunds_payment_id;

    select coalesce(sum(r.amount_minor), 0) into v_total_refunded
    from public.payments r
    where r.refunds_payment_id = new.refunds_payment_id
      and r.id != coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and r.payment_type = 'refund';

    if (v_total_refunded + new.amount_minor) > v_original_amount then
      raise exception 'Total refunds (%, + new %,) exceed original payment amount (%)',
        v_total_refunded, new.amount_minor, v_original_amount
        using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_check_refund_cap
  before insert or update on public.payments
  for each row execute function public.check_refund_cap();

-- ============================================================================
-- IDEMPOTENCY_KEYS (ADR-31: UUID key, tenant-scoped, 30-day retention)
-- ============================================================================
create table public.idempotency_keys (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  key             text not null,
  function_name   text not null,
  status          text not null default 'processing'
                  check (status in ('processing', 'completed', 'failed')),
  response_status smallint,
  response_body   text,
  created_at      timestamptz not null default now(),
  unique (tenant_id, key)
);

create index idx_ik_key on public.idempotency_keys(tenant_id, key);
create index idx_ik_created on public.idempotency_keys(created_at);