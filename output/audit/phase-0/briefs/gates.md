# Gates: run every check once and capture the logs

Output directory: `/Users/fahadasad/hermes-council/output/audit/phase-0/gates/`. Summary file: `/Users/fahadasad/hermes-council/output/audit/phase-0/gates/GATES.md`.

You are the only council member allowed to run stateful commands (database reset, seeding, the Playwright suite). Every other member waits for you and reads your logs, so be complete and exact. The repository at `/Users/fahadasad/glowdesk` stays read-only: you run its scripts, you never edit its files.

1. Record the repository state in `GATES.md`: path, current branch, `git rev-parse HEAD`, `git log --oneline -20`, `git status --porcelain` (save the full output to `gates/git-status-before.txt`), and the list of local branches with their tip commits. If the working tree has uncommitted changes, say so prominently: the audit covers the working tree as it is.
2. Check the toolchain and record versions: `node`, `pnpm`, `supabase`, `deno`, `docker`. Check the local Supabase stack with `supabase status` run in the repo (redact keys from the saved output). If the stack is not running, start it with `supabase start` in the repo.
3. Read `/Users/fahadasad/glowdesk/package.json` (and each workspace `package.json`), the phase 0 exit criteria and the "Tests" and "Acceptance criteria" of every subphase of phase 0 in `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md`, plus CONVENTIONS.md §7 and §9. Then run, from the repo root, each gate that applies, saving stdout and stderr of each to its own log file in `gates/` and recording the exit code:
   - `pnpm install --frozen-lockfile`
   - `pnpm db:reset` (or `supabase db reset`): every migration must apply to an empty database and the seed must load
   - `pnpm db:test` (or `supabase test db`)
   - `pnpm db:lint` (or `supabase db lint --level warning`)
   - type drift, without writing into the repo: `supabase gen types typescript --local > /Users/fahadasad/hermes-council/output/audit/phase-0/gates/database.types.generated.ts`, then `diff` it against the committed `packages/db/src/database.types.ts`. Ignore whitespace-only differences and record whether real drift exists.
   - `pnpm fn:test` (or `deno test --allow-all supabase/functions/`) if any Edge Function exists
   - `pnpm verify` if the script exists
   - the Playwright suite, writing results outside the repo: `pnpm exec playwright test --output /Users/fahadasad/hermes-council/output/audit/phase-0/gates/playwright-results --reporter=list` (run it from the package that holds `playwright.config.ts`). If Chromium is missing, run `pnpm exec playwright install chromium` first.
   - any other gate the phase's Tests section names
   A missing script that the phase or CONVENTIONS requires is itself a gate result: record it as `MISSING`, do not invent a replacement silently.
4. Run `pnpm db:reset` once more at the end so the other members start from a clean, seeded database, and confirm it succeeded.
5. Run `git status --porcelain` again and save it to `gates/git-status-after.txt`. If anything changed compared with the first snapshot (a generated file, a report folder, a lockfile), list it in `GATES.md` as a finding: gates must not modify the repository.
6. Write `GATES.md`: a table with one row per gate (command | exit code | result PASS / FAIL / MISSING / SKIPPED with reason | log file | key lines). For every failure quote the first relevant error lines. Add the test counts (pgTAP, Deno, Vitest, Playwright: passed / failed / skipped) and which Playwright projects ran (for example `en` and `ar`).

Do not judge the implementation beyond the gates; the other members do that. Complete your task once `GATES.md` is written, even if gates failed: failing gates are results, not a reason to block.
