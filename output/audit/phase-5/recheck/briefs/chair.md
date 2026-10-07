# Chair: write the re-check report

Inputs: `/Users/fahad/council/output/audit/phase-5/recheck/adjudication.md` (authoritative), `/Users/fahad/council/output/audit/phase-5/recheck/gates/GATES.md`, `/Users/fahad/council/output/audit/phase-5/recheck/recheck.md`, and the previous `/Users/fahad/council/output/audit/phase-5/AUDIT_REPORT.md`. Output: `/Users/fahad/council/output/audit/phase-5/recheck/RECHECK_REPORT.md`. The repository at `/Users/fahad/GlowDesk` stays read-only.

Write for the product owner first and the coding agent second: full sentences, no internal shorthand, every claim traceable to evidence. Structure:

1. **Verdict.** The previous verdict and the new one (`PASS`, `PASS WITH FIXES` or `FAIL`) for phase 5, exactly as the verifier decided. Then one paragraph in plain language: did the fixes work, what is still wrong, and how much work remains.
2. **What was re-checked.** Repository path, branch, the audited commit, the re-checked commit, the fix commits (one line each), whether the working tree had uncommitted changes, and the date.
3. **Gates.** One row per gate: command, result before, result now, key detail, including test counts before and now.
4. **Previous findings.** One row per accepted finding of the audit: id, severity, title, status now, evidence. Anything not `FIXED` gets a sentence on what remains.
5. **Criteria.** Every exit or acceptance criterion the audit did not rate `DONE`: criterion, subphase, status now, evidence.
6. **New findings.** Accepted `F-RC` findings grouped by severity, each with location, problem and fix. Rejected ones are listed briefly with the reason.
7. **Fix prompt.** If anything remains, a ready-to-paste prompt for the coding agent (Cursor), in this shape:

   ```text
   Fix the remaining phase 5 findings below in /Users/fahad/GlowDesk, in order.
   Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
   Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture <the area skills these fixes touch, from: /supabase-database /supabase-edge-functions /react-frontend /i18n-rtl /airbnb-design>

   1. <finding id>: <file> - <exact change>
   ...

   Rules: never edit an applied migration (add a new one); keep both skill copies identical;
   keep every test assertion; Conventional Commits. Done = every gate passes and each
   fixed acceptance criterion is demonstrated by a test.
   ```

   If the verdict is `PASS` with nothing left, say plainly that phase 5 passes and there is nothing to fix.

Keep the report under about 300 lines; link to `recheck.md` and the audit report for detail rather than copying them.
