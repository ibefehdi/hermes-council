# Frontend tests: Vitest and Playwright gaps, i18n and RTL guards

Your sandbox: `{{SANDBOX}}/frontend`. Output: `{{CI_DIR}}/tests-frontend.md`. You own new and changed test files under `{{CI_DIR}}/draft/apps/` and `{{CI_DIR}}/draft/packages/`: `*.test.ts(x)`, `e2e/*.spec.ts`, and e2e helpers. Start by reading `{{CI_DIR}}/baseline/BASELINE.md` and the gaps owned by `tests-frontend` in `{{CI_DIR}}/traceability.md`. Close the P1 gaps first, then P2, then P3.

You are the only worker who runs Playwright during this stage. It starts its own dev server on port 5173 from your sandbox (see `apps/back-office/playwright.config.ts`). If that port is taken by another process, do not kill it; record it and write the specs anyway, so the verifier can run them.

## How to write them

- **Vitest:** next to the code, matching existing test names. `pnpm test` runs them, so no wiring is needed. Follow CONVENTIONS §7:
  - `packages/core` coverage at least 95%; feature logic (queries, mutations, mappers) at least 70%.
  - Money math against the ADR-51 golden fixtures.
  - No snapshot tests except design-skill wrappers.
  - The degraded-network behaviour: a timed-out mutation retries with the same idempotency key.
- **Playwright:** in `apps/back-office/e2e/`.
  - Use `test` from `./fixtures` so every journey runs in both `en` and `ar`, and the `s` strings fixture rather than hardcoded English. Reuse the existing `*Flows.ts` helpers, or add one per feature in the same style.
  - Locate elements by role and accessible name, never by CSS class.
  - No `waitForTimeout`; wait for a visible outcome.
  - Data a journey creates carries a per-run marker. Never depend on another spec's data.
- Assert the outcome the user sees and the state behind it: after saving, reload and assert the value is still there; after a denial, assert the error message and that nothing changed.

## What to cover

1. **Built screens and journeys from the gap list.**
   - Every acceptance criterion of a built subphase that a user performs on screen gets a journey.
   - The critical journeys CONVENTIONS §7 lists for built features: login, client CRUD, branch switch and the others that are built.
   - Scope denials: a role that must not see a screen or an action gets the right outcome.
2. **i18n and RTL guards:**
   - Every built route renders in `ar` with `<html lang="ar" dir="rtl">`, with no raw message ids or untranslated English strings in the visible text.
   - Mixed-direction text (a Latin phone number or email inside Arabic) is bidi-isolated where the plan requires it.
   - A Vitest guard that the `en` and `ar` catalogs have exactly the same keys, if `i18n:compile --strict` does not already prove it (check that first).
3. **Accessibility:** if `@axe-core/playwright` is already a dependency, add axe assertions on the main flows of built screens. If it is not, record the gap with the exact dependency to add, as a pipeline amendment for the chair; do not add dependencies yourself.

## Validate each test

1. Run it in your sandbox: Vitest with `pnpm test -- <file>`; Playwright from `apps/back-office` with `CI=1 pnpm exec playwright test <spec> --output {{CI_DIR}}/scratch/pw-frontend --reporter=list`, in both projects.
2. Then run the full Vitest suite and the full Playwright suite once more, and check nothing else broke.
3. Do a mutation check: break the screen or logic in your sandbox (remove a guard, change a label key, drop a field from the save), watch the test fail, then restore with `git -C {{SANDBOX}}/frontend checkout -- <file>`.
4. Copy the file to the draft and record it in your output file in the common brief's format.
