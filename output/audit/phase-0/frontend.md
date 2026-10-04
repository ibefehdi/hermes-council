# Frontend, i18n and RTL audit — Phase 0 (Foundation)

Auditor: phase audit council member
Repo: /Users/fahadasad/glowdesk (main, HEAD 2e22eff)
Gates: /Users/fahadasad/hermes-council/output/audit/phase-0/gates/GATES.md
Date: 2026-10-04

---

## Scope and method

Every frontend-related item in Phase 0 (subphases 0.1 through 0.5) and the i18n/RTL baseline, judged against:
- Phase plan at plan/parts/11-delivery-plan.md (### Phase 0)
- ADRs 16, 36–42, and the chair rulings
- CONVENTIONS.md sections 2, 3.4, 3.5, 7
- The frontend brief (this brief)

All sources were read fresh from the repository. Every check is backed by file paths and line numbers. The repository was never modified.

---

## Subphase 0.1 — Repository & environments (frontend aspects)

### pnpm monorepo scaffold (ADR-36)
**DONE**

- apps/back-office (MVP), apps/booking (scaffold-only), packages/{ui,db,api,validation,i18n,core}, supabase/ — all present.
- Root package.json line 4 declares `pnpm@11.24.0`. Workspace scripts (dev, test, lint, verify, e2e, size, i18n:extract, i18n:compile, etc.) all present.
- Gate 1 confirms "Scope: all 9 workspace projects" resolved cleanly.
- apps/booking/package.json description: "Public booking app. Scaffold only until plan Phase 9." — correct per spec.

### CI/CD: ci.yml and deploy.yml
**MISSING (blocker)**

- `.github/workflows/` does not exist. No ci.yml, deploy.yml, or any workflow file exists in the entire repo.
- Phase 0 subphase 0.1 explicitly requires these. The phase exit criteria cannot be met without automated CI. Other auditors (conformance, backend) have flagged the same blocker.
- Gate 7 proves the commands work locally (pnpm verify passes) but there is no automated pipeline to run them on every PR.
- Fix: Create `.github/workflows/ci.yml` (typecheck Deno + TS, lint, supabase db lint, pgTAP via supabase test db, Deno tests, Vitest, build, size-limit, gen-types drift, clean-migration gate) and `.github/workflows/deploy.yml` (migrations, functions --use-api, frontend build).

### Sentry (frontend + Deno)
**NOT VERIFIABLE LOCALLY — but no Sentry packages present**

- No `@sentry/` dependency found in any package.json.
- No sentry init code or configuration wrapper found.
- While I cannot verify whether a live Sentry project exists, the absence of any code package or config is a concrete finding: the plan requires Sentry wiring in Phase 0.1.
- Fix: Add `@sentry/react` + `@sentry/vite-plugin` to apps/back-office, `@sentry/deno` to supabase/functions/_shared/, initialise at the app entry point.

---

## Subphase 0.2 — Tenancy & security skeleton (frontend aspects)

### Login screen
**DONE**

- apps/back-office/src/features/auth/components/LoginPage.tsx: uses Zod validation (loginSchema from @repo/validation), React Hook Form with zodResolver, Supabase auth.signInWithPassword.
- Routes at auth/routes.tsx: deep-link redirect preserved (`?redirect=%2Fsettings`), signed-in users skip login.
- Evidence: LoginPage.tsx:1-75, auth/routes.tsx:1-36.
- Gate 8 (Playwright) passes in both en and ar.

### Password reset screens
**DONE**

- ForgotPasswordPage.tsx: email form, Supabase resetPasswordForEmail, rate-limit-safe error handling. Uses `dir="ltr"` on email field and `<bdi>` around email for bidi isolation.
- ResetPasswordPage.tsx: new password + confirm fields, expiry detection.
- e2e/password-reset.spec.ts tests full flow: forgot link → send → Mailpit recovery email → reset → sign in with new password. Runs per locale.

### App shell
**DONE**

- AppShell.tsx wraps AppLayout with Sidebar, Topbar, skip-to-content link, FormatScopeProvider (threads currency + timezone).
- Sidebar.tsx: Home active link, Calendar/Clients/Sales/Reports as disabled placeholders (`aria-disabled="true"`), Settings conditional on role (owner/manager).
- Topbar.tsx: TenantSwitcher (label or picker), role badge, BranchSwitcher (dropdown or locked), LanguageSwitcher, UserMenu (account/theme/sign-out).
- Evidence: AppShell.tsx:1-23, Sidebar.tsx:1-49, Topbar.tsx:1-22.

### Error pages (403, 404, no-access)
**DONE**

- ForbiddenPage.tsx (403): "You don't have permission" message, "Go to home" link.
- NotFoundPage.tsx (404): "We can't find that page", used as Router's defaultNotFoundComponent.
- NoAccessPage.tsx: email with `<bdi>`, "not linked to a company" message, sign-out. Tested in Playwright.
- SessionGate.tsx: loading (skeleton), error (retry/sign-out), ready states with full i18n.
- Evidence: ForbiddenPage.tsx:1-22, NoAccessPage.tsx:1-36, SessionGate.tsx:1-46.

### Language switcher
**DONE** (fully functional, not a stub)

- LanguageSwitcher.tsx: toggle between en/ar, labelled in target language's own script.
- SessionProvider.tsx `useProfileLocaleSync` syncs device preference to user's profile record.
- Locale persisted in localStorage; survives reload (Playwright-verified).

---

## Subphase 0.3 — Edge Function platform (frontend-relevant items)

### packages/validation
**DONE**

- Pure JS Zod schemas (no Node-only APIs), Deno-importable.
- Error catalogue at validation/src/errors.ts: exactly the ADR-29 codes (VALIDATION, UNAUTHENTICATED, FORBIDDEN, NOT_FOUND, CONFLICT, IDEMPOTENCY_MISMATCH, RATE_LIMITED, INTERNAL, UNAVAILABLE).
- _shared/errors.ts mirrors the same catalogue — contract test validates alignment.

---

## Subphase 0.4 — Frontend platform (primary audit focus)

### Structure and import boundaries
**DONE**

- Feature folder pattern: `features/<name>/` with components/, index.ts, routes.tsx, queries.ts.
- Apps import from `@repo/*` packages and feature `index.ts` only: verified in App.tsx, LoginPage.tsx, etc.
- All 6 packages (ui, db, api, validation, i18n, core) present and build successfully.

### Typed Supabase client
**DONE**

- packages/db/src/client.ts exports `createTypedClient` parameterised with generated `Database` type.
- database.types.ts at packages/db/src/ is generated from `supabase gen types`. Gate 5 confirms no drift.

### Scope-scoped TanStack Query keys (ADR-38)
**DONE**

- packages/core/src/scopeKeys.ts: `scopeKeys(tenantId, branchId)` returns `tenant(...)` and `branch(...)` key factories.
- Tenant scope: `["tenant", t, ...]`. Branch scope: `["tenant", t, "branch", b, ...]`.
- Session queries use `["session", "context", userId]` (session/queries.ts).
- Tenant switch clears all cached queries except session data (SessionProvider.tsx:62-63).
- Tests at scopeKeys.test.ts: verify key separation across tenants, branches, and "all" scope.

### invariant writes through packages/api (ADR-30)
**DONE**

- packages/api/src/invoke.ts: builds function URL, sends ADR-29 envelope, parses response into data or ApiError.
- Idempotency-Key header threaded for money mutations (invoke.ts:58).
- Tenant context sent as `x-tenant-id` header (invoke.ts:57).
- ApiError class at errors.ts carries code, status, fieldErrors, details, requestId.

### Route guards — UX only (ADR-42)
**DONE**

- guards.ts line 6: "Guards are UX only: RLS is the security boundary."
- `requireMembership`: redirects to /login or /no-access.
- `requireBranchInScope`: redirects out-of-scope branch to default.
- `requireRole`: redirects to /forbidden.

### TanStack Router with typed search params (ADR-42)
**DONE**

- router.tsx: typed route tree with Zod-validated search params for branch filter.
- `retainSearchParams(["branch"])` middleware keeps branch in URL across navigation.
- Deep-link restore tested in Playwright.

### Session context (multi-tenant ADR-37)
**DONE**

- SessionProvider.tsx: loads profile + memberships (with nested tenant/currency/branch) + visible branches.
- Status states: loading → signedOut / noAccess / ready / error.
- Multi-tenant: user can hold memberships in multiple tenants; active tenant is application context (default persisted per user in localStorage).
- Tenant switch clears TanStack Query cache completely (then restores session data).
- Branch scope: `allowedBranches()`, `isAllowedBranch()`, `defaultBranch()`, localStorage persistence.

### Tenant and branch switcher
**DONE**

- TenantSwitcher.tsx: picker for multi-tenant users, label for single-tenant. Uses `flushSync` to commit before navigation.
- BranchSwitcher.tsx: dropdown for multi-branch users, locked label + icon for single-branch users. "All branches" option when >1 branch.
- Playwright scope.spec.ts validates: tenant switch redirects correctly, branch in URL survives reloads, locked branch for receptionist, "all" redirects to default for single-branch users.

### packages/ui primitives
**DONE**

- Exported: AppLayout, AsyncBoundary, AuthLayout, Button, Card, DataTable, Drawer, EmptyState, Field, InlineAlert, Badge/Heading/Stack/Text, Popover, SegmentedControl, Select, SideNav, Skeleton, TextLink, ThemeProvider, Toast.
- Tokens from tokens.css only — no raw hex or off-scale values in feature code.
- Token definitions: colour palette (light + dark), typography scale, spacing grid (4px), radii, elevation/shadow, control heights, motion durations. All reference CSS custom properties.
- Focus visible: `:focus-visible { outline: 2px solid var(--color-primary); outline-offset: 2px; }` (tokens.css:182-185).
- Skip-to-content link: hidden off-screen via `transform: translateY(-200%)`, visible on `:focus-visible` (AppLayout.module.css:11-27).

### i18n: Lingui setup
**DONE**

- lingui.config.ts: source locale en, targets [en, ar], catalogs at packages/i18n/locales/{locale}/messages.
- Source scan paths: apps/back-office/src, packages/ui/src.
- Vite plugin compiles catalogs on import.

### i18n: Both catalogs complete
**DONE**

- en/messages.po: 415 lines, 81 message ids.
- ar/messages.po: 415 lines, all 81 message ids translated.
- Every user-facing string in Phase 0 screens is captured and has an Arabic translation.
- Gate 7 confirms `i18n:compile --strict` passes (would fail on untranslated strings).

### i18n: No concatenated translations
**DONE**

- All translations use ICU interpolation (`{name}`, `{count}`) or rich text (`<0>{email}</0>`). No string concatenation of fragments found anywhere.
- Examples: "Welcome, {name}", "New appointment with {name}", "If an account exists for <0>{sentTo}</0>."

### i18n: UseFormat with money and dates
**DONE**

- useFormat.tsx: returns money/number/dateTime formatters bound to UI locale, tenant currency, and branch timezone.
- format.ts: uses `Intl.NumberFormat` (style=currency, KWD exponent 3) and `Intl.DateTimeFormat` (branch timezone).
- Arabic: `ar-KW-u-nu-latn` locale extension for Latin digits.
- Money test: `formatMoney(12500, KWD, "en")` → "KWD 12.500". Arabic: "12.500 د.ك."
- Date test: UTC `2026-10-04T09:30:00Z` → "Oct 4, 2026, 12:30 PM" (Asia/Kuwait).
- Core money helpers (core/src/money.ts): integer-only `toMajorUnits`, `fromMajorInput` accepts Arabic-Indic digits.

### RTL: dir/lang on <html>
**DONE**

- I18nProvider.tsx:46-56: sets `root.lang` and `root.dir` on each locale activation.
- directionOf("ar") → "rtl", directionOf("en") → "ltr" (locales.ts:20-22).
- Playwright `expectDocumentLocale` asserts both attributes on every test.

### RTL: Logical CSS properties enforced
**DONE**

- `stylelint-use-logical` (2.1.3) in root devDependencies. `pnpm lint:css` runs `stylelint "apps/**/*.css" "packages/**/*.css"`.
- Audit of all CSS files: no `left`, `right`, `margin-left`, `margin-right`, `padding-left`, `padding-right`, `border-left`, `border-right` found in any application CSS.
- All directional references use logical properties: `inset-inline-start`, `inset-block-start`, `padding-inline`, `padding-block`, `border-inline-end`, `border-block-end`, `max-inline-size`, `min-inline-size`, `min-block-size`.
- The only "left" match: `--sx-calendar-week-grid-padding-left` in BookingCalendar.css — this is a schedule-x CSS variable name, not a CSS property. Not actionable.

### RTL: Directional icons mirrored
**DONE**

- tokens.css:174-176: `[dir="rtl"] .icon-directional { transform: scaleX(-1); }` handles directional icon mirroring via CSS.

### RTL: Mixed-direction text isolated
**DONE**

- NoAccessPage.tsx uses `<bdi>{email}</bdi>` for bidi isolation of email in Arabic context.
- ForgotPasswordPage.tsx uses `<bdi>{sentTo}</bdi>`.
- Email fields use `dir="ltr"` to ensure correct text flow in Arabic UI.

### Dark theme
**DONE**

- tokens.css defines dark palette (data-theme="dark" and prefers-color-scheme: dark).
- ThemeProvider + useTheme + ThemeSwitcher (light/dark/system).
- Playwright test at theme.spec.ts verifies theme switching and persistence.

### packages/db and packages/api
**DONE**

- packages/db/src/client.ts: createTypedClient with generated Database type.
- packages/api/src/invoke.ts: typed invoke wrapper with envelope parsing, idempotency-key, tenant context.
- packages/api/src/errors.ts: ApiError class with full envelope properties.

### Playwright suite (en + ar)
**DONE**

- playwright.config.ts: two projects — "en" and "ar", each with `appLocale` fixture.
- 20 tests total (10 en + 10 ar) — all PASS per Gate 8.
- Test files:
  - smoke.spec.ts: sign in → shell → language switch → sign out; no-access state; deep-link restore; 403 for wrong role; 404.
  - scope.spec.ts: multi-tenant switch clears cache; branch in URL persists; locked branch for receptionist.
  - password-reset.spec.ts: full password reset via Mailpit, per locale.
  - theme.spec.ts: theme switch.
- Fixtures: initScript sets localStorage locale; expectDocumentLocale asserts html[lang] and html[dir].

---

## Subphase 0.5 — Calendar library spike

### schedule-x fallback prototype
**DONE** (per ADR-41 verdict: fallback GO, premium not evaluated)

- BookingCalendar.tsx, resourceDayView.ts, resourceDrag.ts implement custom resource-day view on schedule-x core 4.9.1.
- Perf budgets: calendar chunk 84.3 kB gzip (under 150 kB budget). Size-limit passes.
- ADR-41 spike evidence in evidence/0.5/: render traces, keyboard test output, screenshots.
- 6-item gap list documented for Phase 5 closure (keyboard nav, live announcements, etc.).

---

## Findings

### F-FE-1: CI/CD workflow files missing (blocker)
- **Severity**: blocker
- **Location**: .github/workflows/ (directory does not exist)
- **Problem**: Phase 0 subphase 0.1 requires ci.yml and deploy.yml. Without them, the phase exit criteria (CI green on a trivial PR, deploy pipeline) cannot be met.
- **Evidence**: `.github/workflows/` does not exist. No workflow file found anywhere in the repo.
- **Fix**: Create `.github/workflows/ci.yml` with: typecheck Deno + TS, lint, supabase db lint, pgTAP, Deno tests, Vitest, build, size-limit, gen-types drift, clean-migration gate. Create `.github/workflows/deploy.yml` with: migrations → functions --use-api → frontend build.
- **Plan item**: Subphase 0.1 — Features delivered (CI/CD) and all backlog items under it.

### F-FE-2: Sentry SDK not wired in any dependency (major)
- **Severity**: major
- **Location**: Root package.json and apps/back-office/package.json
- **Problem**: The plan requires Sentry (frontend + Deno) in Phase 0.1. No Sentry package exists in any workspace's dependencies. No sentry init code or configuration is present.
- **Evidence**: grep for "sentry" in all package.json files returns nothing. No sentry.ts/js files found.
- **Fix**: Add `@sentry/react` + `@sentry/vite-plugin` to apps/back-office; add `@sentry/deno` to the _shared logging module; initialise at app entry point and in the server wrapper.
- **Plan item**: Subphase 0.1 — backlog "[Ops] Sentry + uptime monitor + log drain wiring"

### F-FE-3: apps/back-office/.env.example missing (minor)
- **Severity**: minor
- **Location**: /Users/fahadasad/glowdesk/apps/back-office/src/lib/supabase.ts:8
- **Problem**: The error message says "Copy apps/back-office/.env.example to .env.local" but no .env.example exists.
- **Evidence**: supabase.ts:8 references the file. `ls apps/back-office/.env.example` returns nothing.
- **Fix**: Create apps/back-office/.env.example with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY placeholders.
- **Plan item**: Developer experience

### F-FE-4: schedule-x CSS variable contains "left" token (minor)
- **Severity**: minor
- **Location**: /Users/fahadasad/glowdesk/apps/back-office/src/features/calendar/components/BookingCalendar.css:30
- **Problem**: `--sx-calendar-week-grid-padding-left` is a schedule-x variable name containing "left". While this is a third-party library variable, it could cause breakage if schedule-x uses it in a physical-direction property.
- **Evidence**: BookingCalendar.css:30: `--sx-calendar-week-grid-padding-left: var(--gd-axis-width);`
- **Fix**: Verify in schedule-x source that this variable feeds a logical property (padding-inline-start). If not, wrap in an RTL override. No known rendering issue.
- **Plan item**: Subphase 0.4 i18n/RTL baseline

---

## Summary table

| ID | Severity | Title |
|----|----------|-------|
| F-FE-1 | blocker | CI/CD workflow files (ci.yml, deploy.yml) missing |
| F-FE-2 | major | Sentry SDK not wired in frontend dependencies |
| F-FE-3 | minor | apps/back-office/.env.example not found |
| F-FE-4 | minor | schedule-x CSS variable name contains directional token |

**Counts**: 1 blocker, 1 major, 2 minor

---

## Per-subphase verdict

| Subphase | Verdict |
|----------|---------|
| 0.1 — Repository & environments | PARTIAL — monorepo scaffold complete; CI/CD and Sentry missing |
| 0.2 — Tenancy & security skeleton | DONE — all screens, guards, auth flows |
| 0.3 — Edge Function platform | DONE — validation schemas and error catalogue complete |
| 0.4 — Frontend platform | DONE — all packages, shell, i18n/RTL baseline, routing, Playwright suite |
| 0.5 — Calendar library spike | DONE — fallback approved, implemented, meeting budgets |

## Phase-level exit criteria

| Criterion | Status |
|-----------|--------|
| CI green on a trivial PR touching both a function and a component | NOT MET — CI pipeline does not exist |
| Deploy pipeline promotes staging → production | NOT MET — deploy pipeline does not exist |
| Clean-migration gate passes end to end | MET (gate 2) |
| Spike verdict recorded in ADR-41 with evidence | MET |

**Overall frontend phase verdict**: NOT COMPLETE (1 blocker: missing CI/CD prevents verifying the phase exit criteria). The frontend code quality is high and all intended screens, packages, and i18n/RTL features are correctly built and tested.

---

## Gates consistency check

| Gate | Relevant | Status |
|------|----------|--------|
| 1 — pnpm install --frozen-lockfile | Yes | PASS |
| 5 — Type drift | Yes | PASS |
| 7 — pnpm verify | Yes | PASS (i18n:compile, typecheck, lint, lint:css, 79 Vitest, build, size-limit) |
| 8 — Playwright suite | Yes | PASS (20 tests, 10 en + 10 ar) |
| 6 — fn:test (Deno) | Partial | FAIL (health only) — does not affect frontend validation |

No frontend-relevant gate failures. All frontend tests pass in both locales.