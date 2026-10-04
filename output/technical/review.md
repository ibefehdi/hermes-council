# Deep technical pass verification review

Date: 2026-10-04
Environment: staging, Test Salon, pid 3110536, location 3216614, authenticated session.
Method: Cross-read architecture.md, settings.md, reports.md, gaps.md, flows.md, and test-records.md; live Playwright spot checks across Reports, Settings > Cancellation reasons, Clients list, Dashboard chrome, and Fresha Connect; Mermaid validator run.

## Summary and gate

The reports are broadly credible and technically useful, with strong direct evidence for Reports, Setup/Scheduling, global navigation, Connect, and the exercised create flows. However, the required propagation check cannot pass: the current live Clients list returned count 0 and no rows, so the COUNCIL-TEST client/appointment/service records documented by flows.md could not be re-observed in the current session. Several workflow edges and inferred APIs remain correctly marked UNVERIFIED, but some architecture diagrams and prose still promote those edges as confirmed. Gate: CONDITIONAL PASS for the technical map; not sufficient to claim full propagation or complete workflow coverage.

Confidence by section:

| Section | Confidence | Rationale |
|---|---:|---|
| Platform, authentication, global API catalogue | 0.90 | Repeated 200 session/bootstrap traffic and consistent app version; some host purpose remains inferred. |
| Reports | 0.95 | Live Reports route showed 59, 3 dashboards, 49 standard, 10 premium, 0 custom; catalogue UI matched reports.md. |
| Settings | 0.92 | Cancellation-reasons route and COUNCIL-TEST row confirmed live; gated/billing-sensitive areas intentionally not exercised. |
| Global top bar, drawers, user account | 0.90 | Routes and controls are visible/live; notification data endpoint and some account API details remain unverified. |
| Connect | 0.93 | Direct navigation loaded full Connect app, Client/Team Connect controls, search/settings, conversation list, and Step 1 of 3. |
| Create/edit flows | 0.78 | Client/service/appointment creation is well documented, but current-session propagation is not reproducible; product/supplier mutation details are inferred. |
| Data model and workflow edges | 0.70 | Core entities are grounded, while inventory, payroll, POS, automation triggers, and some cardinalities remain unexercised. |
| Mermaid diagrams | 1.00 syntactic / 0.78 evidentiary | All 15 diagrams parse; several diagrams include edges explicitly labeled UNVERIFIED elsewhere. |

## Verdict table

