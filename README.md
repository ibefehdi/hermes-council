# hermes-council

A council of [Hermes Agent](https://hermes-agent.nousresearch.com) profiles that explores a web dashboard with Playwright, maps every page and feature, and explains how the features link together. Members work independently, a verifier cross-checks them against the live dashboard, and a chair writes the final report.

Each member runs on a different model family (set in `council.conf`) so no single model's blind spots dominate.

| Member | Model (OpenRouter) | Job |
|---|---|---|
| cartographer | `z-ai/glm-5.3` | Inventory every page and feature |
| linker | `deepseek/deepseek-v4-pro` | Map relationships: navigation, shared entities, data flows, shared APIs |
| verifier | `openai/gpt-5.6-luna` | Cross-check both reports in the live dashboard, rule on disagreements |
| chair | `qwen/qwen3.8-max-0902` | Write `output/FINAL_REPORT.md` |

## Requirements

Hermes Agent, Node.js 20+, and an OpenRouter API key.

## Setup on a new machine

```bash
git clone git@github.com:ibefehdi/hermes-council.git ~/council && cd ~/council
./setup.sh
```

`setup.sh` installs Playwright and Chromium, creates the four Hermes profiles, sets their models from `council.conf`, registers the Playwright MCP server, and asks for the dashboard login and OpenRouter key. Secrets go to `.env` and the profiles' own `.env` files, never into git. Re-run it any time after editing `council.conf` or pulling changes.

## Run

```bash
./run-council.sh                                  # whole dashboard
./run-council.sh "Focus on billing and reports"   # narrower run
```

The script checks the saved session in `auth.json`. If it's missing or expired, it logs in: automatically when `DASHBOARD_PASS` is set, otherwise (OTP, SSO, 2FA, CAPTCHA) it opens a browser where you log in yourself and saves the session as soon as the dashboard loads. Every agent reuses that session, so neither the password nor the OTP ever reaches the models. It then starts the Hermes gateway if needed and launches the swarm. The report lands in `output/FINAL_REPORT.md`; previous runs are moved to `runs/`.

To refresh the session by hand: `npm run login:headed`. To test it: `node login.mjs --check`.

### Deep technical pass

After a survey, run a second pass that builds on it:

```bash
./run-council.sh deep
./run-council.sh deep "Extra focus for this pass"
```

A seed task first fills the account with a realistic `COUNCIL-TEST` data set (clients, services, products, appointments with cash checkouts, quick sales) so lists and reports have content. Then five workers run in parallel, each with a brief in `briefs/deep/`: Setup and every settings page, every report, everything the survey missed, create/edit flows with `COUNCIL-TEST` data, and architecture (API catalogue, data model, page connectivity). Each brief asks for full technical detail and Mermaid UML diagrams (class, ER, sequence, state, flowchart), validated with `node check-mermaid.mjs <file.md>`. Worker outputs go to `output/technical/`, the verifier checks them against the live dashboard, and the chair writes `output/TECHNICAL_REPORT.md`. The survey's `FINAL_REPORT.md` and its source files are made read-only and backed up to `runs/` first; they are never changed.

### Implementation plan (design council)

Needs `output/TECHNICAL_REPORT.md` from the deep pass. No browser or login is used.

```sh
./run-council.sh plan
./run-council.sh plan "Extra focus for this pass"
```

The council turns the reverse-engineering reports into a clean-room plan for a multi-tenant spa/salon SaaS on Supabase, with all server logic in Edge Functions (Deno) and a React + TypeScript frontend. The product definition, MVP scope, stack and output formats are in `briefs/plan/`. Four workers run in parallel: product requirements, data model and multi-tenancy (including SQL migration drafts), Edge Functions backend, and frontend architecture with English/Arabic RTL. Each one proposes decisions and drafts the conventions skills for its area. The verifier reviews every proposed decision, and the chair writes:

- `output/plan/decisions.md`: architecture decision records
- `output/plan/IMPLEMENTATION_PLAN.md`: phases, backlog, dependencies, gantt chart, risks
- `output/plan/CONVENTIONS.md`
- `output/plan/skills/.cursor/skills/<name>/SKILL.md` and identical `output/plan/skills/.claude/skills/<name>/SKILL.md`, checked with `node check-skills.mjs output/plan/skills`

### Plan review (round 2)

```sh
./run-council.sh review
```

An adversarial cross-review of the plan. Each reviewer audits work it didn't write: the linker checks feature coverage against the reverse-engineering reports, the requirements (including a simulated week at a multi-branch spa), the frontend, and every decision; the cartographer checks the data model, SQL, tenant isolation, booking integrity, money handling, the Edge Functions design, the implementation plan and the skills. Findings go to `output/plan/review2/`, the verifier accepts or rejects each one in `adjudication.md`, and the chair applies the accepted fixes in place and logs every change in `output/plan/REVISION_LOG.md`. Round 1 versions are kept in `output/plan/round1/`. If the plan's chair is still working, the review waits for it automatically.

### Auto-push

Every run starts `autopush.sh`, which commits and pushes `output/` and `screenshots/` whenever a file is added or changes (once it has been unchanged for 30 seconds, so files aren't pushed half-written). It refuses to commit anything that looks like an OpenRouter key. Control it with `./autopush.sh start|stop|status`; the log is `autopush.log`. Set `AUTOPUSH=0` to skip it for a run, or `AUTOPUSH_INTERVAL=<seconds>` to change the interval.

### Final plan

```sh
./run-council.sh final
```

The council goes over the revised plan one last time and produces a single self-contained `output/plan/PLAN.md`. Four drafts are written in parallel: the Fresha parity matrix, extra features beyond Fresha and user journeys per role; architecture and UML diagrams (C4, class, ER, sequence, state, security); the reasoning behind every decision plus the council's findings across all rounds and a fresh independent pass; every phase broken into subphases with backlog tasks, dependencies and a gantt chart; and corrected MVP SQL migrations with RLS tests in `output/plan/sql/v2/`. The SQL is checked with `node check-sql.mjs <migrations-dir> [tests-dir]`, which applies the migrations to a fresh in-memory Postgres (PGlite, with stand-ins for Supabase's `auth.uid()`, `auth.jwt()` and roles), fails on tables without RLS and on `SECURITY DEFINER` functions without a fixed `search_path`, and runs the tests. The verifier cross-checks the drafts against each other, the revised plan and the Fresha evidence, and the chair assembles `PLAN.md` section by section, keeping `decisions.md`, `CONVENTIONS.md` and the skills consistent with it. If the review's chair is still working, this waits for it automatically.

### Phase audit

```sh
./run-council.sh audit 0 ~/glowdesk
./run-council.sh audit 5 ~/glowdesk "Extra focus for this audit"
```

Checks whether a full plan phase is properly implemented in a local app repo: every subphase of it plus the phase's exit criteria. A subphase id such as `0.2` is widened to its whole phase. The repo must contain the plan at `plan/parts/11-delivery-plan.md`, and the local Supabase stack must be able to start there. A gates task runs every check once: install, `db:reset`, `db:test`, `db:lint`, type drift, Deno tests, `verify` and Playwright. Then four auditors work in parallel: database and security (including live attacks on tenant and branch isolation through the local API), Edge Functions, frontend with English and Arabic walkthroughs and screenshots, and conformance to every bullet of the phase and its ADRs. The verifier re-checks their findings and decides the verdict (`PASS`, `PASS WITH FIXES` or `FAIL`), and the chair writes `output/audit/phase-<phase>/AUDIT_REPORT.md`, ending with a ready-to-paste fix prompt for Cursor. To keep a scan-through cheap, the audit runs on its own two profiles instead of the four council members: `auditor` (`AUDITOR_MODEL` in `council.conf`, default `deepseek/deepseek-v4-flash`) runs the gates and all four audit passes, and `audit-lead` (`AUDIT_LEAD_MODEL`, default `openai/gpt-6-luna`) verifies and writes the report. Run `./setup.sh` once to create them. The repo is treated as read-only, but the gates reset and reseed its local database. The audit covers whatever is checked out, so check out the branch you want audited first.

### Re-check after fixes

```sh
./run-council.sh recheck 5 ~/glowdesk
```

Once you have applied an audit's fix prompt, this checks only what that audit flagged, without re-running the full audit. A gates task runs every check again, then one auditor rules on each accepted finding, each failed gate and each criterion that was not done in `output/audit/phase-<phase>/AUDIT_REPORT.md` (`FIXED`, `PARTIAL` or `NOT FIXED`), and sweeps the fix commits for regressions: edited migrations, loosened RLS, weakened or skipped tests, missing Arabic strings. The audit lead verifies it, gives a verdict with the same rule as the audit, and writes `output/audit/phase-<phase>/recheck/RECHECK_REPORT.md` with a fix prompt for anything left. The original audit is left untouched; a previous re-check is moved to `runs/`.

### CI merge gates

```sh
./run-council.sh ci ~/glowdesk
./run-council.sh ci ~/glowdesk "Extra focus for this pass"
```

Goes through the app repo's code together with its plan and designs the GitHub merge gates, so nothing is merged into `main` unless the plan's guarantees are proven by tests. The council works on the commit that is checked out; uncommitted changes are ignored because CI never sees them. The repo must contain the plan at `plan/parts/11-delivery-plan.md`.

The repo stays read-only. Each member works in its own clone under `.ci-sandbox/`.

1. A baseline task pins the toolchain versions and runs and times every existing check: database reset, pgTAP, lint, type drift, Deno, `verify` and Playwright in both languages. It also finds the smallest local Supabase stack the suites need.
2. A traceability task decides which phases are built. It maps every acceptance criterion, Tests bullet, testable ADR and CONVENTIONS §7 rule to the test that proves it, and lists the gaps with owners.
3. Four workers then run in parallel:
   - One writes the GitHub Actions workflows and the branch ruleset for `main`.
   - Three write the missing database (pgTAP), Edge Function (Deno) and frontend (Vitest, Playwright) tests, including guard tests that fail when a future PR breaks a rule (a table without RLS, a route without an auth check, a missing Arabic key).
4. Every new test must be shown able to fail: the author breaks the guarantee on purpose and the test must catch it.
5. The audit lead replays the whole pipeline in a fresh clone, re-runs the mutation checks and rules on every test. It then writes `output/ci/CI_REPORT.md`, which ends with install steps and a ready-to-paste Cursor prompt. Tests that fail because the code has a real defect are listed with the fix, so the PR that installs CI can fix them too.

Like `audit`, it runs on the `auditor` and `audit-lead` profiles and resets the local database. When it finishes, it restarts the stack from the app repo.

The workflows, ruleset and tests land in `output/ci/draft/`, mirroring the repo. Check them with `node check-ci.mjs output/ci/draft ~/glowdesk`. Among other things, the check verifies that:

- every action is pinned to a real commit SHA;
- each required check is a job that actually reports on pull requests into `main`;
- the aggregating job can't be skipped into a pass;
- nothing that runs on a PR escapes the required checks;
- every `pnpm` script the workflows call exists;
- the draft touches no migrations.

It also runs actionlint, either installed (`brew install actionlint`) or through Docker.

To install, run `./install-ci.sh ~/glowdesk`. It validates the draft and copies it into the repo. Commit the files, open a PR into `main`, and merge once it's green. Then apply the ruleset with the `gh api` command it prints.

To use the skills, install them into the app repo with `./install-skills.sh /path/to/app`. It validates them, then copies them to the app's `.cursor/skills/` and `.claude/skills/`. Visual design is left to your own design skill.

## Safety

Agents are told the target is staging: they may click anything, but created records are prefixed `COUNCIL-TEST`, existing records are never modified or deleted, and the final report lists everything to clean up. Do not point it at production.
