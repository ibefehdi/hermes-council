# Fresha Partner Dashboard (partners.fresha.com) — Page & Feature Inventory

Mapped by the Cartographer on 2026-10-04 against the staging workspace "Test Salon" (location id 3216614, currency KWD).
One screenshot per page lives in `/Users/fahad/council/output/screenshots/` (filename noted per section).

Navigation structure (left rail, icon accordion + fixed icons top-to-bottom):
Dashboard, Calendar | Sales | Clients | Catalogue | Fresha (Online bookings) | Marketing | Team | Reports, Add-ons, Setup.
Top bar (global): Continue setup, Search, Performance insights, News, Notifications (unread badge), Fresha Connect link, user menu (avatar "FA").
User menu items: Invite a business to Fresha (referral, up to KWD 60), My profile, Personal settings, Help and support, Log out.

---

## 1. Dashboard (Home)
- URL: `/dashboard`
- Nav path: first sidebar icon (house)
- Purpose: business-at-a-glance overview.
- Features:
  - "Recent sales" KPI card w/ Filters button — chart (Sales vs Appointments, last 7 days); reads sales totals, appointment counts/values
  - "Upcoming appointments" KPI card w/ Filters — chart (Confirmed vs Canceled, next 7 days)
  - "Appointments activity" feed — list of upcoming appointments; each row links to appointment drawer `/dashboard/drawer/appointment/:id`
  - "Today's next appointments" feed — same drawer links
  - "Top services" table (Service, This month, Last month)
  - "Top team member" table (Team member, This month, Last month)
- API: `reports.fresha.com/api/json_api_dashboard/{recent_sales,upcoming_appointments,bookings_activity,todays_bookings,top_services,top_employees}`, partners-api bootstrap calls
- Links to: appointment drawer, calendar
- Screenshot: p-dashboard.png

## 2. Calendar
- URL: `/calendar?date=...&view=day&location_id=...`
- Nav path: second sidebar icon
- Purpose: day/week calendar for booking appointments.
- Features:
  - Date navigation (Today, prev/next month, date picker)
  - "Scheduled team" toggle, reset default view, view mode switch (Day)
  - "Add" button (create appointment)
  - Team-member resource columns (per-provider schedule rows, "FA Fahad Asad")
  - Appointment blocks (clickable -> drawer)
- API: `partners-calendar-api.fresha.com/alpha-graphql`, partners-api `employees/with-deleted`, `closed-dates`, `employee-avatars`
- Links to: appointment drawer; Fresha logo links here
- Screenshot: p-calendar.png

## Sales section (sidebar accordion)
## 3. Daily sales summary
- URL: `/sales/daily-sales`
- Purpose: per-day sales breakdown.
- Features: Export button, "Add new", prev/next day navigation with date button; table w/ columns Item type, Sales qty, Refund qty, Gross total; payments table (Payment type, Payments collected, Refunds paid)
- API: `reports.fresha.com/api/reports/daily_sales`
- Screenshot: p-sales-daily-sales.png

## 4. Register
- URL: `/sales/register`
- Purpose: point-of-sale register ("Included in your plan" feature) — activate/upsell page in this workspace.
- Features: Start now (activation CTA); links out to catalogue/sales pages
- Screenshot: p-sales-register.png

## 5. Appointments (sales list of appointments)
- URL: `/sales/appointments-list`
- Purpose: tabular list of all appointments.
- Features: Export, date-range presets ("Month to date"), Filters, sort by Scheduled Date; columns: Ref #, Client, Service, Created by, Created Date, Scheduled Date, Duration, Team member, Price, Status
- API: `reports.fresha.com/api/reports/appointments_list`
- Screenshot: p-sales-appointments-list.png

