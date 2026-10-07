# Phase 6 audit report: checkout, sales and register

## Verdict

PASS

Phase 6 is complete against its local acceptance criteria, and all nine gates passed. The verifier accepted two minor findings and no blockers or majors: the receipt print CSS contains hardcoded font sizes, including 11px below the design skill's 12px minimum; and the `fn/` branch prefix used for Edge Function work is missing from the documented branch-prefix list. Neither finding leaves a phase deliverable or acceptance criterion unmet. The expected follow-up is small: use receipt typography tokens or document an approved print exception, and add `fn/<slug>` to the branch conventions. The authoritative verifier ruling is in `adjudication.md:7-9,46-56,66-69`.

| Phase area | Status |
|---|---|
| 6.1 Money data layer | Done |
| 6.2 Checkout function | Done |
| 6.3 Checkout UI | Done with fixes (one minor finding) |
| 6.4 Sales and register UI | Done |
| Phase-level exit criteria | Done; phase passes with two minor fixes |

## What was audited

The audit covered the full Phase 6 specification, including its four subphases, phase-level exit criteria and all locally runnable gates. The repository is `/Users/fahad/GlowDesk`, branch `feat/sales-register-ui`, commit `925f516ce9cdce2610ef7c43baa77e2b660663e3`. The audit date is 2026-10-07. The working tree is dirty: three modified files (`apps/back-office/src/features/calendar/lib/time.ts`, `apps/back-office/src/features/calendar/mappers.ts`, and `packages/i18n/src/format.ts`) and two untracked paths (`.pnpm-store/` and `.seed-pw`). The gate record says these changes predated the checks and that before/after status was identical (`gates/GATES.md:5-18,103-112`); a fresh read-only status check confirmed the same paths and commit.

The specification is `plan/parts/11-delivery-plan.md:1122-1294`. The verification also considered the governing ADRs and precedence described in `conformance.md:8-11,342-375`. No Playwright suite, database reset, or other stateful gate was rerun for this report; the gate logs were used as required (`adjudication.md:38-40`).

## Gates

All nine gates passed. The warnings-only database lint result is reported as a pass, not an error.

| Command | Result | Key detail and evidence |
|---|---|---|
| `pnpm install --frozen-lockfile` | PASS | Exit 0; already up to date (`gates/GATES.md:56-61`; `gates/pnpm-install.log`). |
| `pnpm db:reset` | PASS | Exit 0; 49 migrations applied and seed loaded (`gates/GATES.md:61`; `gates/db-reset.log`). |
| `pnpm db:test` | PASS | Exit 0; 36 files and 1,730 pgTAP tests passed (`gates/db-test.log:1-7`). The database audit identifies 417 Phase 6 pgTAP tests in files 029–035 (`database.md:103-117`). |
| `pnpm db:lint` | PASS, warnings only | Exit 0; warnings in four functions, no errors (`gates/db-lint.log:1-12`; `gates/GATES.md:63`). |
| Supabase generated-types diff | PASS | Exit 0; no type drift beyond cosmetic header/footer lines (`gates/GATES.md:64`; `gates/type-drift.log`). |
| `pnpm fn:test` | PASS | Exit 0; 9 Deno suites passed, 219 tests total; checkout suite 46 passed (`gates/fn-test.log:1-15`; `gates/GATES.md:70-84`). |
| `pnpm verify` | PASS | Exit 0; typecheck, lint, CSS lint, build and size checks passed; Vitest 74 files, 626 tests and 100% coverage (`gates/verify.log:1-12`). |
| `pnpm exec playwright test` | PASS | Exit 0; 128 passed, 64 English and 64 Arabic, zero failed (`gates/playwright.log:1-10`). |
| `pnpm db:reset` (final) | PASS | Exit 0; 49 migrations applied and seed loaded (`gates/GATES.md:68`). |

## Exit and acceptance criteria

### Phase-level exit criteria

