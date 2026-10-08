# Chair: write the phase audit report

Inputs: `/Users/fahad/council/output/audit/phase-7/adjudication.md` (authoritative), `gates/GATES.md`, and the auditor files it refers to. Output: `/Users/fahad/council/output/audit/phase-7/AUDIT_REPORT.md`. The repository at `/Users/fahad/GlowDesk` stays read-only.

Write for the product owner first and the coding agent second: full sentences, no internal shorthand, every claim traceable to evidence. Structure:

1. **Verdict.** `PASS`, `PASS WITH FIXES` or `FAIL` for phase 7, exactly as the verifier decided, then one paragraph in plain language: is the phase done, what is the most important problem, and how much work the fixes are. Follow it with a small table of every subphase and its own status (done, done with fixes, incomplete) so the owner sees where the gaps are.
2. **What was audited.** Repository path, branch, commit, whether the working tree had uncommitted changes, and the date.
3. **Gates.** The table from `GATES.md` (command, result, key detail), including test counts.
4. **Exit and acceptance criteria.** The phase exit criteria first, then each subphase's acceptance criteria: criterion, subphase, status, evidence (test name or reproduction).
5. **Plan checklist.** The verified checklist, one section per subphase, grouped inside by section (features, database, Edge Functions, screens, i18n/RTL, tests, backlog), with statuses after the verifier's overrides.
6. **Deviations.** Declared and undeclared, each with the ruling and the reason.
7. **Findings.** Accepted findings grouped by severity, each with location, problem and fix. Rejected findings are listed briefly at the end with the reason, so nobody re-raises them.
8. **Not verifiable locally.** Items deferred to cloud environments, and what will prove them later.
9. **Fix prompt.** A ready-to-paste prompt for the coding agent (Cursor) that fixes every accepted blocker and major, in order. Use this shape and fill it in:

   ```text
   Fix the phase 7 audit findings below in /Users/fahad/GlowDesk, in order.
   Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
   Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture <the area skills these fixes touch, from: /supabase-database /supabase-edge-functions /react-frontend /i18n-rtl /airbnb-design>

   1. <finding id>: <file> - <exact change>
   ...

   Rules: never edit an applied migration (add a new one); keep both skill copies identical;
   Conventional Commits. Done = every gate in the audit passes again and each fixed
   acceptance criterion is demonstrated by a test.
   ```

   If the verdict is `PASS`, the fix prompt covers the minors only, or says there is nothing to fix.

Keep the report under about 600 lines; link to the auditor files for detail rather than copying them.
