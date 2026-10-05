# Phase 4 audit report: Clients

## Verdict: PASS

Phase 4 is implemented and its required local gates pass. The verifier found no blocker or major issue, and accepted five minor findings: two database-policy defense-in-depth gaps, an inaccurate plan scope statement, a production import-consumer configuration failure mode, and a gap between the browser import fixture and the named 1,000-row volume. The 1,000-row/5%-invalid acceptance scenario passes through the Edge Function and database tests, so the browser-fixture gap does not leave an acceptance criterion incomplete. The fixes are limited to two additive migrations, plan/configuration documentation and checks, and an additional browser-scale test. See `adjudication.md` for the evidence and verifier rulings.

| Subphase | Status |
|---|---|
| 4.1 Client data | Done with fixes: two minor RLS defense-in-depth findings. |
| 4.2 Client function | Done with fixes: minor plan-scope and import-consumer configuration findings. |
| 4.3 Client UI | Done with fixes: minor browser-scale test gap; other reported concerns were rejected or deferred by plan. |

## What was audited

The audit covers Phase 4, including the phase-level exit criteria and all three subphases (4.1, 4.2 and 4.3), against `/Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md:805-938`. ADRs take precedence over the plan and conventions, as required by the common brief. The verifier reviewed the four audit reports and the gate evidence; its checklist coverage and spot-check evidence are summarized in `adjudication.md:30-48,103-109`.

- Repository: `/Users/fahad/GlowDesk`
- Branch: `feat/ci-merge-gates`
- Commit: `dcaf3ef3343688a39c7adabada2d89f23d80f83c` (`test(platform): cover appointment visibility, guards, idempotency and settings for the merge gates`)
- Working tree: clean; `git status --porcelain=v1` returned no changed paths. The gate record also reports unchanged clean before/after status (`gates/GATES.md:3-9`).
- Audit date: 2026-10-05.

Detailed reports: `conformance.md`, `database.md`, `backend.md`, and `frontend.md`, all under `/Users/fahad/council/output/audit/phase-4/`.

## Gates

All nine recorded gates passed. Counts below come from the gate record; no stateful checks or Playwright tests were rerun for this synthesis (`gates/GATES.md:59-71,93-108`; `adjudication.md:16-28`).

| Gate | Command | Result | Key detail |
|---|---|---|---|
| 1. Frozen-lockfile install | `pnpm install --frozen-lockfile` | PASS, exit 0 | Dependencies already up to date. |
| 2. Clean database reset and seed | `pnpm db:reset` | PASS, exit 0 | All 37 migrations applied and seed loaded. |
| 3. pgTAP database tests | `pnpm db:test` | PASS, exit 0 | 23 files, 1,018 tests passed, 0 failed. |
| 4. Database lint | `pnpm db:lint` | PASS, exit 0 | No schema errors. |
| 5. Generated type drift | `supabase gen types typescript --local` followed by diff | PASS, exit 0 | No substantive drift; only generated-output header lines differed. |
| 6. Edge Function tests | `pnpm fn:test` | PASS, exit 0 | 7 Deno suites; 128 tests passed, 0 failed. Clients suite has 16 tests. |
| 7. Verify pipeline | `pnpm verify` | PASS, exit 0 | Skills, i18n, types, lint, CSS, 288 Vitest tests, build and size checks passed. |
| 8. Playwright E2E | `pnpm exec playwright test` from `apps/back-office` | PASS, exit 0 | 60 tests passed, 0 failed; 30 each in English and Arabic. |
| 9. Final clean database reset | `pnpm db:reset` | PASS, exit 0 | All 37 migrations applied and seed loaded. |

Suite totals: 1,018 pgTAP + 128 Deno + 288 Vitest + 60 Playwright = 1,494 passed, 0 failed, 0 skipped (`gates/GATES.md:93-102`).

## Exit and acceptance criteria