All 11 criteria from `plan/parts/11-delivery-plan.md:1136` are DONE. The conformance report's prose says “13” at line 26, but its table lists the 11 clauses in the source plan and the verifier confirmed the count (`adjudication.md:15`; `conformance.md:577-594`).

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| Two-item appointment checkout with discount, tips and split payment completes with PREFIX-SEQ and reconciled totals | 6.3 | DONE | `apps/back-office/e2e/checkout.spec.ts:38-105`; verifier spot-check `adjudication.md:21`. |
| Repeating completion with the same idempotency key creates one sale | 6.2 | DONE | `apps/back-office/e2e/checkout.spec.ts:118-136`; `supabase/functions/checkout/handlers_test.ts:119-165`; `adjudication.md:22`. |
| Twenty parallel checkouts produce unique sequential invoice numbers | 6.1 | DONE | `supabase/functions/checkout/rpc_concurrency_test.ts:74-88`; `adjudication.md:24`. |
| Refund is manager-only and uses a positive amount | 6.2 | DONE | `apps/back-office/e2e/refund-void.spec.ts:61-119`; `supabase/tests/033_settle_refund_void.test.sql:98-149`; `adjudication.md:25`. |
| Cash refund without an open register is flagged | 6.1 | DONE | `supabase/tests/033_settle_refund_void.test.sql:98-149`; `adjudication.md:25`. |
| Money calculations match ADR-51 golden fixtures | 6.1 / 6.3 | DONE | `packages/core/src/checkout.test.ts:33-45`; parity tests and tampered-total rejection, `adjudication.md:23`. |
| Same-day void with a reason | 6.1 / 6.2 | DONE | `apps/back-office/e2e/refund-void.spec.ts:122-171`; `adjudication.md:26`. |
| Register opening and closing record cash difference | 6.4 | DONE | `apps/back-office/e2e/register.spec.ts:38-97`; `adjudication.md:27`. |
| Part-paid sale shows its balance and can be settled later | 6.3 | DONE | Checkout journey and settle coverage recorded in `frontend.md:84-91`; `conformance.md:277-280`. |
| Receipt prints in English and Arabic | 6.3 | DONE | `apps/back-office/e2e/receipt.spec.ts:139-219`; both locale projects ran, `gates/playwright.log:4-10`; `adjudication.md:28`. |
| Daily summary equals sales-list totals | 6.4 | DONE | `apps/back-office/e2e/daily-summary.spec.ts:15-84`; `adjudication.md:29`. |

### Subphase 6.1 acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| Out-of-session cash refunds have `register_session_id IS NULL` and are flagged in audit | DONE | pgTAP coverage in `database.md:103-117`; verifier review `adjudication.md:25,34`. |
| Twenty parallel checkouts produce 20 unique sequential numbers, with gaps only for failed transactions | DONE | Concurrency assertions `supabase/functions/checkout/rpc_concurrency_test.ts:74-88`; pgTAP sequence-race tests, `adjudication.md:24`. |
| Refunds are capped at the amount paid and receptionists are forbidden from refunds/voids | DONE | `supabase/tests/033_settle_refund_void.test.sql:98-149`; gate pgTAP results `gates/db-test.log:1-7`; `adjudication.md:25`. |

### Subphase 6.2 acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| Repeated completion with one idempotency key creates exactly one sale | DONE | `supabase/functions/checkout/handlers_test.ts:119-165`; `adjudication.md:22`. |
| Replay boundary is per function: same-function replay is cached and another function can use the same key independently | DONE | `plan/evidence/6.2/07-idempotency-across-actions.json:1-128`; wrapper key scope in `supabase/functions/_shared/server.ts:163-165`; `adjudication.md:22`. |
| Receptionists can check out but cannot refund or void | DONE | `supabase/functions/checkout/scope.ts:12-13`; `apps/back-office/e2e/refund-void.spec.ts:61-119`; `adjudication.md:25`. |

