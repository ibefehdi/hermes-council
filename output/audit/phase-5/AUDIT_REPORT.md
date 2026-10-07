# Phase 5 audit report: Calendar & booking

## Verdict: FAIL

Phase 5 is not ready for acceptance. The required Playwright gate failed: 8 of 92 tests failed, including an Arabic walk-in flow that did not load a selectable slot and an Arabic catalogue flow that stayed on the login page. Those failures leave the walk-in acceptance criterion and the full-RTL exit criterion unproven. The data layer, booking RPCs, backend tests, and realtime checks have strong passing evidence; the remaining work is concentrated in the failed browser journeys. Fix those journeys and rerun the full en+ar browser gate before accepting the phase.

| Subphase | Status | Owner summary |
|---|---|---|
| 5.1 Booking data layer | Done with fixes | Core database and concurrency criteria pass. Two minor cleanup/documentation items remain. |
| 5.2 Slot & conflict engine | Done with fixes | SQL implementation is a documented, technically justified deviation; equivalent SQL/Deno coverage passes. The planned core-test location is not met. |
| 5.3 Calendar UI | Incomplete | The Arabic walk-in browser journey and the complete Playwright gate fail; EC-12 remains partial. |
| 5.4 Realtime & performance | Done | Realtime authorization, latency, and performance checks pass. |

The verdict follows the verifier's FAIL decision. I independently rechecked its commit-provenance concern against the current repository: although the gate commit and current HEAD have different commit IDs, their Git tree IDs are identical. I therefore do not retain a separate finding that the gate lacks exact-source evidence. This does not change the FAIL verdict, which rests on the Playwright failures and partial acceptance evidence.

## What was audited

- Repository: `/Users/fahad/GlowDesk`
- Current branch: `main`
- Current HEAD: `e552ed4618debb79d4d538ae655abb9db7d9d544` (`git rev-parse HEAD`, checked 2026-10-07)
- Working tree: one untracked directory, `.pnpm-store/`; no tracked changes (`git status --short`, checked 2026-10-07)
- Audit date: 2026-10-07
- Gate report: `/Users/fahad/council/output/audit/phase-5/gates/GATES.md`
- Verifier adjudication: `/Users/fahad/council/output/audit/phase-5/adjudication.md`
- Specification: `plan/parts/11-delivery-plan.md:940-1120`, cross-checked against the conformance checklist at `conformance.md:36-145`

The gate report names `ca1f1942297cd6c7c94ac24ff9356c4c4553f0d1` (GATES.md:7-12); current HEAD is the merge commit above. Both commits resolve to tree `e8b24ccdee721c5689f84f3a364c1388026bf86f`, and `git diff --name-status ca1f194..HEAD` returned no paths. Thus the tested source tree matches the current source tree even though the commit identity differs. The only untracked path is `.pnpm-store/`, also recorded as untracked in GATES.md:12 and :56-57.

## Gates

Results below are transcribed from `GATES.md:71-84`; test counts are also reported at :101-108. No Playwright suite was rerun for this synthesis.

| Command or check | Result | Key detail |
|---|---|---|
| `pnpm install --frozen-lockfile` | PASS (exit 0) | Lockfile install reports 9 workspace projects already up to date. |
| `pnpm db:reset` | PASS (exit 0) | 48 migrations applied and seed data loaded. |
| `pnpm db:test` | PASS (exit 0) | 1,313 pgTAP tests across 29 files; 0 failed. |
| `pnpm db:lint` | PASS (exit 0) | No schema errors. |
| `supabase gen types typescript --local` type drift check | PASS (exit 0) | Only CLI banner differences; no schema type drift. |
| `pnpm fn:test` | PASS (exit 0 after Supabase restart) | 189 Deno tests across 8 suites; 0 failed. |
| `pnpm verify` | PASS (exit 0) | Skills check, i18n compile, typecheck, ESLint, Stylelint, Vitest, Vite build, and size limits pass. Vitest: 447 tests in 56 files, 0 failed; 100% coverage on 7 covered files. |
| Playwright suite | FAIL (exit 1) | 84 passed, 8 failed, 0 skipped, out of 92 across English and Arabic projects. See GATES.md:86-99. |
| `scripts/perf/slots-bench.ts` | PASS (exit 0) | p50 31.5 ms, p95 36 ms, max 37.5 ms against a 300 ms budget; 30 staff and 60 measured runs after warm-up. |
| Final `pnpm db:reset` | PASS (exit 0) | Clean reset completed for downstream consumers. |

