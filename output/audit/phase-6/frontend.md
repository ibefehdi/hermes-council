# Phase 6 Frontend, i18n and RTL Audit Report

auditor: @auditor
date: 2026-10-07
repository: /Users/fahad/GlowDesk (read-only)
branch: feat/sales-register-ui (HEAD 925f516)
phase: Phase 6 (Checkout, sales & register)
scope: Frontend apps + packages (checkout, sales, register, clients/sales-history features)

## Gates summary

All 9 gates PASS. Key frontend-relevant results:
- Playwright: 128 tests (64 en + 64 ar), 0 failed
- Vitest: 74 files, 626 tests, 100% coverage
- i18n:compile: PASS
- lint:css (stylelint logical-properties): PASS
- size-limit: 236.53 kB gzipped (< 250 kB limit)
- build: PASS

## Subphase 6.1 — Money data layer

No frontend screens. Data layer only (migrations, RPCs under supabase/migrations). 
Status: DONE (no frontend to audit)

## Subphase 6.2 — Checkout function

No frontend screens. Edge Function layer only (supabase/functions/checkout/).
Status: DONE (no frontend to audit)

## Subphase 6.3 — Checkout UI

### Screens delivered

1. Checkout cart (appointment items, manual lines, add service)
   - CheckoutDrawer.tsx / CheckoutEditor.tsx / CartLines.tsx / AddItemPanel.tsx
   - Evidence: screenshots in plan/evidence/6.3/ (01-en, 51-ar)

2. Discounts (line/sale, reason) + tips (per staff) + tax display
   - DiscountEditor.tsx / TipsEditor.tsx / TotalsPanel.tsx
   - Evidence: screenshots in plan/evidence/6.3/ (01-en, 51-ar)

3. Payment split across enabled methods
   - PaymentSplit.tsx
   - Evidence: screenshots in plan/evidence/6.3/ (01-en, 51-ar)

4. Refund/void dialogs (role-gated: owner/manager only)
   - RefundDialog.tsx / VoidDialog.tsx
   - Evidence: screenshots in plan/evidence/6.3/ (04-en, 54-ar refund; 05-en, 55-ar void)

5. Receipt print view (EN/AR, branch-branded, sequential number)
   - ReceiptPrintView.tsx + Receipt.module.css
   - Evidence: screenshots in plan/evidence/6.3/ (07-en receipt)

### i18n verification (PASS)
- Every user-visible string goes through `<Trans>` or `t()` from `@lingui/react/macro`
- Receipt uses `DocumentI18nProvider` to switch lang/dir per receipt language
- Toolbar strings rendered in outer lang, receipt body in its own lang
- Both catalogs have 1252 messages each; exactly 1251 have non-empty translations per catalog (only the PO header is empty)
- No concatenated translated fragments; full sentences with ICU interpolation
- Catalogs synced: `pnpm i18n:compile` passes in gates

### RTL verification (PASS)
- CSS uses logical properties only:
  - `padding-block`, `border-block`, `margin-block` instead of physical
  - `inline-size`, `min-inline-size` instead of width
  - `inset-inline-start/end` pattern where used
  - `text-align: start` / `text-align: end` instead of left/right
  - `border-inline-end` / `border-block-end` for directional borders
- No `margin-left`, `margin-right`, `padding-left`, `padding-right` found in any checkout/sales/register CSS
- Bidi isolation: `<bdi>` tags used throughout for:
  - Phone numbers with `dir="ltr"` (ReceiptPrintView.tsx:109, CheckoutEditor.tsx:373)
  - Invoice numbers with `dir="ltr"` (ReceiptPrintView.tsx:121, CheckoutEditor.tsx:350)
  - Staff names, client names, branch names, service names in mixed contexts
  - Reason text embedded in Arabic context
- `scaleX(-1)` not found in feature code; icons handled by `@repo/ui`

### Design tokens verification (PASS)
- Feature CSS uses `var(--text-*)` tokens for font sizing (Checkout.module.css, Sales.module.css, Register.module.css)
- Colours use `var(--color-*)` tokens exclusively
- No raw hex colors found in feature CSS files
- Spacing uses `var(--space-*)` tokens
- Radii use `var(--radius-*)` tokens

