# Coverage and product audit

Output: `/Users/fahad/council/output/plan/review2/coverage.md`

Audit `requirements.md`, `frontend.md`, the frontend and i18n parts of `CONVENTIONS.md`, and the `react-frontend`, `i18n-rtl` and `spa-domain-glossary` skills.

1. Feature parity map. Walk every page, feature, setting and report in the reverse-engineering evidence (`pages.json`, `technical/settings.md`, `technical/reports.md`, `technical/flows.md`, `TECHNICAL_REPORT.md`). For each, state where the plan covers it (module, phase, ADR) or that it is missing. Missing items must get a proposed phase (MVP, a named later phase, or explicitly out of scope with a reason). Present this as a table.
2. MVP completeness. For each MVP area (tenants, branches, staff and shifts, services per branch, clients, calendar and booking, checkout with cash/manual payments, basic reports) check that user stories, acceptance criteria, screens, permissions and tests exist and agree with each other. Acceptance criteria must be testable.
3. SpaCorner walkthrough. Simulate a realistic week at a multi-branch spa end to end through the plan: onboarding the tenant, two branches with different hours and time zones set the same, a therapist working at both branches, a service priced differently per branch, a walk-in, a booking moved between branches, a no-show, a cancellation, a refund of a cash sale, a client shared across branches, end-of-day cash-up, a manager who must only see their branch, an Arabic-speaking receptionist. Every step the plan cannot handle is a finding.
4. Roles and permissions. Check the roles matrix covers every action in the MVP and matches the RLS and function checks described elsewhere.
5. Frontend and RTL. Check routing with tenant and branch context, offline or flaky network behaviour at the front desk, Arabic numerals and date formats, mixed-direction text (Arabic names with phone numbers), calendar in RTL, printing receipts in both languages, and that no visual design decisions conflict with leaving visuals to the external design skill.
6. Skills. For the three skills above: would an engineer or AI following them build the right thing? Flag vague rules, wrong examples, and contradictions with `decisions.md` or `CONVENTIONS.md`.