The 8 browser failures are: 2 English toast visibility timeouts; 4 Arabic toast visibility timeouts; an Arabic walk-in journey with no 17:00 slot radio; and an Arabic catalogue journey that remained at `/login` (GATES.md:88-99). The underlying walk-in evidence shows the slot list still loading and the booking button disabled (adjudication.md:19; `gates/playwright-results/calendar-booking-the-front-b5c6b-lk-in-with-anyone-available-ar/error-context.md:15-24,239-271`).

## Exit and acceptance criteria

### Phase-level exit criteria

The criterion IDs and evidence are from `conformance.md:127-144`, with the EC-12 status overridden by the verifier at `adjudication.md:14-20`.

| Criterion | Status | Evidence |
|---|---|---|
| EC-1: Two simultaneous creates yield one success and one `CONFLICT` | DONE | `supabase/functions/bookings/rpc_concurrency_test.ts`; conformance.md:131. |
| EC-2: Cross-branch booking is protected | DONE | Branch-independent exclusion constraint and cross-branch pgTAP/Deno checks; conformance.md:132. |
| EC-3: Buffers block adjacent slots | DONE | Buffer-aware `busy_range` and pgTAP 027 parity checks; conformance.md:133. |
| EC-4: Multi-service visits with different staff work | DONE | `composeVisit()` plus pgTAP 024; conformance.md:134. |
| EC-5: Reschedule into an occupied slot fails closed | DONE | Lifecycle RPC conflict check and pgTAP 025; conformance.md:135. |
| EC-6: Appointment references are unique per branch | DONE | Unique constraint and concurrent reference-number test; conformance.md:136. |
| EC-7: Cancellation requires a reason and frees the slot | DONE | Database constraint, `status_active` update, and pgTAP 025; conformance.md:137. |
| EC-8: Status machine rejects illegal transitions | DONE | pgTAP 025 covers all 49 status pairs; conformance.md:138. |
| EC-9: Walk-in booking works | DONE | The verifier retains EC-9 as DONE on the successful walk-in journey evidence; the distinct Arabic walk-in acceptance criterion 5.3.17 remains PARTIAL because its Playwright case cannot select the expected slot or submit; conformance.md:139 and adjudication.md:16,19. |
| EC-10: Day view renders within 2 seconds p95 for the busy-branch fixture | DONE | `calendar-perf.spec.ts` and the passing gate evidence; conformance.md:140. |
| EC-11: Two browser sessions see changes within 5 seconds | DONE | `realtime_test.ts` uses a 5,000 ms budget; conformance.md:141. |
| EC-12: Full RTL | PARTIAL | Core RTL layout evidence exists, but the Arabic Playwright failures leave end-to-end behavior unproven; conformance.md:142 and GATES.md:88-99. |
| EC-13: Realtime authorization isolates branches | DONE | Branch-scoped realtime test and pgTAP 028; conformance.md:143. |
| EC-14: Soft-rule override is recorded | DONE | `booking_overrides`, override dialog, and pgTAP 023; conformance.md:144. |

