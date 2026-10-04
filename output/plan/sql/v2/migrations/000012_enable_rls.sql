-- ADRs implemented: ADR-10 (refunds manager-only), ADR-11 (client visibility,
--   staff read-only), ADR-19 (live membership lookup via helpers),
--   ADR-20 rules 1-10 (branch-scoped RLS, composite FKs, role checks,
--   all-branches, no platform_admin, search_path),
--   ADR-21 (security_invoker views + grants), ADR-22 (audit_log: no direct writes),
--   ADR-28 (direct-write allowlist), ADR-34 (payments: no direct writes)
--
-- Pattern for every table:
--   SELECT: tenant membership required, branch-scoped where applicable
--   INSERT/UPDATE/DELETE: only for allowlist tables; otherwise no policy (fail-closed)
--   Service-role bypasses RLS; privileges derived and verified live (ADR-20 rule 7)

-- ========================================================================
-- MACRO: tenant-scoped SELECT policy
-- ========================================================================
-- Used for: tenants, currencies, plan_features, blocked_time_types,
--   tax_rates, cancellation_reasons, idempotency_keys

-- ========================================================================
-- TENANTS
-- ========================================================================
alter table public.tenants enable row level security;

create policy tenants_select on public.tenants
  for select to authenticated
  using (id in (select public.current_tenant_ids()));

-- ADR-20 rule 3: no insert/update/delete for authenticated
-- Tenant creation: onboarding Edge Function under service role

-- ========================================================================
-- CURRENCIES (reference data, global read)
-- ========================================================================
alter table public.currencies enable row level security;

create policy currencies_select on public.currencies
  for select to authenticated
  using (true);

-- ========================================================================
-- PLAN_FEATURES
-- ========================================================================
alter table public.plan_features enable row level security;

create policy plan_features_select on public.plan_features
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- PROFILES (ADR-20 rule 2: self-read/write, narrow colleague visibility)
-- ========================================================================
alter table public.profiles enable row level security;

create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid());

-- ADR-28: profiles (self) is on the direct-write allowlist
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ========================================================================
-- BRANCHES
-- ========================================================================
alter table public.branches enable row level security;

create policy branches_select on public.branches
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- No insert/update/delete for authenticated (ADR-28: Edge Function only)

-- ========================================================================
-- BRANCH_OPENING_HOURS (branch-scoped: ADR-20 rule 1)
-- ========================================================================
alter table public.branch_opening_hours enable row level security;

create policy branch_opening_hours_select on public.branch_opening_hours
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and (
      public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
      or public.has_tenant_role(tenant_id, array['receptionist', 'staff'], branch_id)
    )
  );

-- ADR-28: not on allowlist (manager-only configuration, Edge Function)

-- ========================================================================
-- CLOSED_PERIODS (branch-scoped: ADR-20 rule 1)
-- ========================================================================
alter table public.closed_periods enable row level security;

create policy closed_periods_select on public.closed_periods
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and (
      public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
      or public.has_tenant_role(tenant_id, array['receptionist', 'staff'], branch_id)
    )
  );

-- ========================================================================
-- MEMBERSHIPS (ADR-20 rule 3: no direct writes for authenticated)
-- ========================================================================
alter table public.memberships enable row level security;

create policy memberships_select on public.memberships
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-20 rule 9 + ADR-28: memberships writes only through onboarding/staff functions

-- ========================================================================
-- STAFF_MEMBERS
-- ========================================================================
alter table public.staff_members enable row level security;

create policy staff_members_select on public.staff_members
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-28: staff writes go through staff Edge Function
-- Staff self-profile: exposed through the staff function

-- ========================================================================
-- STAFF_BRANCH_ASSIGNMENTS
-- ========================================================================
alter table public.staff_branch_assignments enable row level security;

create policy staff_branch_assignments_select on public.staff_branch_assignments
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-28: Edge Function only

-- ========================================================================
-- SHIFTS (ADR-28: manager-gated on allowlist, branch-scoped)
-- ========================================================================
alter table public.shifts enable row level security;

create policy shifts_select on public.shifts
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and (
      public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
      or public.has_tenant_role(tenant_id, array['receptionist', 'staff'], branch_id)
    )
  );

-- ADR-28: manager-gated direct writes (branch-scoped)
create policy shifts_insert on public.shifts
  for insert to authenticated
  with check (
    public.has_tenant_role(tenant_id, array['tenant_owner', 'branch_manager'], branch_id)
  );

create policy shifts_update on public.shifts
  for update to authenticated
  using (
    public.has_tenant_role(tenant_id, array['tenant_owner', 'branch_manager'], branch_id)
  )
  with check (
    public.has_tenant_role(tenant_id, array['tenant_owner', 'branch_manager'], branch_id)
  );

create policy shifts_delete on public.shifts
  for delete to authenticated
  using (
    public.has_tenant_role(tenant_id, array['tenant_owner', 'branch_manager'], branch_id)
  );

