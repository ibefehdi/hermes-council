Fresha Partner Dashboard verification review
Date: 2026-10-04
Reviewer: Verifier
Environment: staging, Test Salon, location 3216614, authenticated session confirmed

Overall verdict: PARTIAL PASS. The two reports are broadly consistent on the navigation inventory and core entity relationships, but several Linker edges are hypotheses explicitly marked UNVERIFIED, and the Connect page plus some global/permission-gated behavior were under-described. The live session also did not reproduce the reported hard-navigation 403 for Link builder.

Verdict table

Claim | Source member | Status | Evidence
---|---|---|---
Dashboard, Calendar, Sales, Clients, Catalogue, Fresha/Online bookings, Marketing, Team, Reports, Add-ons, Setup are the main sidebar areas | Both | CONFIRMED | Live dashboard snapshot showed links for Dashboard, Calendar, Reports, Add-ons, Setup and icon buttons; live Online bookings and Marketing routes exposed their section labels and sublinks.
Global top bar contains Continue setup, Search, Performance insights, Notifications, Fresha Connect and user menu | Both | CONFIRMED | Live dashboard/setup/reports snapshots showed all six controls; Notifications displayed badge 4 on setup/reports.
Fresha logo routes to /calendar | Both | CONFIRMED | Live snapshots showed link href /calendar.
User menu includes My profile and Personal settings | Cartographer | CONFIRMED | User-menu find result exposed /user-account/profile and /user-account/personal-settings. The reports also listed referral, Help and support, and Log out, but those labels were not all exposed in the accessibility snapshot.
Setup is a settings hub with Settings, Online presence, Marketing and Other tabs | Cartographer | CONFIRMED | Live /setup snapshot showed heading Workspace settings, Test Salon, and all four tabs. It also showed links to business setup, scheduling, sales, clients, legal entities, team, forms and payments.
Marketing has Messaging, Promotion and Engage groups, with Reviews cross-linking to /clients/online-reputation?tab=all | Both | CONFIRMED | Live /marketing/automated-messages snapshot showed all groups and exact Reviews href.
Online bookings has Marketplace profile, Reserve with Google, Facebook and Instagram bookings, Link builder, and Smart Website | Both | CONFIRMED | Live Link builder route exposed the Online bookings and Your websites sections with all five links.
Link builder is only reachable by client-side navigation; hard navigation returns 403 | Cartographer | PARTIAL | In this authenticated verification session direct navigation to /fresha/online-booking/buttons-and-links loaded the page and exposed its content. Treat 403 as an earlier/session-specific observation, not a stable route invariant.
Link builder offers Create link and Link to everything / Link to services | Cartographer | CONFIRMED | Live page showed title, help link, descriptions, and two Create link buttons with those exact card names. Additional cards were not visible in the captured viewport.
Reports lands at /reports/report-group/1?category=all and exposes report categories | Both | CONFIRMED | Live navigation redirected to that exact URL. Snapshot showed All reports, Sales, Finance, Appointments, Team, Clients, Inventory and Other tabs, plus Add.
Reports contains exactly 58 report cards | Cartographer | PARTIAL | Live snapshot showed a large report-card list and the expected category tabs, but the accessibility output had unlabeled card nodes; exact count was not independently recoverable from this run.
Fresha Connect is only a new-feature modal with inbox UNVERIFIED | Cartographer | WRONG | Direct /connect loaded an actual Connect app at /connect/customers/conversations/onboarding-... with Client Connect, Team Connect, Search, Settings, New message, Open 1, Closed, conversation options, Close conversation, contact-information prompt and Add details. An onboarding Step 1 of 3 panel was present, but the inbox itself was visible.
Connect is a two-way client messaging surface | Both | CONFIRMED | Live Connect page heading Client messages and conversation UI confirmed this. The reports understate the available controls and actual route.
Automations includes seven tabs and automation cards | Both | CONFIRMED | Live snapshot showed Reminders, Appointment updates, Waitlist updates, Increase bookings, Celebrate milestones, Client messages and Client loyalty, plus card groups.
Automations includes communication balance / automatic top-up setup | Cartographer | PARTIAL | Live page showed Communication balance KWD 0, Show balance management actions, and a Set up now automatic-top-ups panel. Cartographer recorded only the balance-action button, not the balance value or top-up panel.
The dashboard Top team member table may reference client count | Linker | WRONG | Cartographer’s page inventory describes the table as Team member / This month / Last month; no evidence supports a client-count relationship. Remove that edge/description.
Calendar creates data for Sales > Appointments and Daily sales | Linker | PARTIAL | These are plausible entity/report relationships and are consistent with the page inventory, but this run did not create a COUNCIL-TEST appointment or trace it through the lists. Keep as inferred, not confirmed.
Sales Register creates appointments and feeds Payments/Daily sales | Linker | UNVERIFIED | Register is an activation/upsell page in this workspace. No POS was enabled and no COUNCIL-TEST record was created, so these edges could not be exercised.
Clients list navigates to Calendar through appointment history | Linker | UNVERIFIED | Cartographer only confirmed that a client row opens a client profile. No live row drill-through was performed.
Clients list shares entity with Sales list via purchase history | Linker | UNVERIFIED | No client sales-history drill-through was observed in this run.
Client loyalty depends on having clients | Linker | WRONG | The page is an add-on/trial enablement page; no dependency relationship was evidenced. Client data may be used by loyalty, but “depends-on having clients” should be removed or relabeled as a product/data relationship.
Marketing Automations depends on Calendar appointment events | Linker | UNVERIFIED | Semantically likely, but no COUNCIL-TEST appointment/message trace was performed.
Products -> Stocktakes, Stock orders -> Suppliers, Team members -> shifts/timesheets/pay runs | Linker | UNVERIFIED | These are reasonable workflow relationships but were not exercised with created data; leave explicitly unverified.
Reports aggregates all sections | Linker | PARTIAL | Reports page and categories confirm broad aggregation, but the exact all-section API/edge behavior was not independently verified.
Top-bar Search -> all pages, Performance insights -> Reports, Notifications -> Messages history, Continue setup -> Settings | Linker | UNVERIFIED | Controls were visible live, but no click-through was performed. Do not promote these edges to confirmed.
All pages share Wallet, Finance accounts, Credits campaign APIs | Linker | UNVERIFIED | This is an API-observation claim not confirmed by the page UI in this run; preserve as observed API evidence with scope and timestamp rather than a functional link.

