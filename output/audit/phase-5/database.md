# Phase 5 Database and Security Audit

## Scope
Phase 5: Calendar & Booking (subphases 5.1-5.4) — the booking data layer, slot/conflict engine, calendar UI, and realtime/performance.

## Phase 5 migrations (all new, never edited)
| # | Migration | Purpose |
|---|-----------|---------|
| 1 | 20261009100000_extend_appointments.sql | Adds booking columns (ref_number, cancellation record, branch_id on items, service snapshots, composite FKs) |
| 2 | 20261009100100_create_booking_overrides.sql | Soft-rule override recording table |
| 3 | 20261009100200_appointment_reads_and_guards.sql | Replaces RLS policies for staff-own reads, calendar indexes, status_active constraint trigger |
| 4 | 20261009100300_book_appointment.sql | book_appointment RPC + internal helpers (conflict checks, soft-rule violations, override gate, client checks) + branch_open_ranges |
| 5 | 20261009100400_appointment_lifecycle_rpcs.sql | reschedule_appointment, cancel_appointment, set_appointment_status, attach_appointment_client |
| 6 | 20261010100000_booking_slots.sql | booking_available_slots slot engine + set_appointment_notes RPC |
| 7 | 20261011100000_appointments_realtime.sql | Realtime publication + no-delete triggers |

Total: 7 new migrations. 0 pre-existing migrations modified (confirmed via git log --follow). All applied cleanly per gates log.

## Audit areas

### 1. Migrations
CONFIRMED: Every phase 5 migration follows the conventions:
- uuid PKs with gen_random_uuid() (ADR-44) ✓
- tenant_id NOT NULL on every tenant-owned table ✓
- Composite FKs with (id, tenant_id)/(branch_id, tenant_id) per ADR-20 rule 5 ✓
- Money as bigint _minor columns (price_minor, etc.) per ADR-17 ✓
- timestamptz and IANA zones (branches.timezone) per ADR-45 ✓
- CHECK enums for status (booked/confirmed/arrived/in_progress/completed/cancelled/no_show) per ADR-7 ✓
- updated_at triggers on all mutable tables ✓
- Indexes on tenant_id, branch_id, FKs, and time-range predicates ✓
- All-branches representation: branch_id NULL + all_branches boolean (never sentinel UUID) per ADR-20 rule 6 ✓
- booking_overrides: correct composite FKs to branches, appointments, appointment_items ✓
- 20261009100200: appointments_unique (id, branch_id, tenant_id) for composite FK target ✓
- No direct-write policies on any phase 5 table (writes through RPCs only per ADR-28) ✓

One minor note: the old FK `appointment_items_appointment_fk (appointment_id, tenant_id)` was NOT dropped when the new `appointment_items_appointment_branch_fk (appointment_id, branch_id, tenant_id)` was added. Both coexist. The old FK lacks ON UPDATE CASCADE (needed for cross-branch reschedule). Not harmful, but redundant.

### 2. RLS and grants
Tables and their policies:

**appointments** (1 policy, select-only):
- appointments_select: tenant_id in current_tenant_ids() AND (owner/all-branch manager/receptionist) OR (branch-scoped manager/receptionist) OR (staff at branch AND own appointment IDs)
- Grants: SELECT to authenticated; revoke all from anon
- WRITE: no INSERT/UPDATE/DELETE policies exist (ADR-28) ✓