### Phase-level exit criteria

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| Creating a client with a matching phone shows a warning and link. | 4.1, 4.3 | DONE | English/Arabic Playwright flow verifies the warning, link, and proceed choice; duplicate RPC and Deno coverage: `apps/back-office/e2e/clients.spec.ts:53-63`, `supabase/tests/017_client_rpcs.test.sql`, `supabase/functions/clients/clients_test.ts:87-116` (`adjudication.md:34`). |
| Arabic name search matches regardless of diacritics. | 4.1, 4.3 | DONE | Playwright searches without diacritics/hamza; mapper tests cover normalization: `apps/back-office/e2e/clients.spec.ts:66-75`, `apps/back-office/src/features/clients/mappers.test.ts:60-63` (`adjudication.md:35`). |
| A 1,000-row CSV with 5% bad rows imports valid rows and reports each bad row and reason; duplicates follow policy. | 4.2, 4.3 | DONE | Deno flow asserts 950 valid and 50 invalid rows, reasons, five chunks, audit records and idempotent replay; pgTAP separately checks chunking: `supabase/functions/clients/import_test.ts:156-180,202-255`, `supabase/tests/018_client_import.test.sql:182-194` (`adjudication.md:36`). The browser flow uses four rows; that scale gap remains a minor finding, not a failed acceptance criterion. |
| Blocked-client flag persists and is exposed to the booking path. | 4.1, 4.3 | DONE | Playwright verifies block, persisted flag, filtering and unblock; `client_is_bookable` rejects blocked, deleted and cross-tenant clients: `apps/back-office/e2e/clients.spec.ts:84-106`, `supabase/tests/017_client_rpcs.test.sql:101-111,136-145` (`adjudication.md:37`). |
| Allergies render with the flagging contract for the calendar drawer. | 4.3 | DONE | Component and mapper tests establish the safety-flag contract: `apps/back-office/src/features/clients/components/ClientSafety.tsx:31-67`, `apps/back-office/src/features/clients/mappers.test.ts:72-98`. The calendar drawer consumer is Phase 5.3, not a Phase 4 deliverable (`plan/parts/11-delivery-plan.md:910,925`; `adjudication.md:38,46`). |

### Subphase acceptance criteria

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| Staff can read only name, phone and allergy flags for clients with appointments at their assigned branches. | 4.1 | DONE | `supabase/tests/016_staff_client_cards.test.sql:16-55,65-95`; verifier also checked membership, assignment and inactive-scope cases (`adjudication.md:39`). |
| Receptionist has tenant-wide read; manager has tenant-wide read/write. | 4.1 | DONE | Role and column matrix: `supabase/tests/015_clients_matrix.test.sql:110-167`; tenant-wide behavior is permitted by ADR-11 (`plan/decisions.md:182-188`; `adjudication.md:40`). |
| Import of 1,000 rows with 5% invalid reports every invalid row, applies the selected duplicate policy and audits the batch. | 4.2 | DONE | Deno import tests: `supabase/functions/clients/import_test.ts:156-180,202-278`. |
| Replaying the same batch with the same idempotency key does not duplicate clients. | 4.2 | DONE | `supabase/functions/clients/import_test.ts:240-255`; same batch is returned and no new clients are inserted. |
| Block route is manager-only. | 4.2 | DONE | Deno denies receptionist and other-tenant requests and accepts manager requests; audit actor is checked: `supabase/functions/clients/clients_test.ts:128-176`; pgTAP corroboration: `supabase/tests/017_client_rpcs.test.sql:113-149` (`adjudication.md:41`). |
| Duplicate-warning, Arabic/partial-phone search, blocked flag and allergy-contract UI behavior are covered in both required locales where applicable. | 4.3 | DONE | Playwright covers duplicate, search, block/unblock and import journey in English and Arabic: `apps/back-office/e2e/clients.spec.ts:53-106,130-170`; gates report 60 passes (`gates/GATES.md:73-90`). The 1,000-row browser fixture gap is recorded as F-FE-1 below. |

## Plan checklist

Statuses below reflect the verifier's adjudication, not the unreviewed auditor labels. `N/A` means the plan assigns no work in that category. More detailed file-by-file evidence is in `conformance.md:46-175`, `database.md:12-151`, `frontend.md:7-152`, and `backend.md:115-182`.

### Subphase 4.1: Client data