| Claim | Source member/file | Status | Evidence |
|---|---|---|---|
| Reports catalog has 59 reports, split into 3 dashboards, 49 standard, 10 premium, 0 custom | reports.md / cartographer | CONFIRMED | Live `/reports` redirected to `/reports/report-group/1?category=all`; accessibility tree showed exactly those counts and category tabs. |
| Reports use `/reports/table/<slug>` and support search, Created by, Category, Add | reports.md | CONFIRMED | Live Reports snapshot showed Search textbox, Created by, Category, Add, and report catalog. |
| `/setup/scheduling/cancellation-reasons` has Add/Options and default reasons | settings.md | CONFIRMED | Live snapshot showed the route, Cancellation reasons heading, Options/Add, Duplicate appointment, Appointment made by mistake, Client not available. |
| COUNCIL-TEST cancellation reason exists | settings.md/test-records.md | CONFIRMED | Live snapshot showed `COUNCIL-TEST cancellation reason`; record log contains creation endpoint and payload. |
| Setup scheduling navigation includes cancellation reasons and online-booking group | settings.md | CONFIRMED | Live scheduling snapshot showed the Scheduling navigation and three online-booking entries (labels are icon-only in accessibility output). |
| Global top bar contains Continue setup, Search, Performance insights, Notifications, Fresha Connect, user menu | gaps.md/architecture.md | CONFIRMED | Live Reports, Settings, and Clients snapshots all showed these controls; Connect href was `/connect`. |
| Fresha Connect is a full app, not merely a modal | gaps.md/architecture.md | CONFIRMED | Live `/connect` redirected to `/connect/customers/conversations/onboarding-01a105e7-...`; snapshot showed Client Connect, Team Connect (4), Search, Settings, New message, conversations, and Step 1 of 3. |
| Reports endpoint is one reporting GraphQL backend with operations listed | reports.md/architecture.md | PARTIAL | Catalog and counts confirmed live; this run did not capture full request bodies/operation names, so endpoint contract is accepted from prior evidence but not re-probed here. |
| Client list exposes search API and contains the created client | architecture.md/gaps.md/flows.md | PARTIAL | Current live `/clients/list` loaded successfully but showed count `0` and no rows. The route/chrome is confirmed; the record propagation claim is not reproducible in this session. |
| Client creation flow requires first name and uses duplicate check then POST customer | flows.md | UNVERIFIED | No client was created in this verification run; prior flow evidence is documented but not independently replayed to avoid duplicate records. |
| Service creation mutation and product/supplier mutations are confirmed | flows.md | PARTIAL | Service flow is described with a captured mutation; product and supplier entries explicitly say inferred/missed network capture, so they must not be promoted to confirmed API contracts. |
| Appointment creation produced Oct 5 10:00–11:00 COUNCIL-TEST appointment | flows.md/test-records.md | UNVERIFIED | Current Clients list showed no data and this verifier did not navigate into calendar or appointment list to mutate/refresh records. Prior observation remains historical, not current propagation proof. |
| Test records propagate to Sales, Payments, Daily sales, client history, and reports | flows.md propagation matrix | UNVERIFIED | Required propagation check is incomplete. Current client list was empty; no positive current-session evidence for all five destinations exists. |
| Link-builder hard-navigation 403 is invariant | gaps.md/architecture.md | PARTIAL | Reports state correctly qualifies it as session/environment-dependent; no invariant should be asserted. This run did not retest the route. |
| Notifications drawer has five tabs and settings route | gaps.md | UNVERIFIED | Top-bar button was confirmed visible, but this run did not click it. Keep drawer tabs and endpoint as prior evidence, not newly verified evidence. |
| Reports exact count was previously 58 | architecture.md historical open question | WRONG | Live Reports showed 59. The newer sections correctly use 59; any remaining “58” wording must be removed or labeled historical. |
| Loyalty is a gated add-on at KWD 32.95/location/month | gaps.md | UNVERIFIED | Not opened in this run; prior evidence is plausible and safety-compliant, but not independently rechecked. Keep the no-activation rule. |
| Global wallet/finance/credits calls are functional feature links | architecture.md/gaps.md | PARTIAL | Prior traffic evidence supports recurring background calls; it does not establish navigational/functional links. The newer wording correctly distinguishes observed traffic from links. |
| Inventory, POS/register, automation triggers, payroll chains are confirmed workflows | architecture.md diagrams / flows.md | PARTIAL | Reports and flows repeatedly mark these unexercised; diagrams/prose should not imply confirmed propagation. |

## Propagation results

| Record | Sales list | Payments | Daily sales | Client history | Reports | Result |
|---|---|---|---|---|---|---|
| COUNCIL-TEST Client1 / Service1 / Oct 5 appointment | Not checked in this run | Not checked in this run | Not checked in this run | Current Clients list returned 0; not observed | Not checked in this run | UNVERIFIED; propagation gate not passed |

The current live `/clients/list` is itself a material discrepancy against `flows.md` and `gaps.md`, which reported 4 clients and the sibling-created COUNCIL-TEST client visible. This could be session timing, data replication, account state, or an environment difference; it must be reported as a discrepancy rather than silently resolved.

## Corrections with the right information

