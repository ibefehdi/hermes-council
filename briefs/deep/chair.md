# Brief: Technical final report (chair)

Output: {{COUNCIL_DIR}}/output/TECHNICAL_REPORT.md

Do NOT modify or overwrite {{COUNCIL_DIR}}/output/FINAL_REPORT.md. It is the first survey's report and must stay as it is. You write a separate document.

Inputs: everything in {{COUNCIL_DIR}}/output/technical/ (settings.md, reports.md, gaps.md, flows.md, architecture.md, test-records.md, review.md) plus the first survey files for context. The verifier's review.md overrides other members where they conflict. Do not invent anything; carry UNVERIFIED labels through.

Structure of TECHNICAL_REPORT.md:

1. Scope and method: what this pass covered, what changed versus FINAL_REPORT.md, confidence summary.
2. System architecture: component diagram, frontend stack, API hosts and style, auth mechanism (no secrets), realtime, third parties.
3. Domain model: classDiagram and erDiagram, entity reference tables.
4. Module technical reference: for every page, grouped by module: route, purpose, UI structure, fields, actions, API calls, links in and out.
5. Page connectivity: full adjacency table and navigation flowchart.
6. Setup and settings reference, including "setting -> affected features".
7. Reports reference: catalogue, metrics, filters, data lineage.
8. Create and edit flows: one sequenceDiagram per flow, validation rules, propagation matrix.
9. Lifecycles: stateDiagram-v2 for appointment, sale/payment, stock order and any others observed.
10. API endpoint catalogue (complete table).
11. Items missed by the first survey and how they were resolved; remaining unknowns.
12. Test records created and cleanup checklist.
Appendix: evidence index (screenshots per page).

Validate with `node {{COUNCIL_DIR}}/check-mermaid.mjs {{COUNCIL_DIR}}/output/TECHNICAL_REPORT.md` and fix until OK. Write for engineers: precise, complete, full sentences where explanation is needed, tables for reference data.