### Acceptance criteria verification
| Criterion | Evidence | Status |
|---|---|---|
| Checkout of 2 items, 1 line discount, tips for 2 staff, split cash+KNET | checkout.spec.ts:38 (Phase 6 AC journey) | PASS |
| Money math matches ADR-51 golden fixtures | packages/core/src/checkout.test.ts:33 (G01-G20 fixtures) | PASS |
| Tampered total rejected (negative test) | Deno checkout tests (46 suites), pgTAP 031 | PASS |
| Part-paid sale shows balance and settles | checkout.spec.ts walk-in unpaid test, checkoutFixtures settle path | PASS |
| Receipt prints in EN/AR with mandated elements | receipt.spec.ts:139 (print test both locales) | PASS |

### Minor finding

**F-FRONTEND-1: Receipt CSS uses hardcoded font sizes outside design token system**
- Severity: minor
- Location: apps/back-office/src/features/checkout/components/Receipt.module.css:31, 52, 101, 116
- Problem: Four font-size declarations use hardcoded px values (15px, 16px, 11px, 14px) instead of `var(--text-*)` tokens from packages/ui. The 11px value is below the 12px minimum specified by the Airbnb design skill (airbnb-design SKILL.md §Typography).
- Evidence:
  - Line 31: `.tenant { font-size: 15px; }` (─text-label is 16px)
  - Line 52: `.voidedMark { font-size: 16px; }`
  - Line 101: `.lineMeta, .when { font-size: 11px; }` (below 12px minimum)
  - Line 116: `.grand { font-size: 14px; }` (--text-label-small is 14px)
- Context: This is a print view (80mm receipt paper) that needs compact sizing. The design skill notes printed receipts render outside the app shell. The 11px is notably below the 12px floor but common in thermal-receipt typography.
- Fix: Use CSS variable tokens where possible (16px → var(--text-label), 14px → var(--text-label-small); 11px may need a new --text-receipt token or documented exception)
- Plan item: Subphase 6.3 screens: Receipt print view (EN/AR)

## Subphase 6.4 — Sales & Register UI

### Screens delivered

1. Register bar + open/close flow
   - RegisterBar.tsx / OpenRegisterDialog.tsx / CloseRegisterDialog.tsx / CashUpSummary.tsx
   - Evidence: screenshots in plan/evidence/6.4/ (01-en, 51-ar)

2. Sales list (filters, search by client/invoice) + sale detail (lines, payments, history)
   - SalesListPage.tsx / SalePage.tsx / SaleHistory.tsx / SalesNav.tsx / ListPagination.tsx
   - Evidence: plan/evidence/6.4/ (05-en, 06-en sales list/detail)

3. Payments list with per-method totals
   - PaymentsListPage.tsx / MethodTotalsTable.tsx
   - Evidence: plan/evidence/6.4/ (07-en payments list)

4. Daily sales summary + reconciliation
   - DailySummaryPage.tsx
   - Evidence: plan/evidence/6.4/ (08-en daily summary)
   - Reconciliation test: daily-summary.spec.ts asserts summary figures match sales list

5. Client profile balance section (branch-scoped RPC)
   - ClientSales.tsx (BalanceSection)
   - Evidence: plan/evidence/6.4/ (09-en)

6. Client profile sales history (branch-labelled)
   - ClientSales.tsx (SaleItem component with branch name, timezone formatting)
   - Evidence: plan/evidence/6.4/ (09-en)

### i18n verification (PASS)
- All user-facing strings through `<Trans>` or `t()` macros
- Plural forms used for sales counts, payment/refund counts
- useFormat().money() for all monetary values
- formatDateTime() with branch timezone for timestamps
- useLocalizedName() for bilingual branch/staff names
- Both en and ar complete

### RTL verification (PASS)
- Sales.module.css uses `padding-block`, `border-block-end`, `padding-inline`, `inline-size` exclusively
- Register.module.css uses `min-inline-size`, `padding-block-start`, `border-block-start`
- No physical left/right properties found
- `<bdi>` used around invoice numbers, branch names, and staff names in SaleDrawer.tsx

### Data access verification (PASS)
- All writes (create-sale, settle, refund, void, register-open, register-close) go through `api.checkout.*` Edge Function wrappers (mutations.ts)
- No direct money-table writes from frontend code (ADR-28 allowlist respected)
- Reads use supabase-js under RLS (appropriate for reads per ADR-28)
- Query keys carry tenant+branch scope (`scopeKeys(tenantId, branchId).branch(...)`)
- Idempotency keys on all mutations (`useAttemptKey` from @repo/api)
- Route guards are UX only; RLS is the real boundary