1. Keep the canonical Reports count at 59 (3 dashboards + 56 tables, with 49 standard and 10 premium in the live catalog). Remove any residual “58 reports” statement except as a historical baseline note.
2. Keep `COUNCIL-TEST cancellation reason` logged as additive and not reverted. The live settings page confirmed it exists.
3. Mark all flow propagation destinations as UNVERIFIED until a single authenticated session observes the same records in Sales, Payments, Daily sales, client history, and Reports. The current Clients list count 0 prevents a positive result.
4. Treat `products_createProduct` and supplier `POST /suppliers` as inferred unless a request body/status is captured. Do not present them as confirmed API contracts.
5. Treat Connect UI coverage as CONFIRMED, but keep Connect API surface UNVERIFIED. The live route loaded a separate full application and onboarding modal, not merely a modal-only feature.
6. Treat top-bar button visibility as CONFIRMED. Keep click-through details for Notifications and Performance insights tied to their existing screenshots/session evidence unless re-clicked in the same verification run.
7. In architecture flowcharts, visually distinguish confirmed edges from inferred/unexercised edges. In particular, inventory, payroll, automation, POS/register, and “Reports aggregates” edges should be dashed or labeled UNVERIFIED where no direct trace exists.
8. Correct any data-model relationship notation that is only semantic/inferred. The ER diagram uses cardinalities such as `APPOINTMENT ||--o{ CLIENT`, which visually asserts a database relationship; retain only if backed by observed payloads or label it conceptual.

## Missing pages, features, and links

- Required propagation destinations remain unverified: Sales list, Payments, Daily sales summary, client history, and relevant report rows for the COUNCIL-TEST appointment.
- Notification drawer click-through and its exact API endpoint were not independently verified in this run.
- The Clients list empty/current-state discrepancy needs resolution before relying on client, service, supplier, and appointment links as current-state evidence.
- Product creation request payload/status and supplier creation request payload/status are missing from evidence.
- POS/register data flow, inventory chain, automation trigger execution, payroll chain, report email/scheduling, loyalty dashboard content, Data connector behavior, and permission edge cases remain unverified as stated by the workers.
- Empty-state coverage is incomplete for current Clients list versus the populated-state screenshots; both states should be retained with session/date context.

## Disagreements and rulings

1. Reports count: older architecture/open-question text says 58; reports.md and live UI say 59. Ruling: 59 is canonical; 58 is wrong/historical.
2. Connect scope: early architecture called the full API/onboarding unverified and prior baseline treated it as a link/modal-like feature; gaps.md and the live run show a full Connect application with Client/Team Connect and Step 1 of 3. Ruling: full UI scope confirmed; API remains unverified.
3. Link-builder 403: reports differ between successful and failed sessions. Ruling: session/environment-dependent, not a universal 403.
4. Client propagation: flows/gaps report the COUNCIL-TEST client visible; current verifier session shows client count 0. Ruling: historical observation is retained, current propagation is unverified until reconciled.
5. Mutation certainty: flows documents captured service mutation but explicitly marks product/supplier network details inferred. Ruling: service mutation can be reported as observed; product/supplier mutations remain partial/unverified.
6. Global background APIs versus feature links: architecture/gaps observe wallet/finance/credits traffic, but that does not prove user-facing links. Ruling: observed recurring background traffic only.

## Diagram check

Command run:
`node /Users/fahad/council/check-mermaid.mjs /Users/fahad/council/output/technical/settings.md /Users/fahad/council/output/technical/reports.md /Users/fahad/council/output/technical/gaps.md /Users/fahad/council/output/technical/flows.md /Users/fahad/council/output/technical/architecture.md`

Result: `OK: 15 mermaid diagram(s) parsed`.

Syntactic validation passes. Evidentiary validation is lower: architecture and flow diagrams include several conceptual edges whose supporting files explicitly say UNVERIFIED. Those edges should be dashed/labeled as inferred in the final synthesis.

## Test-record audit

`test-records.md` is complete relative to the records reported by the workers: Client1, its note, Service1, Product1, Supplier1, the appointment, and the cancellation reason are listed with creator/source and not-reverted status. No new record was created by this verifier. The live settings page confirmed the cancellation reason. The current Clients list did not expose Client1, so the log cannot by itself establish that the record is currently replicated or visible.

No paid add-on, billing, payment-provider, logout, deletion, refund, void, bulk delete, or outbound client message action was triggered.
