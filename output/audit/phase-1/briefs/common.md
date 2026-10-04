# Phase audit: common brief

A team implemented plan phase **1** of a multi-tenant spa/salon SaaS (GlowDesk) in the git repository at `/Users/fahadasad/glowdesk`. Your job is an adversarial audit: decide whether that phase is properly implemented, exactly as the plan specifies, and safe. Assume there are mistakes. "Looks good" is not a finding, and a claim in a commit message, README or code comment is not evidence until you have checked the code or run it.

## What "the phase" means

- The specification is the full section for phase 1 in `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md`: everything from the heading `### Phase 1:` up to the next `### Phase` heading. That is the phase's own Goal, "What the business can do at the end", Risks and Exit criteria, plus **every** subphase `1.<n>` under it. The audit always covers the whole phase; never stop at the first subphase or audit a subset.
- Every item counts, in the phase header and in each subphase: Goal, Features delivered, Database work, Edge Functions, Screens, i18n/RTL, Acceptance criteria, Tests, Dependencies and Backlog. The phase passes only if every subphase passes and the phase exit criteria are met.
- Organise your output by subphase (one section per subphase, in order), followed by a section for the phase-level exit criteria.
- Binding rules, in this order of precedence: `/Users/fahadasad/glowdesk/plan/decisions.md` (ADRs) > `/Users/fahadasad/glowdesk/plan/PLAN.md` > `/Users/fahadasad/glowdesk/plan/CONVENTIONS.md` > the skills in `/Users/fahadasad/glowdesk/.cursor/skills/`. When the phase text and an ADR disagree, the ADR wins, and an implementation that followed the ADR is correct.
- `/Users/fahadasad/glowdesk/plan/sql/v2/` is a reference validation set, not the spec. Code that differs from it is not wrong for that reason alone; code that copies a bug from it is.
- Dependencies: work from earlier phases may legitimately exist already. Do not credit it to this phase, and do not fault this phase for later-phase items that are absent. Work that the team pulled forward from a later phase is fine if it was declared; note it.

## Rules

- **The repository is read-only.** Never edit, create, delete, stage or commit files in `/Users/fahadasad/glowdesk`, never switch branches, never stash, never push. Read files, use `git log`, `git show`, `git diff` and `git status`, and run read-only queries.
- **Do not reset or reseed the database, and do not run the Playwright suite.** The gates task already ran every stateful check once and saved the logs in `/Users/fahadasad/hermes-council/output/audit/phase-1/gates/`. Use those logs. You may run `supabase test db` (it runs inside rolled-back transactions) and read-only `psql` queries against `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, and you may send requests to the local API on `http://127.0.0.1:54321` using the seed logins in `/Users/fahadasad/glowdesk/README.md`.
- Never copy secrets into your output: no service-role keys, JWTs, passwords from `.env` files or API keys. The local seed password documented in the README is fine to mention.
- Write only your own output file under `/Users/fahadasad/hermes-council/output/audit/phase-1/`, and write it incrementally (append as you go) so work survives a crash.
- Cite every location precisely: repo path and line (`supabase/migrations/20261004170400_create_memberships.sql:42`), commit hash, test name, or gate log file and line.
- Verify any claim about Supabase, Postgres, Deno, Lingui, TanStack or Playwright behaviour that a finding depends on with web search, and cite the URL.
- Every finding must carry a fix that a coding agent can apply without further research: the file to change and the exact change, a new migration, a new test, or a plan amendment.
- Items that cannot be checked on a local machine (staging deploys, Sentry, uptime monitors, cloud regions) are marked `NOT VERIFIABLE LOCALLY`, not failed, unless the phase required a local stand-in that is missing.

## Checklist statuses

- `DONE`: implemented as specified, with evidence.
- `PARTIAL`: some of it exists; say exactly what is missing.
- `MISSING`: not implemented.
- `DEVIATED-JUSTIFIED`: differs from the phase text because an ADR, a dependency, or a sound technical reason requires it, and the deviation is reported (commit message, README, or plan note).
- `DEVIATED-UNJUSTIFIED`: differs without a sound reason, or the deviation was not reported.
- `NOT VERIFIABLE LOCALLY`: see the rule above.

## Finding format

```
### F-<area>-<n>: <short title>
- Severity: blocker | major | minor
- Location: <repo path:line / commit / test / gate log>
- Problem: <what is wrong or missing>
- Evidence: <quote, command and output, query result, or URL>
- Fix: <exact change to make>
- Plan item: <the phase bullet or ADR this relates to>
```

Severity guide. **Blocker**: data visible or writable across tenants or branches, a privilege escalation, double booking, a money or tax error, an acceptance criterion not met, a gate failing, or a phase deliverable missing. **Major**: a test the phase requires is missing or does not test what it claims, a convention or ADR broken in a way that will spread, an undeclared deviation, a missing edge case users will hit. **Minor**: naming, clarity, small omissions.

End your file with a summary table (id, severity, one-line title) and a count per severity.