-- ========================================================================
-- BLOCKED_TIME_TYPES (tenant-scoped config)
-- ========================================================================
alter table public.blocked_time_types enable row level security;

create policy blocked_time_types_select on public.blocked_time_types
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- BLOCKED_TIMES (F-DB-6: NOT direct-write; all writes through locked staff RPC)
-- ========================================================================
alter table public.blocked_times enable row level security;

create policy blocked_times_select on public.blocked_times
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and (
      public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
      or (
        branch_id is not null
        and public.has_tenant_role(tenant_id, array['receptionist', 'staff'], branch_id)
      )
      or (
        all_branches = true
        and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
      )
    )
  );

-- ========================================================================
-- SERVICE_CATEGORIES
-- ========================================================================
alter table public.service_categories enable row level security;

create policy service_categories_select on public.service_categories
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-28: catalogue function for mutations

-- ========================================================================
-- SERVICES
-- ========================================================================
alter table public.services enable row level security;

create policy services_select on public.services
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-28: catalogue function when pricing changes

-- ========================================================================
-- SERVICE_BRANCH_OVERRIDES
-- ========================================================================
alter table public.service_branch_overrides enable row level security;

create policy service_branch_overrides_select on public.service_branch_overrides
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and (
      public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
      or public.has_tenant_role(tenant_id, array['receptionist', 'staff'], branch_id)
    )
  );

-- ========================================================================
-- SERVICE_STAFF
-- ========================================================================
alter table public.service_staff enable row level security;

create policy service_staff_select on public.service_staff
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- CLIENTS (ADR-11: tenant-scoped SELECT)
--   ADR-28: contact/profile writes by receptionist+; protected columns carved out
--   F-DB-5/F-perm-2: staff role has NO client writes
-- ========================================================================
alter table public.clients enable row level security;

create policy clients_select on public.clients
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-28: receptionist+ can create/update contact fields
-- Protected columns (is_blocked, is_deleted, merged_into) are carved out
-- and routed through the clients Edge Function (F-4)
create policy clients_insert on public.clients
  for insert to authenticated
  with check (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  );

create policy clients_update on public.clients
  for update to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  )
  with check (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  );

-- No delete policy for authenticated: deletion is soft-delete via the clients function

-- ========================================================================
-- CLIENT_NOTES (ADR-28: receptionist+ on allowlist; staff read-only)
-- ========================================================================
alter table public.client_notes enable row level security;

create policy client_notes_select on public.client_notes
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ADR-28: receptionist and above write; staff is read-only
create policy client_notes_insert on public.client_notes
  for insert to authenticated
  with check (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  );

-- ========================================================================
-- CANCELLATION_REASONS
-- ========================================================================
alter table public.cancellation_reasons enable row level security;

create policy cancellation_reasons_select on public.cancellation_reasons
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- APPOINTMENTS (ADR-20 rule 1: branch-scoped; ADR-28: no direct writes)
-- ========================================================================
alter table public.appointments enable row level security;

create policy appointments_select on public.appointments
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and (
      public.has_tenant_role_any_branch(tenant_id, array['tenant_owner'])
      or public.has_tenant_role(tenant_id, array['branch_manager', 'receptionist', 'staff'], branch_id)
    )
  );

-- ADR-28: all appointment writes go through bookings Edge Function (ADR-24)

-- ========================================================================
-- APPOINTMENT_ITEMS (ADR-20 rule 1: branch-scoped)
-- ========================================================================
alter table public.appointment_items enable row level security;

-- Appointment items inherit scope from their parent appointment via join,
-- but we also have tenant_id for direct policy filtering.
create policy appointment_items_select on public.appointment_items
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- BOOKING_OVERRIDES
-- ========================================================================
alter table public.booking_overrides enable row level security;

create policy booking_overrides_select on public.booking_overrides
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- SALES (ADR-20 rule 1: branch-scoped; ADR-28: no direct writes)
--   F-DB-5: staff role does NOT get SELECT on sales; see report_staff_performance RPC
-- ========================================================================
alter table public.sales enable row level security;

create policy sales_select on public.sales
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  );

-- ADR-28: all sales writes through checkout Edge Function

-- ========================================================================
-- SALE_ITEMS
-- ========================================================================
alter table public.sale_items enable row level security;

create policy sale_items_select on public.sale_items
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  );

-- ========================================================================
-- TIPS (branch-scoped)
-- ========================================================================
alter table public.tips enable row level security;

create policy tips_select on public.tips
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- PAYMENTS (ADR-34: no direct writes; ADR-20 rule 1: branch-scoped)
--   ADR-10: refunds are owner/manager only, but the checkout function enforces
--   that server-side. RLS here just governs visibility.
-- ========================================================================
alter table public.payments enable row level security;

create policy payments_select on public.payments
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager', 'receptionist'])
  );

