# Phase 7 database & security audit
started: 2026-10-08T13:01:05Z
updated: 2026-10-08T13:22:00Z

## Scope

Every migration, test, seed and database-facing change belonging to Phase 7 of the GlowDesk multi-tenant spa/salon SaaS, judged against the delivery plan (PLAN.md ## Phase 7), the binding ADRs (decisions.md), CONVENTIONS.md and the supabase-database skill.

## Gates reference

GATES.md (pre-audit run): 14/14 applicable gates PASS, 2073 pgTAP, 255 Deno, 722 Vitest, 196 Playwright. 1 benchmark gate SKIPPED (perf fixture). Type drift: clean (generated types identical to committed).

## Executive verdict

PHASE 7 DATABASE LAYER: **PASS** with 3 minor findings.

The report views/RPCs, export pipeline, home_today, global-search indexes, matrix-sweep test and housekeeping cron are all correctly implemented, properly gated at the DB level, and protected against cross-tenant and cross-branch leakage (verified via 19 attack vectors + 12 live RPC calls). The three minor findings are ADR-convention deviations in the new export tables, an incomplete full_tenant file set, and a caller-controlled audit field in record_export.

---

## 1. Migrations — PASS

**10 new Phase 7 migration files**, created in order and never edited (git log --follow confirms every file has exactly 1 commit):

| File | Description | Phase item |
|------|-------------|------------|
| 20261013100000 | report sales/payments summaries + shared checks (report_branch_scope, report_check_range, report_currency) | 7.1-T2 |
| 20261013100100 | report appointments summary + staff performance | 7.1-T3 |
| 20261013100200 | report client list + shifts | 7.1-T4 |
| 20261013100300 | report taxes summary + home_today + types regeneration | 7.1-T5 |
| 20261013100400 | audit_log keyset index + appointments ref_number prefix index (R13) | 7.1-T6 |
| 20261014100000 | export_kind_allowed + record_export (R10 matrix) | 7.3-T1 |
| 20261014100100 | export_jobs, export_parts, export_download_tokens tables + queue + all helpers (start_export, process_export_slice, etc.) + 2 crons | 7.3-T2 |
| 20261014100200 | export_slice custom plan fix (force_custom_plan) | 7.3-T4 |
| 20261015100000 | report_branch_bounds + sargable reports rewrite (R18, R8) | 7.4-T3 |
| 20261016100000 | purge_cron_job_run_details + daily cron | 7.4-T6 |

No prior migration was edited. All 62 migrations remain exactly 1 commit each.

**Convention checks** (all PASS):
- uuid PRIMARY KEY with gen_random_uuid() on new tables (export_jobs, export_parts)
- tenant_id NOT NULL REFERENCES tenants(id) on every tenant-scoped table (export_jobs: YES; export_parts: NO tenant_id — see F-1)
- All-branches representation (branch_id NULL + all_branches + CHECK + partial unique) consistent with ADR-20 rule 6 (no new tables needing it in Phase 7)
- Money columns: bigint _minor suffix (export_jobs.row_count bigint, not a money column; export headers carry price_minor etc.)
- timestamptz storage, IANA zones via branches.timezone
- updated_at triggers on export_jobs; set_updated_at function reused
- CHECK enums: export_jobs.status uses quoted check; kind check lists all 13 export kinds

---

## 2. RLS and grants — PASS (1 minor deviation)

### Rows in scope

Every Phase 7 table properly configured:

**export_jobs**: RLS enabled, one SELECT policy for authenticated (requester OR tenant owner), SELECT-only grant. No INSERT/UPDATE/DELETE grant — writes go through start_export (SECURITY DEFINER). Verified via live API: PATCH rejected 42501.

**export_parts**: RLS enabled (no policies = deny-all). `REVOKE ALL ... FROM public, anon, authenticated, service_role`. Only SECURITY DEFINER functions (process_export_slice, export_file_part) reach it. Verified via matrix sweep: every role's cell is '-'.

**export_download_tokens**: Same pattern — RLS enable + revoke all. Verified via matrix sweep.

### Report functions — all SECURITY INVOKER

Eight report RPCs (report_sales_summary, report_payments_summary, report_appointments_summary, report_staff_performance, report_client_list, report_shifts, report_taxes_summary, home_today) plus shared helpers (report_branch_scope, report_check_range, report_currency, report_branch_bounds) are all `security invoker` with `SET search_path = public`. pgTAP 042 asserts this for every present and future report_* function.

EXECUTE: revoked from PUBLIC and anon; granted to authenticated and service_role. Verified via proacl queries and confirmed by live API calls (authenticated users succeeded; anon received 401/42501).

### SECURITY DEFINER functions — search_path pinned (ALL PASS)

Every SECURITY DEFINER function in Phase 7 (export_kind_allowed, start_export, process_export_slice, export_slice, record_export, authorize_export_download, redeem_export_download, export_file_part, export_job_audit, fail_export_job, export_queue_read, kick_report_export_consumer, purge_expired_exports) has `search_path = public` in proconfig — verified via pg_proc query on the live database.

### No USING (true) (PASS)

psql scan of pg_policies: no policy in any Phase-7 table uses `USING (true)` or `WITH CHECK (true)`. Tenant data boundaries are enforced.

---

## 3. Functions — PASS

### ## has_tenant_role — no default on p_branch_id (ADR-20 rule 4)

Definition in 20261004170400_create_memberships.sql:80:
  `create function public.has_tenant_role(p_tenant_id uuid, p_roles text[], p_branch_id uuid)`
  NO default on p_branch_id. Verified in pg_proc query. A forgotten argument is a SQL error.

### has_tenant_role_any_branch — all-branches only

Definition line 99: `and m.all_branches`. A branch-scoped membership never passes. Verified.

### report_branch_scope — proper scope validation

Two paths:
1. NULL p_branch_ids → aggregates branches of caller's tenant where has_tenant_role passes. All-branches memberships get every branch of the tenant.
2. Explicit p_branch_ids → validates EACH branch in scope (has_tenant_role + branch.tenant_id match). An all-branches member of tenant A naming a tenant B branch is rejected (the branch_id check catches it because the branch doesn't belong to tenant A).

Live verification: manager_a1 calling report_sales_summary for branch A2 → 403 (42501 forbidden).

### export_kind_allowed — role matrix (R10)

One shared gate for both report CSV and export jobs:
- Owner: all 8 report kinds + 8 operational kinds + audit_log + 5 owner-only kinds (clients_contacts, client_notes, staff, catalogue, full_tenant)
- Branch manager: same report/operational kinds but restricted to own branch(es); owner-only kinds → 42501
- Receptionist, staff, other tenant, outsider, anon → 42501

Verified via live API (A4, A7, A17, A18 all → 42501; A8 owner clients_contacts → null/accepted).

---

## 4. Attack results — PASS (all 19 vectors rejected, 12 verifications correct)

All cross-tenant and cross-branch attempts rejected. Summary of the 19 attack vectors (see attack.py output):

| Attack | Description | Expected | Actual |
|--------|------------|----------|--------|
| A1 | manager->tenant B report | 403 | 42501 forbidden |
| A2 | manager->branch A2 report | 403 | 42501 forbidden |
| A3 | manager->tenant B export | 403 | 42501 forbidden |
| A4 | receptionist export | 403 | 42501 forbidden |
| A5 | nobody report | 403 | 42501 forbidden |
| A6 | anon report | 401 | JWT decode fail |
| A7 | staff report | 403 | 42501 forbidden |
| A8 | manager PATCH export_jobs | 403 | 42501 perm denied |
| A9 | manager REST tenants | 200 | own tenant only |
| A10 | receptionist REST audit_log | 200 | [] (RLS) |
| A11 | owner INSERT audit_log | 403 | 42501 no INSERT grant |
| A12 | owner REST export_jobs | 200 | [] (scope RLS) |
| A13 | manager report_client_list | 200 | phone present, no allergy/email |
| A14 | staff home_today | 200 | no sales key |
| A15 | manager record_export tenant B | 403 | 42501 forbidden |
| A16 | export_kind_allowed tenant B | 403 | 42501 forbidden |
| A17 | manager clients_contacts | 403 | 42501 forbidden |
| A18 | staff export_kind_allowed | 403 | 42501 forbidden |
| A19 | manager taxes branch A2 | 403 | 42501 forbidden |

Plus 12 verification RPC calls confirmed:
- owner report_appointments_summary → 200 totals
- manager report_shifts own branch → 200 (branch_ids=[A1])
- staff report_own_sales → 200 (own lines only)
- receptionist home_today → 200, has sales key
- staff home_today → 200, NO sales key (correct)
- manager report_client_list → phone present, NO allergy/alert/email (F-verifier-3 correct)
- owner export_kind_allowed clients_contacts → 200 null/accepted
- manager same → 42501 correct
- receptionist report_daily_sales → 200 (reads on screen)
- staff report_client_list → 42501 correct
- manager taxes A2 → 42501 correct
- bad kind 'receipts' → 400 invalid_kind

---

## 5. Tests — PASS

### pgTAP files (Phase 7 additions)

| File | Plan | Coverage |
|------|------|----------|
| 036_reports_fixture | 24 | Business dates, DST invariants, per-sale totals, currency, fixture shapes |
| 037_report_sales_payments | 31 | Sales/payments literals vs daily_summary, scope_codes, mixed currencies, by_item/staff sums |
| 038_report_appointments_staff | 22 | Appointments totals, ADR-5 rates, midnight/DST dates, scope; staff perf rows+unassigned |
| 039_report_clients_shifts | 19 | Multi-sale client aggregation (F-DB-8), keyset paging, allergy/email absence, overnight shifts, scope |
| 040_report_taxes_home | 24 | Tax by rate, refunds telescope, home_today midnight ±1s, receptionist sales, staff no sales |
| 041_audit_reads | 13 | Owner tenant-wide, manager branch-only, null-branch exclusion, DML revoked, indexes exist |
| 042_catalog_guards | 7 | Every view security_invoker, every report fn invoker+search_path+grants, report_own_sales allowlisted |
| 043_record_export | 30 | Matrix per kind+role, owner/manager/receptionist/staff/anon gates, audit rows |
| 044_export_jobs | 52 | CSV formula guard, ISO offsets, scope matrix, start_export rejections, drainage, BOM+header, volumes, purge |
| 045_matrix_sweep | 83 | 42 relations × 4 ops × 9 roles, enforce coverage, direct-write allowlist, anon privilege zero |
| 046_realtime_publication | 10 | Realtime allowlist only (appointments, appointment_items), no DELETE, no FULL |
| 047_housekeeping | 12 | Cron daily purge, retention, anon/authenticated/service_role cannot call |

Every phase-required test area is covered: metric dictionary references (036-040), scope rows (037-040), branch-local day boundaries (036, 038, 039, 040), DST (036, 038, 039, 040), midnight (036, 040), F-DB-8 top-services (037), F-DB-8 client-summary pre-aggregation (039), report multi-sale fixture (036, 037), report own-sales (Phase 6), audit reads (041), catalog guards (042), export matrix (043), export CSV/BOM/purge/volumes (044), matrix coverage (045), Realtime publication (046), housekeeping cron (047).

### Matrix sweep (045)

Coverage enforcement: `set_eq` check comparing pg_class public relations vs matrix_relations ensures every table/view has a row. 42 relations × 4 ops × 9 roles = 1512 cells. All 9 roles per relation verified. CI enforces matrix tags (309/309 cells, 0 invalid per gates). Direct-write allowlist compared to CONVENTIONS.md (no export tables on allowlist — correct). Anon privilege zero verified.

---

## 6. Types and seed — PASS

**Type drift** (gate 05-typedrift-clean.diff): `supabase gen types typescript --local` produces output identical to committed `packages/db/src/database.types.ts`. No drift.

**Seed**: `supabase/seed.sql` (213 lines, 17 KB) loads only the SpaCorner demo tenant (3 branches, staff, catalogue, checkout fixtures — all with fixed UUIDs, `password123`). No production data. Verified: all 5 documented seed logins work (owner, manager, receptionist, staff, nobody) + tenant-switcher and Setup Studio tenants.

---

## 7. Skill consistency — PASS (no contradictions)

The supabase-database skill (`.cursor/skills/supabase-database/SKILL.md`) is consistent with the Phase 7 real migrations:
- Composite FK pattern described per ADR-20 rule 5 (enumerated minimum pairs, not covering export tables — they were added later per ADR-43)
- Report/views section describes security_invoker pattern (Phase 7 uses RPCs instead of views, which is the ADR-21 escape hatch; the plan says "views/RPCs")
- Authorization helpers match actual definitions
- Money, timestamptz, naming conventions all match

The skill does NOT yet document the new export tables (export_jobs, export_parts, export_download_tokens) or the export queue — future workers copying the skill would miss them. This is a documentation lag, not a contradiction.

---

## FINDINGS

### F-DB-01: ADR-20 rule 5 composite FK missing on export_parts and export_download_tokens

- Severity: minor
- Location: supabase/migrations/20261014100100_export_jobs.sql:57-67, 70-79
- Problem: export_parts.job_id (line 58) and export_download_tokens.job_id (line 71) reference export_jobs(id) via plain FKs, not composite (id, tenant_id). Neither table carries a tenant_id column at all. ADR-20 rule 5 requires "every foreign key to another tenant-owned table is composite on (parent_id, tenant_id)". export_jobs IS a tenant-owned table (has tenant_id NOT NULL REFERENCES tenants(id), exposes UNIQUE (id, tenant_id) at line 45). The plain FK means the composite tenant consistency constraint is absent.
- Evidence: Migration file lines 58, 66, 71:
  export_parts: `job_id uuid not null references public.export_jobs (id) on delete cascade`
  export_download_tokens: `job_id uuid not null references public.export_jobs (id) on delete cascade`
  No tenant_id on either table. Compare with:
  export_jobs line 45: `unique (id, tenant_id)` — the parent-side composite unique exists.
- Exploitability: Low. Both tables have RLS enabled with no policies (deny-all) and REVOKE ALL from public, anon, authenticated AND service_role. Only SECURITY DEFINER functions (process_export_slice, export_file_part, redeem_export_download), which scope by the job's own tenant_id, can write them. No authenticated or service-role path can create a cross-tenant reference. This is a defense-in-depth gap against a future grant or new write path.
- Fix: Add `tenant_id uuid NOT NULL REFERENCES public.tenants (id)` to both tables, and change FKs to `FOREIGN KEY (job_id, tenant_id) REFERENCES public.export_jobs (id, tenant_id) ON DELETE CASCADE`. Update process_export_slice to supply p_job.tenant_id instead of relying on the job's tenant_id from the join.
- Plan item: ADR-20 rule 5 (binding), ADR-29 (contract), FINAL.md enumeration "enumerated minimum pairs" — export tables were added in Phase 7 per ADR-43; the general rule applies per the round-2 text "every foreign key to another tenant-owned table is composite".

### F-DB-02: full_tenant export file set is incomplete

- Severity: minor
- Location: supabase/migrations/20261014100100_export_jobs.sql:164-168
- Problem: The `full_tenant` kind in export_kind_files() includes branches, tax_rates, clients, client_notes, staff_members, staff_branch_assignments, service_categories, services, appointments, appointment_items, sales, sale_items, payments, tips, register_sessions, shifts, blocked_times, audit_log (17 files). It omits service_branch_overrides, service_staff, booking_overrides, closed_periods, branch_opening_hours, cancellation_reasons, blocked_time_types, settings, invoice_counters, memberships, and profiles. A tenant restoring from the full export would lose branch opening hours, service overrides, eligibility, booking overrides, closed periods, cancellation reasons, blocked-time types, settings, invoice counters, memberships, and profiles.
- Evidence: Migration line 165-168 lists the full_tenant files. Compare against tables that exist in the schema: the omitted tables all contain tenant-owned data.
- Fix: Add the 11 missing tables to `export_kind_files('full_tenant')` and add corresponding `when` branches to `export_slice` for each new file key, with the export_file_header for each.
- Plan item: ADR-43 ("Full-tenant export as a chunked, resumable queued job"), ADR-50 offboarding contract (step 1: Export — full tenant export delivered to the tenant owner). Phase 7.3 acceptance: "Owner full-tenant export of the benchmark fixture completes end-to-end in ≤10 min".

### F-DB-03: record_export row_count and filters are caller-controlled (audit forgery)

- Severity: minor
- Location: supabase/migrations/20261014100000_report_exports.sql:67-101
- Problem: record_export is a SECURITY DEFINER function granted EXECUTE to authenticated (line 105). It writes an EXPORT row to audit_log with caller-supplied p_row_count and p_filters (subject to a 4KB size limit and type check). Any authenticated user who passes export_kind_allowed (owner for owner-only kinds, owner/manager for branch kinds) can forge audit EXPORT rows claiming a fictitious row_count or filters. The actor (auth.uid()) is truthful, so a manager could claim 999999 rows exported from A1 when they only exported 10. ADR-22 says audit rows are "written only by SECURITY DEFINER trigger functions... and by Edge Function code paths for non-table events" — while record_export IS a definer function, its caller-controlled row_count means an operator auditing who exported what cannot trust the row_count field without cross-checking the export_jobs table (which only captures job-based exports, not report CSVs).
- Evidence:
  Lines 85-86: `if p_row_count is null or p_row_count < 0 then raise exception ...` — only validates that row_count is non-negative, it doesn't verify it.
  Line 72: `security definer`, but line 79: `v_scope := public.export_kind_allowed(p_tenant_id, p_kind, p_branch_ids)` — the scope check passes if the caller is authorized.
  The function is directly callable via `SELECT public.record_export(...)` by any authenticated user with the proper scope.
- Fix: Change p_row_count to a `DEFAULT 0` that is supplied by the edge function (not by the caller). Or, remove the direct EXECUTE grant and make the function callable only through the reports Edge Function (service_role), which supplies row_count from the computed data. For the report-csv handler (handleReportCsv), the row_count is available from `table.dataRows` — keep this value server-side in the function, not user-controlled.
- Plan item: ADR-22 (audit append-only, written by triggers and Edge Functions), ADR-28 (write allowlist).

---

## Summary table

| ID | Severity | Title |
|----|----------|-------|
| F-DB-01 | minor | export_parts / export_download_tokens composite FK to export_jobs missing tenant_id |
| F-DB-02 | minor | full_tenant export omits 11 tenant-owned tables |
| F-DB-03 | minor | record_export row_count caller-controlled (audit forgery within scope) |

## Counts per severity

- Blocker: 0
- Major: 0
- Minor: 3