### Acceptance criteria verification
| Criterion | Evidence | Status |
|---|---|---|
| Register: open 50 KWD, take cash sales, close counted 180 KWD, diff recorded | register.spec.ts:38 (full register day cycle) | PASS |
| Cash payments outside session rejected when register required | register.spec.ts:99 (cash refused) | PASS |
| Daily summary equals sales-list totals | daily-summary.spec.ts (reconciliation assertion) | PASS |

### Client profile section verification
- Branch-labelled sales history: ClientSales.tsx uses `nameOf(sale.branch)` with `<bdi>`, timestamps in branch timezone
- Branch-scoped balance RPC: queries `client_sales_summary` RPC which is branch-scoped
- Settle from profile: opens SaleDrawer with the oldest owing sale
- Implementation satisfies Phase 4 stub completion per F-PLAN-7

## Phase-level exit criteria

| Criterion | Status | Evidence |
|---|---|---|
| Checkout of 2 items, discount, tips, split payment completes with PREFIX-SEQ | PASS | checkout.spec.ts:38 |
| Double-click completes same key creates one sale | PASS | checkout.spec.ts:118 (double-click test) |
| 20 parallel checkouts produce 20 unique sequential numbers | PASS | pgTAP invoice-sequence race test |
| Refund is manager-only with positive amount_minor | PASS | refund-void.spec.ts:98 (receptionist forbidden) |
| Money math matches ADR-51 golden fixtures | PASS | core/checkout.test.ts: golden fixtures G01-G20 |
| Void same-day with reason | PASS | refund-void.spec.ts:122 (void test) |
| Register open/close with cash difference recorded | PASS | register.spec.ts:38 |
| Part-paid sale shows balance and settles | PASS | receipt.spec.ts:91 (settle from sale drawer) |
| Receipt prints in EN and AR | PASS | receipt.spec.ts:139 (print test, both locales) |
| Daily summary equals sales-list totals | PASS | daily-summary.spec.ts: reconciliation gate |

## Findings summary

### F-FRONTEND-1: Receipt CSS uses hardcoded font sizes outside design token system
- Severity: minor
- Location: apps/back-office/src/features/checkout/components/Receipt.module.css:31,52,101,116
- Problem: Four font-size values (15px, 16px, 11px, 14px) use hardcoded px instead of `var(--text-*)` CSS variable tokens. The 11px value is below the 12px minimum from the airbnb-design skill.
- Evidence:
  - `font-size: 15px` (line 31, `.tenant`)
  - `font-size: 16px` (line 52, `.voidedMark`)
  - `font-size: 11px` (line 101, `.lineMeta`, `.when`)
  - `font-size: 14px` (line 116, `.grand`)
  - All other feature CSS files use `font: var(--text-*)` tokens
- Fix: Map 16px → `var(--text-label)`, 14px → `var(--text-label-small)`. For 11px, add a `--text-receipt-micro: 400 11px/1.3 var(--font-sans)` token in packages/ui/tokens.css or document the print-view exception. The 15px tenant name could use `--text-card-title` (18px) or a print-specific token.
- Plan item: 6.3 Receipt print view (EN/AR)

### Findings not applicable for frontend audit
These items were checked and found implemented correctly at the code/data layer:
- report_own_sales secured RPC: migration 20261012100600_checkout_reads.sql:19 (exists with proper security)
- Idempotency-key boundary: checked at Edge Function layer (Deno replay tests)
- Refund cap trigger: checked at database layer (pgTAP)
- Invoice sequence races: checked at database layer (pgTAP)

## Summary table

| ID | Severity | Title |
|---|---|---|
| F-FRONTEND-1 | minor | Receipt CSS uses hardcoded font sizes outside design token system |

Counts: 0 blocker, 0 major, 1 minor

## Overall verdict: PASS

Phase 6 frontend, i18n and RTL implementation is complete and correct. All screens delivered, all acceptance criteria met, all tests passing (0 Playwright failures, 100% Vitest coverage), i18n catalogs complete and balanced (1252 messages in en and ar), RTL layout uses logical CSS properties exclusively, bidi isolation is correctly applied throughout, design tokens are used properly across feature CSS, and data access follows the ADR-28 allowlist.

One minor finding (F-FRONTEND-1) regarding hardcoded font sizes in the receipt print view CSS — acceptable for a print view but a small inconsistency with the token system.