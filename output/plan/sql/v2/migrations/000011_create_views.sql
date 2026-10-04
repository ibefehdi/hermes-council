-- ADRs implemented: ADR-5 (seven MVP reports), ADR-11 (financials branch-scoped,
--   client aggregates via secured RPC), ADR-21 (WITH (security_invoker = true),
--   explicit GRANT SELECT for authenticated), ADR-45 (branch-local date grouping)
--
-- Every view is created WITH (security_invoker = true) so the invoker's RLS
-- (tenant + branch scope, ADR-20) filters the rows. Views that need cross-branch
-- visibility use SECURITY DEFINER RPCs instead.

-- ============================================================================
-- REPORT: Daily Sales Summary (US-RPT-1)
-- ============================================================================
create or replace view public.report_daily_sales
with (security_invoker = true)
as
select
  s.tenant_id,
  s.branch_id,
  (s.created_at at time zone coalesce(b.timezone, 'Asia/Kuwait'))::date as local_date,
  count(*) as sale_count,
  coalesce(sum(s.total_minor), 0) as total_sales_minor,
  coalesce(sum(s.discount_minor), 0) as total_discounts_minor,
  coalesce(sum(s.tax_minor), 0) as total_tax_minor,
  coalesce(sum(s.tip_minor), 0) as total_tips_minor,
  coalesce(sum(p.amount_minor) filter (where p.payment_type = 'payment'), 0) as total_payments_minor,
  coalesce(sum(p.amount_minor) filter (where p.payment_type = 'refund'), 0) as total_refunds_minor,
  count(*) filter (where s.status = 'voided') as voided_count
from public.sales s
left join public.branches b on b.id = s.branch_id
left join public.payments p on p.sale_id = s.id
group by s.tenant_id, s.branch_id, local_date;

-- ============================================================================
-- REPORT: Payment Transactions (US-RPT-2)
-- ============================================================================
create or replace view public.report_payment_transactions
with (security_invoker = true)
as
select
  p.tenant_id,
  p.branch_id,
  (p.created_at at time zone coalesce(b.timezone, 'Asia/Kuwait'))::date as local_date,
  p.payment_type,
  p.payment_method,
  count(*) as transaction_count,
  coalesce(sum(p.amount_minor), 0) as total_amount_minor
from public.payments p
left join public.branches b on b.id = p.branch_id
group by p.tenant_id, p.branch_id, local_date, p.payment_type, p.payment_method;

-- ============================================================================
-- REPORT: Appointments Summary (US-RPT-3)
-- ============================================================================
create or replace view public.report_appointments_summary
with (security_invoker = true)
as
select
  a.tenant_id,
  a.branch_id,
  (a.scheduled_start at time zone coalesce(b.timezone, 'Asia/Kuwait'))::date as local_date,
  a.status,
  count(*) as appointment_count,
  count(distinct a.client_id) as unique_clients,
  count(distinct ai.staff_id) as staff_involved,
  coalesce(sum(ai.price_minor), 0) as total_value_minor
from public.appointments a
left join public.branches b on b.id = a.branch_id
left join public.appointment_items ai on ai.appointment_id = a.id
group by a.tenant_id, a.branch_id, local_date, a.status;

-- ============================================================================
-- REPORT: Appointments List (US-RPT-3 detail)
-- ============================================================================
create or replace view public.report_appointments_list
with (security_invoker = true)
as
select
  a.id,
  a.tenant_id,
  a.branch_id,
  a.client_id,
  a.ref_number,
  a.scheduled_start,
  a.scheduled_end,
  a.status,
  a.channel,
  a.notes,
  a.created_at
from public.appointments a;

-- ============================================================================
-- REPORT: Sales List (US-RPT-1 detail)
-- ============================================================================
create or replace view public.report_sales_list
with (security_invoker = true)
as
select
  s.id,
  s.tenant_id,
  s.branch_id,
  s.client_id,
  s.appointment_id,
  s.invoice_seq,
  s.subtotal_minor,
  s.discount_minor,
  s.tax_minor,
  s.tip_minor,
  s.total_minor,
  s.status,
  s.created_at
from public.sales s;

-- ============================================================================
-- REPORT: Client Summary (US-RPT-4)
--   Uses a subquery to avoid join-inflated counts (F-DB-8).
-- ============================================================================
create or replace view public.report_client_summary
with (security_invoker = true)
as
with client_sales as (
  select
    c.id as client_id,
    c.tenant_id,
    count(distinct s.id) as sale_count,
    coalesce(sum(s.total_minor), 0) as total_spend_minor,
    max(s.created_at) as last_visit
  from public.clients c
  left join public.sales s on s.client_id = c.id
  group by c.id, c.tenant_id
)
select
  c.tenant_id,
  count(distinct c.id) as total_clients,
  count(distinct c.id) filter (where not c.is_deleted) as active_clients,
  count(distinct c.id) filter (
    where date_trunc('month', c.created_at) = date_trunc('month', now())
      and not c.is_deleted
  ) as new_this_month,
  coalesce(sum(cs.sale_count), 0) as total_sales_count,
  coalesce(sum(cs.total_spend_minor), 0) as total_spend_minor