Corrections

1. Replace the Connect entry with a route/state note: clicking Fresha Connect opens the Connect application, which may land at /connect/customers/conversations/onboarding-<id>. It has Client Connect and Team Connect modes, search, settings, new-message, open/closed conversation filters, conversation options, contact details, and onboarding Step 1 of 3. The “inbox behind modal” wording is incomplete.
2. Remove Linker edge “Dashboard top team member may reference client count.” It conflicts with the Cartographer’s field description and has no evidence.
3. Change “Client loyalty depends on having clients” from an entity dependency to “loyalty add-on consumes client data” or leave unlinked.
4. Mark the Register/POS, client history, automation trigger, inventory workflow, payroll feed, and top-bar navigation edges as UNVERIFIED until exercised with non-destructive COUNCIL-TEST data or click-through evidence.
5. Qualify the hard-navigation 403 quirk. It was reported by Cartographer but direct navigation to Link builder worked in this authenticated session. This may be session, timing, or deployment dependent; do not state it as universal.
6. Add the automatic-top-up panel and Communication balance KWD 0 to Automations features.
7. Correct Connect URL behavior in both reports: /connect is an entry point, not necessarily the final inbox URL.

Missing pages/features/links discovered

- Fresha Connect: Client Connect and Team Connect toggle; Search textbox; Settings; New message; Open 1 and Closed filters; conversation list; conversation options; Close conversation; Add details; disabled Type a message until contact details are supplied.
- Connect onboarding: “Just added: accept general inquiry messages via your own public Contact Page with a dedicated link”, Step 1 of 3, Next and Close.
- Automations: Communication balance (KWD 0), automatic top-up explanatory panel, Set up now, and horizontal tab scroll controls.
- Link builder: explicit help-center Learn more link and two visible card descriptions. The captured live view confirmed only the first two link types; “more types” remains unverified.
- Setup: exact visible tab labels Settings, Online presence, Marketing, Other; this is stronger than a generic cross-links description.
- Coverage still needing dedicated verification: permission-gated settings subpages, user-menu referral/help/logout actions, global Search, Performance insights, Continue setup, News (listed by Cartographer but not exposed in current snapshots), empty states and bulk actions on list pages, and all data-creation edges.

Disagreements and ruling

- Scope/count: Cartographer inventories 41 page/features including overlays, drawer and user-account pages; Linker reports 40 sub-pages and focuses on entity relationships. Ruling: not a direct contradiction; the counts use different inclusion rules. Final map should distinguish canonical routes from overlays/drawers and account pages.
- Connect: Cartographer calls the inbox unverified behind a modal; live evidence rules this WRONG/INCOMPLETE. The app is present and interactive, although onboarding overlays it.
- Link builder hard-nav 403: Cartographer observed it, but current live evidence contradicts universality. Ruling PARTIAL and environment/session-qualified.
- Marketing Reviews: Linker calls it a Marketing page while Cartographer places Online reputation under Clients. Live navigation proves it is a Marketing Engage cross-link to the Clients URL. Both are right when expressed as source menu vs destination page.
- Reports 58 cards vs Linker’s broad “Reports” node: no contradiction; Cartographer provides the detailed catalog, Linker provides aggregation edges.
- POS and workflow edges: Linker labels several UNVERIFIED and Cartographer describes Register as activation-only. Ruling: retain as hypotheses only; do not claim observed data propagation.

Confidence score per final-map section

- Global navigation and top bar: 0.95
- Setup hub and account/user-menu routes: 0.90
- Online bookings routes and Link builder visible UI: 0.88
- Marketing navigation and Automations UI: 0.92
- Reports route/categories: 0.90; exact 58 count: 0.75
- Fresha Connect: 0.90 for visible UI; 0.65 for full onboarding flow
- Core page inventory (41 entries): 0.86
- Entity/page relationships: 0.72 overall; 0.95 for shared-entity relationships directly described by page UI, 0.45 for unexercised workflow edges
- API-host observations: 0.78 as observations, 0.55 as proof of functional links
- Empty states, permission-gated areas, modals, bulk actions: 0.45

Gate recommendation: PASS with corrections required in the final synthesis. Evidence is sufficient for a broad map, but the final report must preserve UNVERIFIED labels and the corrections above; it must not present inferred workflow edges as tested facts.
