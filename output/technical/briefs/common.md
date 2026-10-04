# Deep technical pass: rules for every council member

You are part of a second, deeper pass over the dashboard. A first survey already exists and is your baseline:

- /Users/fahad/council/output/FINAL_REPORT.md (product-level map)
- /Users/fahad/council/output/pages.json and pages.md (41-page inventory)
- /Users/fahad/council/output/links.md (feature links)
- /Users/fahad/council/output/review.md (verifier verdicts, incl. UNVERIFIED and WRONG items)

Read them before you start. They are READ-ONLY: never edit, move, or delete them. Do not redo confirmed work unless you need it for technical detail; spend your effort on depth and on what was missed.

All your output goes to /Users/fahad/council/output/technical/ under the file name your brief gives you. Write incrementally (append each section as you finish it) so work survives a crash; on restart, read your file first and continue where it stops.

## What "full technical detail" means

For every page you touch, record:

- Route pattern with query params (normalize IDs: /clients/:clientId), how it is reached, breadcrumb/nav path.
- UI structure: tables (columns, sorting, pagination), forms (each field: label, input type, options, required, validation message), filters, tabs, drawers, modals, menus (Add / Options / kebab), bulk actions, empty states.
- Every API call the page makes, from browser_network_requests and browser_network_request: HTTP method, path (IDs normalized), GraphQL operationName if any, purpose, key request parameters, key response field names and types, status code. Never copy tokens, cookies, auth headers, or personal data values; field names only.
- Entities read or written, with the fields you observed in UI and payloads.
- Links in and out: every way to reach another page or feature from here, and every way to arrive here.
- Plan/add-on gating and permission notes.

## UML diagrams

Use Mermaid only, in fenced ```mermaid blocks: classDiagram (domain model), erDiagram (data model), sequenceDiagram (user action -> UI -> API calls), stateDiagram-v2 (lifecycles), flowchart (navigation, components). Keep node IDs simple (letters, digits, underscores); put labels in quotes.

Validate every file you write: `node /Users/fahad/council/check-mermaid.mjs <file.md>`. Fix and re-run until it prints OK.

## Evidence

Every claim needs evidence: what you clicked or observed, the API call, or a screenshot file name. Mark anything you could not confirm as UNVERIFIED.

## Safety rules (test account, but real integrations)

- Any record you create must have a name starting with COUNCIL-TEST. Use fake contact details only: email council-test+<n>@example.com, no real phone numbers.
- Log every record you create or setting you change in /Users/fahad/council/output/technical/test-records.md (what, where, ID, created by which member, reverted yes/no). Append; other members write to it too.
- You may create and edit your own COUNCIL-TEST records. Never edit or delete records you did not create.
- Settings: prefer additive changes (add a COUNCIL-TEST option). If you must flip a toggle or change a value, note the original value and change it back.
- STOP and do not confirm if a dialog involves: buying or activating a paid add-on or plan, subscriptions or billing, connecting or changing payment providers/terminals/payouts, sending a blast campaign or any SMS/email to clients, changing the account owner, login, password, or 2FA, or deleting the location or business. Document what the dialog says instead.
- If the browser shows a login page, stop and report SESSION EXPIRED.