### Subphase acceptance criteria

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| Two simultaneous creates produce exactly one success and one conflict | 5.1 | DONE | `rpc_concurrency_test.ts`; `supabase/tests/024_book_appointment.test.sql`; conformance.md:57-58. |
| Reference numbers remain unique per branch under concurrency | 5.1 | DONE | `rpc_concurrency_test.ts`; conformance.md:59. |
| Illegal completed-to-booked transition is rejected without manager override | 5.1 | DONE | `supabase/tests/025_appointment_lifecycle.test.sql`; conformance.md:60. |
| Cross-branch reschedule re-resolves price and snapshots | 5.1 | DONE | pgTAP 025 and cross-branch Deno/HTTP evidence; conformance.md:61. |
| Buffers participate in conflict checks | 5.1 | DONE | ADR-25 implementation and pgTAP 027 parity checks; conformance.md:62. |
| Availability covers overnight shifts, DST, closed periods, and blocked time | 5.2 | DONE | pgTAP 027 and Deno slot parity tests; conformance.md:76; adjudication.md:30,35. |
| Slot availability p95 stays within 300 ms | 5.2 | DONE | Gate benchmark p95 36 ms; GATES.md:83. |
| Edge Function wrappers pass envelope, scope, and replay tests | 5.2 | DONE | Deno suite 189/189; backend.md:64-79,120-137; GATES.md:80. |
| Busy-branch day view p95 stays within 2 seconds | 5.3 | DONE | `calendar-perf.spec.ts`; conformance.md:101. |
| Multi-service visit with distinct staff and sequential spans works | 5.3 | DONE | pgTAP 024 and booking journey; conformance.md:102. |
| Walk-in booking works and can attach a client later; blocked clients are rejected | 5.3 | PARTIAL | The attach-client path and blocked-client RPC check exist, but the required Arabic walk-in booking fails in Playwright; conformance.md:103, adjudication.md:19, GATES.md:96. |
| Cancellation requires a reason and frees the slot immediately | 5.3 | DONE | Cancel dialog, RPC constraint, and pgTAP 025; conformance.md:104. |
| Full RTL calendar and RTL drag work | 5.3 | DONE for the recorded layout/drag checks; phase criterion EC-12 remains PARTIAL | RTL layout tests and bidirectional interaction evidence exist; the Arabic gate failures still prevent acceptance of the full phase criterion; conformance.md:105,142 and GATES.md:88-99. |
| Two sessions receive changes within 5 seconds | 5.4 | DONE | `realtime_test.ts`, 5,000 ms budget; conformance.md:120. |
| Branch B receives no branch A realtime payloads | 5.4 | DONE | Deno realtime test and pgTAP 028; conformance.md:121. |
| Busy-branch performance benchmark stays within 2 seconds p95 | 5.4 | DONE | `calendar-perf.spec.ts`; conformance.md:122. |

## Plan checklist

Statuses below reflect the verifier's adjudication, not the original auditors' uncorrected summaries. Full source details are in `conformance.md`; this report groups each subphase by the plan categories. `DEVIATED-JUSTIFIED` identifies documented deviations accepted under the common brief.

### Subphase 5.1: Booking data layer

- Features — 5.1.1-5.1.8: DONE. Appointment and item schema, lifecycle/booking RPCs, exclusion and advisory-lock conflict protection, snapshots, references, override recording, and audit behavior are implemented. Evidence: conformance.md:42-49; adjudication.md:10,21.
- Database — 5.1.9-5.1.15: DONE. Migrations, constraints/indexes, audit triggers, select-only RLS, service-role RPC grants, and database isolation tests are present. Evidence: database.md:6-17,21-35,38-60; conformance.md:50-56.
- Edge Functions — No distinct 5.1 Edge Function checklist item; booking wrappers are covered under 5.2.
- Screens — No 5.1 screens; this is the data layer.
- i18n/RTL — No distinct 5.1 i18n/RTL item.
- Acceptance criteria — 5.1.17-5.1.21: DONE. See the five criteria above and conformance.md:57-62.
- Tests — 5.1.16 and 5.1.22: DONE. Concurrent booking/reschedule/cancellation races and pgTAP/Deno RPC coverage pass; total gates include 1,313 pgTAP and 189 Deno tests. Evidence: conformance.md:57,63; GATES.md:77,80.
- Dependencies — 5.1.23: DONE. Phase 2.3 blocked-time, Phase 3.1 service resolution, and Phase 4.1 blocked-client dependencies exist; conformance.md:64.
- Backlog — No separate outstanding Phase 5.1 backlog item is recorded in the phase checklist.

### Subphase 5.2: Slot & conflict engine

