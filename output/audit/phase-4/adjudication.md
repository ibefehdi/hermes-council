# Phase 4 audit adjudication

## Verdict: PASS

The evidence is sufficient to conclude that Phase 4 is implemented and its required local gates pass. I found no blocker or major issue. The five accepted findings below are minor: two database-policy defense-in-depth gaps, one inaccurate plan line, a production import-worker configuration failure mode, and a gap between the small browser import fixture and the specified 1,000-row volume. The backend 1,000-row/5%-invalid acceptance scenario is independently exercised through the clients Edge Function and database, so the browser-fixture gap does not make an acceptance criterion incomplete.

## Repository and gates

- Repository: `/Users/fahad/GlowDesk`.
- Branch: `feat/ci-merge-gates`.
- HEAD: `dcaf3ef3343688a39c7adabada2d89f23d80f83c`.
- Working tree: clean at verification; `git status --short --branch` showed only the branch header and no changed paths. The recorded gate before/after status is also clean (`gates/git-status-before.txt`, `gates/git-status-after.txt`).
- Audit date: 2026-10-05.
- Gate result: 9/9 passed, per `gates/GATES.md:59-71`.

| Gate | Result and evidence |
|---|---|
| Frozen-lockfile install | PASS, exit 0; `gates/GATES.md:63`, `gates/pnpm-install-frozen.log`. |
| Clean database reset and seed | PASS, exit 0; all 37 migrations applied; `gates/GATES.md:64`, `gates/pnpm-db-reset.log:1-2`. |
| pgTAP | PASS, 23 files / 1,018 tests / 0 failures; `gates/GATES.md:65`, `gates/pnpm-db-test.log:1-11`. Client tests include 015–018. |
| Database lint | PASS, no schema errors; `gates/GATES.md:66`. |
| Generated type drift | PASS, no substantive drift; `gates/GATES.md:67`. |
| Deno Edge Function tests | PASS, 7 suites / 128 tests / 0 failures; clients suite has 16 tests; `gates/GATES.md:68`, `gates/pnpm-fn-test.log:1-13`. |
| Verify (skills, i18n, types, lint, CSS, Vitest, build, size) | PASS; Vitest 288 tests; `gates/GATES.md:69`, `gates/pnpm-verify.log:1-12`. |
| Playwright | PASS, 60 tests / 0 failures across English and Arabic; `gates/GATES.md:70`, `gates/playwright-test.log:1-15`. |
| Final clean database reset | PASS, exit 0; all 37 migrations applied and seed loaded; `gates/GATES.md:71`. |

The gate suite reports 1,494 total tests passed: 1,018 pgTAP, 128 Deno, 288 Vitest and 60 Playwright (`gates/GATES.md:93-102`). No gate was skipped in the provided gate record. I did not rerun stateful checks or Playwright, as directed by the common brief.

## Checklist and acceptance-criterion adjudication

The conformance report covers the phase header, all three subphases (4.1, 4.2, 4.3), and each subphase's acceptance criteria, tests and backlog: `conformance.md:20-42`, `46-86`, `90-127`, `131-175`. The section boundaries match the plan at `plan/parts/11-delivery-plan.md:805-938`. I spot-checked the following acceptance evidence directly:

