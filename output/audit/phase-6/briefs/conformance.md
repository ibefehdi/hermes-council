# Plan conformance audit

Output: `/Users/fahad/council/output/audit/phase-6/conformance.md`

You check the implementation against the plan item by item, and the process against CONVENTIONS. Start by reading `/Users/fahad/council/output/audit/phase-6/gates/GATES.md`.

1. **Extract the spec.** List every subphase of phase 6 first (count them and state the count). Then copy every bullet of each subphase from `/Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md` into a checklist: Features delivered, Database work, Edge Functions, Screens, i18n/RTL, Acceptance criteria, Tests and Backlog. Add the phase-level Exit criteria as their own rows. Cross-check with the same phase in `/Users/fahad/GlowDesk/plan/PLAN.md`; if the two disagree, note it and apply the precedence rule from the common brief.
2. **Rule on each item.** For every checklist row give a status from the common brief and the evidence: repo path and line, commit, test name, or gate log line. A row is not `DONE` because a file with the right name exists; open it and confirm it does what the bullet says. Each acceptance criterion needs a demonstration: a passing test that actually exercises it, or a reproduction you ran against the local stack.
3. **ADRs.** List every ADR the phase cites or that governs its work. For each, state whether the implementation honours it, with evidence. An ADR violation is at least major.
4. **Deviations.** Collect every place the implementation differs from the phase text. For each, find whether it was declared (commit messages, README, plan notes, PR text) and rule `DEVIATED-JUSTIFIED` or `DEVIATED-UNJUSTIFIED` with your reasoning. Also check the opposite direction: work done in this phase that belongs to a later phase, and whether that was declared.
5. **Process.** Branch names follow CONVENTIONS §8 (`feat/`, `db/`, `fn/`, `fix/`); commits follow Conventional Commits with a bounded-context scope; one logical change per commit; no applied migration edited; generated files (`database.types.ts`, compiled catalogs) committed when CONVENTIONS requires; no secrets or local-only files committed (`.env`, `.env.local`, `supabase/.temp`); the definition of done in CONVENTIONS §9 is met for each backlog task.
6. **Docs and skills.** If the phase changed a convention, the skills (both `.cursor/skills/` and `.claude/skills/` copies, which must be identical) and the glossary were updated in the same work. Check the README still describes how to run what the phase delivered.
7. **Dependencies.** Confirm the phase's declared dependencies are actually in place, and flag anything the next phase will need from this one that is missing.

End with the full checklist table (subphase | item | section | status | evidence), a one-line status per subphase, and the phase exit criteria, before the findings.