- Features: DONE — CRUD and duplicate-warning infrastructure; bilingual/contact/profile fields; timestamped, authored notes; allergies, alerts and tags; `merged_into`, non-direct-write blocked/deleted fields, source defaults; normalized tenant-wide search and privacy/anonymization groundwork. Evidence: `conformance.md:48-58`, `backend.md:117-127`.
- Database: DONE — client and notes migrations; partial unique indexes; tenant-wide client-facing RLS; column-restricted staff view and appointment/assignment scope; audit triggers; anonymization and client RPCs. Two minor policy hardening changes are accepted. Evidence: `conformance.md:60-69`, `database.md:16-71`; findings F-DB-4.1-01 and F-DB-4.1-02 below.
- Edge Functions: DONE — none required; data layer only (`plan/parts/11-delivery-plan.md:841`; `backend.md:141-147`).
- Screens: N/A — none specified (`plan/parts/11-delivery-plan.md:843`).
- i18n/RTL: DONE for the data-layer obligations — bilingual name fields, search normalization and Arabic variants are covered by migrations and tests; full UI behavior is in 4.3. Evidence: `conformance.md:57,154-160`; `frontend.md:39-46`.
- Acceptance/tests: DONE — staff scope and role/write matrix pass; pgTAP role, column, cross-tenant and search tests plus Vitest normalization/duplicate checks pass. Evidence: `conformance.md:73-86`; gate counts above.
- Dependencies: DONE — Phase 1 and 1.2 tenancy, branches, memberships and staff-branch assignments exist; 4.1 precedes the dependent function/UI work. Evidence: `conformance.md:295-303`.
- Backlog: DONE — client/notes migrations, staff view, anonymization RPC and pgTAP coverage are present (`plan/parts/11-delivery-plan.md:853-859`; `conformance.md:60-69`).

### Subphase 4.2: Client function

- Features: DONE — duplicate check, manager-only block, import producer/consumer with dry run, duplicate policy and idempotent batches, shared validation, and anonymization wrapper. Evidence: `conformance.md:92-100`, `backend.md:151-162`.
- Database: DEVIATED-JUSTIFIED — import tables, anchor columns, queue, RPCs and cron consumer were added although the plan says “none.” This database work is required by the planned producer/consumer backlog; the verifier accepts the implementation and requires the plan wording to be corrected. Evidence: `plan/parts/11-delivery-plan.md:869-879,892-896`, `plan/REVISION_LOG.md:162-178`, `adjudication.md:69-74`.
- Edge Functions: DONE — user-authenticated duplicate, block, delete, anonymize and import routes; secret-authenticated consumer; shared validation. Evidence: `backend.md:31-41,104-162`.
- Screens: N/A — none specified (`plan/parts/11-delivery-plan.md:881`).
- i18n/RTL: N/A — no screens in this subphase; Arabic CSV headers/BOM and validation behavior are covered by import tests (`conformance.md:158-160`).
- Acceptance/tests: DONE — 1,000-row/5%-invalid case, bad-row reasons, duplicate policies, batch audit/idempotency and manager-only block are tested. Evidence: `supabase/functions/clients/import_test.ts:156-180,202-278`, `supabase/functions/clients/clients_test.ts:128-176`.
- Dependencies: DONE — 4.1 tables are in place and migration order supports 4.1 → 4.2 → 4.3 (`plan/parts/11-delivery-plan.md:890`; `conformance.md:301-303`).
- Backlog: DONE — all four Edge Function/validation backlog items are delivered (`plan/parts/11-delivery-plan.md:892-896`; `conformance.md:104-111`).

### Subphase 4.3: Client UI

- Features: DONE — list/filter/search, editor/profile with planned history stubs, duplicate warning with proceed-and-record, import wizard, manager-gated block/unblock, safety flags. Evidence: `conformance.md:133-142`, `frontend.md:101-122`.
- Database: N/A — no separate database work is specified for this subphase (`plan/parts/11-delivery-plan.md:900-927`).
- Edge Functions: DONE by integration — UI calls typed clients API wrappers for duplicate check, block, delete and import; envelope handling follows ADR-29. Evidence: `frontend.md:79-97`.
- Screens: DONE — list, editor/profile, duplicate dialog, import wizard and block/unblock/safety component. Evidence: `conformance.md:144-152`, `frontend.md:101-122`.
- i18n/RTL: DONE — bilingual fields and CSV template, EN/AR catalogs, dynamic `lang`/`dir`, logical CSS, bidi isolation, Arabic search and both-locale browser tests. Evidence: `frontend.md:28-68,124-143`; gates `GATES.md:69-70,73-90`.
- Acceptance/tests: DONE — duplicate, search, block, safety flags, CRUD and import journey verified; four-row browser fixture leaves a minor UI-scale test gap while API/database tests meet the volume criterion. Evidence: `apps/back-office/e2e/clients.spec.ts:53-106,130-170`; `adjudication.md:36,42,83-88`.
- Dependencies: DONE — 4.2 function is available to the UI (`plan/parts/11-delivery-plan.md:929`; `conformance.md:301-303`).
- Backlog: DONE — all five frontend backlog items are delivered (`plan/parts/11-delivery-plan.md:931-936`; `conformance.md:144-152`).

