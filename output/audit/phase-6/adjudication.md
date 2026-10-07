# Phase 6 verifier adjudication

Date: 2026-10-07
Repository: `/Users/fahad/GlowDesk`
Branch and commit: `feat/sales-register-ui`, `925f516ce9cdce2610ef7c43baa77e2b660663e3`

## Verdict: PASS

The implementation meets the phase 6 requirements and all locally runnable gates passed. The phase has two accepted minor findings: receipt typography uses hardcoded sizes, including 11px despite the design skill's 12px minimum, and the `fn/` branch prefix used for Edge Function work is missing from the documented branch-prefix list. There are no accepted blocker or major findings, no failed gates, and no unmet acceptance or phase exit criteria.

## Inputs and completeness

Read the four auditor files required by the verifier brief: `database.md`, `backend.md`, `frontend.md`, and `conformance.md`, alongside `gates/GATES.md`. All four auditor files are present and cover their assigned areas; the conformance report enumerates all four subphases (6.1–6.4) and lists every phase exit criterion. The auditors' handoffs also appear on blackboard task `t_3853df6a`.

The phase specification at `plan/parts/11-delivery-plan.md:1122-1294` contains four subphases. The phase header's exit criterion at line 1136 has 11 clauses (confirmed against the source text); the conformance report's line 26 calls this 13, which is a counting error, but its actual exit-criteria table at lines 577-594 lists all 11 and marks each DONE. Subphase acceptance criteria are covered in the conformance checklist and the area reports. No criterion was found missing or incorrectly marked.

## Independent evidence checks

All 11 phase exit criteria were checked against their named tests and source evidence, including:

- The complete two-item, discount, two-staff-tip, split cash/KNET flow and its invoice/totals assertions: `apps/back-office/e2e/checkout.spec.ts:38-105`.
- Duplicate-safe completion: `apps/back-office/e2e/checkout.spec.ts:118-136`; function-level replay and changed-payload rejection: `supabase/functions/checkout/handlers_test.ts:119-165`. Per-function key scoping is also demonstrated by the same key succeeding independently for settle and refund, then replaying each action separately: `plan/evidence/6.2/07-idempotency-across-actions.json:1-128`; the wrapper includes the function/action in its key scope (`supabase/functions/_shared/server.ts:163-165`).
- Money calculations: 20 fixtures are individually checked against expected totals and line values (`packages/core/src/checkout.test.ts:33-45`); the 1-fil tampered total is rejected without a write (`supabase/functions/checkout/handlers_test.ts:167-184`).
- Twenty concurrent invoice sequences: `supabase/functions/checkout/rpc_concurrency_test.ts:74-88` verifies 20 calls, exact sequential values, unique stored rows, and matching invoice numbers.
- Refund/void role enforcement and out-of-session cash-refund handling: `apps/back-office/e2e/refund-void.spec.ts:61-119`; underlying role, positive-ledger, cap, and audit assertions: `supabase/tests/033_settle_refund_void.test.sql:98-149`.
- Same-day void and re-checkout: `apps/back-office/e2e/refund-void.spec.ts:122-171`.
- Register opening, cash-up, stale-count refusal, and stored difference: `apps/back-office/e2e/register.spec.ts:38-97`; cash handling with the register-required rule: lines 99-134.
- Receipt content, RTL/language attributes, and payment/refund content: `apps/back-office/e2e/receipt.spec.ts:139-219` (the test is run in both locale projects according to `gates/playwright.log:4-10`).
- Daily summary and sales-list reconciliation: `apps/back-office/e2e/daily-summary.spec.ts:15-84`.
- Table grants and RLS: `supabase/tests/029_checkout_matrix.test.sql:81-126`; branch/tenant/role checks and register privileges: `supabase/tests/034_register.test.sql:66-101`.

The above spot checks cover the acceptance criteria across all four subphases. The conformance checklist contains 87 DONE rows; more than 30% were sampled by opening the cited source and evidence, including the migration definitions and RLS at `supabase/migrations/20261012100000_create_checkout_tables.sql:64-100, 113-170, 518-594`, `create_sale` scope and appointment-branch check at `supabase/migrations/20261012100300_create_sale.sql:151-199`, the secured staff read at `supabase/migrations/20261012100600_checkout_reads.sql:17-85`, the register totals function and grant at `supabase/migrations/20261012100500_register_rpcs.sql:187-219`, the checkout UI at `apps/back-office/src/features/checkout/components/CheckoutDrawer.tsx:20-40`, and the sales/register/client surfaces in `apps/back-office/src/features/sales/components/SalesListPage.tsx:23-50`, `PaymentsListPage.tsx:24-50`, `DailySummaryPage.tsx:18-68`, `apps/back-office/src/features/register/components/RegisterBar.tsx:24-50`, and `apps/back-office/src/features/clients/components/ClientSales.tsx:19-49`.