- Features — 5.2.1: DEVIATED-JUSTIFIED. Availability computation is in SQL `booking_available_slots`, not `packages/core`, because browser reads under branch RLS could offer slots that the booking RPC would reject. The migration records the reason; parity coverage is in pgTAP/Deno. 5.2.2-5.2.3: DONE (booking routes and conflict suggestions). Evidence: conformance.md:70-72; adjudication.md:30.
- Database — 5.2.4: DONE. The checklist calls for no new database work in this subphase beyond consuming 5.1 RPCs; the SQL availability engine is the declared implementation deviation. Evidence: conformance.md:73.
- Edge Functions — 5.2.5-5.2.6: DONE. Availability and booking handlers are present and tested; GATES.md:80 reports 189/189 Deno tests.
- Screens — No separate 5.2 screen item; the slot picker is included in 5.3.
- i18n/RTL — No distinct 5.2 i18n/RTL item.
- Acceptance criteria — 5.2.7-5.2.9: DONE. Overnight/DST/closed-time correctness, p95 latency, and wrapper contracts have passing evidence; conformance.md:76-78 and GATES.md:80,83.
- Tests — 5.2.10: PARTIAL as written, because the spec locates slot-engine unit tests in `packages/core` while the engine now runs in SQL. The required DST/overnight/closed-period behavior is covered by pgTAP 027 and Deno parity tests. This is accepted as a justified test-location deviation, not a missing behavior. 5.2.11: DONE; Deno contract tests pass. Evidence: conformance.md:79-80; adjudication.md:18,30.
- Dependencies — 5.2.12: DONE. Depends on the 5.1 booking RPCs and existing shifts/blocked-time work; conformance.md:81.
- Backlog — The core slot-engine wording is satisfied through the documented SQL deviation; no relocation is required. Keep the reason and equivalent parity tests documented (adjudication.md:30).

### Subphase 5.3: Calendar UI

- Features — 5.3.1-5.3.7: DONE as implemented. Calendar views, booking and appointment drawers, optimistic reschedule, override/cancel flows, and client history are present; end-to-end gate failures are recorded separately below. Evidence: frontend.md:29-90; conformance.md:87-93.
- Database — No new 5.3 database checklist item.
- Edge Functions — No separate 5.3 Edge Function checklist item; booking wrappers are covered under 5.2.
- Screens — 5.3.8-5.3.13: DONE. Day/week/my-day, booking and appointment drawers, cancellation/override dialogs, and cross-branch client history exist; conformance.md:94-99.
- i18n/RTL — 5.3.14: DONE for the specified locale support, mirroring, bidi handling, and branch first-day configuration in implementation and targeted layout checks. End-to-end Arabic failures keep phase-level EC-12 PARTIAL; frontend.md:120-160, conformance.md:100,142, GATES.md:88-99.
- Acceptance criteria — 5.3.15-5.3.16 and 5.3.18-5.3.19: DONE on the cited performance, multi-item, cancellation, layout, and drag evidence. 5.3.17: PARTIAL because the Arabic walk-in journey has no available slot radio and cannot submit; adjudication.md:19 and GATES.md:96. See the acceptance table above.
- Tests — 5.3.20: PARTIAL. The Playwright journeys exist, but the required gate fails 8/92; the failures include real stalled/disabled UI states as well as missing toast assertions. GATES.md:82,88-99; adjudication.md:27,40.
- Dependencies — 5.3.21: DONE. The 5.2 slot endpoint and ADR-41 fallback verdict are present; conformance.md:107,168.
- Backlog — No separate uncompleted backlog item is recorded. The verifier requires the failing browser flows to be fixed and demonstrated, not removed or downgraded (adjudication.md:40).

### Subphase 5.4: Realtime & performance

- Features — 5.4.1-5.4.4: DONE. Appointment realtime cache patching, channel authorization, benchmarks, and appointment global search are present; conformance.md:113-116.
- Database — 5.4.5-5.4.6: DONE. Realtime publication and authorization tests exist; database.md:108-125 and conformance.md:117-118.
- Edge Functions — No separate 5.4 Edge Function checklist item.
- Screens — 5.4.7: DONE. Global search includes appointments; conformance.md:119.
- i18n/RTL — No distinct 5.4 i18n/RTL checklist item.
- Acceptance criteria — 5.4.8-5.4.10: DONE. Realtime latency, branch isolation, and the render benchmark are covered; conformance.md:120-122.
- Tests — 5.4.11-5.4.12: DONE. Channel authorization and performance fixture checks are present; conformance.md:123-124.
- Dependencies — 5.4.13: DONE. The calendar and appointment schema are in place; conformance.md:125.
- Backlog — No separate uncompleted Phase 5.4 backlog item is recorded.

## Deviations

### Declared and accepted