## Deviations

The conformance audit recorded ten documented deviations and no undeclared deviations (`conformance.md:212-233`). The verifier accepts the following as justified:

| Deviation | Ruling and reason |
|---|---|
| Duplicate matching was rebuilt in 4.2 as a set-based, index-backed matcher. | DEVIATED-JUSTIFIED; documented performance improvement, original applied migration left unchanged (`plan/REVISION_LOG.md:166-168`). |
| Import uses batch-level and per-row idempotency. | DEVIATED-JUSTIFIED; improves replay safety (`plan/REVISION_LOG.md:170`). |
| Import consumer drains via `EdgeRuntime.waitUntil` and pg_cron. | DEVIATED-JUSTIFIED; cron is a safety net (`plan/REVISION_LOG.md:172`). Missing Vault configuration is separately accepted as a minor finding. |
| Staff view writes fail with SQLSTATE 55000 because the view reads a function. | DEVIATED-JUSTIFIED; test asserts this and separately checks SELECT-only privileges (`plan/REVISION_LOG.md:173`). |
| `monitors.json` added clients and the missed catalogue entry. | DEVIATED-JUSTIFIED, additive monitoring (`plan/REVISION_LOG.md:174`). |
| Client profile history remains stubbed; appointments/sales data is deferred. | DEVIATED-JUSTIFIED; later phases wire the data (`plan/REVISION_LOG.md:179`). |
| Client list sorts by primary-script name, not locale-aware collation. | DEVIATED-JUSTIFIED; deferred to Phase 7 (`plan/REVISION_LOG.md:180`). |
| Subphase 4.2 adds import database infrastructure despite “Database work: none.” | DEVIATED-JUSTIFIED as implementation; plan text must be amended (F-DB-4.2-01). `plan/REVISION_LOG.md:169-172`; `adjudication.md:69-74`. |
| Import migration extends `anonymize_client` to redact import rows. | DEVIATED-JUSTIFIED; required for anonymization (`plan/REVISION_LOG.md:169,178`). |
| No separate staff CSV import stub was added. | DEVIATED-JUSTIFIED; client import is the first CSV/pgmq pattern, and the plan note describes the direction of reuse (`plan/REVISION_LOG.md:160`). |

The verifier rejected or excluded other reported deviations/findings: tenant-wide manager visibility is allowed by ADR-11; allergy drawer consumption and profile history data belong to later phases; the schedule-x variable is a library API, not a directional declaration in clients CSS; locale-aware ordering is deferred to Phase 7; empty bookings/reports directories belong to later phases; no evidence supports the alleged JWT-logging claim. Reasons and evidence: `adjudication.md:90-101`.

## Findings

### Minor

#### F-DB-4.1-01 — Notes update/delete policies do not exclude deleted clients
- Location: `supabase/migrations/20261008100100_create_client_notes.sql:53-73`.
- Problem: Insert policy checks that the parent client is not deleted; update/delete policies do not (`adjudication.md:54-60`).
- Fix: Add a new migration replacing `client_notes_update` and `client_notes_delete`; add to each `USING` clause an `EXISTS` check for the matching `id` and `tenant_id` in `public.clients` with `NOT c.is_deleted`. Preserve tenant, role, author and manager conditions.