### Subphase 6.3 acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| Appointment checkout with two items, one line discount, tips for two staff and split cash/KNET completes with PREFIX-SEQ and reconciled totals | DONE | `apps/back-office/e2e/checkout.spec.ts:38-105`; `adjudication.md:21`. |
| Totals match ADR-51 fixtures and tampered client totals are rejected | DONE | `packages/core/src/checkout.test.ts:33-45`; `supabase/functions/checkout/handlers_test.ts:167-184`; `adjudication.md:23`. |
| Part-paid sale shows balance and settles later | DONE | Checkout and settlement acceptance coverage, `conformance.md:277-280`; frontend tests summarized in `frontend.md:84-91`. |
| Receipt prints in English and Arabic with the required content | DONE | `apps/back-office/e2e/receipt.spec.ts:139-219`; `gates/playwright.log:4-10`; `adjudication.md:28`. |

### Subphase 6.4 acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| Open register with 50 KWD, take cash sales, close with 180 KWD counted and record/show the difference | DONE | `apps/back-office/e2e/register.spec.ts:38-97`; `adjudication.md:27`. |
| Reject cash payments outside a session when branch configuration requires a register | DONE | `apps/back-office/e2e/register.spec.ts:99-134`; `adjudication.md:27`. |
| Daily summary matches sales-list totals for identical filters | DONE | `apps/back-office/e2e/daily-summary.spec.ts:15-84`; `adjudication.md:29`. |

## Plan checklist

Statuses below reflect the verifier's rulings. Full auditor inventories are in `conformance.md:65-341`, `backend.md:21-164`, `database.md:12-217`, and `frontend.md:30-171`.

### 6.1 Money data layer

| Plan area | Status | Verified scope |
|---|---|---|
| Features | DONE | Sales and sale-item tables, canonical payment ledger, tips, register sessions, tax rates, secured staff-sales reporting, transactional sale creation, balance settlement, refund, void, register open/close, currency lock and refund cap (`conformance.md:65-163`; `database.md:14-84`). |
| Database | DONE | Seven Phase 6 migrations, integer minor-unit money fields, RLS and select-only direct access, audit triggers, branch isolation and concurrency protections (`database.md:14-63,103-132`; `adjudication.md:30-34`). |
| Edge Functions | DONE / none in this subphase | The plan assigns no Edge Functions to 6.1; wrappers are in 6.2 (`plan/parts/11-delivery-plan.md:1155-1166`). |
| Screens | DONE / none in this subphase | The plan specifies no screens for 6.1 (`plan/parts/11-delivery-plan.md:1164-1166`). |
| i18n/RTL | DONE / not applicable | No user interface is specified for 6.1. |
| Tests | DONE | pgTAP files 029–035 and Deno RPC coverage; all 1,730 pgTAP tests passed (`database.md:103-117`; `gates/db-test.log:1-7`). |
| Backlog | DONE | All listed database migrations, triggers, secured reads, RPCs and database tests are implemented (`plan/parts/11-delivery-plan.md:1177-1183`; `conformance.md:152-163`). |

### 6.2 Checkout function

| Plan area | Status | Verified scope |
|---|---|---|
| Features | DONE | Create-sale, settle, refund, void, register-open/close, receipt-data assembly, validation, idempotency and scope enforcement (`backend.md:71-130,155-185`). |
| Database | DONE | Uses the 6.1 RPCs; no separate database deliverable is listed for this subphase (`plan/parts/11-delivery-plan.md:1187-1210`). |
| Edge Functions | DONE | All seven POST routes plus health route exist; live HTTP exercises returned the expected 200/400/401/403/404 outcomes (`backend.md:76-89,259-275`). |
| Screens | DONE / none in this subphase | 6.2 specifies the function layer, not screens (`plan/parts/11-delivery-plan.md:1187-1208`). |
| i18n/RTL | DONE / not applicable | No UI deliverable is specified for 6.2. |
| Tests | DONE | Nine Deno suites passed; checkout suite has 46 tests; replay, role denial, envelope and contract behavior are covered (`gates/fn-test.log:4-15`; `backend.md:277-298`). |
| Backlog | DONE | All checkout routes and contract/replay tests are present (`plan/parts/11-delivery-plan.md:1212-1216`; `backend.md:76-130`). |

### 6.3 Checkout UI