The targeted security review found no missed cross-tenant or cross-branch exposure: checkout tables use tenant and branch predicates in their select policies and have no authenticated write grants (`20261012100000_create_checkout_tables.sql:522-594`); the matrix test asserts select-only grants and no anon access (`029_checkout_matrix.test.sql:86-103`); `create_sale` checks the appointment branch against the requested sale branch (`20261012100300_create_sale.sql:167-173`); sensitive sale/refund/register RPCs are inaccessible directly to authenticated and anon roles (`033_settle_refund_void.test.sql:25-37`, `034_register.test.sql:66-71`) and the Edge Function tests exercise role denial. No verifier finding was warranted.

## Gates

`gates/GATES.md:56-68` records all nine gates as passing: frozen-lockfile install; database reset; pgTAP; database lint (warnings only); type drift; Deno function tests; full `pnpm verify`; Playwright; and final database reset. The detailed evidence is consistent: `db-test.log:1-7` reports 36 files and 1,730 passing pgTAP tests; `fn-test.log:1-15` reports nine suites and 219 passing Deno tests; `verify.log:1-12` reports 626 passing Vitest tests, 100% coverage, typecheck/lint/CSS lint/build/size gates passing; and `playwright.log:1-10` reports 128 passed, 64 per locale, with zero failures. The only gate qualification is database-lint warnings, explicitly reported without errors in `GATES.md:63`.

The repository was at the stated branch and commit when independently checked. The working tree remains dirty with the three modified files and two untracked paths listed in `GATES.md:9-18`; the gate report says those changes predated the gate and that before/after status was identical (`GATES.md:103-112`). The gates therefore did not alter the repository. No Playwright suite or stateful check was rerun during verification.

## Findings adjudication

### Accepted

#### F-FRONTEND-1 — Receipt CSS uses hardcoded font sizes
- Ruling: Accept as minor.
- Evidence: `apps/back-office/src/features/checkout/components/Receipt.module.css:30-33, 51-55, 99-103, 113-117` contains 15px, 16px, 11px, and 14px declarations. The project's design skill sets a 12px minimum and says nothing should be below it (`.claude/skills/airbnb-design/SKILL.md:56-60`); existing tokens include 16px and 14px (`packages/ui/src/tokens.css:47-58`).
- Fix: Replace 16px and 14px with their matching typography tokens; replace 15px with a suitable existing token or define a receipt-specific token; replace 11px with a token of at least 12px, or document and approve an explicit print-only exception in the design skill and token source.
- Plan item: 6.3 receipt print view and the project design system.

#### F-CONF-1 — Missing `fn/` branch prefix in CONVENTIONS §8
- Ruling: Accept as minor.
- Evidence: `plan/CONVENTIONS.md:195-199` lists `feat/`, `fix/`, and `db/` branch prefixes; the gate's branch inventory at `gates/GATES.md:39-41` includes `fn/checkout`.
- Fix: Add `fn/<slug>` for Edge Function branches to the branch-prefix list in `plan/CONVENTIONS.md:197`.
- Plan item: Phase 6 process/conventions.

### Rejected

- F-DB-01 (appointment foreign key omits branch): Rejected as a defect. The migration explicitly documents why this FK is tenant-composite rather than branch-composite (`supabase/migrations/20261012100000_create_checkout_tables.sql:21-24, 168-170`), and the only sale-creation RPC checks that the appointment branch matches the sale branch (`supabase/migrations/20261012100300_create_sale.sql:167-173`). The auditor's residual future-bug concern does not establish a current violation.
- F-DB-02 (`register_session_totals` is executable by authenticated): Rejected as a security finding. It is `SECURITY INVOKER`, so its reads are subject to the session and payment RLS policies; the matrix tests verify staff and out-of-scope roles do not see protected rows. Granting access to an invoker read function does not bypass those policies (`supabase/migrations/20261012100500_register_rpcs.sql:187-219`; `supabase/migrations/20261012100000_create_checkout_tables.sql:533-594`). No plan item requires this read function to be service-role-only.
- F-DB-03 (`report_own_sales` is SECURITY DEFINER): Rejected as a defect. The function checks authenticated identity and tenant membership, then restricts returned data to the caller's staff IDs and branch scope (`supabase/migrations/20261012100600_checkout_reads.sql:19-57`); it also revokes public/anon execution (`:84-85`).
- F-CONF-2 (deviations are documented): Rejected as a finding because it is a positive observation, not a problem requiring a fix.
- F-BACKEND-1 (no actual issues): Rejected as a finding because it is a verdict statement, not an issue. The backend audit evidence itself is retained.

## Final ordered fix list

1. F-FRONTEND-1 — `apps/back-office/src/features/checkout/components/Receipt.module.css` and, if needed, `packages/ui/src/tokens.css` / the design skill: replace the hardcoded receipt type sizes with design tokens; use at least 12px or document an approved print-specific exception for smaller type.
2. F-CONF-1 — `plan/CONVENTIONS.md:197`: add `fn/<slug>` to the documented branch naming patterns for Edge Function work.
