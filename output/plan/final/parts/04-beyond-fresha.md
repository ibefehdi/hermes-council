## Beyond Fresha

Features Fresha does not have (or does not have in a Kuwait/GCC-usable form) that would make the product better here and more sellable. Sizes are rough engineer-weeks (ew) for the same team as IMPLEMENTATION_PLAN.md. **The MVP scope is unchanged by this section** — nothing below is added to Phases 0–8; items marked "go-live need" would be the only exceptions, and there are none.

#### Already decided (post-MVP phases carry these) — listed for completeness

These appear in the parity matrix but are worth calling out as beyond-Fresha-in-execution because our target market differs:

| Feature | Problem it solves | Users | Size / deps | Phase |
|---|---|---|---|---|
| Cross-branch staff conflict & scheduling | Fresha's per-workspace model cannot guarantee a staff member is not double-booked across two locations; Kuwait spa chains move staff between branches weekly | Reception, managers | Already in MVP (ADR-12/24) — 0 cost beyond plan | 2/5 |
| Per-branch time zone, Hijri-aware i18n, KWD 3-decimal money | Fresha's GCC localization is thinner; fils math and branch-local day boundaries are accounting-correct in ours | All | Already in MVP (ADR-17/40/45) | 0/1/5 |
| Audit log + tenant offboarding contract | Multi-tenant B2B trust: who changed what, and exit-with-your-data | Owner, platform | Already in MVP (ADR-22/43) + 17 (ADR-50) | 0/1/7/17 |
| KNET + local gateways (MyFatoorah first) | Fresha Payments' local coverage and pricing fit Western markets; Kuwait desks need KNET | Clients paying online | 10 ew + KYC lead time; deps Phase 9 (ADR-34, binding re-verification at discovery) | 10 |
| WhatsApp-first reminders | SMS is ignored in Kuwait; WhatsApp is the default channel. Meta bills per delivered template message, utility category (reminders) is the cheapest tier, and replies inside the 24-hour customer window are free — so reminders are cheap and two-way replies are free (https://business.whatsapp.com / Meta rate card; see also https://setsmart.io/blog/whatsapp-business-api-pricing for the per-message model since July 2025) | Clients | Within Phase 9's 12 ew (provider decision Twilio/WATI re-verified at discovery, IMPLEMENTATION_PLAN Phase 9) | 9 |
| Arabic-first experience | RTL-everything, Arabic search normalization, AR-first training material — a differentiator Fresha cannot retrofit cheaply | All users | Already in MVP (ADR-40); keep as release gate | 0–8 |

#### New proposals

| # | Feature | Problem it solves | Who uses it | Size | Dependencies | Proposed phase.subphase |
|---|---|---|---|---|---|---|
| B1 | Hijri date display + Kuwait/GCC holiday presets | Arabic-first clients read dates in Hijri (e.g. "14 Ramadan"); national/religious closures are Hijri-determined and drift against the Gregorian calendar every year | Reception (optional display), clients on the booking page (9) | 1–2 ew (Intl `islamic-ua` calendar formatting + a toggle in branch calendar preferences, ADR-52 fields already exist) | ADR-40 formatters; none else | Toggle + internal display: candidate during Phase 8 Arabic review (explicitly optional); client-facing: 9.x with the booking page. **Not a go-live need.** |
| B2 | WhatsApp booking deep links + "book via WhatsApp" entry | Most Kuwait salon bookings start in a WhatsApp chat; a deep link that opens the pre-filled booking page (or the staff's calendar) shortens the path | Clients, staff who share links | 1 ew (link builder extension) | Phase 9 link builder + messaging | 9 (same epic as link builder) |
| B3 | Gender-specific staff & sections | GCC spas commonly run ladies-only sections/days and clients expect gender-matched therapists; Fresha has no notion of this | Reception (filter), clients (online booking filter) | 2–3 ew: `gender` attribute on staff + client preference + filter in pickers; "female-only day" can be modeled as closed-period + booking-option rules | Catalogue (Phase 3 data shape decision — the attribute should be added to `staff_members` before go-live data import even if unused, to avoid a migration) | Data field: decide before Phase 8 import (1-line column, no behavior); behavior: 9 with online booking filters. **Recommend SpaCorner confirm the requirement; not committed.** |
| B4 | Stock transfers between branches | Fresha's inventory is per-location with no inter-branch transfer flow; multi-branch chains leak stock accountability | Managers | 1–2 ew (transfer order + two-sided stock movement rows) | Phase 13 stock ledger | 13 (added epic) |
| B5 | Branch comparison dashboards | Owners of chains want branch-vs-branch performance, not per-branch reports opened side by side | Owner | 3–4 ew | Deferred "dashboards & analytics" workstream (F-cov-2) | Analytics workstream after Phase 12 data exists (non-committed) |
| B6 | Couples / group bookings | Gulf spas take couples massages and bridal-party groups; Fresha's group appointments cover the case thinly | Reception | In Phase 15 scope already | Phase 15 | 15 |
| B7 | Packages & session bundles (spa framing) | GCC spas sell 6-session packages upfront; already planned (ADR-3) — called out because it is a stronger revenue lever here than in Fresha's core markets | Owner, reception | Phase 14 scope | 13/10 | 14 |
| B8 | Corporate / house accounts | Hotels and companies book for employees and want monthly invoicing against a house account instead of per-visit payment | Owner, reception, corporate clients | 3–4 ew (account entity + part-paid balance accumulation + monthly statement) | Phase 6 part-paid machinery (6.1); statement needs Phase 9 email | Candidate 14.x after gift cards; **not committed, no phase placement** — requires a new ADR before any team schedules it (final round, R-final-phases-4) |
| B9 | White-label booking site per tenant | Chains want booking on their own domain with their brand; Fresha only offers the marketplace page or the Smart Website add-on | Tenants (selling point) | 2 ew (custom domain + logo/colors on the 9 booking page) | Phase 9 booking page | 17 (with self-serve) |
| B10 | Client mobile app | Clients expect an app; but a native app is a separate product line | Clients | Recommendation: do NOT build native. Ship the booking page + portal (9/11) as installable PWA (responsive, requirements §7) and revisit only with market evidence | Phase 9 responsive | Post-17 candidate only |
| B11 | Platform admin console | MVP platform ops is a documented CLI runbook (ADR-20 rule 3); as tenant count grows, provisioning/impersonation/health need a UI | Platform admin | 3–4 ew | Audit log (7), onboarding RPCs (1.1) | 17 (before opening self-serve signup) |
| B12 | Tenant self-serve onboarding + subscription billing | Selling to many companies without us in the loop; already planned | New tenants | Phase 17 scope (8 ew) | 8 (single-tenant proof), 10 (payment patterns) | 17 |
| B13 | Client consent & treatment records (patch tests) | GCC regulations and spa practice need recorded consent and patch-test outcomes, not just an allergy flag; Fresha's client forms cover it, ours defers | Staff, managers | 2–3 ew (simple structured record per appointment + retention rules) | Client forms candidate (F-cov-6), retention policy Phase 8 legal gate | 11 candidate (with client portal); consent-specific requirement must come from SpaCorner/legal first |
| B14 | Prayer-time & Ramadan-aware hours | Ramadan operating hours shift wholesale; prayer times affect peak flow | Owner (setup), reception | 0 ew new code — split-interval opening hours (ADR-26) + closed periods already model it; ship a Ramadan hours preset template in the branch editor | None | 1.2 template (content, not code); document in training material for Phase 8 |
| B15 | Waitlist with auto-offer | Already planned — listed because no-show economy in a hot market makes it high-value | Reception, clients | Phase 11 scope | 9 notifications | 11 |
| B16 | Deposits & no-show protection | Deep-link deposits are standard practice for GCC premium spas | Owner, clients | Phase 10 scope | 10 gateway | 10 |
| B17 | Loyalty & gift cards | Already planned (12/14) — listed as beyond-Fresha-in-emphasis: gift cards are a Diwaniya/Eid gift norm in Kuwait | Owner, clients | In-phase | 12/14 | 12 / 14 |

Explicit statement: **none of the above is required for SpaCorner go-live**; Phases 0–8 are unchanged. B3 (gender data field) is the only item with a pre-go-live decision point — adding a nullable column before the Phase 8 data import avoids a later migration; the behavior itself remains post-MVP.

---