## 6. Sales
- URL: `/sales/sales-list`
- Purpose: list of completed sales.
- Features: Options, Add new; tabs "Sales" / "Drafts"; Filters; Sort by; columns: Sale #, Client, Status, Sale date, Tips, Gross total
- API: `reports.fresha.com/api/reports/sales_list`
- Screenshot: p-sales-sales-list.png

## 7. Payments
- URL: `/sales/payment-transactions`
- Purpose: all payment transactions.
- Features: Options, date-range picker (Sep 4 – Oct 4, 2026), Filters; sortable columns: Payment date, Location, Ref #, Client, Team member, Type, Method, (amount)
- API: partners-api-gateway graphql
- Screenshot: p-sales-payment-transactions.png

## 8. Gift cards sold
- URL: `/sales/gift-cards`
- Purpose: list of gift cards sold.
- Features: Options menu; Learn-more link; (empty state in this workspace)
- API: `reports.fresha.com/api/reports/gift_cards`, `gift-cards-api.fresha.com/config`
- Screenshot: p-sales-gift-cards.png

## 9. Packages sold
- URL: `/sales/packages-sold`
- Purpose: packages purchased by clients.
- Features: Options, "All statuses" filter, "Set up now" (feature enablement)
- Screenshot: p-sales-packages-sold.png

## 10. Memberships sold
- URL: `/sales/paid-plans` (redirects to `/sales/memberships`)
- Purpose: view/filter memberships purchased by clients.
- Features: Export button, filters
- API: partners-api `paid-plan-management`
- Screenshot: p-sales-paid-plans.png

## Clients section
## 11. Clients list
- URL: `/clients/list`
- Purpose: view, add, edit, delete client profiles.
- Features: client count badge, Options, Add; "Import your client list" banner (Start import); Search box (name/email/phone), Filters, sort by Created at; table columns: select-all checkbox, Client name (avatar, email), Mobile number, Reviews, Sales, Created at; pagination footer; row click opens client profile
- API: `customers-api.fresha.com/v2/customer-search`, `customer-avatars`, `customer-duplicates/existence-check`, `customers-merge/auto-status`
- Screenshot: p-clients-list.png

## 12. Client segments
- URL: `/clients/segments`
- Purpose: standard & custom client segments for marketing.
- Features: Options, Add (create custom segment); tabs Standard / Custom; standard segments: New clients (added last 30 days), Recent clients (appointments last 30 days), First visit, Loyal clients (2+ sales in 5 months), Lapsed clients (3+ sales/12mo, none in 2 months); each with Actions menu
- Screenshot: p-clients-segments.png

## 13. Client loyalty
- URL: `/clients/loyalty`
- Purpose: loyalty program add-on ("Client Loyalty add-on — Try it FREE for 7 days!").
- Features: Start now (trial CTA), Learn more
- API: partners-app wallet endpoints (wallets-summary)
- Screenshot: p-clients-loyalty.png

## 14. Online reputation (Reviews)
- URL: `/clients/online-reputation` (Reviews nav = `?tab=all`)
- Purpose: ratings & reviews management.
- Features: onboarding modal (Watch now / Dismiss / "Watch Discover ratings and reviews"); tabs Overview / All reviews; Connect button (connect review sources)
- Screenshot: p-clients-online-reputation.png

## Catalogue section
## 15. Service menu
- URL: `/catalogue/services`
- Purpose: manage bookable services.
- Features: services table with categories, add/edit service (UNVERIFIED detail — page rendered but data rows not captured in snapshot)
- Screenshot: p-catalogue-services.png

## 16. Packages
- URL: `/catalogue/packages`
- Purpose: sellable service packages.
- Features: "Included in your plan" + Start now; package cards (e.g. "Spa Package, 6 sessions included, KWD 120, Save up to KWD 30", "Full body massage, 5 sessions")
- Screenshot: p-catalogue-packages.png

## 17. Products
- URL: `/catalogue/products`
- Purpose: retail product catalogue.
- Features: "import many at once" link, Start now (enable feature), Learn more
- API: `inventory-api.fresha.com/inventory`
- Screenshot: p-catalogue-products.png