- Phase exit: duplicate warning/link and proceed choice — the bilingual Playwright flow sees the matching client link and proceeds (`apps/back-office/e2e/clients.spec.ts:53-63`); the RPC audit contract is exercised in `supabase/tests/017_client_rpcs.test.sql` and the Deno duplicate tests (`supabase/functions/clients/clients_test.ts:87-116`).
- Phase exit: Arabic normalization — the UI test searches without diacritics/hamza and finds the Arabic client (`apps/back-office/e2e/clients.spec.ts:66-75`); unit tests cover diacritics/alef/taa marbuta normalization (`apps/back-office/src/features/clients/mappers.test.ts:60-63`).
- Phase exit and subphase 4.2: 1,000 rows with 5% invalid — Deno tests assert 1,000 total / 950 valid / 50 invalid, every bad row and its reason, five import chunks, audit records, and an idempotent replay (`supabase/functions/clients/import_test.ts:156-180`, `202-255`). The test calls the local clients function and checks persisted rows and audit data. The pgTAP import test separately checks 1,000-row chunking (`supabase/tests/018_client_import.test.sql:182-194`).
- Phase exit and subphase 4.3: blocked-client behavior — the Playwright test blocks with a reason, observes the persisted “blocked from booking” flag, filters the client, and unblocks (`apps/back-office/e2e/clients.spec.ts:84-106`). `client_is_bookable` rejects deleted, cross-tenant and blocked clients (`supabase/tests/017_client_rpcs.test.sql:101-111`, `136-145`).
- Phase exit and subphase 4.3: allergy flag contract — the client-safety component renders allergy and alert fields (`apps/back-office/src/features/clients/components/ClientSafety.tsx:31-67`); mapper tests verify the safety contract (`apps/back-office/src/features/clients/mappers.test.ts:72-98`). The calendar drawer consumer is explicitly Phase 5.3 work (`plan/parts/11-delivery-plan.md:910`, `REVISION_LOG.md:179`), not an absent Phase 4 deliverable.
- Subphase 4.1: staff privacy and branch scoping — the pgTAP test asserts the exact exposed columns and rows, denies tenant B, deleted-client and no-appointment cases, and tests membership/assignment/inactive-scope changes (`supabase/tests/016_staff_client_cards.test.sql:16-55`, `65-95`).
- Subphase 4.1: tenant-wide receptionist/manager visibility and client-write restrictions — the matrix asserts all tenant A clients are visible to owner, branch managers and receptionist, excludes staff and tenant B, and verifies allowed profile writes versus protected fields (`supabase/tests/015_clients_matrix.test.sql:110-167`). This is consistent with the binding tenant-wide client rule in ADR-11 (`plan/decisions.md:182-188`).
- Subphase 4.2: manager-only block route — Deno tests reject receptionist and other-tenant requests, accept manager requests, and verify audit actor and unblock behavior (`supabase/functions/clients/clients_test.ts:128-176`); pgTAP independently checks service-role privileges and manager restrictions (`supabase/tests/017_client_rpcs.test.sql:113-149`).
- Subphase 4.3: the Playwright import journey runs in both locales and covers dry run, duplicate policy, progress/result and failure download (`apps/back-office/e2e/clients.spec.ts:130-170`, `gates/playwright-test.log:9-15`). Its four data rows do not test browser behavior at 1,000-row volume; the full volume requirement is exercised by the Deno/API test above.

### Status overrides

- Phase-level allergy criterion: **DONE**, overriding `PARTIAL` in `conformance.md:42`. The requirement is that allergies render with the flagging contract the future calendar drawer consumes. The contract and rendering exist and are tested; the plan identifies drawer consumption as Phase 5.3 (`plan/parts/11-delivery-plan.md:910, 925`).
- Subphase 4.2 database work: mark **DEVIATED-JUSTIFIED**, not simply DONE. The plan explicitly says “none” at `plan/parts/11-delivery-plan.md:873`, while its import backlog requires a producer plus pgmq consumer (`:892-896`) and the migration implements supporting tables, RPCs, queue and cron. The import design and its additions are recorded in `plan/REVISION_LOG.md:162-178`; update the plan text to make the scope explicit (accepted minor finding F-DB-4.2-01).
- Other listed subphase and phase-exit acceptance criteria remain **DONE**. No acceptance criterion is missing or failed.

## Findings accepted

No blocker or major findings were identified. Accept these five minor findings, with the fixes below. Where a migration is proposed, add a new migration; do not edit an applied migration.

### F-DB-4.1-01 — Notes update/delete policies do not exclude deleted clients
- Severity: minor.
- Location: `supabase/migrations/20261008100100_create_client_notes.sql:53-73`.
- Problem: the insert policy excludes notes whose parent client is deleted (`:44-51`), but update and delete policies do not apply the corresponding parent-client check.
- Evidence: policy definitions at `:53-73`; the parent-client check is present only at `:49-50`.
- Fix: add a new migration replacing `client_notes_update` and `client_notes_delete` so each `USING` clause also requires `EXISTS (SELECT 1 FROM public.clients c WHERE c.id = client_id AND c.tenant_id = client_notes.tenant_id AND NOT c.is_deleted)`. Preserve the existing tenant, role and author/manager conditions.
- Plan item: subphase 4.1 client notes, RLS and audit (`plan/parts/11-delivery-plan.md:836, 839`).

