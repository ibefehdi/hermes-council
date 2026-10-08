# Phase 7 audit report

## Verdict: FAIL

The verifier's verdict is FAIL, and my review confirms it. Phase 7 has substantial working report, search, export and security features, but it is not complete: the required timed staging backup-and-restore drill has not happened. Two major implementation gaps also remain. Full-tenant export leaves out tenant-owned data required for recovery/offboarding, and the hosted function setup does not document or configure the CORS allowlist needed by a deployed browser client. The fixes include one Ops-run staging drill and focused code, configuration and test changes; the audit does not estimate their duration. Subphases 7.1 and 7.2 are done, 7.3 is done with fixes, and 7.4 is incomplete.

| Subphase | Status |
|---|---|
| 7.1 Report data | Done |
| 7.2 Reports UI | Done |
| 7.3 Exports | Done with fixes |
| 7.4 Hardening | Incomplete |

## What was audited

The audit covers the full Phase 7 section, including all four subphases and the phase-level exit criteria, in `/Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md:1297-1473`. Binding decisions in `plan/decisions.md` take precedence over the plan, followed by `plan/PLAN.md`, `plan/CONVENTIONS.md` and the repository skills, as specified in the audit brief. The detailed verifier ruling is in `adjudication.md`; it supersedes earlier auditor classifications where noted below.

| Repository detail | Value |
|---|---|
| Path | `/Users/fahad/GlowDesk` |
| Branch | `main` |
| Commit | `6920a18b639906fa925eb20015c95740916b831c` |
| Working tree | Two untracked items, `.pnpm-store/` and `.seed-pw`; no tracked changes. The gate recorded the same state before and after its checks. |
| Audit date | 2026-10-08 (+03) |

## Gates

All 14 applicable gates passed. The export-volume benchmark was skipped because it requires production-like fixtures; the implementation and scheduled CI job exist, so the verifier classifies that measurement as NOT VERIFIABLE LOCALLY rather than a phase failure. The full gate record and raw logs are under `/Users/fahad/council/output/audit/phase-7/gates/`.

| Gate | Command | Result | Key detail |
|---|---|---|---|
| Frozen install | `pnpm install --frozen-lockfile` | PASS (exit 0) | Lockfile current; 631 entries. |
| Initial database reset | `pnpm db:reset` | PASS (exit 0) | 62 migrations applied; seed loaded. |
| pgTAP | `pnpm db:test` | PASS (exit 0) | 50 files; 2,073 tests passed. |
| Database lint | `pnpm db:lint --level warning` | PASS with warnings (exit 0) | 26 existing cast/type warnings in four checkout functions; no errors. |
| Type drift | `supabase gen types typescript --local` and diff | PASS (exit 0) | Generated types match committed types. |
| Deno function tests | `pnpm fn:test` | PASS after runtime restart (exit 0) | 10 suites; 255 tests passed. First attempt hit a local 503 BOOT_ERROR after reset; restarting the local stack resolved it. |
| Production dependency audit | `pnpm audit:prod` | PASS (exit 0) | Zero advisories, blocking, allowed or expired entries. |
| Frozen Deno lock pins | `pnpm fn:pins` | PASS (exit 0) | 10 function configs and lockfiles; zero problems. |
| Function config guard | `pnpm fn:config` | PASS (exit 0) | Eight functions; zero problems. |
| Matrix tags | `pnpm db:matrix-tags` | PASS (exit 0) | 309 of 309 allowed cells tagged; zero invalid tags. |
| Function typecheck | `pnpm fn:check` | PASS (exit 0) | All functions check clean. |
| Full verification | `pnpm verify` | PASS (exit 0) | 91 Vitest files, 722 tests, 100% reported coverage; typecheck, lint, CSS lint, i18n compile, build and size limits passed. Initial JS 238.47 kB (<250 kB); calendar 80.85 kB (<150 kB); report chunks 13.13 kB (<14 kB). |
| Playwright | `pnpm exec playwright test` | PASS (exit 0) | 196 passed: 98 English and 98 Arabic; zero failures. |
| Final database reset | `pnpm db:reset` | PASS (exit 0) | 62 migrations applied; seeded DB restored for subsequent audit work. |
| Export volume and performance benchmarks | `perf:*` scripts | SKIPPED | >100k-client production-like fixture required; scheduled in `.github/workflows/perf-volume.yml`. NFR-10 timing is NOT VERIFIABLE LOCALLY. |