1. Slot availability is computed in SQL rather than `packages/core`. The migration header documents the reason: branch-scoped browser reads cannot safely see all conflicting bookings, so client-computed slots could be rejected by the privileged booking RPC. The SQL path has pgTAP parity coverage, DST/overnight/closed-period cases, Deno tests, and a passing latency gate. Ruling: `DEVIATED-JUSTIFIED`; do not move the engine back to the browser (`conformance.md:70,178-182`; `supabase/migrations/20261010100000_booking_slots.sql:4-11`; adjudication.md:30).
2. Because of that relocation, the `packages/core` slot test item is partial by location, while equivalent behavior coverage is in pgTAP 027 and Deno. Ruling: accepted as part of the same justified deviation, not a missing behavior (adjudication.md:18,30).
3. The extra `attach-client` and `notes` routes support the walk-in and appointment lifecycle. Ruling: justified extension; no code change (`conformance.md:71,184`; adjudication.md:34).
4. Appointment global search was pulled forward from later work and is declared in the Phase 5.4 backlog. Ruling: planned pull-forward, not an undeclared deviation (`conformance.md:186-188`).

### Rejected as deviations or defects

- `--sx-calendar-week-grid-padding-left` is a schedule-x library token, not a directional CSS property. No change is needed (frontend.md:196-202; adjudication.md:31).
- The claim that overnight/DST coverage is absent is incorrect: pgTAP 027 covers the required cases (database.md:116-123; adjudication.md:35).
- The assertion that the API was persistently unavailable is a transient outage, not a phase defect; backend HTTP exercises and the verifier's current health request succeeded (backend.md:103-118; adjudication.md:12,32).

## Findings

### Blocker

#### F-TEST-1 (merged with duplicate F-CONF-4): Required Playwright gate fails

- Location: `/Users/fahad/council/output/audit/phase-5/gates/GATES.md:82,88-99`; Arabic walk-in error context at `gates/playwright-results/calendar-booking-the-front-b5c6b-lk-in-with-anyone-available-ar/error-context.md:15-24,239-271`.
- Problem: 8 of 92 tests fail. The failures include actual user-flow failures, not only toast timing: the Arabic walk-in screen remains in a slot-loading state without the expected 17:00 choice and leaves booking disabled; the Arabic catalogue journey stays at `/login`. Other booking, reschedule, cancel/status, and blocked-time assertions time out waiting for confirmations. This leaves 5.3.17, 5.3.20, and phase exit criterion EC-12 unproven.
- Evidence: GATES.md:82 reports 84 passed and 8 failed; :88-99 enumerates the failures. The verifier reviewed the error snapshots and raised this finding from major to blocker under the common severity rule for failed gates/unmet acceptance criteria (adjudication.md:5,19,27).
- Fix: In `apps/back-office/e2e/calendar-booking.spec.ts` and the slot-picker/query code, fix the Arabic walk-in state so a valid available slot loads, can be selected, and enables booking. In `apps/back-office/e2e/calendar-appointment.spec.ts`, `calendar-reschedule.spec.ts`, `calendar.spec.ts`, and `blocked-time.spec.ts`, fix the underlying status, reschedule, booking, and blocked-time journeys; for actions that succeed but whose transient toast lookup is unstable, assert the durable resulting state through a stable accessible locator rather than merely increasing the timeout. In `apps/back-office/e2e/catalogue.spec.ts` and session setup, fix the Arabic login/session journey. Keep all assertions; do not delete or downgrade the failing tests. Then demonstrate the complete English and Arabic Playwright gate passing and close EC-12 with end-to-end evidence (adjudication.md:40).
- Plan item: Phase 5.3.17, 5.3.20, and phase exit criterion EC-12.

### Major

No major finding remains after the chair's source-tree recheck. The verifier's F-VERIFIER-1 is listed under rejected findings below.

### Minor

#### F-DB-1: Redundant appointment-item foreign key remains

- Location: `supabase/migrations/20261006120000_create_appointments.sql:63-68` and `supabase/migrations/20261009100000_extend_appointments.sql:40-46`.
- Problem: Both the old `(appointment_id, tenant_id)` FK and the new `(appointment_id, branch_id, tenant_id)` FK remain. This is redundant but was not found to break booking behavior.
- Fix: Add a new cleanup migration that drops `appointment_items_appointment_fk` after confirming no dependent code relies on it. Do not edit the already-applied migration.
- Plan item: Phase 5.1 database work and ADR-20 rule 5 (adjudication.md:28).

#### F-DB-2: `busy_range` skill text does not match the approved trigger implementation