## 18. Stocktakes
- URL: `/catalogue/stocktakes`
- Purpose: inventory stock counts.
- Features: Start now (enable), Learn more
- Screenshot: p-catalogue-stocktakes.png

## 19. Stock orders
- URL: `/catalogue/orders`
- Purpose: purchase/stock orders.
- Features: Options, Learn more (empty state)
- Screenshot: p-catalogue-orders.png

## 20. Suppliers
- URL: `/catalogue/suppliers`
- Purpose: supplier directory.
- Features: Add supplier, "Click here" CTA, Learn more
- API: `inventory-api.fresha.com/suppliers`
- Screenshot: p-catalogue-suppliers.png

## Fresha section (Online bookings)
## 21. Marketplace profile
- URL: `/fresha/online-booking/locations`
- Purpose: manage the business's Fresha marketplace profile per location.
- Features: "Start now" enablement CTA, Learn more; location profile editor
- API: `shopkeeper-api.fresha.com/backoffice/shop`, partners-api `published-location-profiles-check`
- Screenshot: p-fresha-marketplace.png

## 22. Reserve with Google
- URL: `/fresha/online-booking/google-reserve`
- Purpose: enable bookings from Google Search & Maps.
- Features: setup/connect flow; NOTE: on repeat visit redirected to /add-ons — feature content UNVERIFIED beyond first screenshot
- API: `google-appt-redirection-api.fresha.com/reserve-with-google-settings`
- Screenshot: p-fresha-google-reserve.png

## 23. Facebook and Instagram bookings
- URL: `/fresha/online-booking/facebook-setup`
- Purpose: add Book Now button to social pages.
- Features: "Included in your plan", Set up now, Learn more; "Promote your Book Now button on social posts and ads"
- API: partners-api `facebook-fbe/provider-settings`
- Screenshot: p-fresha-facebook.png

## 24. Link builder
- URL: `/fresha/online-booking/buttons-and-links` (hard nav returns 403 — reach via sidebar click only)
- Purpose: create shareable booking links & QR codes.
- Features: "Create link"; link types: "Link to everything" (one simple link covering everything bookable), "Link to services" (booking links for certain services, locations or team members), (further types in page body)
- Screenshot: p-fresha-link-builder.png

## 25. Smart Website
- URL: `/fresha/online-booking/smart-website` (hard nav 403 — sidebar click only)
- Purpose: Fresha-hosted website add-on.
- Features: "Smart Website / Fresha add-on", Continue (setup wizard), Learn more
- Screenshot: p-fresha-smart-website.png

## Marketing section (Messaging / Promotion / Engage groups)
## 26. Blast campaigns
- URL: `/marketing/blast-campaigns/home` (hard nav 403 — sidebar click only)
- Purpose: email/SMS blast marketing.
- Features: Start now (enable), Learn more
- API: `partners-api.fresha.com/blast-marketing/campaigns` (also seen `blast-marketing`)
- Screenshot: p-marketing-blast-campaigns.png

## 27. Automations
- URL: `/marketing/automated-messages`
- Purpose: automated client messaging.
- Features: "Show balance management actions"; Set up now; tabs: Reminders, Appointment updates, Waitlist updates, Increase bookings, Celebrate milestones, Client messages, Client loyalty; automation cards (3 days / 24 hours / 1 hour upcoming appointment reminder, New/Rescheduled/Canceled appointment, Did not show up, Thank you for visiting, Joined the waitlist, Time slot available, Reminder to rebook, Celebrate birthdays) each with Enable
- API: `customer-notifier-api.fresha.com/v3/notification-types`, `messages`
- Screenshot: p-marketing-automations.png

## 28. Messages history
- URL: `/marketing/notifications`
- Purpose: history of all sent email/text/push messages.
- Features: Set up now (enable), link to automations, Learn more
- Screenshot: p-marketing-notifications.png