`GATES.md` reports that repository status before and after the gates was identical. No Playwright or stateful checks were rerun for this synthesis.

## Exit and acceptance criteria

Phase exit criteria are shown first. Statuses reflect the verifier's overrides, not the earlier auditor summaries.

| Phase exit criterion | Status | Evidence |
|---|---|---|
| Home shows correct role-scoped numbers using branch-local days. | DONE | `apps/back-office/e2e/home.spec.ts:40-60,85-95`; branch-local bounds use ADR-45. |
| Each report reconciles to hand-computed fixtures in fils in both locales. | DONE | `supabase/tests/036_reports_fixture.test.sql` through `040_report_taxes_home.test.sql`; English and Arabic Playwright gate, `GATES.md:41,67-75`. |
| Branch managers see only their branches' numbers. | DONE | `database.md:110-175`; scope assertions in tests 037-040. |
| Exports are BOM-prefixed and role-scoped. | DONE WITH FIXES | `apps/back-office/e2e/exports.spec.ts:28-45,73-104`; full-tenant coverage remains incomplete (F-DB-02). |
| Audit viewer shows actor, action, entity, branch and time; records are immutable. | DONE | `supabase/tests/041_audit_reads.test.sql:31-50`; `apps/back-office/e2e/audit.spec.ts:55-80`. |
| Global search finds clients, appointments and sales. | DONE | `apps/back-office/e2e/appointment-search.spec.ts:94-127`. |
| Accessibility audit finds zero serious axe violations. | DONE | `apps/back-office/e2e/a11y.spec.ts:13-20,45-76`; Playwright gate passed. |
| pgTAP matrix covers every table/operation/role. | DONE | `supabase/tests/045_matrix_sweep.test.sql:1-17,57-80`; `GATES.md:38` reports all 309 tags passing. |
| Backup/restore drill is completed. | PARTIAL — FAIL trigger | `plan/evidence/7.4/restore-drill.md:3-29` says staging is pending and leaves the timed table blank. The local seven-second rehearsal at `:34-63` is not staging evidence. Phase criterion: `11-delivery-plan.md:1311`; 7.4 criterion: `:1458`. |

Subphase acceptance criteria:

| Subphase | Criterion | Status | Evidence |
|---|---|---|---|
| 7.1 | Reports match hand-computed seeded-branch fixtures to the fils in both locales, including correct branch-local day boundaries. | DONE | Tests 036-040; `GATES.md:41,67-75`. Test 036 checks a 23:30 UTC sale against Kuwait local date. |
| 7.1 | Fixtures cover a multi-sale client and a service sold through sale items; summary and top-services calculations match. | DONE | `supabase/tests/036_reports_fixture.test.sql:17-43,45-67`, `037_report_sales_payments.test.sql:68-99`; `database.md:154-171`. |
| 7.1 | Midnight and daylight-saving boundaries pass for daily metrics. | DONE | Test 036 plus report fixture coverage in tests 038-040. |
| 7.1 | Branch managers see only their branches; receptionists see only the daily summary. | DONE | Role-scope assertions in tests 037-040; `database.md:91-97,136-147`. |
| 7.2 | Home shows correct seeded-fixture numbers in both locales, scoped by role and branch-local day. | DONE | `apps/back-office/e2e/home.spec.ts:40-60,85-95`; 196 bilingual Playwright tests passed. |
| 7.2 | Each report screen reconciles with underlying report data. | DONE | `reports-money.spec.ts:31-80` and `reports-operations.spec.ts:42-70,72-106`; details in `frontend.md:58-83`. |
| 7.2 | Audit view exposes actor/action/entity/branch/time; rows cannot be edited or deleted. | DONE | `audit.spec.ts:55-80`; database immutability in `041_audit_reads.test.sql:31-50`. |
| 7.2 | Global search finds an Arabic-named client, an appointment by reference and a sale by invoice. | DONE | `appointment-search.spec.ts:94-127`. |
| 7.3 | BOM CSV opens with Arabic text. | DONE | `apps/back-office/e2e/exports.spec.ts:28-45`; the test asserts the UTF-8 BOM bytes. |
| 7.3 | Full-tenant export of the benchmark fixture completes within ten minutes; no invocation exceeds its wall limit. | NOT VERIFIABLE LOCALLY | `GATES.md:43`; >100k-client fixture is unavailable locally and the scheduled job is `.github/workflows/perf-volume.yml`. Do not treat this as a failure. |
| 7.3 | A killed mid-run export resumes from the last completed slice. | DONE | `supabase/functions/reports/export_resume_test.ts:23-55`; raw test evidence `gates/06-fntest.log:588`. |
| 7.3 | Every export writes an audit record. | DONE WITH FIXES | Export job request/completion/download audit path verified in `backend.md:76-78,97`; however, `record_export` accepts caller-controlled audit fields (F-DB-03). |
| 7.3 | A manager's contacts export is forbidden and aggregate exports contain no allergy details. | DONE | `exports.spec.ts:73-104`; `report_csv_test.ts:162-172`; live role evidence `database.md:128-147`. |
| 7.4 | Matrix has no uncovered relation/operation/role cells and CI enforces it. | DONE | Test 045 and `GATES.md:38`; `database.md:173-175`. |
| 7.4 | Accessibility has zero serious axe violations and calendar/checkout are keyboard-complete. | DONE | `a11y.spec.ts:13-20,45-76`; `keyboard.spec.ts:43-119`; Playwright passed. |
| 7.4 | Timed staging-snapshot restore finishes within four-hour RTO. | PARTIAL — FAIL trigger | Staging run is pending; no timings or smoke/reconciliation artifacts in `restore-drill.md:3-29`. |
| 7.4 | Performance benchmarks re-pass NFR-4/5. | DONE for locally evidenced budgets; export-volume timing NOT VERIFIABLE LOCALLY | `plan/evidence/7.4/perf.md:7-19`; NFR-10 volume run was skipped (`GATES.md:43`). |

## Plan checklist

Statuses below include verifier overrides. The phase plan's required sections are represented under each subphase, including sections with no deliverable. The cited auditor reports provide additional file-level detail.

### Subphase 7.1: Report data

| Plan section | Checklist item | Status and evidence |
|---|---|---|
| Features | Seven report views/RPCs plus Phase 6 `report_own_sales`; explicit security-invoker access and grants. | DONE. Migrations listed in `database.md:21-38`; pgTAP catalog guards in test 042. |
| Features | Branch-local grouping and timezone conversion per ADR-45; F-DB-8 service joins and per-client pre-aggregation; view-audit CI. | DONE. `conformance.md:59-63`; tests 036-042. |
| Database work | Report RPC/view migrations and indexes. | DONE. `database.md:25-36`. |
| Database work | Branch-local, multi-sale, service-item, midnight and DST reconciliation fixtures, with per-role scope assertions. | DONE. Tests 036-040; `database.md:154-171`. |
| Edge Functions | None required by the plan. | N/A, consistent with plan `11-delivery-plan.md:1340`. |
| Screens | None required by the plan. | N/A, consistent with plan `:1342`. |
| i18n/RTL | No 7.1-specific UI requirement. | N/A. Report UI localization is covered in 7.2. |
| Tests | SQL fixture-based report reconciliation and scope tests. | DONE. `GATES.md:31` records 2,073 pgTAP tests passing; tests 036-042 cover the specified fixtures and grants. |
| Dependencies | Phase 6 sales/payments and Phase 5 appointments data. | DONE. Required source data exists; reports reconcile on seeded fixtures (`database.md:154-171`). |
| Backlog | Report migrations/RPCs/indexes; taxes report; F-DB-8 fixes; branch-local fixtures; CI view audit; per-role pgTAP scope. | DONE. Evidence above and in `conformance.md:56-70`. |

### Subphase 7.2: Reports UI