- Location: `.cursor/skills/supabase-database/SKILL.md:148-160`; implementation at `supabase/migrations/20261006120000_create_appointments.sql:73-93`.
- Problem: The skill describes `busy_range` as generated, while the migration maintains it with a trigger, as the plan specifies.
- Fix: Update `.cursor/skills/supabase-database/SKILL.md` and the matching `.claude/skills/supabase-database/SKILL.md` to document the trigger as canonical; keep the two copies identical.
- Plan item: Phase 5.1 database work and the plan's trigger-maintained range requirement (adjudication.md:29).

#### F-CONF-1 / F-CONF-2 / F-SLOT-1: Slot engine and tests are in SQL rather than the planned core package

- Location: `supabase/migrations/20261010100000_booking_slots.sql:4-11`; `supabase/tests/027_booking_slots.test.sql:81-85,113-151`.
- Problem: The availability engine and exhaustive behavior tests are not in `packages/core` as the backlog wording specifies.
- Ruling and fix: This is one accepted minor, justified by branch RLS and documented in the migration/build note. Keep the explanation and equivalent SQL/Deno parity coverage. No engine relocation or test duplication is required (adjudication.md:30).

#### F-DESIGN-1: Calendar library token contains “left” in its name

- Location: `apps/back-office/src/features/calendar/components/BookingCalendar.css:34`.
- Problem: The token name `--sx-calendar-week-grid-padding-left` is directional, but it is a third-party schedule-x variable name, not a CSS property.
- Fix: No code change. Retain the mapping; this does not violate the logical-property rule (adjudication.md:31; frontend.md:196-202).

### Rejected findings

- F-VERIFIER-1, “exact-HEAD gate evidence missing”: rejected after recheck. The gate commit and current HEAD have different commit IDs, but `git rev-parse ca1f194^{tree}` and `git rev-parse HEAD^{tree}` both returned `e8b24ccdee721c5689f84f3a364c1388026bf86f`; `git diff --name-status ca1f194..HEAD` returned no paths. The gate therefore exercised the identical tracked source tree. This rejection removes the separate rerun/provenance major; it does not waive the failed Playwright gate.
- F-DB-3, API unavailable for live security probing: rejected as a transient local outage; backend HTTP exercises and a current health request returned HTTP 200 (adjudication.md:12,32).
- F-layout-1, missing Deno type-check in CI: rejected because `.github/workflows/ci.yml:18-22,268-272` runs `pnpm fn:check` (adjudication.md:33).
- F-CONF-3, extra `attach-client` and `notes` routes: rejected as a defect; these are compatible lifecycle extensions (adjudication.md:34).
- F-SLOT-2, missing DST/overnight coverage: rejected because pgTAP 027 covers overnight shifts, closed periods, and London spring-forward DST (adjudication.md:35).

Counts after chair review: 1 blocker, 0 majors, 4 minors, 5 rejected findings/groups (the four verifier-rejected groups plus F-VERIFIER-1).

## Not verifiable locally

No Phase 5 exit criterion was identified that requires a cloud-only check. The backend auditor exercised the local API over HTTP and reported no remaining unverifiable backend item (backend.md:103-118,178-179). This report makes no claim about later staging deployment, Sentry, uptime monitors, or cloud-region health.

## Fix prompt

```text
Fix the Phase 5 audit findings below in /Users/fahad/GlowDesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /react-frontend /i18n-rtl /supabase-database

1. F-TEST-1: apps/back-office/e2e/calendar-booking.spec.ts and the slot picker/query code - fix the Arabic walk-in flow so available slots load, a slot can be selected, and booking becomes enabled. Fix the failing Arabic login/session and appointment/reschedule/blocked-time journeys in the affected E2E specs and application code. Keep every assertion. Where an action succeeds but a transient toast cannot be located reliably, assert the durable resulting state with a stable accessible locator. Demonstrate the full en+ar Playwright gate passing and the full RTL acceptance criterion with end-to-end evidence.
2. F-DB-1: add a new cleanup migration that drops appointment_items_appointment_fk after checking dependencies; do not edit an applied migration.
3. F-DB-2: update .cursor/skills/supabase-database/SKILL.md and .claude/skills/supabase-database/SKILL.md to describe trigger-maintained busy_range as canonical; keep both copies identical.

Rules: never edit an applied migration; keep both skill copies identical; use Conventional Commits. Done = every gate in the audit passes again and each fixed acceptance criterion is demonstrated by a test.
```
