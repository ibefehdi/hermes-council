# Plan review round 2: common brief

Round 1 produced a plan for a new multi-tenant spa/salon SaaS. Your job now is an adversarial audit: find everything that is missing, wrong, inconsistent, unsafe, or not buildable as written. Assume there are mistakes. "Looks good" is not a finding.

## Inputs (read-only for reviewers)

- Product definition and constraints: `{{COUNCIL_DIR}}/output/plan/briefs/common.md` and `skill-format.md`. The plan must satisfy these. Key constraints: multi-tenant (tenant = company, SpaCorner first, multiple branches with their own staff, hours and services with per-branch price/duration), all server logic in Supabase Edge Functions (Deno) isolated from each other, React + TypeScript frontend, English + Arabic with full RTL from day one, KWD with 3 decimals, per-branch time zone, MVP = core ops with cash/manual payments, an online gateway chosen for a later phase, visual design left to an external design skill.
- Round 1 outputs in `{{COUNCIL_DIR}}/output/plan/`: `requirements.md`, `data-model.md`, `sql/*.sql`, `backend.md`, `frontend.md`, `skill-drafts/`, `review.md`, `decisions.md`, `IMPLEMENTATION_PLAN.md`, `CONVENTIONS.md`, `skills/.cursor/skills/*/` and `skills/.claude/skills/*/`.
- Reverse-engineering evidence of what a mature product in this space does: `{{COUNCIL_DIR}}/output/TECHNICAL_REPORT.md`, `FINAL_REPORT.md`, `pages.json`, `links.md`, and `output/technical/*.md`. Use it to spot missing features and edge cases. The clean-room rule still applies: never propose copying its UI, text, branding or API shapes.

If any round 1 deliverable is missing or obviously truncated, that is a blocker finding in itself.

## Rules

- Do not edit any round 1 file. Write only your own output file under `{{COUNCIL_DIR}}/output/plan/review2/`, and write it incrementally (append as you go) so work survives a crash.
- Verify every claim about Supabase, Deno, Postgres, or a payment provider that your finding depends on with web search, and cite the URL. Do the same when you dispute a round 1 claim.
- Validate any Mermaid you write with `node {{COUNCIL_DIR}}/check-mermaid.mjs <file>`, and the skills with `node {{COUNCIL_DIR}}/check-skills.mjs {{COUNCIL_DIR}}/output/plan/skills`. Report failures as findings.
- Cite locations precisely: file, heading, ADR id, phase, SQL file and line, skill name.
- Be concrete: every finding must carry a fix that the chair can apply without further research (replacement text, SQL, a new ADR, a new backlog item, a moved phase).

## Finding format

```
### F-<area>-<n>: <short title>
- Severity: blocker | major | minor
- Location: <file / heading / ADR / phase / skill>
- Problem: <what is wrong or missing>
- Evidence: <quote, reasoning, or URL>
- Fix: <exact change to make>
- Affects: <other ADRs, phases, skills, SQL files that must change with it>
```

Severity guide: blocker = data leak between tenants, double booking, money or tax error, unbuildable or contradictory decision, MVP requirement missing. Major = wrong phase placement, untestable acceptance criteria, missing edge case that users will hit, a skill that would teach the wrong convention. Minor = clarity, naming, small omissions.

End your file with a summary table (id, severity, one-line title) and a count per severity.