| Plan area | Status | Verified scope |
|---|---|---|
| Features | DONE | Appointment and walk-in cart, manual lines, discounts, staff tips, tax, split and part-paid payments, refund/void dialogs, and receipt view (`conformance.md:214-255`; `frontend.md:32-52`). |
| Database | DONE | Reads and money mutations use the audited 6.1/6.2 layer; ADR-28 direct-write restrictions are followed (`frontend.md:151-157`; `adjudication.md:34`). |
| Edge Functions | DONE | Money writes route through checkout Edge Function wrappers (`frontend.md:151-157`). |
| Screens | DONE | Cart, discounts/tips/tax, split payment, refund/void dialogs and receipt print view are delivered (`frontend.md:30-52`). |
| i18n/RTL | DONE | English and Arabic catalogs compile; RTL uses logical CSS properties and bidi isolation; receipt locale and print behavior are tested (`frontend.md:54-75`; `gates/verify.log:5-9`; `gates/playwright.log:4-10`). |
| Tests | DONE | Checkout journey, money fixtures, tamper rejection, part-paid settlement and bilingual receipt tests pass; 626 Vitest and 128 Playwright tests passed (`frontend.md:84-91`; `gates/verify.log:10`; `gates/playwright.log:4-10`). |
| Backlog | DONE | All five planned frontend deliverables are present (`plan/parts/11-delivery-plan.md:1249-1254`; `frontend.md:32-52`). |

### 6.4 Sales and register UI

| Plan area | Status | Verified scope |
|---|---|---|
| Features | DONE | Register cycle, sales list/detail, payments with method totals, daily summary, and client balance/history (`frontend.md:108-135`; `conformance.md:287-327`). |
| Database | DONE | Branch-scoped summary and client-balance reads and RLS-protected sales/payment reads are present (`backend.md:147-164`; `adjudication.md:32-34`). |
| Edge Functions | DONE / none required | The specified post-checkout reads use the documented RPC/direct-read model; no new Edge Function backlog is listed for 6.4 (`plan/parts/11-delivery-plan.md:1258-1285`). |
| Screens | DONE | Register, sales, payments, daily summary, client balance and client sales history screens are delivered (`frontend.md:108-135`). |
| i18n/RTL | DONE | User-facing strings are localized; feature CSS uses logical properties and bidirectional isolation (`frontend.md:137-149`). |
| Tests | DONE | Register day cycle, register-required cash handling and daily-summary reconciliation pass in the Playwright gates (`frontend.md:159-164`; `gates/playwright.log:4-10`). |
| Backlog | DONE | All six planned UI deliverables are present (`plan/parts/11-delivery-plan.md:1287-1293`; `frontend.md:110-135`). |

## Deviations

The conformance auditor recorded 12 declared implementation deviations in `REVISION_LOG.md` and the verifier accepted them as justified. Their complete list and source references are in `conformance.md:377-401`:

1. Store `business_date` on sales, payments and register sessions for day-boundary handling (`REVISION_LOG.md:250`).
2. Use a tenant-composite appointment foreign key, with branch matching checked in the sale RPC, so a voided appointment can move branches (`REVISION_LOG.md:251`; verifier ruling `adjudication.md:60`).
3. Reuse invoice numbers after refused sales roll back (`REVISION_LOG.md:252`).
4. Pass payments into `checkout_compute_totals` to compute paid, due and overpayment together (`REVISION_LOG.md:253`).
5. Return configuration refusals as 400 field errors mapped from SQLSTATE 55000 (`REVISION_LOG.md:265`).
6. Use the documented sale-line `type` field variants rather than the plan's `item_type` wording (`REVISION_LOG.md:266`).
7. Provide drawer feedback inline rather than with toasts (`REVISION_LOG.md:277`).
8. Start refunds from a payment row rather than the sale (`REVISION_LOG.md:278`).
9. Use a named `@page receipt` rule (`REVISION_LOG.md:279`).
10. Aggregate “all branches” by calling `report_daily_sales` for each branch (`REVISION_LOG.md:289`).
11. Add invoice-prefix/client search to the payments list (`REVISION_LOG.md:291`).
12. Test the currency lock in `daily-summary.spec` (`REVISION_LOG.md:295`).