#### F-DB-4.1-02 — Client update policy omits the deleted-state invariant in `WITH CHECK`
- Location: `supabase/migrations/20261008100000_create_clients.sql:155-165`.
- Problem: `USING` requires `not is_deleted`, but `WITH CHECK` does not. Current column grants prevent authenticated callers from changing the field, so the gap is defense in depth (`adjudication.md:62-67`).
- Fix: Add a new migration replacing `clients_update` and repeat the existing `not is_deleted` condition in `WITH CHECK`, preserving tenant and role conditions.

#### F-DB-4.2-01 — Subphase 4.2 plan understates delivered database work
- Location: `plan/parts/11-delivery-plan.md:873`; implementation at `supabase/migrations/20261008110000_create_client_import.sql`.
- Problem: The plan says database work is “none,” while the import pipeline adds tables, queue, RPCs and cron support. The work is required by the planned import consumer and documented in the revision log (`adjudication.md:69-74`).
- Fix: Amend the 4.2 “Database work” line to list client import batches/rows, import anchors, queue/consumer RPCs and cron trigger, and link the implementation note. Do not edit the applied migration.

#### F-CLIENTS-3 — Missing Vault secrets silently disable the cron consumer
- Location: `supabase/migrations/20261008110000_create_client_import.sql:523-557`.
- Problem: If either `functions_base_url` or `internal_function_secret` is absent, `kick_client_import_consumer()` returns null without an actionable failure. The initial `EdgeRuntime.waitUntil` drain does not ensure that the cron safety net can consume queued work (`adjudication.md:76-81`).
- Fix: Add a deployment preflight that fails unless both named Vault secrets are configured; document production setup; surface missing configuration as an error or alert rather than a successful no-op; add a missing-secret test.

#### F-FE-1 — Browser import test does not exercise the specified 1,000-row volume
- Location: `apps/back-office/e2e/clients.spec.ts:130-170`.
- Problem: Browser import test uses four rows. The Edge Function/database tests cover 1,000 rows and 5% invalid, so the acceptance criterion is DONE; the remaining gap is the browser journey at scale (`adjudication.md:83-88`).
- Fix: Add a Playwright test uploading the 1,000-row fixture and asserting the dry-run 950-valid/50-invalid report and completed import summary, or document and enforce a separate UI scale test. Keep the small interaction test.

No blockers or majors were accepted. Rejected findings are listed above under “Deviations” and in `adjudication.md:90-101`; most notably, the all-branches manager/client visibility is consistent with ADR-11, and the Phase 5.3 calendar drawer is not a Phase 4 omission.

## Not verifiable locally

Production Vault values, cloud Edge Function deployment, and production cron/queue alerting cannot be verified using the local repository and stack. Before rollout, confirm both named Vault secrets are configured and demonstrate a successful deployed import-consumer/queue-drain check. This verifies the production configuration and addresses F-CLIENTS-3 (`adjudication.md:107-109`).

## Fix prompt

```text
Fix the phase 4 audit findings below in /Users/fahad/GlowDesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /supabase-database /supabase-edge-functions /react-frontend

1. F-DB-4.1-01: supabase/migrations - add a new migration replacing client_notes_update and client_notes_delete so each USING clause verifies that the matching parent client has the same tenant_id and is not deleted; preserve existing tenant, role, author and manager checks.
2. F-DB-4.1-02: supabase/migrations - add a new migration replacing clients_update and repeat the existing not is_deleted condition in WITH CHECK; preserve tenant and role checks.
3. F-DB-4.2-01: plan/parts/11-delivery-plan.md - amend the Subphase 4.2 Database work statement to list the client import batches/rows, import anchors, queue/consumer RPCs and cron trigger; link the existing implementation note. Do not change an applied migration.
4. F-CLIENTS-3: deployment configuration and import consumer - add a preflight that fails unless functions_base_url and internal_function_secret are present in Vault, document production setup, make missing configuration visible as an error or alert, and add a missing-secret test.
5. F-FE-1: apps/back-office/e2e/clients.spec.ts - add a browser test for the 1,000-row/5%-invalid fixture asserting 950 valid rows, 50 invalid rows with reasons, and the completed import summary. Retain the existing small interaction test.

Rules: never edit an applied migration; add new migrations. Keep both skill copies identical. Use Conventional Commits. Done = every gate in the audit passes again and each fixed acceptance criterion is demonstrated by a test.
```
