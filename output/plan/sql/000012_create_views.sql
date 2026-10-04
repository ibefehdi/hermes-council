-- Create report views for MVP

-- ============================================================================
-- REPORT: DAILY SALES
-- ============================================================================
CREATE OR REPLACE VIEW public.report_daily_sales AS
SELECT
  s.tenant_id,
  s.branch_id,
  s.sale_date::date AS sale_day,
  count(*) AS sales_count,
  coalesce(sum(s.gross_total), 0) AS gross_total,
  coalesce(sum(s.amount_paid), 0) AS amount_collected,
  coalesce(sum(s.tip_total), 0) AS tips_total,
  coalesce(sum(s.discount_total), 0) AS discounts_total,
  coalesce(sum(s.tax_total), 0) AS taxes_total
FROM public.sales s
WHERE s.status NOT IN ('voided')
GROUP BY s.tenant_id, s.branch_id, s.sale_date::date;

-- ============================================================================
-- REPORT: PAYMENT TRANSACTIONS
-- ============================================================================
CREATE OR REPLACE VIEW public.report_payment_transactions AS
SELECT
  p.tenant_id,
  p.branch_id,
  p.payment_date,
  p.ref_number,
  p.payment_type,
  p.payment_method,
  p.amount,
  s.sale_number,
  c.first_name AS client_first_name,
  c.last_name AS client_last_name,
  prof.full_name AS received_by_name
FROM public.payments p
JOIN public.sales s ON s.id = p.sale_id
LEFT JOIN public.clients c ON c.id = s.client_id
LEFT JOIN public.profiles prof ON prof.id = p.received_by;

-- ============================================================================
-- REPORT: APPOINTMENTS LIST
-- ============================================================================
CREATE OR REPLACE VIEW public.report_appointments_list AS
SELECT
  a.tenant_id,
  a.branch_id,
  a.ref_number,
  a.scheduled_start,
  a.scheduled_end,
  a.duration_minutes,
  a.status,
  a.total_price,
  a.channel,
  a.created_at,
  c.first_name AS client_first_name,
  c.last_name AS client_last_name,
  prof.full_name AS created_by_name,
  -- Aggregated from appointment_items
  (SELECT string_agg(s.name, ', ' ORDER BY ai.display_order)
   FROM public.appointment_items ai
   JOIN public.services s ON s.id = ai.service_id
   WHERE ai.appointment_id = a.id) AS services,
  (SELECT string_agg(st.initials, ', ' ORDER BY ai.display_order)
   FROM public.appointment_items ai
   JOIN public.staff st ON st.id = ai.staff_id
   WHERE ai.appointment_id = a.id) AS staff_initials
FROM public.appointments a
LEFT JOIN public.clients c ON c.id = a.client_id
LEFT JOIN public.profiles prof ON prof.id = a.created_by;

-- ============================================================================
-- REPORT: SALES LIST
-- ============================================================================
CREATE OR REPLACE VIEW public.report_sales_list AS
SELECT
  s.tenant_id,
  s.branch_id,
  s.sale_number,
  s.status,
  s.sale_date,
  s.subtotal,
  s.discount_total,
  s.tax_total,
  s.tip_total,
  s.gross_total,
  s.amount_paid,
  s.amount_due,
  s.source_type,
  c.first_name AS client_first_name,
  c.last_name AS client_last_name,
  prof.full_name AS created_by_name
FROM public.sales s
LEFT JOIN public.clients c ON c.id = s.client_id
LEFT JOIN public.profiles prof ON prof.id = s.created_by;

-- ============================================================================
-- REPORT: APPOINTMENT SUMMARY
-- ============================================================================
CREATE OR REPLACE VIEW public.report_appointment_summary AS
SELECT
  tenant_id,
  branch_id,
  date_trunc('day', scheduled_start)::date AS appointment_day,
  status,
  count(*) AS count,
  coalesce(sum(total_price), 0) AS total_value
FROM public.appointments
GROUP BY tenant_id, branch_id, date_trunc('day', scheduled_start)::date, status;

-- ============================================================================
-- REPORT: TOP SERVICES
-- ============================================================================
CREATE OR REPLACE VIEW public.report_top_services AS
SELECT
  si.tenant_id,
  si.service_id,
  s.name AS service_name,
  sc.name AS category_name,
  count(*) AS booking_count,
  coalesce(sum(si.total_price), 0) AS total_revenue
FROM public.sale_items si
JOIN public.services s ON s.id = si.service_id
JOIN public.service_categories sc ON sc.id = s.category_id
WHERE si.item_type = 'service'
GROUP BY si.tenant_id, si.service_id, s.name, sc.name;

-- ============================================================================
-- REPORT: CLIENT SUMMARY
-- ============================================================================
CREATE OR REPLACE VIEW public.report_client_summary AS
SELECT
  c.tenant_id,
  count(*) FILTER (WHERE c.is_deleted = false) AS total_clients,
  count(*) FILTER (WHERE c.is_deleted = false AND c.created_at >= date_trunc('month', now())) AS new_this_month,
  count(DISTINCT s.client_id) FILTER (WHERE s.sale_date >= date_trunc('month', now())) AS active_this_month
FROM public.clients c
LEFT JOIN public.sales s ON s.client_id = c.id AND s.status NOT IN ('voided')
GROUP BY c.tenant_id;