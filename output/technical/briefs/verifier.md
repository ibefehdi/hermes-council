# Brief: Verify the deep technical pass (verifier)

Output: /Users/fahad/council/output/technical/review.md

Inputs: settings.md, reports.md, gaps.md, flows.md, architecture.md, test-records.md in /Users/fahad/council/output/technical/.

1. Cross-check the five files against each other and against the first survey: conflicting route names, endpoints, entity fields, or links; pages present in one file and missing in another.
2. Propagation check in the live dashboard: for the COUNCIL-TEST appointment checkout and quick sale in test-records.md, confirm they appear in Sales, Payments, Daily sales summary, the client's history, and the relevant reports. Record yes/no with evidence.
3. Spot-check at least 25% of claims in each file in the live dashboard (prioritise endpoints, form validation rules, settings effects, report metrics). Verdict table: claim | file | CONFIRMED / WRONG / PARTIAL / UNVERIFIED | evidence.
4. Run `node /Users/fahad/council/check-mermaid.mjs` on every file and list diagrams that fail; check diagrams match the evidence (no invented entities or edges).
5. Confirm test-records.md is complete (every COUNCIL-TEST record you see in the dashboard is logged).

Sections of review.md: Summary with confidence per file, Verdict table, Propagation results, Conflicts and rulings, Diagram check, Test-record audit.