## 29. Deals
- URL: `/marketing/deals`
- Purpose: discount codes, flash sales, promotions.
- Features: Start now (enable), Learn more
- API: `deals-api.fresha.com/deals`
- Screenshot: p-marketing-deals.png

## 30. Smart pricing
- URL: `/marketing/peak-pricing`
- Purpose: adjust prices for busy/quiet hours.
- Features: Start now (enable), Learn more
- API: `deals-api.fresha.com/smart-pricing/migration-result`
- Screenshot: p-marketing-peak-pricing.png

## Team section
## 31. Team members
- URL: `/team/team-members`
- Purpose: manage staff.
- Features: Options, Add; "Activate plan" banner; Search + Filters; Custom order sort; team member cards/rows
- Screenshot: p-team-team-members.png

## 32. Scheduled shifts
- URL: `/team/scheduled-shifts?date=...&locationId=...`
- Purpose: weekly shift scheduling.
- Features: Options, Add; This week / prev-next week navigation ("Oct 3 – 9, 2026"); schedule grid by team member
- Screenshot: p-team-scheduled-shifts.png

## 33. Timesheets
- URL: `/team/timesheets`
- Purpose: worked hours tracking (add-on).
- Features: Start now (enable), Learn more
- API: `timesheets-api.fresha.com/graphql`
- Screenshot: p-team-timesheets.png

## 34. Pay runs
- URL: `/team/payrun/overview`
- Purpose: payroll runs (add-on).
- Features: "Included in your plan", Start now, Learn more
- API: `staff-working-hours-api.fresha.com/graphql`
- Screenshot: p-team-payrun.png

## Global pages
## 35. Reports
- URL: `/reports` (lands on `/reports/report-group/1?category=all`)
- Purpose: report catalog.
- Features: category filter; 58 report cards (level-3 headings), including: Appointments summary/list/cancellations & no-show, Attendance summary, Break activity, Cash flow statement/summary, Cash register summary, Client insights/list/summary, Commission activity/summary, Discount summary, Fee deduction activity/summary, Finance summary, Gift card by time period/list, Liability activity/summary, Loyalty dashboard, Memberships benefits consumption/list/summary, Online presence dashboard, Ordered stock, Packages benefits consumption/list/summary, Pay summary, Payment transactions, Payments summary, Performance dashboard/over time/summary, Prepayment list, Prepayments by time period, Product list, Sales by time period/list/log detail/summary, Scheduled shifts, Service charges, Stock movement log/summary, Stock on hand, Taxes list/summary, Team time off, Tips detail/summary, Wages detail/summary, Waitlist detail/summary, Working hours activity/summary. External link to help-center reports knowledge base.
- API: `partners-reporting-api.fresha.com/`, `reports.fresha.com/api/reports/*`
- Screenshot: p-reports.png

## 36. Add-ons
- URL: `/add-ons`
- Purpose: Fresha add-on marketplace.
- Features: add-on cards with descriptions: Payments, Premium Support, Insights, Google Rating Boost, Client Loyalty, Data Connector, Client Connect, Smart Website, Team Connect, Bookable Resources; "Integrations" group: Xero Accounting, QuickBooks Accounting, Facebook and Instagram bookings, Meta Pixel Ads, Google Analytics, Google Ads
- Screenshot: p-add-ons.png

