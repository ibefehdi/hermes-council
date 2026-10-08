# Baseline: pin the toolchain, run every existing check once, and time it

Your sandbox: `{{SANDBOX}}/base`. Output: `{{CI_DIR}}/baseline/BASELINE.md`, one log file per command in `{{CI_DIR}}/baseline/`.

You are the only worker allowed to start, stop or reset the local Supabase stack. Every later task builds on your numbers, so be complete and exact. Failing checks are results, not a reason to stop.

1. **Repository facts.** Record the following for `{{REPO}}`:
   - Path, branch `{{BRANCH}}`, commit `{{COMMIT}}`, and `git log --oneline -15`.
   - `git status --porcelain`. Uncommitted changes are out of scope because CI only sees commits; say so if there are any.
   - The `origin` URL, the default branch (`git -C {{REPO}} symbolic-ref refs/remotes/origin/HEAD`), and the remote branches. Note whether `staging` exists.
   - Whether `.github/` exists already, and what it contains.
2. **Toolchain pins.** The workflows must use exactly the versions development uses. Record a table of tool, version and source for:
   - Node (`.nvmrc`, `engines`, or `node --version` locally).
   - pnpm (`packageManager` in `package.json`).
   - Supabase CLI (`supabase --version`, plus any pin in the README or plan; "the pinned CLI" is part of the clean-migration gate).
   - Deno (`deno --version`, plus any pin).
   - `@playwright/test` (from the lockfile).
   - The Postgres major version in `supabase/config.toml`.
3. **Move the shared stack onto the sandbox.** Run `supabase stop` in `{{REPO}}` (keep the data; no `--no-backup`), then `pnpm install --frozen-lockfile` and `supabase start` in `{{SANDBOX}}/base`, so the edge runtime serves the functions of `{{COMMIT}}`. Record the start time. Save `supabase status` output with every key redacted.
4. **Run every check** from `{{SANDBOX}}/base`. Time each one (record start and end, or use `/usr/bin/time -p`), and save its stdout and stderr to its own log:
   - `pnpm db:reset`
   - `pnpm db:lint`
   - `pnpm db:test`
   - Type drift: `supabase gen types typescript --local > {{CI_DIR}}/baseline/database.types.generated.ts`, then `diff` it against `packages/db/src/database.types.ts`. Record whether there is real drift, beyond whitespace.
   - `pnpm fn:check`
   - `pnpm fn:test`
   - `pnpm verify`, then each of its parts separately so the pipeline can split them: `skills:check`, `i18n:compile`, `typecheck`, `lint`, `lint:css`, `test`, the back-office build, `size`.
   - Playwright from `apps/back-office`: `CI=1 pnpm exec playwright test --output {{CI_DIR}}/baseline/playwright-results --reporter=list`. Run `pnpm exec playwright install chromium` first if needed. If port 5173 is taken by another process, do not kill it; record that e2e could not run and why.
   - The clean-migration gate's grep: does anything under `supabase/` reference `sql/drafts-v1/`?
5. **Find the smallest stack that works.** Work out which services the suites actually use, from `supabase/config.toml` and the tests: for example the edge runtime, Auth, Mailpit (`apps/back-office/e2e/mailpit.ts`), Realtime, Storage and Studio. Then `supabase stop` and `supabase start -x <candidate exclusions>` in the sandbox, re-run `pnpm db:test`, `pnpm fn:test` and the Playwright suite against it, and record start time for the full stack versus the reduced one. Report the exclusion list that keeps every suite green, or explain why none can be excluded.
6. **Inventory the existing tests.** Give the count per kind (pgTAP plans, Deno tests, Vitest tests, Playwright tests per project). Add one line per test file saying what it covers. Flag signs of flakiness or tests that cannot fail: retries, sleeps, `.skip`, `.only`, `todo`, `--permit-no-files` hiding an empty suite, assertions that only check a status code.
7. **Leave the stack ready.** End with a full `supabase start` from `{{SANDBOX}}/base` (if you stopped it) and a final `pnpm db:reset`, and confirm both succeeded. The stack stays running from the sandbox for the other members.

Write `BASELINE.md` with these sections:

- Repository facts.
- The pins table.
- A checks table: check | command | exit code | duration | test counts | log file | key lines. Quote the first relevant error lines of every failure.
- The stack service set and start times.
- The test inventory.

Do not judge coverage; the traceability task does that.
