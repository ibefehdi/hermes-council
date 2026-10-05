# Pipeline: the workflows and the ruleset for main

Your sandbox: `/Users/fahad/council/.ci-sandbox/GlowDesk/pipeline`. Output: `/Users/fahad/council/output/ci/pipeline.md`. You own these draft files: `/Users/fahad/council/output/ci/draft/.github/**`, and any `package.json` or runner config changes (`playwright.config.ts`, `vitest` config, `scripts/`). If you change a `package.json`, put a full copy with minimal edits in the draft. Start by reading `/Users/fahad/council/output/ci/baseline/BASELINE.md` and the gaps owned by `pipeline` in `/Users/fahad/council/output/ci/traceability.md`.

The test authors put new tests where the existing runners already find them, so the commands you wire pick them up without changes. Document which locations each job covers.

## Design requirements

1. **Triggers.**
   - `pull_request` into `main`, plus `staging` if that branch exists on `origin`.
   - `push` to `main`, so main's own status stays visible.
   - `workflow_dispatch`.
   - `merge_group` only if you choose a merge queue, and justify it.
   - No `paths` or `paths-ignore` filter on a workflow that holds a required check. When the filter does not match, the check never reports and the PR cannot merge. Skip work inside jobs if you must.
2. **Safety.**
   - Top-level `permissions: contents: read`; widen per job only with a reason.
   - Never use `pull_request_target`.
   - Never put `${{ github.event.* }}` text (PR title, branch name) directly in a `run:` script; pass it through `env:` to avoid script injection.
   - Pin every action to a full commit SHA with the version as a comment. Look each one up; do not write SHAs from memory.
   - Give every job a `timeout-minutes`.
   - Concurrency: one group per PR ref with `cancel-in-progress` for pull requests, but never cancel runs on `main`.
3. **Toolchain.** Use exactly the BASELINE pins:
   - `supabase/setup-cli` with the CLI version.
   - `denoland/setup-deno` with the Deno version.
   - `pnpm/action-setup` (reads `packageManager`).
   - `actions/setup-node` with the Node version and `cache: pnpm`.
   - Playwright browsers cached on the `@playwright/test` version and installed with `--with-deps chromium`.
   - A Deno cache, if it saves measurable time.
4. **Jobs.** Derive the split from the BASELINE timings and justify it in `pipeline.md`. Parallel jobs each starting their own stack cost more minutes but less wall time; one stack job running everything in sequence costs fewer minutes. Target a total wall time of 20 minutes or less on `ubuntu-latest`, and say what you expect. The pipeline must cover at least:
   - **Static.** `pnpm install --frozen-lockfile`, then every part of `pnpm verify`: skills check, `i18n:compile --strict` (missing Arabic keys fail), typecheck, lint, CSS logical-property lint, Vitest, back-office build, size budgets. Add `pnpm fn:check`.
   - **Clean-migration gate** (CONVENTIONS §7):
     - `supabase start` with the BASELINE service set, then `supabase db reset` from empty on the pinned CLI.
     - `pnpm db:lint` and `pnpm db:test`.
     - Type drift: regenerate the types and fail on any non-whitespace difference from `packages/db/src/database.types.ts`.
     - Fail if anything references `sql/drafts-v1/`.
   - **Edge Functions.** `pnpm fn:test` against the served functions of the same stack.
   - **End to end.** The Playwright suite in both the `en` and `ar` projects with `CI=true`. Upload the report and traces as artifacts on failure only, with short retention.

     CONVENTIONS §7 says "E2E nightly and pre-release", but CONVENTIONS §8 makes `main` production. Every PR into `main` is therefore pre-release, so E2E is a required check here. Record this as a plan amendment for the chair. If the suite is too slow, shard it with `--shard` under a matrix, behind the aggregator.
   - **Aggregator.** One job, for example `ci-passed`:
     - `needs` every other job and runs with `if: ${{ !cancelled() }}`.
     - Fails unless every needed job's result is `success`, or `skipped` where you deliberately skip that job on some events; list those jobs explicitly.

     GitHub counts a skipped required check as passing, and matrix jobs report as `name (values)`. That is why the ruleset requires only this aggregator.
   - **Pipeline gaps from `traceability.md`.** Add whatever cheap, high-value repository checks they call for: for example a Conventional Commits check of the PR title (the squash-merge commit), committed secrets or local-only files (`.env`, `supabase/.temp`), and skills copies identical. Prefer plain shell over third-party actions.
5. **Ruleset `.github/rulesets/main.json`.** Use the body of the REST endpoint "Create a repository ruleset" (look up the current schema in GitHub's docs and cite the URL). It needs:
   - `target: branch`, `enforcement: active`, and `conditions.ref_name.include: ["refs/heads/main"]`.
   - Rules: `deletion`, `non_fast_forward`, `pull_request`, and `required_status_checks` with the aggregator's exact name, the GitHub Actions `integration_id` (look it up), and `strict_required_status_checks_policy: true`.
   - Approvals: GitHub does not let authors approve their own PRs, so check how many people push to the repo (`git shortlog -sne --all`). With a single developer, set `required_approving_review_count: 0` and say why. Otherwise choose 1.
   - Bypass actors: decide whether admins can bypass, and justify it.

   Rulesets on private repositories need a paid GitHub plan. Check the repo's visibility with `gh repo view <owner/repo> --json visibility` if `gh` is authenticated, and record the result. Do not apply the ruleset or change anything on GitHub.

## Validate

1. `node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/GlowDesk` must pass with no `FAIL` lines. Explain every remaining `warn`.
2. In `/Users/fahad/council/.ci-sandbox/GlowDesk/pipeline`, run every stateless `run:` step of every job exactly as written, in order: install, the static checks, `fn:check`, the grep checks, and the PR-title check with sample good and bad titles. Record the result of each.

   Do not start, stop or reset the shared stack and do not run Playwright. The verifier replays the whole pipeline, including the stack steps, once the workers are done.

## Write `pipeline.md`

- A Mermaid flowchart of the job graph, and the required check(s).
- A table: job | what it proves | plan items and CONVENTIONS rules | commands | expected duration (from BASELINE) | how a developer reproduces it locally, as one command.
- The cache strategy, and an estimate of minutes per PR.
- Every design decision with its reason, and the plan amendments for the chair (at least the E2E one).
- How to read a red check: which job, which log, which local command.
- The list of test locations each job picks up, for the verifier to confirm the new tests are wired.
