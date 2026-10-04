# Product requirements and scope

Planning pass output for the multi-tenant spa/salon SaaS (working name **GlowDesk**; first tenant **SpaCorner**, Kuwait). Inputs: FINAL_REPORT.md and TECHNICAL_REPORT.md (read-only, clean-room design — Fresha's features inform the catalogue, but nothing is copied: no UI, text, branding, or API shapes).

Conventions used below:

- **MVP** = first release for SpaCorner: core operations only (tenant/branch setup, staff and shifts, service catalogue with branch overrides, clients, calendar and booking, checkout with cash/manual payments, sales records, basic reports).
- **Phase 2** = online presence and money: client-facing online booking, reminders/notifications, online payments, deposits.
- **Phase 3** = growth and depth: marketing, inventory/retail, packages/gift cards/memberships, resources, timesheets/payroll.
- **Out of scope** = things we do not intend to build because they are marketplace/network features or outside our business model.
- Fresha report slugs (e.g. `sales-summary`) are cited only as source evidence for what a feature means; our reports are designed from the requirement, not copied.

---

## 1. Module catalogue and release placement

Every module and feature Fresha offers (from FINAL_REPORT §2–§4 and TECHNICAL_REPORT §4, §6, §7), with our release placement. "Justify" notes cover non-obvious placements.

### 1.1 Core operations (MVP)

| Fresha feature | One-line description | Our release | Notes |
|---|---|---|---|
| Dashboard / home | Business at a glance: today's schedule, recent sales, upcoming appointments | MVP (reduced) | Only today-at-a-glance: today's appointments, today's sales, no-show count. Rich KPI dashboards are Phase 3 (see 1.4). |
| Calendar (day/week booking grid) | Per-staff columns, bookable time slots, appointment blocks | MVP | Day + week views. Resources/rooms columns deferred with Resources (Phase 3). |
| Appointment create/edit | Create from calendar; edit in drawer: services, time, status, repeat | MVP | No group appointments (Phase 3), no repeat series beyond simple weekly repeat? See PD-scope-8: repeating appointments deferred to Phase 2 to keep conflict logic simple. |
| Appointment statuses | Booked → Confirmed → Arrived → Started → Completed / Cancelled / No-show | MVP | Fixed status set in MVP (no custom statuses); see PD-scope-7. |
| Conflicts, buffers, working hours | Prevent double-booking; prep/cleanup time; staff hours constrain slots | MVP | Core of booking integrity. |
| Reschedule / cancel with reasons / no-show | Move appointments; cancellation requires a reason from a configurable list; mark no-show | MVP | |
| Blocked time | Blocks on the calendar (lunch, training, meeting) with paid/unpaid types | MVP | Simple version: any staff member can be blocked; block types configurable. |
| Closed periods / holidays | Branch closure days that remove availability | MVP | |
| Staff records (team members) | Staff profile, contact, role, branch assignment, bookable on/off | MVP | |
| Scheduled shifts | Weekly per-staff, per-branch shift grid; shifts constrain bookable hours | MVP | Shifts define working windows; walk-in work outside shift warns but allows override (see US-T-xx). |
| Clients list + profile | CRUD clients, search, notes, tags, visit history | MVP | Tags yes (cheap, useful); segments no (marketing, Phase 3). Import yes (needed for SpaCorner). Merge/dedupe: MVP gets duplicate warning on create; full merge tool Phase 2 (see PD-scope-9). |
| Service menu (services + categories) | Catalogue of bookable services with category, duration, price, description, per-service staff assignment | MVP | |
| Per-branch service overrides | Same service, different price/duration/availability per branch | MVP | Key multi-branch requirement, §2. |
| Sales list (invoices) | Completed sales with line items, status (Completed/Unpaid/Part-paid), client or walk-in | MVP | |
| Checkout (POS) | Cart of services (+products once inventory exists), discounts, tips, payment capture | MVP | Cash + manual/"other" methods only. Register open/close (cash counting) included — it is how a salon reconciles cash; see PD-scope-6. |
| Discounts | Line-level or sale-level discount, fixed or % | MVP | Promo codes/deals are Phase 3 marketing. |
| Tips | Tip at checkout, per staff member | MVP | Salon reality in Kuwait; tips feed staff reports. |
| Refunds / voids | Full refund of a payment; void a sale before settlement | MVP | Partial refunds Phase 2 (needs online-payment machinery); see PD-scope-10. |
| Payments list | All payment transactions (method, amount, refund) | MVP | |
| Daily sales summary | Per-day totals by method, exportable | MVP | |
| Reports (basic set) | Sales summary, appointments summary, payments summary, client list, staff performance, shifts | MVP | Which reports and metric definitions in §4.8. |
| Receipts | Printable/emailable receipt with configurable header/footer | MVP (print) | Email receipts Phase 2 (needs messaging provider). |
| Invoice numbering | Per-branch sequential invoice numbers with prefix | MVP | Per-branch sequences; §2. |
| Taxes | Tax rates applied at checkout; retail-prices-include-tax option | MVP | Kuwait has no VAT today, but the model must support it (tenant-level tax rates) so a GCC tenant turns it on without a migration. Placement justified by the "sellable to many companies" goal. |
| Cancellation reasons | Configurable reason list used by the cancel dialog | MVP | |
| Setup/settings hub | Business details, branches, opening hours, calendar defaults, checkout methods | MVP | |
| Search (global) | Search clients/appointments/sales from anywhere | MVP (narrow) | Clients + appointments + sales only in MVP; full palette later. |
| Audit trail | Who changed what, when | MVP | NFR-3; not a Fresha-visible feature but non-negotiable for a multi-tenant B2B product. |

### 1.2 Online presence and money (Phase 2)

| Fresha feature | One-line description | Our release | Notes |
|---|---|---|---|
| Online booking (client-facing web) | Public page per branch: pick service → staff → time → confirm; no account required | Phase 2 | The single biggest value-add after core ops. Requires slot-availability engine hardened for public traffic (rate limits, abuse prevention). |
| Booking link builder / QR | Shareable links to book (all services, or a specific service/staff) | Phase 2 | Ships with online booking. |
| Reminders (SMS/WhatsApp/email) | Automated appointment reminders before the visit | Phase 2 | Needs a messaging provider and per-tenant balance/billing; deliberately not MVP so MVP has zero external paid dependencies. |
| Notification history | Log of sent messages | Phase 2 | With reminders. |
| Online payments at booking/checkout | KNET + cards via a Kuwaiti gateway | Phase 2 | PD-payments-1: MyFatoorah primary, Tap alternative; KNET cannot do recurring charges (see citations in PD-payments-1), which constrains later memberships. |
| Deposits / prepayments | Take part of the price at booking | Phase 2 | Needs online payments. |
| No-show / late-cancellation fees | Charge a fee automatically | Phase 2 | With deposits. |
| Client self-service portal | Clients see history, rebook, manage their data (privacy right) | Phase 2 | Privacy requirement makes some client-facing data-access surface necessary eventually. |
| Email receipts | Receipt emailed after checkout | Phase 2 | |
| Client merge tool | Merge duplicate profiles, reassigning history | Phase 2 | MVP warns on duplicates at create time. |
| Repeating appointment series | "Every Tuesday at 4" series with per-occurrence edit | Phase 2 | See PD-scope-8. |
| Waitlist | Queue for cancelled slots; auto-offer freed time | Phase 2 | Valuable for a busy spa, but needs the notification machinery. |
| Performance dashboards (rich KPIs) | Sales/appointment KPIs with comparison periods | Phase 3 | See 1.4. |

### 1.3 Growth and depth (Phase 3)

| Fresha feature | One-line description | Our release | Notes |
|---|---|---|---|
| Blast campaigns (email/SMS) | Send offers to client segments | Phase 3 | Needs segments + messaging. |
| Client segments | Saved audience filters (lapsed, loyal, new) | Phase 3 | MVP ships tags; segments are filters-on-tags + behaviour, built when marketing exists. |
| Deals / promo codes | Discount codes, flash sales | Phase 3 | |
| Loyalty program | Points per visit, redeemable | Phase 3 | |
| Packages | Bundled sessions sold upfront (e.g. 6 sessions KWD 120), redeemed over visits | Phase 3 | Creates a liability (prepaid sessions) — needs revenue-recognition care; deferred deliberately. |
| Gift cards | Sell code with balance, redeem at checkout | Phase 3 | Same liability reasoning. |
| Memberships (paid plans) | Recurring membership billing | Phase 3 | Requires card recurring (not KNET — see PD-payments-1) and is the deepest billing surface; last. |
| Products / retail catalogue | Sellable products with SKU, brand, retail price | Phase 3 | Many spas sell retail, but SpaCorner's MVP ask is services. Checkout already supports a "manual item" line so retail can be rung up in a pinch (see US-CO-5). |
| Inventory: stock takes, stock orders, suppliers | Count stock, reorder from suppliers | Phase 3 | Only meaningful once products exist. |
| Resources/rooms | Bookable rooms and equipment constraining capacity | Phase 3 | Adds a second conflict dimension; MVP conflicts are staff+time only (see PD-scope-4). |
| Group appointments | One service, several clients (e.g. bridal party) | Phase 3 | |
| Timesheets / clock in-out | Staff clock in, worked hours | Phase 3 | |
| Pay runs / commissions | Payroll calculation, per-service commissions | Phase 3 | |
| Client forms (consent/intake) | Form templates attached to services/appointments | Phase 3 | spas need patch tests/allergies; a simple "allergy" field on the client is MVP (see US-CL-4), full forms later. |
| Online reputation / reviews | Collect and respond to reviews | Out of scope for now | Tied to consumer marketplace traffic we don't have; revisit if we build a discovery layer. |
| Client messaging inbox (two-way chat) | Chat with clients in-app (Fresha Connect) | Out of scope for now | Requires a consumer-facing presence; WhatsApp integration is the realistic Kuwait path and would be a Phase 3 integration, not a built inbox. |

### 1.4 Deliberately out of scope (not planned)

| Fresha feature | Why out of scope |
|---|---|
| Marketplace listing (Fresha marketplace) | We are not building a consumer marketplace; our product is B2B SaaS. Discovery/listing is a different business. |
| Reserve with Google / Facebook-Instagram bookings | Channel integrations of a marketplace; revisit only if we add online booking widgets embeddable on third parties (Phase 3+ idea, not committed). |
| Smart Website (hosted site) | Website builder is a separate product. Our online booking (Phase 2) will be embeddable via link/iframe. |
| Smart/dynamic pricing | Optimization feature; low priority for a single-tenant first release. |
| Communication balance wallet / credits system | Fresha's prepaid messaging wallet is a marketplace monetization mechanic. We bill tenants by subscription (see PD-billing-1); messaging costs pass through the provider per use. |
| Add-on marketplace with per-location pricing | We are a single-product SaaS with a plan per tenant; no add-on storefront. Premium reports (Fresha's Insight gating) are simply part of our higher plan tiers. |
| Referral program | No consumer network to leverage. |
| News / help-center drawer in-product | Standard docs site + in-app help later; not a requirements-level module. |

**Release placement summary (justifications for the non-obvious calls):** the guiding rule is: *MVP is what a receptionist and a manager need to run the floor and close the day with zero external service dependencies.* Anything needing a third-party provider (messaging, payments, map listing), a liability model (packages, gift cards, deposits), or a second conflict dimension (resources, group appointments) is out of MVP. That rule produces the placements above and the proposed decisions PD-scope-1…PD-scope-10.

---

## 2. Multi-tenant and multi-branch requirements

Tenant = company (SpaCorner). Branch = a physical location with its own staff, hours, catalogue overrides, and money records. Everything below is a requirement, not a suggestion; the data model must express it (the domain glossary skill fixes the naming).

### 2.1 What is tenant-level vs branch-level

| Concern | Level | Notes |
|---|---|---|
| Subscription/billing, plan | Tenant | |
| Users + role assignments | Tenant (assignment may be branch-scoped) | A user's role can carry a branch scope: "manager of branch A". |
| Service catalogue (service definitions, categories, descriptions) | Tenant | The *definition* lives once at tenant level; enabling/pricing is per branch (below). |
| Service branch overrides (price, duration, enabled/disabled, extra time) | Branch (fallback to tenant defaults) | A service disabled at a branch is invisible in that branch's calendar/booking. |
| Staff records | Tenant; branch assignments many-to-many | See 2.2. |
| Shifts / working hours | Branch (a shift belongs to one staff member at one branch on one date) | |
| Opening hours, closed periods, time zone | Branch | Time zone default Asia/Kuwait but per branch. |
| Clients | Tenant (shared across branches) | See 2.3. |
| Client notes, allergies | Tenant | A therapist at branch B must see the allergy recorded at branch A — safety requirement. |
| Currency, languages | Tenant (currency), with display formatting per tenant | One currency per tenant in MVP (multi-currency out of scope). |
| Taxes (rate definitions) | Tenant; applicable-flag per branch | |
| Appointment, sale, payment records | Branch | Every appointment and sale belongs to exactly one branch. |
| Invoice numbering | Branch (own sequence + prefix) | Fresha's per-location receipt sequencing (TECHNICAL_REPORT §6.2) confirms this is what real operators need. |
| Receipts (header/footer text) | Branch, with tenant defaults | |
| Tipping defaults, checkout methods (cash/other/manual-KNET etc.) | Branch, with tenant defaults | A branch may disable tips or add a manual "KNET terminal" method. |
| Cancellation reasons | Tenant defaults + branch additions | |
| Reports | Both: every report has a branch filter; default scope = user's branch(es); owners see all | |
| Audit log | Tenant (records include branch id and actor) | |

### 2.2 Staff working at more than one branch

- A staff member is one record at tenant level (single profile, single login, single permission role set) with N branch assignments.
- Each assignment carries: default branch flag, bookable at that branch (on/off), and per-branch working pattern (shifts are per branch anyway).
- The calendar always renders **one branch at a time**. A staff member's calendar column shows only that branch's appointments and shifts. Cross-branch double-booking is prevented: the conflict engine checks the staff member's appointments across **all** branches, not just the current view — a therapist booked at branch A 10:00–11:00 cannot be booked at branch B 10:30 (hard constraint; see US-CAL-2).
- Shifts at branch A count as busy for branch B bookings (soft warning, overridable by a manager, recorded in the audit trail; see US-CAL-9).
- Staff-facing views ("my day") show all their assigned branches merged, clearly labelled.

### 2.3 Clients across branches

- A client record belongs to the tenant; any branch can book and serve them. No per-branch client ownership.
- Every appointment/sale records the branch, so per-branch visit history falls out of the data.
- Duplicate detection (name+phone / email) runs tenant-wide.
- Client-facing display defaults (language) are tenant-level; per-client preferred language overrides.

### 2.4 Who sees and does what

- **Tenant owner**: everything, all branches. Financial roll-up across branches, tenant settings, subscription, staff roles. Cannot be excluded from any branch.
- **Branch manager**: full operations for their branch(es) only — staff shifts and assignments at their branch, catalogue overrides for their branch (not tenant-level service definitions), clients (tenant-wide visibility is required to book them, but export is restricted — see US-SEC-3), reports scoped to their branch. No access to other branches' calendars, sales, or numbers; no tenant settings; no subscription/billing.
- **Receptionist**: bookings, clients, checkout, sales at their branch. No financial reports beyond their branch's daily summary; no settings except none; no staff management.
- **Staff/therapist**: their own calendar and appointments, their clients' basic profiles (contact + notes needed to serve them), no financial data except their own tips; no settings.
- **Platform admin (us)**: platform-level operations tooling, only acting on a tenant through an impersonation flow that is always audit-logged and visible to the tenant owner. Never a silent backdoor (see NFR-1).

### 2.5 Isolation invariants (testable)

1. No query path in the product can return rows of another tenant — enforced at the database layer (RLS), not in application code alone.
2. Branch-scoped roles can never read or write another branch's appointments, shifts, sales, payments, or financial reports, even by guessing IDs.
3. Client records are readable tenant-wide but their financial aggregates respect the caller's branch scope.
4. Deleting/archiving a branch never deletes its history: sales and appointments are retained (financial records), and the branch becomes non-operational.

---

## 3. Roles and permissions matrix

Capability scope legend: **T** = tenant-wide, **B** = own branch(es) only, **S** = self only, **—** = no access.

| Capability | Platform admin (audited) | Tenant owner | Branch manager | Receptionist | Staff |
|---|---|---|---|---|---|
| Tenant settings (name, currency, languages, taxes) | via support flow | T | — | — | — |
| Subscription/billing | — | T | — | — | — |
| Create/archive branch | via support flow | T | — | — | — |
| Branch settings (hours, receipt, tips, checkout methods) | — | T (all branches) | B | — | — |
| Service definitions (tenant catalogue) | — | T | B overrides only | — | — |
| Service branch overrides (price/duration/enable) | — | T | B | — | — |
| Staff records (create/edit) | — | T | B (assign to own branch) | — | — |
| Assign roles | — | T | — | — | — |
| Shifts (view/edit) | — | T | B | B view | S view |
| Booked-time / blocked time | — | T | B | B (create) | S (request → manager approves in MVP: manager creates it) |
| Clients (create/edit/notes/allergies) | — | T | T (tenant-wide records; see 2.4) | T | B |
| Clients export | — | T | — (see US-SEC-3) | — | — |
| Client delete | — | T | — | — | — |
| Calendar: create/reschedule appointments | — | T | B | B | B (own column only) |
| Cancel appointment / mark no-show | — | T | B | B | S own appointments |
| Checkout, discounts, tips, refunds, voids | — | T | B | B | — |
| Register open/close (cash count) | — | T | B | B | — |
| Sales/invoices view | — | T | B | B | S own lines only |
| Reports: operational (appointments, shifts, staff performance) | — | T | B | B (daily summary only) | S own stats |
| Reports: financial (sales, payments, taxes) | — | T | B | B daily summary only | — |
| Audit log view | — | T | B | — | — |
| Data export (CSV) | — | T | B (own-branch data) | — | — |

Matrix rules: a capability marked B applies to each branch the user is scoped to; a user can hold different roles at different branches (e.g. manager at A, staff at B — the union of capabilities applies, scoped per branch). The platform admin has no standing access to tenant data (see 2.4 and NFR-1).

---

## 4. MVP user stories with acceptance criteria

Format: **US-&lt;module&gt;-&lt;n&gt;** Story / Acceptance criteria (Given/When/Then style, condensed). "Manager" = tenant owner or branch manager (scoped); "front desk" = receptionist or manager. All stories assume branch scope by default.

### 4.1 Tenant onboarding and branch setup (US-ON)

- **US-ON-1 Create tenant.** As platform operator I create the SpaCorner tenant (name, currency KWD, default language, owner account) so the owner can log in.
  - Tenant exists with one owner user, one default branch pre-created, currency stored with 3-decimal precision, plan set.
  - Owner's first login lands on a setup checklist: business details → branch details → opening hours → staff → services → first booking.
- **US-ON-2 Business details.** As tenant owner I set tenant name, legal name, contact email/phone, currency, default language (EN/AR) so branding and receipts are correct.
  - Changing currency after the first sale is blocked (money records are denominated).
- **US-ON-3 Create a branch.** As tenant owner I add a branch (name, address, phone, time zone defaulting to tenant's, opening hours per weekday) so it can operate.
  - The branch appears in the branch switcher for users scoped to it; it has its own invoice-number sequence, receipt settings, tips, checkout methods.
  - A branch cannot be deleted once it has sales; it can be archived (hidden from operations, history retained — invariant §2.5.4).
- **US-ON-4 Opening hours.** As branch manager I set per-weekday opening hours and closure days (holidays) so booking availability respects them.
  - Slots outside opening hours cannot be booked without an explicit manager override (which is audit-logged).
  - A closure day removes all availability that day and shows the day as closed on the calendar.
- **US-ON-5 Cancellation reasons.** As manager I manage the cancellation-reason list (defaults provided, translated).
  - Cancelling an appointment without a reason is impossible; the reason is stored on the appointment and appears in the cancellation report.
- **US-ON-6 Checkout methods & tips.** As branch manager I configure which manual payment methods the checkout offers (Cash, KNET terminal — manual, bank transfer, other) and tip behaviour (enabled, default percentages).
  - Checkout shows exactly the enabled methods; a disabled method never appears.

### 4.2 Staff and shifts (US-T)

- **US-T-1 Add a staff member.** As manager I add a therapist (name, phone, email, role, bookable flag, assigned branches) so they appear on the calendar.
  - A staff member with login access gets an invitation; one login works across all their branches.
  - A staff member assigned to 2 branches appears in both branches' calendars; their time is conflict-checked across both (§2.2).
- **US-T-2 Set shifts.** As manager I draw the week's shifts per staff member on the branch shift grid (copy previous week supported).
  - Booking a slot outside a staff member's shift raises a soft warning the manager can override (override recorded).
  - Shifts are per branch: the same therapist can have branch A Sat–Wed and branch B Thu–Fri.
- **US-T-3 Time off / blocked time.** As front desk I block a therapist's time (lunch, training, personal) with a type from the configurable list.
  - Blocked time is treated as busy by the conflict engine (hard constraint — no override without manager permission level).
- **US-T-4 Staff permissions.** As tenant owner I assign each user a role (owner / manager / receptionist / staff) with branch scope.
  - The user's navigation and data immediately reflect the union of their role capabilities per branch (§3 matrix).

### 4.3 Service catalogue with branch overrides (US-CAT)

- **US-CAT-1 Manage categories and services.** As manager I create categories and services (name EN+AR, description, duration, buffer before/after, tenant default price).
  - A service requires a category; duration in 5-minute steps; price in KWD with 3 decimals.
- **US-CAT-2 Branch overrides.** As branch manager I override a service's price, duration, and enabled/disabled state for my branch.
  - With no override the tenant default applies; the service page shows which branches override what.
  - A service disabled at my branch cannot be booked there, but remains bookable at other branches.
- **US-CAT-3 Assign staff to services.** As manager I choose which staff members can perform a service (at a branch).
  - The booking picker for that service at that branch offers only eligible staff (plus "any" → round-robin among eligible).
- **US-CAT-4 Reorder and visibility.** As manager I reorder categories and services for display.
  - The order is used consistently in the calendar picker and later online booking (Phase 2 requirement encoded now).

### 4.4 Clients (US-CL)

- **US-CL-1 Add a client.** As front desk I create a client (first name required; phone/email optional but validated; birthday, gender optional).
  - Creating a client with an email or phone matching an existing client shows a duplicate warning with a link to the existing record; the user can proceed (families share phones) — the choice is recorded.
- **US-CL-2 Client profile.** As front desk I view a client's full cross-branch history (appointments, sales, notes, allergies) so any branch can serve them.
  - The profile shows each appointment/sale with its branch clearly labelled.
- **US-CL-3 Notes.** As any authorized user I add timestamped notes to a client (who/when recorded).
- **US-CL-4 Allergies / alerts.** As front desk I record allergies or alerts on a client so every therapist sees them before the visit.
  - Allergies are visibly flagged on the appointment drawer and calendar block tooltip for that client.
- **US-CL-5 Tags.** As front desk I tag clients; I can filter the client list by tag.
- **US-CL-6 Search.** As front desk I search clients by name (EN and AR), phone, or email from the client list and the global search.
  - Search is tenant-wide; Arabic and English text both match; partial phone matches.
- **US-CL-7 Import.** As tenant owner I import clients from CSV (see §6 format).
  - Rows with errors are reported per-line with reasons; valid rows import; duplicates by email/phone are merged/skipped per a pre-selected choice.
- **US-CL-8 Block a client.** As manager I block a client so they cannot be booked.
  - Booking a blocked client is prevented with a clear message; the block is reversible and audit-logged.

### 4.5 Calendar and booking (US-CAL)

- **US-CAL-1 Create an appointment.** As front desk I book a service: pick client (or walk-in), service, staff, date, time.
  - Duration comes from the branch override (or default); price likewise.
  - The appointment appears on the calendar immediately for other users at that branch (realtime or fast refresh — NFR-4).
- **US-CAL-2 No double-booking (hard).** The system prevents booking overlapping appointments for the same staff member at the same time, in any branch.
  - Overlap check includes buffers (prep/cleanup) and blocked time; an overlap is rejected with the conflicting appointment shown.
- **US-CAL-3 Slot generation.** Bookable slots are generated from: branch opening hours ∩ staff shift ∩ service duration + buffers, minus existing appointments/blocks.
  - Slots in 15-minute steps (configurable per branch 5/10/15/30).
- **US-CAL-4 Reschedule.** As front desk I move an appointment to another time/staff/branch-date, subject to the same conflict rules.
  - Rescheduling is recorded on the appointment (audit trail), and the original time is kept in history.
- **US-CAL-5 Cancel with reason.** As front desk I cancel an appointment choosing a reason.
  - The slot becomes available again; the cancellation is countable in reports (by reason).
- **US-CAL-6 No-show.** As front desk I mark a past appointment as no-show.
  - No-shows count per client and per staff in reports; a client's no-show count shows on their profile.
- **US-CAL-7 Statuses.** Front desk can move an appointment through Booked → Confirmed → Arrived → In progress → Completed.
  - Only legal transitions are allowed (e.g. Completed → cannot revert to Booked without manager).
- **US-CAL-8 Multi-service visit.** One appointment can contain multiple services with different staff (service A with therapist X, service B with therapist Y, sequential or parallel).
  - Conflict checks run per staff member's own time span; total price sums the lines.
- **US-CAL-9 Override warning.** Where a booking violates a soft rule (outside shift, outside opening hours), a manager-level user may confirm with an explicit override.
  - Every override stores who, when, and which rule was overridden.
- **US-CAL-10 Calendar views.** Day view with per-staff columns; week view per staff member; date navigation; filter by staff and service category; branch switcher.
  - Performance target in NFR-5; the day view of a busy branch loads with all appointments visible within the target.
- **US-CAL-11 Walk-in.** As front desk I book a walk-in (no client) and can attach a client later or leave it clientless.
  - A clientless completed sale is recorded as walk-in (Fresha's behaviour here is confirmed sensible; we adopt the concept, not the implementation).

### 4.6 Checkout with cash/manual payments (US-CO)

- **US-CO-1 Checkout an appointment.** As front desk I open an appointment and check it out: cart shows the appointment's services with prices; I take payment in cash or a manual method.
  - Completing checkout marks the appointment Completed and creates a sale (invoice) with a per-branch sequential number; the sale appears in the sales list and reports.
- **US-CO-2 Discounts.** As front desk I apply a discount per line or to the whole sale (fixed or percent), with a reason.
  - The receipt and reports show gross, discount, and net; discount reasons aggregate in reports.
- **US-CO-3 Tips.** As front desk I record a tip (fixed or percent preset), attributed to the serving staff member(s).
  - Tips are outside the sale's taxable net and appear in staff tip reports.
- **US-CO-4 Refund and void.** As manager I refund a completed sale's payment (cash out) or void an erroneous sale same-day.
  - A refund creates a linked negative payment record (never deletes the original); sales totals net refunds automatically; voiding requires a reason and keeps the record with status Void.
  - Partial refunds are Phase 2 (PD-scope-10).
- **US-CO-5 Quick sale / manual item.** As front desk I sell an ad-hoc item ("manual item" with name+price) or a service without an appointment.
  - The sale is attributed to the branch and, optionally, a staff member (for their stats).
- **US-CO-6 Unpaid / part-paid sales.** As front desk I complete a checkout partially paid (client pays the rest later).
  - Sale status is Part-paid/Unpaid; the balance is visible on the client profile; settling it later creates the remaining payment records.
- **US-CO-7 Register open/close.** As front desk I open the day's register with a starting cash amount and close it with a counted amount.
  - The difference (expected vs counted) is recorded; the daily sales summary shows register movements.
- **US-CO-8 Receipt.** As front desk I print a receipt for a sale.
  - Receipt shows branch name/address, sequential sale number, date/time, lines, discounts, tips, payments, tax if any, and configurable header/footer (EN/AR per client language).

### 4.7 Sales and invoices (US-SAL)

- **US-SAL-1 Sales list.** As front desk I browse sales (date filter, status filter, search by client or sale number) at my branch.
  - Row opens the sale with full line items, payments, and history (who created/edited).
- **US-SAL-2 Payment transactions list.** As front desk I browse all payments (and refunds) with method, amount, staff, client, date.
  - Totals per method for the filtered period; export to CSV.
- **US-SAL-3 Daily sales summary.** As manager I see today's (or any day's) totals: gross, discounts, refunds, net, tips, by payment method, and can export/print.
  - Figures match the sales list for the same filter exactly (reconciliation test).

### 4.8 Basic reports (US-RPT)

MVP report set (informed by Fresha's 59-report catalogue, TECHNICAL_REPORT §7.3 — we picked the operator-critical ones; metric definitions are our own):

- **US-RPT-1 Sales summary.** Period report, branch filter, group by day/staff/service/category.
  - Metrics: sales count, items sold, gross (sum of line prices before discounts), discounts, refunds, net (gross − discounts − refunds), tips, tax collected. Default period: today/this week/this month.
- **US-RPT-2 Payments summary.** By method totals per period + refunds netted.
- **US-RPT-3 Appointments summary.** Appointments by status (booked, completed, cancelled, no-show), cancellation rate %, no-show rate %, per staff and per service.
  - Cancellation rate = cancelled ÷ (completed + cancelled + no-show). No-show rate = no-show ÷ same denominator.
- **US-RPT-4 Client list report.** Clients with visit count, last visit date, lifetime value (sum of net sales), filtered by branch visited and by tag; exportable.
- **US-RPT-5 Staff performance report.** Per staff member: appointments completed, utilization (booked time ÷ shift time), services rendered, tips, revenue per service line attributed to them.
- **US-RPT-6 Shifts report.** Scheduled shifts per staff per week; exportable (for payroll preparation done outside the product in MVP).
- All reports: date-range presets, branch filter (scoped by role), CSV export, EN/AR labels, RTL layout.

### 4.9 Cross-cutting MVP stories (US-SEC)

- **US-SEC-1 i18n/RTL.** Every screen works in EN and AR with full RTL mirroring; the user's language is per-user, persisted.
  - No hardcoded strings; dates and money format per locale; Arabic search matches Arabic input.
- **US-SEC-2 Audit trail.** Every create/update/delete of clients, appointments, sales, settings, and role changes is recorded (actor, action, entity, before/after essentials, timestamp).
  - Managers can view an audit log for their branch; owners for the tenant.
- **US-SEC-3 Data export.** As tenant owner I can export my tenant's data (clients, services, staff, appointments, sales — CSV) as required for data portability and offboarding.
  - Branch managers can export only their branch's operational data; client contact exports are owner-only (privacy).
- **US-SEC-4 Branch switcher.** Users scoped to several branches switch context via a global control; all lists/calendars follow the switch.

---

## 5. Non-functional requirements

- **NFR-1 Tenant isolation (the top NFR).** Isolation enforced by the database (Postgres Row Level Security keyed on tenant id), with a CI test that queries as each role and asserts cross-tenant/branch results are empty. Platform staff never have standing data access; any impersonation is explicit, time-boxed, audit-logged, and visible to the tenant owner.
- **NFR-2 Function isolation (owner requirement).** Each Edge Function is independently deployable and a failure/redeploy of one function must not affect others: no shared in-process state, per-function deploy units, failures contained per request with timeouts and circuit-broken downstream calls. (Granularity and shared-code decisions belong to the architecture worker; recorded here as the requirement.)
- **NFR-3 Audit trail.** Append-only audit records (actor user id, tenant, branch, entity type/id, action, changed fields, timestamp in UTC) for all mutations on clients, appointments, sales, payments, settings, roles. Retained ≥ 2 years. No audit record is editable by any tenant role.
- **NFR-4 Calendar performance.** Day view for a busy branch (30 staff, 200 appointments, 8h window) renders in ≤ 2s p95 on a mid-range laptop; slot availability computation ≤ 300ms p95; booking (create appointment) round-trip ≤ 1s p95. Concurrent booking of the same slot is impossible (database-level serialization of the conflict check — double-click safe).
- **NFR-5 Multi-user consistency.** Two front-desk users at the same branch see each other's calendar changes within ≤ 5s (Supabase Realtime or polling — architecture decides; requirement is the staleness bound).
- **NFR-6 Availability.** Booking and checkout are the critical paths; target 99.5% monthly availability for MVP. A failing reports feature must never block checkout (isolation NFR-2 applied at the UX level too: report widgets fail independently).
- **NFR-7 Arabic/RTL.** Full RTL from day one: layout mirroring, Arabic-capable search, locale-correct number/date/currency formatting (Arabic-Indic digits optional per user), translated UI with no string interpolation into RTL layout breaking. Client and staff names are stored in both scripts when available; either is searchable.
- **NFR-8 Time zones.** Every branch has an IANA time zone (default Asia/Kuwait). All timestamps stored in UTC; rendered in the branch's zone in operational screens and the user's zone preferences where relevant. DST-safe arithmetic (Kuwait has no DST, but other tenants might).
- **NFR-9 Money precision.** KWD has 3 decimal places (fils). All monetary values are stored as integers in minor units (fils) — no floats anywhere; other currencies' minor-unit exponents are per-ISO 4217. Rounding rules defined once (half-up at the line level) and used by checkout, reports, and exports identically.
- **NFR-10 Data export.** Every core entity exportable to CSV (UTF-8 with BOM so Excel opens Arabic correctly) per §4.9 US-SEC-3. Full-tenant export (owner-initiated) completes within 10 minutes for 100k clients / 1M appointments.
- **NFR-11 Privacy.** Compliance target: Kuwait's Personal Data Privacy Law (Decree-Law No. 42 of 2023) plus GDPR-baseline practices for future tenants: consent capture for marketing fields (used from Phase 3), purpose-limited retention policy, delete/anonymize a client on request while preserving anonymized financial records, and access logging on client-data exports.
- **NFR-12 Security baseline.** Passwords hashed (Argon2id/bcrypt), session expiry and revocation, rate limiting on auth and public endpoints, all service roles least-privileged, secrets only in platform vault (never in client bundles), dependency audit in CI.
- **NFR-13 Accessibility.** WCAG 2.1 AA on all MVP screens (keyboard-complete calendar and checkout, labelled inputs, RTL-aware focus order).
- **NFR-14 Backups/DR.** Automated daily backups with point-in-time recovery; documented restore drill before GA. (Supabase-managed; requirement stated for the ops plan.)

---

## 6. SpaCorner onboarding: data we need and formats

SpaCorner (Kuwait, multiple branches) is the first tenant. Their real-world data is loaded via CSV imports (UTF-8; Arabic text supported; template files provided with example rows):

1. **Branches** (`branches.csv`): branch name (EN + AR), address, phone, time zone (default Asia/Kuwait), opening hours per weekday, invoice-number prefix + next number, tips on/off, checkout methods.
2. **Staff** (`staff.csv`): full name (EN + AR), phone, email (login), job title, branches worked at (comma list), role per branch (manager/receptionist/staff), bookable flag, weekly shift pattern per branch (template: day → start → end).
3. **Services** (`services.csv`): category (EN + AR), service name (EN + AR), description, default duration (minutes), default price (KWD, 3 decimals), buffer before/after; per-branch overrides in the same file as extra columns (`price@<branch>`, `duration@<branch>`, `enabled@<branch>`) or a second `service_overrides.csv`.
4. **Clients** (`clients.csv`): first name, last name, phone (with country code, default +965), email, birthday, gender, preferred language, notes (free text), tags. Duplicate policy chosen at import time (skip/merge/create).
5. **Future sales history** (optional `sales.csv`): only if SpaCorner wants pre-launch numbers in reports — recommended to skip for MVP cleanliness; appointment history likewise optional and read-only if imported.
6. **Currencies/settings**: confirm KWD, confirm receipt header/footer text EN + AR, cancellation reasons, block types, tax (none for Kuwait today).

Import mechanics: validation report per file (row numbers + errors) before commit; dry-run mode; all imports audit-logged; imports are owner-run (see §3 matrix). Sequence: tenant → branches → staff → services → clients → shift grid → go-live checklist (test booking, test checkout voided, receipt printed, report reconciled).

---

## Proposed decisions

Scope/release decisions from this brief; the verifier challenges these, the chair rules in decisions.md.

### PD-scope-1: Online booking is Phase 2, not MVP
- Context: Online booking is the highest-demand feature; MVP must deliver core operations.
- Options considered: (a) include online booking in MVP — broadens surface to public traffic, abuse/rate limiting, payment pre-auth questions; (b) defer to Phase 2.
- Proposal: defer. MVP = staff-facing operations; Phase 2 adds the public booking page, shareable links, and reminders.
- Consequences: booking engine (slot generation, conflict rules) built in MVP must be reusable as a service for public traffic; no online-only fields may leak staff-only assumptions into the conflict model.

### PD-scope-2: Inventory/retail (products, stock, suppliers) is Phase 3
- Context: Fresha has a full retail module; SpaCorner's ask is services-first.
- Options: (a) MVP includes products; (b) MVP checkout supports a generic "manual item" line (name+price) and the full inventory chain comes in Phase 3.
- Proposal: (b). A manual-item line covers incidental retail in MVP without SKU/stock models.
- Consequences: sale line items need a type discriminator (service | manual_item | later product) from day one.

### PD-scope-3: Packages, gift cards, memberships are Phase 3, in that order
- Context: all three create prepaid liabilities (unused sessions, balances, recurring billing).
- Options: bundle earlier vs defer as a group.
- Proposal: defer all three to Phase 3, build packages first (no payment gateway dependency), then gift cards, then memberships.
- Consequences: memberships need recurring card billing (see PD-payments-1); no schema may hardcode "sale = appointment services" (packages redeem later).

### PD-scope-4: MVP conflict dimensions are staff + time only; resources/rooms are Phase 3
- Context: adding room/resource constraints doubles the conflict engine's dimensions and UI.
- Options: build both now vs staff-time now, resources later as an additive constraint layer.
- Proposal: staff + time only in MVP; the conflict engine interface is designed so a resource dimension can be added without rewriting the engine.
- Consequences: data model reserves a polymorphic "resource" concept later; calendar UI stays one-column-per-staff in MVP.

### PD-scope-5: MVP report set is the six reports in US-RPT-1..6; the rest phase in with their features
- Context: Fresha has 59 reports; most monetize add-ons or belong to later features (loyalty, inventory, payroll).
- Options: build a Fresha-scale reporting engine now vs ship the operator-critical six on a simple aggregation layer.
- Proposal: six MVP reports (sales, payments, appointments, client list, staff performance, shifts) with defined metrics; the report framework (filters, date presets, branch scoping, CSV) is generic so later reports are additive.
- Consequences: schema should make the aggregates cheap (denormalized counters where needed); no custom report builder in MVP.

### PD-scope-6: Register (cash open/close) is in MVP
- Context: cash reconciliation is daily practice in Kuwaiti salons; Fresha gates registers behind an add-on.
- Options: defer with checkout (record payment only) vs include open/close with counted difference.
- Proposal: include a minimal register: open with starting cash, close with counted cash, difference recorded. No multi-register, no float transfer in MVP.
- Consequences: payments link to a register session when taken during one; reports expose the difference.

### PD-scope-7: Fixed appointment status set in MVP; custom statuses later
- Context: Fresha allows custom statuses; status drives conflict/report logic.
- Options: configurable statuses from day one vs a fixed enum (booked, confirmed, arrived, in_progress, completed, cancelled, no_show).
- Proposal: fixed enum in MVP (mapped to code-level state machine); custom statuses become Phase 3 config (they only matter with automations).
- Consequences: the enum is the single source of truth; UI labels translate the enum; no status strings in the database beyond these values.

### PD-scope-8: Repeating appointment series deferred to Phase 2
- Context: "same time every week" is common; series complicate reschedule/cancel semantics.
- Options: MVP series vs simple single appointments now.
- Proposal: single appointments in MVP; series in Phase 2 with per-occurrence edit/cancel.
- Consequences: no parent_id/series fields in MVP schema beyond a nullable reservation for series grouping (decide in implementation plan; safe default: leave out and migrate later — chair to rule).

### PD-scope-9: Client duplicate handling: warn in MVP, merge tool in Phase 2
- Context: Kuwaiti families share phone numbers; imports create dupes.
- Options: build merge now vs pre-create duplicate warning + import-time skip/merge choice, full interactive merge later.
- Proposal: warn-on-create + import-time choice in MVP; interactive merge (reassigning appointments/sales) in Phase 2.
- Consequences: all history tables reference client by id, so a later merge is a re-pointing + tombstone operation; client record needs a `merged_into` field from MVP.

### PD-scope-10: Full refunds + void in MVP; partial refunds Phase 2
- Context: refunds against cash are simple; partial refunds matter mostly with online payments.
- Options: full refund machinery now vs complete refund/void matrix now.
- Proposal: full refund (per payment) and same-day void in MVP; partial refund ships with online payments (Phase 2).
- Consequences: refund is a linked negative payment, never a mutation of the original payment — this makes partial refunds additive later.

### PD-tenant-1: Clients belong to the tenant, shared across branches
- Context: §2.3. Fresha's model is account-scoped clients; some competitors are location-scoped.
- Options: tenant-scoped vs branch-scoped clients.
- Proposal: tenant-scoped (with per-visit branch attribution). The multi-branch reality (clients visit whichever branch) makes branch-scoped clients a data-quality disaster.
- Consequences: RLS on clients is tenant-level; financial aggregates on the client profile respect the viewer's branch scope (invariant §2.5.3).

### PD-tenant-2: Staff are tenant records with per-branch assignments; conflict checks are cross-branch
- Context: §2.2. A therapist working at two branches must not be double-bookable.
- Options: per-branch staff duplicates vs one staff record + assignment rows with cross-branch conflict checking.
- Proposal: single staff record; `staff_branch_assignments`; conflict engine checks busy time across all branches.
- Consequences: calendar queries for a branch must join assignments; the booking mutation must serialize on the staff member, not per-branch (affects the DB constraint design — architecture worker).

### PD-tenant-3: Branch override model for services (override rows, not per-branch copies)
- Context: §2.1.
- Options: copy the service per branch (simple queries, update propagation nightmare) vs tenant-level service + nullable override row per branch (price, duration, enabled).
- Proposal: override rows with fallback-to-default semantics resolved in a view/RPC.
- Consequences: effective price/duration is a resolved value; UI must always display which branches deviate; bookings snapshot the resolved values at booking time (historical accuracy).

### PD-tenant-4: Invoice numbering is per branch, sequential, gap-tolerant
- Context: §2.1; Kuwait operators expect per-branch sequences.
- Options: global tenant sequence vs per-branch sequence with prefix.
- Proposal: per-branch sequence (prefix + number), assigned at sale creation via a per-branch counter with retry; gaps allowed on failed transactions (documented), no re-use of numbers.
- Consequences: counter must be race-safe (row lock / sequence table); receipt shows branch-prefixed number.

### PD-payments-1: MyFatoorah as the Phase 2 online gateway, Tap as fallback; abstraction layer mandatory
- Context: MVP is cash/manual only; Phase 2 adds KNET + cards. Kuwait's KNET is 55–70% of online transactions, so gateway choice is KNET-first.
- Options considered:
  - **MyFatoorah**: Kuwait HQ, one signup covers KNET + Visa/Mastercard + Apple Pay + Tabby, lowest published KNET fee (~0.250 KWD flat, ~2% per third-party comparisons), built-in invoicing/payment links (useful for a service business), settlement within 24 business hours; weaker developer docs than Tap. ([kuwaitdev comparison](https://kuwaitdev.com/en/insights/myfatoorah-vs-knet-vs-tap-comparison), [dsrpt.com fees analysis](https://dsrpt.com.au/think-tank/how-to-accept-k-net-on-a-kuwait-website-or-app-with-real-fees))
  - **Tap Payments**: best developer docs and embedded checkout in the region, GCC-wide coverage, marketplace splits; slightly higher fees (~2.85% + fixed on cards, ~0.250 KWD KNET) and slower settlement. ([same sources](https://kuwaitdev.com/en/insights/myfatoorah-vs-knet-vs-tap-comparison))
  - KNET direct (bank): cheapest per-tx but bank PDF integration, 2–6 weeks KYC, no cards without a second acquirer — not for a small SaaS's first tenant.
- Proposal: **MyFatoorah** primary for SpaCorner (Kuwait-only, fee-sensitive, wants payment links), Tap as the documented alternative for GCC multi-country tenants; both sit behind a payment-provider abstraction (charges, webhooks, refunds) so tenants can be switched per tenant. Critical constraint found: **KNET does not support merchant-initiated recurring billing** (Tap's and UPayments' own docs; see [dsrpt.com](https://dsrpt.com.au/think-tank/how-to-accept-k-net-on-a-kuwait-website-or-app-with-real-fees)) — so Phase 3 memberships must use card tokenization, not KNET.
- Consequences: payments module keeps a provider-neutral "intent → redirect/webhook → capture" model from Phase 2 (the MVP manual checkout records the same payment records with method=manual); webhook signature verification and idempotency required; merchant onboarding (CR, IBAN, ~3–7 business days) must start before Phase 2 code freeze.

### PD-i18n-1: English and Arabic with RTL from day one; i18n is an MVP gate, not a retrofit
- Context: the owner requires full EN/AR + RTL from day one.
- Options: English-first with AR strings later vs bilingual schema and RTL layout from the first component.
- Proposal: bilingual from day one: name fields carry EN+AR columns where dual-script matters (services, categories, block types, reasons), all UI strings in message catalogs, RTL as the default layout direction for AR users, locale-aware money/date formatting, Arabic search normalization.
- Consequences: every entity needing operator-facing names gets `name_en` / `name_ar` (+ fallback rules); tests include RTL screenshots; acceptance criterion on every MVP story (US-SEC-1).

### PD-money-1: All money stored as integer minor units (fils for KWD); one rounding rule
- Context: KWD uses 3 decimal places; floats are unacceptable; reports and receipts must agree to the fils.
- Options: numeric(14,3) columns vs integer minor units with a currency exponent table.
- Proposal: integers in minor units (fils) everywhere, exponent per currency from a small ISO-4217 table; single half-up rounding at line level.
- Consequences: all arithmetic in the backend/DB is integer; only the presentation layer renders decimals; totals derive from lines, never stored independently without the lines that prove them.

### PD-billing-1: We bill tenants by subscription; no in-product credits/wallet
- Context: Fresha monetizes per-add-on and messaging wallets; we are a conventional B2B SaaS.
- Options: per-feature add-on pricing vs plan tiers (e.g. Core/Pro) with all features of a phase included.
- Proposal: subscription plans per tenant (all branches included, price tiered by branch count/staff count), premium reports in higher tiers. No prepaid balances in the product; Phase 2 messaging costs are the tenant's provider account (their SMS gateway keys) or a pass-through billed monthly.
- Consequences: no wallet/credits tables in our domain; the plan gate is a single tenant-level entitlement check; pricing page and entitlement service are out of MVP scope beyond a hardcoded plan row.