### F-DB-4.1-02 — Client update policy omits the deleted-state invariant in WITH CHECK
- Severity: minor.
- Location: `supabase/migrations/20261008100000_create_clients.sql:155-165`.
- Problem: `USING` requires `not is_deleted` (`:157-161`), while `WITH CHECK` does not (`:162-165`). Column grants currently prevent authenticated users from changing `is_deleted`, so this is defense in depth rather than a demonstrated bypass.
- Fix: add a new migration replacing `clients_update` with the existing `not is_deleted` condition repeated in `WITH CHECK`, preserving the existing tenant and role conditions.
- Plan item: subphase 4.1 deleted clients are non-direct-write; ADR-28/ADR-46.

### F-DB-4.2-01 — Subphase 4.2 plan understates delivered database work
- Severity: minor.
- Location: `plan/parts/11-delivery-plan.md:873`; import migration `supabase/migrations/20261008110000_create_client_import.sql`.
- Problem: the 4.2 header says no database work, although the specified import producer/consumer requires and has schema, queue, RPC and cron support. The import rationale and details appear in `plan/REVISION_LOG.md:162-178`, but the scope statement remains contradictory.
- Fix: amend the 4.2 “Database work” line to name the client import batches/rows, import anchors, queue/consumer RPCs, and cron trigger, and point to the documented implementation note. Do not change the already-applied migration.
- Plan item: subphase 4.2 database work and import backlog (`plan/parts/11-delivery-plan.md:869-879, 892-896`).

### F-CLIENTS-3 — Missing Vault secrets silently disable the cron consumer
- Severity: minor.
- Location: `supabase/migrations/20261008110000_create_client_import.sql:523-557`.
- Problem: when queued work exists but either `functions_base_url` or `internal_function_secret` is absent, `kick_client_import_consumer()` returns null without an actionable failure (`:541-545`). The import request's `EdgeRuntime.waitUntil` drain is a first attempt, but the cron safety-net cannot invoke the consumer in this configuration.
- Fix: add a deployment preflight that fails unless both named Vault secrets are configured, document the production setup, and make missing configuration visible as an error/alert rather than a successful no-op. Add a test for the missing-secret case.
- Plan item: subphase 4.2 import pipeline and pgmq consumer (`plan/parts/11-delivery-plan.md:869, 878`).

### F-FE-1 — Browser import test does not exercise the specified 1,000-row volume
- Severity: minor.
- Location: `apps/back-office/e2e/clients.spec.ts:130-170`.
- Problem: the browser flow uses four data rows, not the named 1,000-row/5%-invalid fixture. The core volume acceptance does pass through the API/database path (`supabase/functions/clients/import_test.ts:156-180, 202-255`), so the acceptance criterion is DONE; the remaining gap is browser-level verification of the large-file journey.
- Fix: add a Playwright case that uploads the 1,000-row fixture and asserts the dry-run 950-valid/50-invalid result and completed import summary (or document and enforce a separate UI scale-test if the full UI run is unsuitable). Keep the small test for quick interaction coverage.
- Plan item: subphase 4.3 Playwright import journey (`plan/parts/11-delivery-plan.md:927`) and phase-level 1,000-row import exit criterion (`:819`).

## Findings rejected or not counted