| Plan section | Checklist item | Status and evidence |
|---|---|---|
| Features | Home/today default route, role-scoped appointments and sales, no-show count, upcoming visits, branch-local day. | DONE. `frontend.md:40-56`; `home.spec.ts:40-60,85-95`. |
| Features | Reports framework with date presets, role-scoped branch filter, CSV action and generic filters. | DONE. `frontend.md:22-38`. |
| Features | Seven report screens, daily-sales link, audit viewer and global search for clients/appointments/sales. | DONE. `frontend.md:58-114`. |
| Database work | No new database deliverables specified for 7.2; it depends on 7.1 report data. | DONE as scoped. Report data and authorization are covered under 7.1 (`database.md:63-67,91-97`). |
| Edge Functions | No new Edge Function required; typed API wrappers are used for export calls. | DONE. `backend.md:30-34`; `packages/api/src/client.ts:309-322`. |
| Screens | Home, reports hub and seven report screens, audit screen and global search palette. | DONE. Routes and component evidence in `frontend.md:22-114`. |
| i18n/RTL | English and Arabic labels, RTL layouts, branch-local formatting and isolated mixed-direction text. | DONE. `frontend.md:193-223`; strict i18n compilation passed in `GATES.md:40`. |
| Tests | Playwright covers home, each report, audit and search in both locales. | DONE. `GATES.md:41,72-75`: 196 passed (98 per locale); test inventory in `frontend.md:253-271`. |
| Dependencies | 7.1 report views/RPCs. | DONE. Backed by the report data and role checks above. |
| Backlog | Home, report framework, six named reports plus taxes, audit viewer and global search. | DONE. `frontend.md:22-114`; no remaining frontend finding. |

### Subphase 7.3: Exports

| Plan section | Checklist item | Status and evidence |
|---|---|---|
| Features | Queued CSV generation, UTF-8 BOM, streaming, export UX, role scope and audit events. | DONE WITH FIXES. BOM and route tests passed (`exports.spec.ts:28-45,73-104`; `backend.md:82-97`); full-tenant contents are incomplete (F-DB-02), and report-export audit inputs need hardening (F-DB-03). |
| Features | Full-tenant chunked/resumable export. | DONE WITH FIXES. Queue, slices, retry and download are exercised (`backend.md:74-109`), but the advertised full export omits 11 tenant-owned entities and ADR-50's settings JSON dump (F-DB-02). |
| Database work | Export jobs/parts, queue, slice builders and purge cron. | DONE. `database.md:25-36`; `supabase/tests/044_export_jobs.test.sql`; `backend.md:76-78`. Two child-table foreign keys do not enforce tenant consistency as ADR-20 requires (F-DB-01). |
| Edge Functions | `reports/export` and associated full-tenant job/download routes. | DONE WITH FIXES. Routes and served end-to-end flow in `backend.md:49-63,80-109`; hosted CORS configuration is a major setup defect (F-backend-2). |
| Screens | Export progress and download UX. | DONE. `frontend.md:118-134`; Playwright export page checks passed. |
| i18n/RTL | CSV handles Arabic, and export UI follows bilingual/RTL framework. | DONE. Arabic CSV/BOM probes in `backend.md:82-97`; bilingual UI evidence in `frontend.md:193-223,269-271`. |
| Tests | Export tests cover role rules, BOM, idempotency, recovery and downloads; benchmark suite also required. | Functional tests DONE; export-volume benchmark NOT VERIFIABLE LOCALLY. Suites pass (`supabase/tests/043_record_export.test.sql`, `044_export_jobs.test.sql`, `export_resume_test.ts`, `export_download_test.ts`); gate skipped the volume benchmark (`GATES.md:43`). |
| Dependencies | 7.1 report data and 7.2 export-button wiring. | DONE. Report RPCs and UI are present and exercised (`backend.md:18-34`; `frontend.md:120-134`). |
| Backlog | Edge export route, chunked full-tenant job and progress/download UX. | DONE WITH FIXES. See feature, data coverage and test statuses above. |

### Subphase 7.4: Hardening

