## Product

### Vision

Give spa and salon companies in Kuwait (and the wider Gulf) one back-office system that runs the whole operation: the calendar, the desk, the money, the team, and the reports — in English and Arabic, with the dinar handled to the fil, and with per-branch reality (different staff, different hours, different prices at each location) modeled honestly instead of flattened. GlowDesk is built as multi-tenant SaaS from the first migration: SpaCorner is the design partner and first tenant, and everything learned operating its branches feeds the self-serve product that arrives in Phase 17.

The benchmark is Fresha, the category leader the council reverse-engineered as an evidence corpus. The parity matrix (next section) states feature by feature what GlowDesk matches, what it defers to a named phase, and what it will not build. Where GlowDesk differs from Fresha, the difference is deliberate and carries an ADR.

### Tenants and branches

- Tenant = the buying company. It owns branches, staff records, clients, the service catalogue, and all money configuration. Tenants never see each other's data; isolation is enforced by Postgres Row Level Security with composite foreign keys, not by application code (ADR-20).
- Branch = one physical location. A branch has its own staff assignments, opening hours (including overnight and split intervals), closed periods, service price/duration overrides, register sessions, invoice prefix and sequence, and IANA time zone that drives every daily boundary (ADR-45).
- SpaCorner runs multiple branches. Clients belong to the tenant, not to a branch: someone who gets a treatment at branch A shows up at branch B with their history and allergies visible, because safety beats tidiness (ADR-11). Financial aggregates (lifetime value, balances, reports) still respect the viewer's branch scope.
- Staff members are single tenant records with per-branch assignments; a therapist working at two branches is one person, and the double-booking engine checks their busy time across all branches (ADR-12, ADR-24).
- "All branches" entities (a holiday for everyone, a tenant-wide price) use a nullable `branch_id` plus an `all_branches` flag with partial unique indexes. The round-1 sentinel UUID is withdrawn — it could never satisfy the composite FKs (ADR-20 rule 6).

### Roles

Four membership roles, and nothing else in the enum (ADR-20):

| Role | Scope | Core capabilities |
|---|---|---|
| `tenant_owner` | All branches | Everything, including tenant settings, memberships, currency, client CSV import/export (owner-only), refunds and voids |
| `branch_manager` | One or more branches, or all | Branch operations, shifts and rosters, blocked time, refunds and voids, reports for their scope, grants receptionist/staff in own branch |
| `receptionist` | One branch (or all) | Calendar, booking, check-in, checkout with discounts and tips, client records. Forbidden: refunds and voids (ADR-10, server-enforced) |
| `staff` | Assigned branches | Own schedule, own appointments, read-only basic client fields (name, phone, allergy flags) via a column-restricted view, own sales via an RPC |

Platform operations are not a fifth role. `platform_admin` was removed from the enum in round 2; platform staff act through explicit, time-boxed, audit-logged impersonation with a banner the tenant owner can see (ADR-20 rule 9). A user may hold different roles at different branches and memberships in multiple tenants; the active tenant is client context, and the server re-derives membership and scope on every request (ADR-19, ADR-37).

### MVP scope (Phases 0-8)

The MVP is the complete back office for running SpaCorner's branches, with cash and manual payments:

- Tenancy, onboarding, settings hub, roles and memberships (Phase 1)
- Staff records, weekly shift grids materialized to dated rows, blocked time with a locked write path (Phase 2)
- Service catalogue: tenant-level services with branch overrides and staff eligibility, resolved and snapshotted at booking time (Phase 3)
- Clients: tenant-wide records, allergies and notes, duplicate warning, CSV import, soft delete (Phase 4)
- Calendar and booking: the slot and conflict engine (staff + time dimensions), multi-item appointments, double-booking prevention by exclusion constraint plus advisory locks, cross-branch reschedule with price re-resolution, realtime calendar (Phase 5)
- Checkout, sales and register: the deterministic money calculation (ADR-51), split manual payments, tips, discounts, tax, full refunds and same-day void (owner/manager only), cash register sessions with daily reconciliation (Phase 6)
- Reports and exports: seven branch-local reports (sales, payments, taxes, appointments, client list, staff performance, shifts) plus the home/today screen, streamed CSV exports, and the hardening pass (Phase 7)
- SpaCorner go-live: real import software, migration and cutover per branch, training and a pilot week (Phase 8)

Everything user-facing ships in English and Arabic with RTL from day one; missing Arabic translations fail CI (ADR-40).

### Out of scope, and why

| Not in MVP | Where it lands | Why |
|---|---|---|
| Public online booking, shareable links, reminders | Phase 9 | The back-office engine must be proven at real scale before it faces public traffic; MVP has zero external attack surface (ADR-1) |
| Online payment gateway (MyFatoorah, Tap as alternative) | Phase 10 | Merchant KYC lead time and webhook machinery are not MVP work; MVP is cash/manual behind a provider abstraction (ADR-34) |
| Partial refunds | Phase 10 | They need the gateway's refund primitives (ADR-10) |
| Products, stock, suppliers, inter-branch transfers | Phase 13 | SpaCorner is services-first; incidental retail uses a manual item line at the desk (ADR-2) |
| Packages, gift cards, memberships (subscriptions) | Phase 14, in that order | Prepaid-liability accounting and recurring card billing; KNET cannot do merchant-initiated recurring charges (ADR-3) |
| Resources/rooms, group appointments | Phase 15 | A second conflict dimension doubles the engine and the calendar UI; the engine is designed around a "busy sources" list so this plugs in later (ADR-4) |
| Repeating appointment series, waitlist, client merge tool, client portal | Phase 11 | Single appointments cover the MVP desk; not even a nullable `series_id` is reserved (ADR-8, ADR-9) |
| Marketing: segments, campaigns, deals, loyalty points | Phase 12 | Needs a real client base and notifications first |
| Timesheets, commissions, payroll | Phase 16 | Needs go-live data and the sales ledger |
| Self-serve signup, subscription billing, offboarding automation | Phase 17 | The platform becomes a product after SpaCorner proves it (ADR-18) |
| WhatsApp notifications | Phase 9.3 | A beyond-Fresha differentiator; needs the notification platform |
| Staff in-app time-off request/approval | Post-MVP candidate | MVP is manager-created blocks (ADR-53); a request state would be dead weight until staff ask for it |
| Corporate/house accounts | Uncommitted candidate, no phase | Needs an account entity, balance accumulation, monthly statements; requires a new ADR before scheduling |
| Sale drafts (parked carts) | Not planned | Sale creation is atomic and idempotent; `unpaid`/`part_paid` express "not settled yet". Revisit only on pilot evidence |
| Service charges | Not planned | Tips and manual items cover the desk need; ADR-51 has the percentage machinery if ever demanded |
| Reviews, two-way messaging inbox | Not planned (revisit trigger recorded) | WhatsApp integration is the realistic path; the trigger fires with Phase 9 learnings |
| Rich KPI dashboards, comparison-period reports | Deferred non-committed | A separate analytics workstream after Phase 12 data exists (ADR-5) |
| Custom appointment statuses | Deferred non-committed | The fixed enum covers observed operations; a Phase 12 automations candidate (ADR-7) |
| Runtime feature flags | Not in MVP | Entitlements via `plan_features` gate features; introducing flags requires a new ADR |
| In-product wallet | Rejected | A marketplace mechanic that does not fit a back-office SaaS (ADR-18) |

Two round-1 proposals were rejected outright and must never resurface without a new ADR: money as `numeric`/float (ADR-17 binds integer minor units) and authorization from JWT claims (ADR-19 binds live membership lookup — a revoked role must die on the next request, not at token expiry).