## 37. Setup (Workspace settings)
- URL: `/setup`
- Purpose: manage settings for the workspace ("Test Salon").
- Features: settings links w/ descriptions:
  - Business setup (`/setup/business-setup`) — customize business details, manage locations
  - Scheduling (`/setup/scheduling`) — availability, bookable resources, online booking prefs
  - Sales (`/setup/sales`) — payment methods, taxes, receipts, service charges, gift cards
  - Clients (`/setup/clients`) — client sources, client tags
  - Billing (`/legal-entities`) — Fresha invoices, text messages, add-ons, billing
  - Team (`/setup/team`) — permissions, compensation, time-off
  - Forms (`/setup/forms-and-notes`) — client form templates
  - Payments (`/setup/payments`) — payment methods, terminals, payment policy
  - Cross-links groups: Online presence (Marketplace profile, Reserve with Google, Book with Facebook and Instagram, Link builder), Marketing (Blast marketing, Automations, Deals, Smart pricing, Sent messages, Ratings and reviews), Other (Add-ons, Integrations)
- Screenshot: p-setup.png

## 38. Fresha Connect
- URL: `/connect`
- Purpose: two-way client messaging (Client Connect inbox) — new-feature modal.
- Features: "New feature: Connect to clients with two-way messaging" modal w/ Go to inbox + Learn more (help-center link); underlying inbox (UNVERIFIED — modal dismissed navigated away)
- Screenshot: p-connect.png

## 39. Appointment drawer
- URL: `/dashboard/drawer/appointment/:id` -> `/dashboard/drawer/view-appointment/:id?focusedBookingId=:id`
- Reached by: clicking any appointment (dashboard feeds or calendar block)
- Features: Close Drawer, Focus appointment; client header (name, email button, Actions, View profile); created date; date picker (Sun 4 Oct), status (Booked), time (09:00), repeat (Doesn't repeat); Services list (Edit / Remove per item), Add service; Total & To-pay (KWD 40); Options, Checkout (POS)
- API: partners-api `customers/:id/{recently-booked-appointments,paid-plan-instances,ncf-events}`, `employees`, `location-tip-settings/:locationId`
- Screenshot: p-appointment-drawer.png

## 40. My profile (user account)
- URL: `/user-account/profile`
- Nav path: user menu -> My profile
- Purpose: personal online profile.
- Features: Share profile (public URL fresha.com/p/...), Edit personal details, Portfolio, Interests, Social links; languages
- Screenshot: p-user-profile.png

## 41. Personal settings (user account)
- URL: `/user-account/personal-settings`
- Nav path: user menu -> Personal settings
- Features: Personal info (`/personal-info`), Login & security (`/login-security`), Appearance (`/appearance`) tabs
- Screenshot: p-personal-settings.png

## Global top-bar overlays (not separate URLs)
- Continue setup — onboarding checklist (`onboarding-api.fresha.com/onboarding-checklist`)
- Search — global search
- Performance insights — insights overlay (Insights add-on)
- News — news/announcements
- Notifications — unread alerts (staff-notifications activity-log-unread-count)
- User menu — profile/settings/logout/referral (contents listed above)

## Notable API hosts observed (method-less paths, no tokens)
- partners-api-gateway.fresha.com/graphql (bulk data loading), partners-api.fresha.com (session, locations, employees, provider, blast-marketing, paid-plan-management, facebook-fbe), reports.fresha.com (per-report REST), customers-api.fresha.com, deals-api.fresha.com, inventory-api.fresha.com, gift-cards-api.fresha.com, shopkeeper-api.fresha.com, google-appt-redirection-api.fresha.com, customer-notifier-api.fresha.com, staff-notifications.fresha.com, onboarding-api.fresha.com, timesheets-api.fresha.com, staff-working-hours-api.fresha.com, partners-calendar-api.fresha.com, partners-app.fresha.com (wallet/credits), auth-api.fresha.com (session heartbeat), unleash-proxy.fresha.com (feature flags).

## Quirks worth knowing
- `/sales/paid-plans` redirects to `/sales/memberships`.
- `/fresha/online-booking/buttons-and-links`, `/smart-website`, and all `/marketing/*` routes return HTTP 403 on hard navigation — they must be reached via in-app (client-side) routing.
- On second visit `/fresha/online-booking/google-reserve` redirected to `/add-ons`.
- All money values in this workspace are KWD.