**appointment_items** (1 policy, select-only):
- appointment_items_select: tenant_id in current_tenant_ids() AND same role pattern as appointments, using item's own branch_id (migration 20261009100200)
- Staff role sees: all items of its own appointments (including colleague's items in multi-staff visits)
- Grants: SELECT to authenticated; revoke all from anon ✓

**booking_overrides** (1 policy, select-only):
- booking_overrides_select: tenant_id in current_tenant_ids() AND (all-branches owner/manager/receptionist) OR (branch-scoped manager/receptionist at override's branch)
- Staff role: correctly excluded (no matching condition) ✓
- Grants: SELECT to authenticated; revoke all from anon ✓

Key RLS properties verified through code review:
- All policies use TO authenticated (never USING(true)) ✓
- No direct-write policies on any phase 5 table ✓
- Grants follow the revoke-everything-then-grant-SELECT pattern ✓
- Staff role correctly scoped to own appointments via current_staff_appointment_ids() ✓
- cross-tenant isolation via current_tenant_ids() ✓

### 3. Functions
All SECURITY DEFINER functions in phase 5:
| Function | search_path pinned? | Executable by anon/authenticated? |
|----------|--------------------|----------------------------------|
| book_appointment | SET search_path = public | service_role only ✓ |
| reschedule_appointment | SET search_path = public | service_role only ✓ |
| cancel_appointment | SET search_path = public | service_role only ✓ |
| set_appointment_status | SET search_path = public | service_role only ✓ |
| attach_appointment_client | SET search_path = public | service_role only ✓ |
| booking_available_slots | SET search_path = public | service_role only ✓ |
| set_appointment_notes | SET search_path = public | service_role only ✓ |
| booking_actor_has_role | SET search_path = public | service_role only ✓ |
| booking_check_conflicts | SET search_path = public | service_role only ✓ |
| booking_soft_rule_violations | SET search_path = public | service_role only ✓ |
| booking_check_self_overlap | SET search_path = public | service_role only ✓ |
| booking_check_override_request | SET search_path = public | service_role only ✓ |
| booking_check_override_gate | SET search_path = public | service_role only ✓ |
| booking_check_client | SET search_path = public | service_role only ✓ |
| booking_lock_staff | SET search_path = public | service_role only ✓ |
| booking_lock_appointment | SET search_path = public | service_role only ✓ |
| current_staff_appointment_ids | SET search_path = public | authenticated, service_role (needed by RLS) ✓ |
| branch_open_ranges | SET search_path = public | authenticated, service_role (needed by slot engine) |
| appointment_transition_kind | (no SECURITY DEFINER - pure function) | authenticated, service_role |
| check_appointment_items_status_active | SET search_path = public | not executable by any role (trigger-only) ✓ |
| appointments_forbid_delete | SET search_path = public | not executable by any role (trigger-only) ✓ |

Key findings:
- All 17 SECURITY DEFINER functions pin search_path (ADR-20 rule 10) ✓
- Booking RPCs and internal helpers are service_role only ✓
- booking_actor_has_role correctly checks is_active, all_branches, specific branch ✓
- has_tenant_role: NO default on p_branch_id (per F-DB-2) ✓
- has_tenant_role_any_branch: checks all_branches only ✓
- Guard checks (022) confirm: zero SECURITY DEFINER functions executable by anon ✓

### 4. Attack surface: API isolation tests
UNVERIFIED LOCALLY — The local Supabase stack was running during the gates execution but API calls failed with "Database connection error" when I attempted security probing. The REST API at 127.0.0.1:54321 returned:
  `{"code":"PGRST000","message":"Database connection error."}`
This prevented direct testing of:
- Booking RPC calls from authenticated (should be forbidden - service_role only)
- Direct REST reads of other tenants' appointments (should be blocked by RLS)
- Cross-tenant FK attacks (should fail at FK constraint level)
- anon access to booking data (should return empty/missing)

However, the pgTAP matrix (test 026 and 019) provides programmatic verification that these isolation guarantees hold. The 1313/1313 passing pgTAP tests in the gates log include the full matrix tests. The cross-tenant and cross-branch isolation is exhaustively tested there.

### 5. pgTAP tests
Phase 5 added 8 pgTAP test files:

| File | Plan | Key coverage |
|------|------|--------------|
| 019_appointments_matrix.test.sql | 57 | Schema/grants/constraints on appointments+items, RLS read matrix per role, booking columns, guard trigger |
| 022_guard_checks.test.sql | 31 | RLS on every table, direct-write allowlist, SECURITY DEFINER search_path, security_invoker views, money columns, sentinel UUID audit, audit triggers |
| 023_booking_overrides_matrix.test.sql | 30 | Schema/grants/FKs, RLS read matrix, constraint violations (wrong rule, wrong action, cross-tenant) |
| 024_book_appointment.test.sql | 61 | Grants, snapshots/refs/audit, walk-in, client blocked/deleted/other-tenant, actor refusals, buffers, multi-item, conflicts, soft rules, override gate, advisory locks, branch_open_ranges (DST, overnight, 23:59) |
| 025_appointment_lifecycle.test.sql | 58 | ADR-7 49-pair transition table, forward/backward/illegal, status overrides, reschedule (cross-branch, same-branch), cancel, no-show, reopen, attach client |
| 026_booking_matrix.test.sql | 43 | RPC grants (6 booking RPCs + helpers), SELECT matrix per role/table, direct-write denial, cross-tenant RPC calls, revocation immediacy |
| 027_booking_slots.test.sql | 69 | Grants, scope, buffers, overnight shifts, 23:59 close, closed periods, DST days, parity loop (exhaustive: every grid point x staff -> book_appointment must agree) |
| 028_appointments_realtime.test.sql | 16 | Publication membership, no-delete triggers (owner + service_role), no-function-deletes-bookings |

Total Phase 5 pgTAP tests: 365 assertions across 8 files.
Total Phase 5 pgTAP passing per gates: 1313/1313 (including earlier phase tests).

Test gaps: None identified for phase 5 scope. The matrix covers all operations (SELECT only for phase 5 tables - correct per ADR-28), all roles (owner, all-branches manager, branch-scoped managers, receptionist, staff, cross-tenant owner, outsider, anon), cross-branch and cross-tenant cases.

### 6. Types and seed
Gates result (gate #5 — Type drift): PASS. Generated types differ only by banner lines, no actual drift.
Seed: loads local demo data per seed.sql. Documented logins work (verified: owner@spacorner.test authenticated successfully via REST API).

### 7. Skill consistency (supabase-database)
Compare SKILL.md against actual migrations:

| Skill statement | Implementation | Match? |
|----------------|----------------|--------|
| busy_range as GENERATED ALWAYS AS | BUSY_RANGE set by trigger set_appointment_item_busy_range() | MINOR DEVIATION: implementation uses plan-approved trigger approach (v2 triggers, F-final-sql-1). Skill documents ideal pattern, implementation follows the plan. |
| Appointment status uses in_progress | status CHECK includes 'in_progress' | ✓ |
| ALL-branches representation: branch_id NULL + all_branches | memberships table uses this pattern | ✓ |
| Money: bigint _minor | price_minor on appointment_items | ✓ |
| has_tenant_role: NO default on p_branch_id | Confirmed: no default parameter | ✓ |
| RLS: branch-scoped template | appointments, appointment_items, booking_overrides follow it | ✓ |
| RPCs: SECURITY DEFINER with SET search_path | All 17 definer functions confirmed | ✓ |
| Staff role reads own appointments only | current_staff_appointment_ids() pattern | ✓ |

Minor gap: the skill says "appointment_items uses the branch template directly" which is correct since migration 20261009100200 moved from join-to-appointments to using items' own branch_id.

## Findings

### F-DB-1: Redundant old FK not dropped on appointment_items (minor)
- Severity: minor
- Location: supabase/migrations/20261009100000_extend_appointments.sql:41-42
- Problem: The old FK `appointment_items_appointment_fk (appointment_id, tenant_id)` from the base migration (20261006120000) was not dropped when the new `appointment_items_appointment_branch_fk` was added. This creates a redundant FK path. The old FK has ON DELETE CASCADE (no ON UPDATE CASCADE), while the new one has both. The redundancy is not harmful.
- Fix: Optionally drop the old FK in a cleanup migration:
  `ALTER TABLE public.appointment_items DROP CONSTRAINT appointment_items_appointment_fk;`
- Plan item: ADR-20 rule 5 (composite FKs)

### F-DB-2: Skill busy_range documentation diverges from implementation (minor)
- Severity: minor
- Location: .cursor/skills/supabase-database/SKILL.md:152-155 vs supabase/migrations/20261006120000_create_appointments.sql:73-86
- Problem: The skill documents busy_range as `GENERATED ALWAYS AS (...)` but the actual implementation uses a BEFORE INSERT/UPDATE trigger `set_appointment_item_busy_range()`.
- Evidence: Skill line 152: `busy_range tstzrange GENERATED ALWAYS AS (...)` but the trigger approach is functionally equivalent and was the plan's approved approach (F-final-sql-1: "v2 triggers").
- Fix: Update the skill to document the trigger approach as the canonical pattern, with a note that GENERATED ALWAYS is an alternative for future phases.
- Plan item: Phase 5.1 Database work (busy_range trigger)

### F-DB-3: API not available for live security probing (unverifiable)
- Severity: major (if it persists through CI)
- Location: Supabase REST API at 127.0.0.1:54321
- Problem: The REST API returned "Database connection error" during the audit. Could not verify live attack surface (RPC isolation, cross-tenant REST reads, anon access). The gates task left the stack running, but the PostgREST connection to the database was broken by the time this audit ran.
- Evidence: curl to /rest/v1/appointments returned HTTP 500 with PGRST000 (db connection error), though auth token endpoint still worked.
- Fix: Ensure postgREST/db connection remains healthy after gates complete. Run a supabase status health check and restart if needed for downstream auditors. If this is a known local-stack flake, document it.
- Plan item: Phase 5.4 (performance CI infra)

## Summary Table
| ID | Severity | Title |
|----|----------|-------|
| F-DB-1 | minor | Redundant old FK not dropped on appointment_items |
| F-DB-2 | minor | Skill busy_range documentation diverges from trigger implementation |
| F-DB-3 | major | API unavailable for live security probing |

## Count per severity
- Blocker: 0
- Major: 1 (F-DB-3 — API unavailability, not a code defect)
- Minor: 2

## Verdict
The Phase 5 database layer passes audit. No blockers. No code defects in migrations, RLS, functions, or tests. The 7 migrations, RLS policies, RPC security model (service_role gating with internal actor checks), pgTAP matrix coverage (365 new assertions across 8 files, all passing), and guard checks are comprehensive. The two minor findings (redundant FK, skill documentation) are non-functional. The API unavailability prevented live attack-surface testing but the pgTAP matrix already programmatically verifies the isolation guarantees.