| Plan section | Checklist item | Status and evidence |
|---|---|---|
| Features | Full pgTAP matrix; realtime authorization sweep; NFR performance results; WCAG/keyboard review; rate-limit review; dependency audit. | DONE. Matrix: `database.md:173-175`; realtime test 046 (`database.md:167-171`); NFR results `plan/evidence/7.4/perf.md:7-19`; accessibility `a11y.spec.ts` and `keyboard.spec.ts`; rate-limit evidence `backend.md:123-124`; zero audit advisories `GATES.md:35`. |
| Features | Backup/restore runbook, smoke subset, script and timed staging restore; PITR documented for Phase 8 verification. | PARTIAL. Local rehearsal and tooling exist, but the required timed staging drill has not run (`restore-drill.md:3-29,34-63`). PITR and RPO/RTO are documented for Phase 8 under ADR-49 (`plan/decisions.md:408-414`). |
| Database work | Matrix sweep over every table, operation and role. | DONE. Test 045 evaluates 1,512 cells; coverage guard and tags passed (`database.md:173-175`, `GATES.md:38`). |
| Edge Functions | Rate-limit/config review and dependency checks; no new user-facing function deliverable. | DONE for reviewed configuration and CI checks. `backend.md:123-126`; `GATES.md:35-40`. The separately identified hosted-origin configuration omission remains F-backend-2. |
| Screens | None new; existing MVP screens receive accessibility review. | DONE. Axe and keyboard suites passed (`frontend.md:138-151,253-271`). |
| i18n/RTL | RTL visual sweep. | DONE. `frontend.md:146-149`; both English and Arabic Playwright projects passed (`GATES.md:72-75`). |
| Tests | Matrix pgTAP, axe/keyboard Playwright, benchmark suite and checkout/booking load tests. | DONE for locally evidenced matrix, accessibility and NFR-4/5 performance; full-tenant NFR-10 volume benchmark is NOT VERIFIABLE LOCALLY; staging restore acceptance remains PARTIAL. Evidence: `GATES.md:31,41,43`; `plan/evidence/7.4/perf.md:7-19`; `restore-drill.md:3-29`. |
| Dependencies | 7.1–7.3 features exist for the hardening pass. | DONE. The prerequisite feature sets are present; 7.3 has the accepted coverage/audit/config findings documented above. |
| Backlog | NFR benchmark CI, backup/restore drill, matrix sweep, WCAG/RTL sweep, dependency audit/rate review, production backup/PITR documentation. | DONE except the timed staging drill, which is PARTIAL and blocks completion. NFR-10 timing remains NOT VERIFIABLE LOCALLY. Source checklist: `11-delivery-plan.md:1465-1471`; evidence cited above. |

## Deviations

| Item | Ruling | Reason |
|---|---|---|
| Export-volume benchmark skipped in the local gate. | NOT VERIFIABLE LOCALLY; not a finding or verdict trigger. | The benchmark requires >100k clients and is wired to scheduled CI. This limitation is recorded in `GATES.md:43` and the conformance evidence. |
| Staging restore drill deferred to Ops. | Not an allowed phase deviation; the acceptance item remains PARTIAL and triggers FAIL. | `restore-drill.md:3-5` documents the pending run, but plan 7.4 explicitly requires a timed staging restore (`11-delivery-plan.md:1449,1458`). ADR-49 moves the production-snapshot/PITR check to Phase 8, not the staging drill (`decisions.md:411-414`). |
| Full-tenant export omits tenant data and ADR-50 settings JSON. | Undeclared implementation gap; accepted as major F-DB-02. | The migration's file list is incomplete against tenant-owned tables and ADR-50's offboarding contract (`20261014100100_export_jobs.sql:165-168`; `decisions.md:416-420`). |
| Hosted CORS origin variable absent from setup documentation. | Undeclared configuration gap; accepted as major F-backend-2. | The function code only allows localhost by default (`cors.ts:1,13-30`); `.env.example:1-14` and staging deployment command `staging-deploy.md:44-48` omit `ALLOWED_ORIGINS`. |
| Export child foreign keys omit tenant consistency. | ADR-20 deviation; accepted as minor F-DB-01. | `export_parts` and `export_download_tokens` use simple job-id foreign keys (`20261014100100_export_jobs.sql:57-79`), although ADR-20 rule 5 requires tenant-composite references (`decisions.md:284`). Current deny-all RLS/revokes reduce exposure but do not satisfy the convention. |
| Export audit event accepts caller-supplied count and filters. | Audit-integrity gap; accepted as minor F-DB-03. | `record_export` is callable by authenticated users and records caller-provided `p_row_count` and `p_filters` (`20261014100000_report_exports.sql:67-105`). |
| Commit messages and integration branch naming. | Undeclared convention violations; accepted as minor F-PROC-1 and F-PROC-2. | The commit subjects violate Conventional Commits (`conformance.md:5-23`). The branch does not follow the required feature prefix; unlike the earlier report, `origin/phase-7-pre-council` still exists (`adjudication.md:17-18`; independently confirmed by `git branch -r`). |