- F-DB-4.1-03, `holds_role_in_tenant` ignores `all_branches`: **reject**. Client and note visibility is intentionally tenant-wide for client-facing roles under ADR-11 (`plan/decisions.md:182-188`); pgTAP confirms branch managers see all tenant clients (`supabase/tests/015_clients_matrix.test.sql:115-128`). Staff access is separately limited through `staff_client_cards` and its assignment checks (`supabase/tests/016_staff_client_cards.test.sql:65-95`).
- F-FE-2, `--sx-calendar-week-grid-padding-left`: **reject**. This is a schedule-x library variable, not a directional declaration in the clients feature CSS; the CSS logical-property gate passed (`gates/GATES.md:69`, `frontend.md:60-68`). The prose comment is not CSS behavior.
- F-CLIENTS-1, profile history stubs: **reject**. The plan expressly requires history stubs with real data deferred to Phases 5.3 and 6.4 (`plan/parts/11-delivery-plan.md:906`; `REVISION_LOG.md:179`).
- F-CLIENTS-2, calendar drawer does not yet consume the allergy contract: **reject**. The Phase 4 criterion is the rendered flagging contract; the drawer is a later Phase 5.3 consumer (`plan/parts/11-delivery-plan.md:910, 925`). Component, type and tests exist as cited above.
- F-CLIENTS-4, client list sort is not locale-aware: **reject as a Phase 4 finding**. Sorting by primary-script names is explicitly documented and deferred to Phase 7 (`plan/REVISION_LOG.md:180`); the phase spec does not require locale-specific ordering.
- F-be-1, empty bookings/reports directories: **reject**. Those functions belong to later phases and are not Phase 4 deliverables (`backend.md:207-213`).
- F-be-2, `normalize_search()` might be absent: **reject**. This was a confirmation note, not a defect; all 37 migrations applied in the reset (`gates/pnpm-db-reset.log:1-2`) and the Arabic normalization tests pass (`supabase/tests/015_clients_matrix.test.sql`, `apps/back-office/src/features/clients/mappers.test.ts:60-63`).
- Backend observation O-1, local gateway CORS wildcard: **not counted**. It describes local gateway behavior, not a Phase 4 source defect; the function's CORS handling and local exercise are documented in `backend.md:71-84, 188-191`.
- Backend observation O-2, alleged JWT logging: **reject**. The cited `supabase/functions/_shared/db.ts:22-27` forwards the caller JWT as an Authorization header to Supabase; those lines contain no logging operation. No evidence supports a token-logging finding.
- Backend observation O-3, local development Supabase test credentials: **not counted**. The cited values are in test-only helper code, which says it is never imported by function entry points (`supabase/functions/_shared/testing.ts:1-18`); the backend audit checked that no production secret was committed (`backend.md:100-111`).

## Independent security and completeness sweep

I found no additional blocker or major. Tenant separation is exercised by the client matrix, duplicate checks, import authorization and client RPC tests (`supabase/tests/015_clients_matrix.test.sql:110-143`; `supabase/tests/017_client_rpcs.test.sql`; `supabase/tests/018_client_import.test.sql:75-94`; `supabase/functions/clients/clients_test.ts:118-126`). The staff view checks appointment, membership and branch assignment scope (`supabase/migrations/20261008100300_create_staff_client_cards.sql:12-61`; `supabase/tests/016_staff_client_cards.test.sql:65-95`). Block, delete and anonymize privileged routes are tested for role denial and audit behavior (`supabase/functions/clients/clients_test.ts:128-218`). All mandatory local gates are accounted for in `GATES.md`; the corresponding test logs confirm the counts above. I found no test-count or gate-result discrepancy in the referenced logs.

## Not verifiable locally

The production Vault values, cloud Edge Function deployment, and production cron/queue alerting cannot be verified from the local repository and local test stack. These are not local gate failures. Before production rollout, prove both Vault secrets are configured and show a successful deployed import-consumer/queue-drain check; this also closes the operational risk in F-CLIENTS-3.

## Ordered fix list

There are no blocker or major fixes. Apply these minor fixes in order:

1. F-DB-4.1-01: add a migration that replaces the client note update/delete RLS policies and checks that the parent client is not deleted.
2. F-DB-4.1-02: add a migration that repeats `not is_deleted` in the `clients_update` policy `WITH CHECK` clause.
3. F-DB-4.2-01: amend the 4.2 plan database-work statement to accurately list the existing import infrastructure and link the recorded build note.
4. F-CLIENTS-3: add a production configuration preflight for both Vault secrets, surface missing values as an error/alert, document setup and test the missing-secret case.
5. F-FE-1: add Playwright coverage of the 1,000-row/5%-invalid import while retaining the four-row UI interaction test.