from public.clients c
left join client_sales cs on cs.client_id = c.id
group by c.tenant_id;

-- ============================================================================
-- REPORT: Top Services (US-RPT-5)
--   F-DB-8 fix: join through sale_items.item_id where item_type = 'service'
-- ============================================================================
create or replace view public.report_top_services
with (security_invoker = true)
as
select
  si.tenant_id,
  si.item_id as service_id,
  count(*) as sale_count,
  coalesce(sum(si.line_total_minor), 0) as total_revenue_minor,
  coalesce(sum(si.quantity), 0) as total_quantity
from public.sale_items si
where si.item_type = 'service'
group by si.tenant_id, si.item_id
order by total_revenue_minor desc;

-- ============================================================================
-- REPORT: Tax Summary (US-RPT-7, F-cov-3: taxes by rate, by period)
-- ============================================================================
create or replace view public.report_tax_summary
with (security_invoker = true)
as
select
  s.tenant_id,
  s.branch_id,
  (s.created_at at time zone coalesce(b.timezone, 'Asia/Kuwait'))::date as local_date,
  si.tax_rate_bp,
  count(distinct s.id) as sale_count,
  coalesce(sum(si.tax_minor), 0) as collected_tax_minor,
  coalesce(sum(p.amount_minor) filter (where p.payment_type = 'refund'), 0) as refunded_tax_minor
from public.sales s
left join public.branches b on b.id = s.branch_id
left join public.sale_items si on si.sale_id = s.id
left join public.payments p on p.sale_id = s.id
group by s.tenant_id, s.branch_id, local_date, si.tax_rate_bp;

-- ============================================================================
-- REPORT: Staff Performance (US-RPT-6)
--   Exposed as SECURITY DEFINER RPC for staff-own-lines visibility (F-DB-5)
-- ============================================================================
create or replace function public.report_staff_performance(
  p_tenant_id uuid,
  p_branch_id uuid,
  p_from_date date,
  p_to_date   date
)
returns table (
  staff_id            uuid,
  full_name_en        text,
  appointment_count   bigint,
  completed_count     bigint,
  total_service_value_minor bigint,
  total_tips_minor    bigint,
  total_product_sales_minor bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    sm.id as staff_id,
    sm.full_name_en,
    count(distinct ai.id) filter (where a.status not in ('cancelled', 'no_show')) as appointment_count,
    count(distinct ai.id) filter (where a.status = 'completed') as completed_count,
    coalesce(sum(ai.price_minor) filter (where a.status not in ('cancelled', 'no_show')), 0) as total_service_value_minor,
    coalesce(sum(t.amount_minor), 0) as total_tips_minor,
    0::bigint as total_product_sales_minor
  from public.staff_members sm
  join public.staff_branch_assignments sba on sba.staff_id = sm.id and sba.branch_id = p_branch_id
  left join public.appointment_items ai on ai.staff_id = sm.id
  left join public.appointments a on a.id = ai.appointment_id
    and a.branch_id = p_branch_id
    and (a.scheduled_start at time zone coalesce(
      (select b2.timezone from public.branches b2 where b2.id = p_branch_id),
      'Asia/Kuwait'
    ))::date between p_from_date and p_to_date
  left join public.tips t on t.staff_id = sm.id
    and (t.created_at at time zone coalesce(
      (select b3.timezone from public.branches b3 where b3.id = p_branch_id),
      'Asia/Kuwait'
    ))::date between p_from_date and p_to_date
  where sm.tenant_id = p_tenant_id
  group by sm.id, sm.full_name_en;
$$;

-- ============================================================================
-- VIEW GRANTS (ADR-21, F-6: authenticated must hold SELECT on views)
-- ============================================================================
grant select on public.report_daily_sales to authenticated;
grant select on public.report_payment_transactions to authenticated;
grant select on public.report_appointments_summary to authenticated;
grant select on public.report_appointments_list to authenticated;
grant select on public.report_sales_list to authenticated;
grant select on public.report_client_summary to authenticated;
grant select on public.report_top_services to authenticated;
grant select on public.report_tax_summary to authenticated;

-- RPC grants
grant execute on function public.report_staff_performance(uuid, uuid, date, date) to authenticated;