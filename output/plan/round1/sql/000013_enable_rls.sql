-- Enable RLS on every table and create policies
-- Pattern: tenant isolation via get_user_tenant_ids() helper

-- ============================================================================
-- TENANTS
-- ============================================================================
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenants_select" ON public.tenants
  FOR SELECT TO authenticated
  USING (id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "tenants_insert" ON public.tenants
  FOR INSERT TO authenticated
  WITH CHECK (true);  -- platform_admin creates tenants; RLS checked via Edge Function

CREATE POLICY "tenants_update" ON public.tenants
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(id, 'tenant_owner', 'platform_admin'))
  WITH CHECK (public.has_tenant_role(id, 'tenant_owner', 'platform_admin'));

-- ============================================================================
-- PROFILES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT TO authenticated
  USING (true);  -- all authenticated users can see basic profiles

CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- ============================================================================
-- BRANCHES
-- ============================================================================
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branches_select" ON public.branches
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "branches_insert" ON public.branches
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "branches_update" ON public.branches
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- BRANCH_HOURS
-- ============================================================================
ALTER TABLE public.branch_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branch_hours_select" ON public.branch_hours
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "branch_hours_insert" ON public.branch_hours
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "branch_hours_update" ON public.branch_hours
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "branch_hours_delete" ON public.branch_hours
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- MEMBERSHIPS
-- ============================================================================
ALTER TABLE public.memberships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "memberships_select" ON public.memberships
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "memberships_insert" ON public.memberships
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "memberships_update" ON public.memberships
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'platform_admin'));

CREATE POLICY "memberships_delete" ON public.memberships
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'platform_admin'));

-- ============================================================================
-- STAFF
-- ============================================================================
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff_select" ON public.staff
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "staff_insert" ON public.staff
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "staff_update" ON public.staff
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- STAFF_BRANCH_ASSIGNMENTS
-- ============================================================================
ALTER TABLE public.staff_branch_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sba_select" ON public.staff_branch_assignments
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sba_insert" ON public.staff_branch_assignments
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "sba_delete" ON public.staff_branch_assignments
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- STAFF_WORKING_HOURS
-- ============================================================================
ALTER TABLE public.staff_working_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "swh_select" ON public.staff_working_hours
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "swh_insert" ON public.staff_working_hours
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "swh_update" ON public.staff_working_hours
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "swh_delete" ON public.staff_working_hours
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- STAFF_TIME_OFF
-- ============================================================================
ALTER TABLE public.staff_time_off ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sto_select" ON public.staff_time_off
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sto_insert" ON public.staff_time_off
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sto_update" ON public.staff_time_off
  FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()))
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sto_delete" ON public.staff_time_off
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- SERVICE_CATEGORIES
-- ============================================================================
ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sc_select" ON public.service_categories
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sc_insert" ON public.service_categories
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "sc_update" ON public.service_categories
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "sc_delete" ON public.service_categories
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- SERVICES
-- ============================================================================
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "services_select" ON public.services
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "services_insert" ON public.services
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "services_update" ON public.services
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- BRANCH_SERVICES
-- ============================================================================
ALTER TABLE public.branch_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bs_select" ON public.branch_services
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "bs_insert" ON public.branch_services
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "bs_update" ON public.branch_services
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "bs_delete" ON public.branch_services
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- RESOURCES
-- ============================================================================
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "resources_select" ON public.resources
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "resources_insert" ON public.resources
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "resources_update" ON public.resources
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- CLIENTS
-- ============================================================================
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clients_select" ON public.clients
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "clients_insert" ON public.clients
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "clients_update" ON public.clients
  FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()))
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "clients_delete" ON public.clients
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- CLIENT_NOTES
-- ============================================================================
ALTER TABLE public.client_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cn_select" ON public.client_notes
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "cn_insert" ON public.client_notes
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- APPOINTMENTS
-- ============================================================================
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "appointments_select" ON public.appointments
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "appointments_insert" ON public.appointments
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "appointments_update" ON public.appointments
  FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()))
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- APPOINTMENT_ITEMS
-- ============================================================================
ALTER TABLE public.appointment_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_select" ON public.appointment_items
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "ai_insert" ON public.appointment_items
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "ai_update" ON public.appointment_items
  FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()))
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "ai_delete" ON public.appointment_items
  FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- SALES
-- ============================================================================
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sales_select" ON public.sales
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sales_insert" ON public.sales
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "sales_update" ON public.sales
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'))
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- SALE_ITEMS
-- ============================================================================
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "si_select" ON public.sale_items
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "si_insert" ON public.sale_items
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- PAYMENTS
-- ============================================================================
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payments_select" ON public.payments
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "payments_insert" ON public.payments
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- REFUNDS
-- ============================================================================
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "refunds_select" ON public.refunds
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "refunds_insert" ON public.refunds
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- INVOICE_SEQUENCES
-- ============================================================================
ALTER TABLE public.invoice_sequences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "is_select" ON public.invoice_sequences
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- CANCELLATION_REASONS
-- ============================================================================
ALTER TABLE public.cancellation_reasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cr_select" ON public.cancellation_reasons
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "cr_insert" ON public.cancellation_reasons
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "cr_update" ON public.cancellation_reasons
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "cr_delete" ON public.cancellation_reasons
  FOR DELETE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- SETTINGS
-- ============================================================================
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "settings_select" ON public.settings
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

CREATE POLICY "settings_insert" ON public.settings
  FOR INSERT TO authenticated
  WITH CHECK (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

CREATE POLICY "settings_update" ON public.settings
  FOR UPDATE TO authenticated
  USING (public.has_tenant_role(tenant_id, 'tenant_owner', 'branch_manager'));

-- ============================================================================
-- AUDIT_LOG
-- ============================================================================
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_log_select" ON public.audit_log
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- NOTE: audit_log is insert-only for the application; no update/delete policies
CREATE POLICY "audit_log_insert" ON public.audit_log
  FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT public.get_user_tenant_ids()));

-- ============================================================================
-- REPORT VIEWS (RLS)
-- ============================================================================
-- Views inherit RLS from their underlying tables via the tenant_id column.
-- No additional policies needed; the USING clause on base tables handles it.

-- Grant authenticated users access to report views
GRANT SELECT ON public.report_daily_sales TO authenticated;
GRANT SELECT ON public.report_payment_transactions TO authenticated;
GRANT SELECT ON public.report_appointments_list TO authenticated;
GRANT SELECT ON public.report_sales_list TO authenticated;
GRANT SELECT ON public.report_appointment_summary TO authenticated;
GRANT SELECT ON public.report_top_services TO authenticated;
GRANT SELECT ON public.report_client_summary TO authenticated;