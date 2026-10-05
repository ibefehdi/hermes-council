# CI merge gates: common brief

The multi-tenant spa/salon SaaS (GlowDesk) lives in the git repository at `/Users/fahad/GlowDesk`, checked out at branch `main`, commit `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb`. Your job is to design the GitHub merge gates for it: nothing may be merged into `main` unless the guarantees of the plan **that are built so far** are proven by automated tests that run on the pull request.

The deliverable is a set of files that mirror the repository layout under `/Users/fahad/council/output/ci/draft/`:

- `.github/workflows/*.yml`: the GitHub Actions workflows that run on every pull request into `main`.
- `.github/rulesets/main.json`: the branch ruleset that makes those checks required for `main` (applied later with `gh api`).
- New test files that close the gaps between the plan and the existing tests, in the locations the existing runners already pick up: `supabase/tests/*.test.sql` (pgTAP), `supabase/functions/<slug>/*_test.ts` (Deno), `*.test.ts(x)` next to the code (Vitest), `apps/back-office/e2e/*.spec.ts` (Playwright).
- Script or config changes the workflows need (a `package.json` script, a Playwright or Vitest setting). Never migrations, never seed data, never product code.

## What a good test is here

- **Traceable.** It names the plan item it proves (subphase and acceptance criterion, ADR, or CONVENTIONS rule) in its description or header comment, the way the existing tests do (see the header of `supabase/tests/015_clients_matrix.test.sql`).
- **Able to fail.** A test that cannot fail is worse than none because it gives false confidence. Every new test gets a mutation check: break the guarantee on purpose, watch the test fail, and restore it (see "Mutation checks" below).
- **Deterministic.** No wall-clock sleeps, no dependence on test order or on data another suite left behind, no network beyond the local Supabase stack. Rows a test writes carry a per-run unique marker, as the existing Deno tests do with `runId`.
- **Built on the existing harness.** pgTAP: the fixtures and role helpers in `supabase/tests/000_harness.sql` (do not edit that file; define extra helpers inside your own file's transaction). Deno: `supabase/functions/_shared/testing.ts`. Playwright: `apps/back-office/e2e/fixtures.ts`, which runs each journey once in `en` and once in `ar`.
- **Not a duplicate.** If an existing test already proves it, cite that test instead.
- **Guarding the future, not just the present.** Prefer structural guard tests that fail when the *next* PR breaks a rule. Examples: a public table without RLS, a `SECURITY DEFINER` function without a fixed `search_path` or callable by `anon`, a view without `security_invoker`, a money column that is not `bigint ..._minor`, an Edge Function route without an auth check, or an `ar` catalog missing a key. A guard test usually has more value than a test of one instance.

## What "built so far" means

The traceability task decides which phases and subphases of `/Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md` are built at `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb`, and only those are gated. Never write a test for a feature that is not built yet: it would fail by design and block every merge. Such items go in the report as future gates.

Binding rules, in this order of precedence: `/Users/fahad/GlowDesk/plan/decisions.md` (ADRs) > `/Users/fahad/GlowDesk/plan/PLAN.md` > `/Users/fahad/GlowDesk/plan/CONVENTIONS.md` (especially §7 Testing standards, §8 Git workflow, §9 Definition of done) > the skills in `/Users/fahad/GlowDesk/.cursor/skills/`.

## Rules

- **The repository at `/Users/fahad/GlowDesk` is read-only.** Never edit, create, delete, stage or commit files there, never switch branches, stash or push. CI only ever sees committed code, so all work happens against `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb` in sandbox clones.
- **Work only in your own sandbox clone** under `/Users/fahad/council/.ci-sandbox/GlowDesk/` (your brief names it). Run `pnpm install --frozen-lockfile --prefer-offline` there before anything else. Copy each file into `/Users/fahad/council/output/ci/draft/` (same relative path) once it is validated, and keep the two copies identical. Only write files in `draft/` that your brief assigns to you.
- **One shared local Supabase stack.** All sandboxes share the stack on `127.0.0.1:54321` (API, functions) and `127.0.0.1:54322` (Postgres), which the baseline task started from `/Users/fahad/council/.ci-sandbox/GlowDesk/base` so it serves the functions of `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb`. Only the baseline task and the verifier may start, stop or reset it. Everyone else may run `supabase test db` (each file runs in a rolled-back transaction), read-only `psql` queries against `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, HTTP calls to the local API and functions using the seed logins in `/Users/fahad/GlowDesk/README.md`, Deno and Vitest suites. Only the frontend test author runs Playwright during the worker stage.
- **Mutation checks**, by area:
  - Database: copy the test to `/Users/fahad/council/output/ci/scratch/`. Right after its `begin;`, add the breaking DDL (`drop policy ...`, `alter table ... disable row level security`, `create or replace function ...` with the guard removed). Run it with `psql ... -v ON_ERROR_STOP=0 -f`, confirm the expected assertion fails, then delete the scratch copy. Everything is rolled back, so nobody else is affected. Never edit migrations or reset the database for this.
  - Deno handler or `_shared` code, Vitest, frontend code: edit the file in your own sandbox, run the test, then restore with `git -C <your sandbox> checkout -- <file>` and confirm it passes again.
  - Code served by the shared stack (a deployed Edge Function's behaviour over HTTP): workers cannot re-serve it. Record `MUTATION DEFERRED (served code)` with the exact edit to make; the verifier runs those checks once the workers are done.
- **Never copy secrets** into your output or the draft. In workflows, read the local stack's well-known keys with `supabase status -o env` at run time. Never hardcode them.
- **Check facts.** Verify any GitHub Actions, Supabase CLI, Deno, Vitest or Playwright behaviour you rely on with a web search, and cite the URL. Look up action versions and their commit SHAs with `git ls-remote --tags https://github.com/<owner>/<repo>.git`. Never write a SHA from memory.
- **Validate the draft** with `node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/GlowDesk` whenever you change a workflow, the ruleset or a `package.json`.
- **Write your output file incrementally** (append as you go) so work survives a crash. Cite every location precisely: repo path and line, test name, or log file and line.

## New test record

Record every test you add or change in your output file like this:

```
### T-<area>-<n>: <short title>
- File: draft/<path> (new | changes existing)
- Proves: <plan item, ADR or CONVENTIONS rule, quoted>
- Closes gap: <G-id from traceability.md>
- Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb: PASSES | KNOWN-FAILING
- Mutation check: <what you broke> -> <the assertion that failed>; restored and passing again | MUTATION DEFERRED (served code): <exact edit>
- Runtime: <seconds>
```

`KNOWN-FAILING` means the test fails at `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb` because the code has a real defect, not because the test is wrong. Add a reproduction, the plan item it violates, and the exact fix. Never weaken a test to make it pass. These defects must be fixed in the same PR that installs CI, otherwise CI starts red.

End your file with a summary table (id, file, gap, result) and the list of gaps assigned to you that you did not close, each with the reason.