## Findings

The verifier accepted eight findings: three major and five minor. No blocker was accepted.

### Major findings

#### F-BACKUP-1: Required timed staging restore drill is still pending

- Severity: major.
- Location: `/Users/fahad/GlowDesk/plan/evidence/7.4/restore-drill.md:3-29`; requirement in `plan/parts/11-delivery-plan.md:1311,1449,1458`.
- Problem: The evidence record says the staging run is pending and its timing, smoke and reconciliation results are blank. A separate seven-second local rehearsal (`restore-drill.md:34-63`) does not demonstrate a restore from a staging snapshot to scratch within the four-hour RTO. This is an explicit Phase 7 acceptance and exit criterion.
- Evidence: `restore-drill.md:3-5,21-29` marks the staging run pending and leaves the clock table empty. ADR-49 moves only the production-snapshot/PITR verification to Phase 8 (`plan/decisions.md:413`).
- Fix: Run `docs/runbooks/backup-restore.md` against a staging snapshot restored to a scratch project. Attach `timings.tsv`, smoke output, `report.diff` and `counts.diff`, then fill the staging table in `plan/evidence/7.4/restore-drill.md` with the measured total and result.
- Plan item: Phase 7 exit criterion; subphase 7.4 timed staging drill (NFR-14 / ADR-49 R16).

#### F-DB-02: Full-tenant export omits 11 tenant-owned datasets and settings dump

- Severity: major (raised from minor by the verifier).
- Location: `supabase/migrations/20261014100100_export_jobs.sql:165-168`; omitted-table inventory in `database.md:215-222`.
- Problem: The `full_tenant` export is advertised for restore/offboarding but omits `service_branch_overrides`, `service_staff`, `booking_overrides`, `closed_periods`, `branch_opening_hours`, `cancellation_reasons`, `blocked_time_types`, `settings`, `invoice_counters`, `memberships` and `profiles`. ADR-50 also requires a JSON settings dump. An 18-file assertion and a client-file read do not prove that all required data is present (`apps/back-office/e2e/exports.spec.ts:47-70`).
- Evidence: The current file list is in migration lines 165-168; the complete omitted entity list is cross-checked in `database.md:215-222`. ADR-50 specifies CSV plus a JSON settings dump (`plan/decisions.md:416-420`).
- Fix: Add a new migration that extends the full-tenant file list, CSV headers and slice builders for every omitted entity, and emits the ADR-50 settings JSON dump. Add tests that assert each required table/configuration is present and verify the exported row contents. Do not modify the applied migration.
- Plan item: Subphase 7.3 full-tenant export, export acceptance and ADR-43; ADR-50 offboarding contract.

#### F-backend-2: Hosted function CORS allowlist is absent from deployment setup

- Severity: major (raised from minor by the verifier).
- Location: `supabase/functions/_shared/cors.ts:1,13-30`; `supabase/functions/.env.example:1-14`; `docs/runbooks/staging-deploy.md:44-48`.
- Problem: If `ALLOWED_ORIGINS` is unset, the function only returns its CORS allow-origin header for the two localhost origins. The committed environment example and staging deployment command do not tell operators to configure the deployed SPA origin. A hosted browser client can therefore fail CORS checks when invoking the function. No hosted deployment was available for inspection; this finding concerns the verified code and deployment instructions, not an observed production outage.
- Evidence: Code reads `ALLOWED_ORIGINS` and otherwise uses localhost defaults (`cors.ts:1,13-30`); it returns no CORS headers for a disallowed origin. The variable is absent from the example and staging command cited above. Supabase's browser-invocation guidance says browser-invoked Edge Functions need CORS handling on preflight and responses: https://supabase.com/docs/guides/functions/cors (accessed 2026-10-08).
- Fix: Document `ALLOWED_ORIGINS` in `supabase/functions/.env.example`, the staging and production runbooks, and hosted deployment commands, with the actual deployed SPA origin(s) supplied per environment. Add tests asserting CORS headers for an allowed hosted origin and no allow-origin header for a rejected origin.
- Plan item: Subphase 7.3 Edge Function/config deliverable; backend configuration contract.

