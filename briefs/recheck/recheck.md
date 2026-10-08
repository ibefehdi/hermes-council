# Re-check: verify every fix

Output: `{{AUDIT_DIR}}/recheck.md`

1. **Build the checklist.** From `{{PREV_DIR}}/adjudication.md` and `{{PREV_DIR}}/AUDIT_REPORT.md`, list every accepted finding (id, severity, title), every gate that was `FAIL` or `MISSING`, and every exit or acceptance criterion that was not `DONE`. Write this list to your file first. Nothing on it may be dropped.
2. **Record the fix range.** The audited commit, current `HEAD`, `git log --oneline <audited commit>..HEAD`, `git diff --stat <audited commit>..HEAD`, and `git status --porcelain`. If there are no new commits and no uncommitted changes, say so at the top: nothing was fixed.
3. **Rule on every checklist item**, in the order of the list: status (`FIXED`, `PARTIAL`, `NOT FIXED`, `NOT VERIFIABLE LOCALLY`), the evidence, and for anything not `FIXED`, what remains and the exact fix.
   - Gates: use the fresh `{{AUDIT_DIR}}/gates/GATES.md` and its logs. Compare test counts with `{{PREV_DIR}}/gates/GATES.md`: a lower test count, or a Playwright project (for example `ar`) that no longer runs, is a finding.
   - Test findings: open the diff of every changed test file against the audited commit. Confirm no assertion was removed or loosened and no `skip`, `only`, `fixme`, retry or blanket timeout was added. Confirm the new or changed test exercises the behaviour the finding describes and would fail without the fix.
   - Code findings: read the changed code and confirm it removes the cause, not just the symptom the audit happened to quote. Where the finding concerns data access, re-run the relevant read-only query or local API request and quote the result.
   - Criteria: re-rate each criterion with the evidence that now proves it.
4. **Regression sweep over the whole fix diff.** Check, and report each as an `F-RC-<n>` finding if it fails:
   - no migration that existed at the audited commit was edited, renamed or deleted;
   - no RLS policy, grant or `SECURITY DEFINER` function was loosened, and new functions pin `search_path`;
   - new user-facing strings exist in both the `en` and `ar` catalogues;
   - both copies of every changed skill (`.cursor/skills/` and `.claude/skills/`) are identical;
   - changes outside the findings' scope are noted; they are only faults if they break a rule or a test;
   - commit messages follow Conventional Commits.
5. **End with** a table (item | previous severity or status | now | evidence), the new findings with a summary table (id, severity, one-line title), and a count per status and per severity.
