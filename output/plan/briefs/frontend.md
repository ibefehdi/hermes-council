# Brief: Frontend architecture and conventions (cartographer)

Output: /Users/fahad/council/output/plan/frontend.md

The visual design language (colours, typography, spacing, component look) comes from the owner's separate "Airbnb" design skill. Do not define visual style. Define everything else.

1. App shape: single React + TypeScript app (Vite) for the back-office (staff/manager/owner), and later a separate client-facing booking app; or a monorepo with shared packages. Propose the repository layout (apps/, packages/, supabase/) and package manager.
2. Routing (including tenant/branch context in the URL or session, branch switcher), auth flows with Supabase Auth, route guards by role.
3. Data access: supabase-js with generated database types, TanStack Query (or justify an alternative) for server state, query key conventions, cache invalidation, optimistic updates, Realtime subscriptions for the calendar, calling Edge Functions through a typed client, error handling surfaced to users.
4. State, forms, and validation: form library and schema validation shared with Edge Functions where possible; client state rules.
5. i18n and RTL: library, message key conventions, Arabic pluralisation, RTL with logical CSS properties, mirrored icons, number/currency/date formatting with Intl (KWD 3 decimals), branch time zones in the UI.
6. The calendar: the hardest screen. Build vs adopt a library (evaluate options for resource/day/week views, drag to reschedule, RTL support, performance with many staff), and how it maps to the booking model.
7. Component architecture: how features consume the design skill's primitives, folder structure per feature, naming, accessibility rules (keyboard, ARIA, focus), loading/empty/error states, responsive behaviour (front desk on tablets).
8. Testing and quality: unit (Vitest + Testing Library), end-to-end (Playwright), lint/format, type strictness, performance budgets.
9. Diagrams: frontend module structure; data flow from component to Supabase/Edge Function.

Draft the skills `react-frontend` (structure, data access, forms, state, testing, how to add a new feature screen step by step; reference the Airbnb design skill for all visual decisions) and `i18n-rtl` (keys, Arabic, RTL rules, formatting money/dates/times per branch).

Add your "Proposed decisions" section.