### Minor findings

#### F-DB-01: Export child tables lack composite tenant-consistency foreign keys

- Severity: minor.
- Location: `supabase/migrations/20261014100100_export_jobs.sql:57-79`; ADR-20 rule 5 at `plan/decisions.md:284`.
- Problem: `export_parts` and `export_download_tokens` have no `tenant_id` and reference `export_jobs(id)` with simple foreign keys, not `(id, tenant_id)`. Their RLS-deny-all policies and revoked grants currently constrain access but do not meet the binding tenant-FK rule.
- Evidence: Child definitions at migration lines 57-79; verifier confirmed RLS/revoke controls at `adjudication.md:14`.
- Fix: In a new migration, add `tenant_id` to both child tables, add composite `(job_id, tenant_id)` references to `export_jobs(id, tenant_id)`, and update definer writers to pass the owning job's tenant id. Add a constraint test.
- Plan item: ADR-20 rule 5.

#### F-DB-03: Authenticated caller can choose export audit count and filters

- Severity: minor.
- Location: `supabase/migrations/20261014100000_report_exports.sql:67-105`.
- Problem: The SECURITY DEFINER `record_export` function accepts caller-provided `p_row_count` and `p_filters` and grants authenticated execution. Scope validation confirms permission to export, but does not make those audit values truthful.
- Evidence: Function arguments and writes at migration lines 67-89; authenticated grant at lines 104-105; adjudication at `adjudication.md:15`.
- Fix: Revoke authenticated direct execution and have the reports Edge Function write the audit event through the server-side path using the verified actor and server-computed filters/count. Add a test that a direct authenticated call is denied and a server-created event records the actual count.
- Plan item: ADR-22 audit integrity and ADR-28 write allowlist.

#### F-backend-1: Untracked `.seed-pw` file is not ignored

- Severity: minor.
- Location: `/Users/fahad/GlowDesk/.seed-pw`; `.gitignore:1-17`.
- Problem: The untracked file is not covered by `.gitignore`, so a broad add could stage it. The gate report says it pre-existed and was unchanged; its value is intentionally not reproduced here.
- Evidence: `GATES.md:5-11,76-78`; verifier ruling `adjudication.md:16`.
- Fix: Add `.seed-pw` to `.gitignore` and determine whether any script still needs the file before documenting its creation.
- Plan item: Backend configuration/secrets hygiene.

#### F-PROC-1: Two commit subjects violate Conventional Commits

- Severity: minor.
- Location: commits `04619bbd1bb97e525ca0ba5523e11c24c8fa5256` and `6cf9f9e482ead845b5171b427e5680fe85640362`; `plan/CONVENTIONS.md:199`.
- Problem: Both commits use the free-form subject `new workflow`, not the required `type(scope): subject` format.
- Evidence: `git log` confirmed both exact subjects; `adjudication.md:17`.
- Fix: Add a CI commit-message guard and require the documented format for future commits. Do not rewrite already-merged main history as the default remediation.
- Plan item: `plan/CONVENTIONS.md:199`.

#### F-PROC-2: Phase integration branch name violates the feature-branch convention

- Severity: minor.
- Location: `phase-7-pre-council`; remote tracking ref `origin/phase-7-pre-council`; branch convention in `plan/CONVENTIONS.md:197`.
- Problem: The branch name lacks the required `feat/<area>-<slug>` prefix. Earlier auditor evidence said the remote ref was gone; a read-only branch query confirmed that `origin/phase-7-pre-council` still exists. The merge commit `c9bcafe` identifies the source branch as `ibefehdi/phase-7-pre-council`.
- Evidence: `git branch -r --list '*phase-7-pre-council*'` returned `origin/phase-7-pre-council`; `git show -s --format='%D' c9bcafe`; adjudication correction at `adjudication.md:18`.
- Fix: Confirm whether the remote branch is still used. If so, rename it to `feat/phase-7-pre-council`; otherwise retire the obsolete remote ref after confirming it is unused. Use the required naming convention for future branches.
- Plan item: `plan/CONVENTIONS.md:197`.

