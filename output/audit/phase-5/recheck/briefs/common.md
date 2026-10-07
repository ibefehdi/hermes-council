# Phase re-check: common brief

The phase **5** audit of the git repository at `/Users/fahad/GlowDesk` found problems, and the team says it has fixed them. Your job is an adversarial re-check: decide whether every problem the audit accepted is really fixed, and whether the fixes broke anything. Assume the fixes are incomplete until the code, a test or a gate log proves otherwise. A commit message saying "fixed" is not evidence.

This is not a new full audit. The scope is exactly:
- every finding the previous audit **accepted** (blockers, majors and minors),
- every gate the previous audit recorded as `FAIL` or `MISSING`,
- every phase exit criterion and subphase acceptance criterion the previous audit did not rate `DONE` (excluding `NOT VERIFIABLE LOCALLY`),
- any regression introduced by the fix commits.

## Inputs

- The previous audit, read-only: `/Users/fahad/council/output/audit/phase-5/AUDIT_REPORT.md` (verdict, criteria, findings, fix prompt) and `/Users/fahad/council/output/audit/phase-5/adjudication.md` (the authoritative rulings). The auditor files and `/Users/fahad/council/output/audit/phase-5/gates/GATES.md` hold the detail.
- The audited commit is in the report's "What was audited" section and in `/Users/fahad/council/output/audit/phase-5/gates/GATES.md`. The fixes are `git log <audited commit>..HEAD` plus any uncommitted changes in the working tree.
- Fresh gate logs for this re-check: `/Users/fahad/council/output/audit/phase-5/recheck/gates/GATES.md`.
- Binding rules, as in the audit: `/Users/fahad/GlowDesk/plan/decisions.md` (ADRs) > `/Users/fahad/GlowDesk/plan/PLAN.md` > `/Users/fahad/GlowDesk/plan/CONVENTIONS.md` > the skills in `/Users/fahad/GlowDesk/.cursor/skills/`. The specification is the phase 5 section of `/Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md`.
- Findings the previous audit rejected stay rejected. Do not re-raise them unless the fixes changed the code they concern.

## Rules

- **The repository is read-only.** Never edit, create, delete, stage or commit files in `/Users/fahad/GlowDesk`, never switch branches, never stash, never push. Read files and use `git log`, `git show`, `git diff` and `git status`.
- **Do not reset or reseed the database, and do not run the Playwright suite** (the gates task is the one exception: it follows `gates.md`). The gates task already ran every stateful check and saved the logs in `/Users/fahad/council/output/audit/phase-5/recheck/gates/`. You may run `supabase test db` and read-only `psql` queries against `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, and send requests to the local API on `http://127.0.0.1:54321` using the seed logins in `/Users/fahad/GlowDesk/README.md`.
- Never copy secrets into your output. The local seed password documented in the README is fine to mention.
- Write only your own output file under `/Users/fahad/council/output/audit/phase-5/recheck/`, and append as you go so work survives a crash.
- Cite every location precisely: repo path and line, commit hash, test name, or gate log file and line.
- A fix counts only if it removes the cause. A gate made green by deleting or weakening assertions, adding `skip`, `only`, `fixme` or retries, inflating timeouts to hide a race, or excluding a test or locale from the run is `NOT FIXED`, and is itself a blocker finding.
- Editing a migration that existed at the audited commit is a blocker: fixes must add new migrations.

## Statuses for each previous item

- `FIXED`: the problem is gone, with evidence (the changed code, a test that would fail without the fix, a passing gate).
- `PARTIAL`: some of it is fixed; say exactly what remains.
- `NOT FIXED`: unchanged, or the change does not address the cause.
- `NOT VERIFIABLE LOCALLY`: only if the previous audit already rated it so, or the fix moved it to a cloud-only check.

## New findings

Problems the fixes introduced use the audit's format, with ids `F-RC-<n>`:

```
### F-RC-<n>: <short title>
- Severity: blocker | major | minor
- Location: <repo path:line / commit / test / gate log>
- Problem: <what is wrong>
- Evidence: <quote, command and output, query result, or URL>
- Fix: <exact change to make>
- Plan item: <the phase bullet, ADR or previous finding this relates to>
```

Severity guide, as in the audit. **Blocker**: data visible or writable across tenants or branches, a privilege escalation, double booking, a money or tax error, an acceptance criterion not met, a gate failing, a phase deliverable missing, or a test weakened to pass. **Major**: a required test missing or not testing what it claims, a convention or ADR broken in a way that will spread, an undeclared deviation. **Minor**: naming, clarity, small omissions.