No unjustified implementation deviation was accepted. One separate documentation gap is accepted as minor: `fn/checkout` was used, but `CONVENTIONS.md:195-199` lists only `feat/`, `fix/` and `db/` (`adjudication.md:52-56`).

## Findings

### Minor

#### F-FRONTEND-1: Receipt typography uses hardcoded font sizes

- Location: `apps/back-office/src/features/checkout/components/Receipt.module.css:30-33,51-55,99-103,113-117`; design floor: `.claude/skills/airbnb-design/SKILL.md:56-60`; available tokens: `packages/ui/src/tokens.css:47-58`.
- Problem: The receipt stylesheet hardcodes 15px, 16px, 11px and 14px. The 11px text is below the design skill's 12px minimum, and the values bypass typography tokens (`frontend.md:93-106`; `adjudication.md:46-50`).
- Fix: Replace 16px and 14px with the matching existing typography tokens; use a suitable token or define a receipt-specific token for 15px; replace 11px with a token at least 12px, or document and approve a print-only exception in the design skill and token source.
- Plan item: Subphase 6.3 receipt print view and project design system.

#### F-CONF-1: `fn/` branch prefix is missing from the documented conventions

- Location: `plan/CONVENTIONS.md:195-199`; branch inventory `gates/GATES.md:39-41`.
- Problem: Edge Function work used branch `fn/checkout`, but the branch naming rules do not list the `fn/` prefix (`adjudication.md:52-56`).
- Fix: Add `fn/<slug>` for Edge Function branches to the list in `plan/CONVENTIONS.md:197`.
- Plan item: Phase 6 process and conventions.

### Rejected findings

- F-DB-01, appointment foreign key omits `branch_id`: rejected as a defect. The migration documents the tenant-composite relationship, and `create_sale` checks that appointment and sale branches match (`adjudication.md:60`; migration `20261012100000_create_checkout_tables.sql:21-24,168-170`; `20261012100300_create_sale.sql:167-173`).
- F-DB-02, `register_session_totals` is executable by authenticated users: rejected as a security finding. It is `SECURITY INVOKER`, so reads remain subject to the session/payment RLS policies; the verifier found no plan requirement for service-role-only access (`adjudication.md:61`; migrations `20261012100500_register_rpcs.sql:187-219`, `20261012100000_create_checkout_tables.sql:533-594`).
- F-DB-03, `report_own_sales` is `SECURITY DEFINER`: rejected as a defect because it checks caller identity, membership, staff IDs and branch scope internally and revokes public/anon execution (`adjudication.md:62`; `20261012100600_checkout_reads.sql:19-57,84-85`).
- F-CONF-2, deviations are well documented: rejected as a finding because it describes a positive observation, not a defect (`adjudication.md:63`).
- F-BACKEND-1, no backend issues: rejected because a clean verdict is not a finding (`adjudication.md:64`).

Finding counts: 0 blockers, 0 majors, 2 accepted minors.

## Not verifiable locally

No Phase 6 acceptance criterion requires a cloud deployment, cloud-region check, uptime-monitor check or live Sentry verification. Those production-only operational checks were not run and are outside this local phase verdict. If the release process requires them, verify the deployment and telemetry in the target environment before go-live; the audit does not mark them as failed. The local test scope and phase criteria are recorded in `plan/parts/11-delivery-plan.md:1122-1294` and `adjudication.md:38-40`.

## Fix prompt

```text
Fix the phase 6 audit findings below in /Users/fahad/GlowDesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /react-frontend /airbnb-design

1. F-FRONTEND-1: apps/back-office/src/features/checkout/components/Receipt.module.css - replace the hardcoded 16px and 14px values with matching typography tokens; replace 15px with a suitable existing or receipt-specific token; replace 11px with a token of at least 12px, or document and approve a print-only exception in the design skill and token source.
2. F-CONF-1: plan/CONVENTIONS.md - add `fn/<slug>` for Edge Function branches to the branch-prefix list in section 8.

Rules: never edit an applied migration (add a new one); keep both skill copies identical; Conventional Commits. Done = every gate in the audit passes again and each fixed acceptance criterion is demonstrated by a test.
```