### Rejected or corrected classifications

- F-PERF-1, the >100k export benchmark, is NOT VERIFIABLE LOCALLY, not a defect and not a verdict trigger. The gate skipped it for production-like fixture requirements and the scheduled benchmark workflow exists (`GATES.md:43`; `adjudication.md:22`).
- No additional cross-tenant/branch leakage finding was added: the verifier confirmed the database auditor's 19 rejected attack vectors and matrix evidence (`database.md:110-175`; `adjudication.md:31`).

## Not verifiable locally

- The >100k-client/1M-appointment full-tenant export benchmark and its ten-minute budget. The benchmark requires a production-like fixture, was skipped by the local gate and is scheduled in `.github/workflows/perf-volume.yml` (`GATES.md:43`; `conformance.md:42-48`). Run it in the fixture-capable CI environment and preserve the timing evidence before relying on NFR-10.
- Staging/production deployments, live hosted CORS behavior, Sentry delivery and uptime monitoring were not available for local inspection. Verify them in the hosted environments after applying the configuration fix. The pending staging restore drill is not classified as merely not verifiable: it is an explicit Phase 7 requirement with a missing local evidence record, so it remains a failure trigger.

## Fix prompt

```text
Fix the Phase 7 audit findings below in /Users/fahad/GlowDesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /supabase-database /supabase-edge-functions

1. F-BACKUP-1: Run docs/runbooks/backup-restore.md against a staging snapshot restored to a scratch project. Attach timings.tsv, smoke output, report.diff and counts.diff; fill plan/evidence/7.4/restore-drill.md with the measured steps and total RTO.
2. F-DB-02: Add a new migration extending the full_tenant export to include service_branch_overrides, service_staff, booking_overrides, closed_periods, branch_opening_hours, cancellation_reasons, blocked_time_types, settings, invoice_counters, memberships and profiles, plus the ADR-50 JSON settings dump. Extend headers/slice builders and test every exported entity and setting.
3. F-backend-2: Configure and document ALLOWED_ORIGINS in supabase/functions/.env.example and staging/production runbooks and deployment commands, with each hosted SPA origin. Test allowed and rejected hosted origins.
4. F-DB-01: In a new migration, add tenant_id to export_parts and export_download_tokens, add composite (job_id, tenant_id) foreign keys to export_jobs(id, tenant_id), update definer writers and test the constraint.
5. F-DB-03: Remove authenticated direct execution of record_export; have the reports Edge Function record server-computed filters/count and verified actor. Test direct-call denial and the accurate server path.
6. F-backend-1: Add .seed-pw to .gitignore and determine whether a script still needs it.
7. F-PROC-1: Add a CI Conventional Commit message guard; use compliant commit subjects going forward without rewriting already-merged history by default.
8. F-PROC-2: Confirm whether origin/phase-7-pre-council remains in use; rename it to feat/phase-7-pre-council or retire it if obsolete, and use the required convention for future branches.

Rules: Never edit an applied migration; add a new migration. Keep both skill copies identical. Use Conventional Commits. Done = every gate in this audit passes again and each fixed acceptance criterion is demonstrated by a test.
```

## Finding summary

| ID | Severity | Title |
|---|---|---|
| F-BACKUP-1 | Major | Required timed staging restore drill is pending |
| F-DB-02 | Major | Full-tenant export omits tenant-owned datasets and settings dump |
| F-backend-2 | Major | Hosted function CORS allowlist is missing from deployment setup |
| F-DB-01 | Minor | Export child tables lack composite tenant-consistency foreign keys |
| F-DB-03 | Minor | Authenticated caller can choose export audit count and filters |
| F-backend-1 | Minor | Untracked `.seed-pw` file is not ignored |
| F-PROC-1 | Minor | Two commit subjects violate Conventional Commits |
| F-PROC-2 | Minor | Phase integration branch name violates convention |
| **Counts** | **Blocker 0; Major 3; Minor 5** | **Eight accepted findings** |