-- ========================================================================
-- REGISTER_SESSIONS (ADR-28: no direct writes; branch-scoped visibility)
-- ========================================================================
alter table public.register_sessions enable row level security;

create policy register_sessions_select on public.register_sessions
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
  );

-- ========================================================================
-- INVOICE_COUNTERS
-- ========================================================================
alter table public.invoice_counters enable row level security;

create policy invoice_counters_select on public.invoice_counters
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- TAX_RATES
-- ========================================================================
alter table public.tax_rates enable row level security;

create policy tax_rates_select on public.tax_rates
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

-- ========================================================================
-- SETTINGS (ADR-20 rule 6: branch-scoped + tenant-wide)
--   ADR-28: settings (role-gated) on the direct-write allowlist
-- ========================================================================
alter table public.settings enable row level security;

create policy settings_select on public.settings
  for select to authenticated
  using (tenant_id in (select public.current_tenant_ids()));

create policy settings_insert on public.settings
  for insert to authenticated
  with check (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
  );

create policy settings_update on public.settings
  for update to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
  )
  with check (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner', 'branch_manager'])
  );

-- ========================================================================
-- AUDIT_LOG (ADR-22: append-only, no direct INSERT/UPDATE/DELETE for authenticated)
-- ========================================================================
alter table public.audit_log enable row level security;

create policy audit_log_select on public.audit_log
  for select to authenticated
  using (
    tenant_id in (select public.current_tenant_ids())
    and public.has_tenant_role_any_branch(tenant_id, array['tenant_owner'])
  );

-- No insert/update/delete policies: audit_log rows are written only by
-- SECURITY DEFINER trigger functions and Edge Function code paths (ADR-22)

-- ========================================================================
-- IDEMPOTENCY_KEYS (internal, no user access)
-- ========================================================================
alter table public.idempotency_keys enable row level security;

-- No policies: idempotency keys are managed by Edge Functions under service role
-- and never exposed to authenticated users directly.

-- ========================================================================
-- AUDIT TRIGGERS on key tables (ADR-22)
-- ========================================================================
create trigger trg_audit_clients
  after insert or update or delete on public.clients
  for each row execute function public.audit_trigger();

create trigger trg_audit_appointments
  after insert or update or delete on public.appointments
  for each row execute function public.audit_trigger();

create trigger trg_audit_sales
  after insert or update or delete on public.sales
  for each row execute function public.audit_trigger();

create trigger trg_audit_payments
  after insert or update or delete on public.payments
  for each row execute function public.audit_trigger();

create trigger trg_audit_memberships
  after insert or update or delete on public.memberships
  for each row execute function public.audit_trigger();

create trigger trg_audit_settings
  after insert or update or delete on public.settings
  for each row execute function public.audit_trigger();

-- ========================================================================
-- GRANTS: base table access for authenticated (RLS policies restrict rows)
--   ADR-21/F-6: authenticated must hold SELECT on viewed tables
-- ========================================================================
grant select on public.tenants to authenticated;
grant select on public.currencies to authenticated;
grant select on public.branches to authenticated;
grant select on public.branch_opening_hours to authenticated;
grant select on public.closed_periods to authenticated;
grant select on public.memberships to authenticated;
grant select on public.staff_members to authenticated;
grant select on public.staff_branch_assignments to authenticated;
grant select on public.shifts to authenticated;
grant select on public.blocked_time_types to authenticated;
grant select on public.blocked_times to authenticated;
grant select on public.service_categories to authenticated;
grant select on public.services to authenticated;
grant select on public.service_branch_overrides to authenticated;
grant select on public.service_staff to authenticated;
grant select on public.clients to authenticated;
grant select on public.client_notes to authenticated;
grant select on public.cancellation_reasons to authenticated;
grant select on public.appointments to authenticated;
grant select on public.appointment_items to authenticated;
grant select on public.booking_overrides to authenticated;
grant select on public.sales to authenticated;
grant select on public.sale_items to authenticated;
grant select on public.tips to authenticated;
grant select on public.payments to authenticated;
grant select on public.register_sessions to authenticated;
grant select on public.invoice_counters to authenticated;
grant select on public.tax_rates to authenticated;
grant select on public.settings to authenticated;
grant select on public.audit_log to authenticated;
grant select on public.plan_features to authenticated;

-- Allowlist write grants (ADR-28)
grant insert, update on public.profiles to authenticated;
grant insert on public.client_notes to authenticated;
grant insert, update on public.clients to authenticated;
grant insert, update, delete on public.shifts to authenticated;
grant insert, update on public.settings to authenticated;

-- Allowlist tables that only get SELECT
grant select on public.idempotency_keys to authenticated;

-- Anon grants (minimal: only what the login/signup flow needs)
grant select on public.currencies to anon;

-- Service_role gets everything (bypasses RLS)
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant all on all routines in schema public to service_role;