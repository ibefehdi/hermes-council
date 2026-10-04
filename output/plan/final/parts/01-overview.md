# GlowDesk: the complete build plan

Multi-tenant spa/salon SaaS — from an empty repository to a sellable product. Final plan, assembled and verified by the council on 2026-10-04.

## Overview and how to read this document

### Executive summary

GlowDesk is a multi-tenant SaaS for spas and salons. A tenant is a company; the first tenant is SpaCorner, which runs several branches, and each branch has its own staff, opening hours, and service prices and durations. The stack is Supabase (Postgres with Row Level Security as the security boundary), seven isolated Deno Edge Functions for all server logic that carries an invariant, and a React + TypeScript single-page app. English and Arabic ship together from day one, with full RTL support. Money is Kuwaiti dinar stored as integer fils (`bigint` minor-unit columns), and every branch carries its own IANA time zone that drives all day boundaries.

The build is organized as plan Phases 0-17. Phases 0-8 are the binding MVP: foundation, tenancy and settings, staff and shifts, the service catalogue, clients, calendar and booking, checkout with cash/manual payments and register sessions, seven reports with exports, and the SpaCorner go-live with real data migration. That is 72 engineer-weeks of work for a three-engineer team, a 22-week critical path, and about 27 weeks with a 20% buffer. Online booking (Phase 9) and an online payment gateway (Phase 10) come after go-live; Phases 11-17 add client depth, marketing and loyalty, retail inventory, packages/gift cards/memberships, resources and group appointments, timesheets and payroll, and self-serve SaaS billing. Visual design is deliberately not defined here — it comes from the owner's external design skill.

The plan was produced by a council over three rounds: an initial design round, an adversarial review round that applied 60 accepted findings (5 of them blockers), and a final round in which an independent verifier re-executed the evidence — the SQL validation set (12 migrations, 33 tables, RLS on all of them, three passing isolation and constraint tests) and all 40 Mermaid diagrams — before this document was assembled. Every decision is recorded as one of 53 ADRs with its reasoning, alternatives, and the comparison to Fresha, the market leader. A parity matrix maps GlowDesk's coverage of Fresha's back-office feature by feature, and a separate list covers the features that go beyond Fresha (WhatsApp notifications, inter-branch stock transfers, self-serve onboarding and billing, and candidates like corporate accounts).

Confidence is highest on product scope and sequencing (0.94) and the decision record (0.93), and lowest on post-MVP detail (0.80), which is labeled illustrative by design. The known unknowns are listed honestly: the active production migration set does not exist yet (it is Phase 0/1 work behind a CI gate), the Fresha report count has a recorded 58-vs-59 discrepancy that was never individually verified, the eu-central-1 region choice is an assumption pending a legal gate, and the schedule-x calendar license decision waits on a Phase 0 spike.

### How to read this document

This document is self-contained: someone who reads only PLAN.md should be able to understand what is being built, why each decision was made, how it compares to Fresha, and in what order to build it. An AI agent or team starting in a fresh repository should read sections in order, then work phase by phase from the Delivery plan.

A few conventions used throughout:

- Phases always mean canonical plan Phases 0-17. Subphases are written `<phase>.<n>` (for example 5.2). Old "release bucket" numbering from round-1 documents is superseded and never used here.
- ADR references (ADR-1 … ADR-53) point to the decision records digested in the Decisions and reasoning section; the binding full text lives in `decisions.md`.
- Fresha claims cite the reverse-engineering evidence corpus (for example `technical/flows.md § Flow 1` or `pages.md §11`). The council compared behaviour only; nothing copies Fresha's UI, text, branding, or API shapes.
- Entity names follow the domain glossary in the Appendix: branch (never location), staff member (never employee), client (never customer), appointment (the record; booking is the act).
- Where documents disagreed during assembly, the precedence was: `decisions.md` (revised) > `REVISION_LOG.md` / round-2 adjudication > `IMPLEMENTATION_PLAN.md` / `CONVENTIONS.md` > round-1 member files. This PLAN.md and the ADRs are now the top of that chain for implementation.
- Validation status: the SQL v2 set under `sql/v2/` is a validation set, not yet the active `supabase/migrations/`. The checker result is recorded in the Domain model section. Diagrams are canonical intent until the active migrations exist and are re-checked against them (finding F-final-arch-1).

### Table of contents

1. Overview and how to read this document (this section)
2. Product — vision, tenants and branches, roles, MVP scope, what is out of scope and why
3. Fresha parity matrix — feature-by-feature coverage with evidence citations and coverage numbers
4. Beyond Fresha — the extra features, the problem each solves, and its phase
5. User journeys — step-by-step per role
6. Architecture — system context, containers, deployment, environments, Edge Function isolation
7. Domain model — class and ER diagrams per area, the validated SQL v2 migrations, and the checker result
8. Key flows — sequence and state diagrams
9. Security and multi-tenancy — roles x actions x enforcement, isolation attack paths and defences, data access map
10. Decisions and reasoning — every ADR in plain language: why, alternatives, Fresha comparison
11. Delivery plan: phases and subphases — goals, features, DB, functions, screens, i18n/RTL, acceptance criteria, tests, backlogs, dependencies, gantt
12. Go-live checklist and risk register
13. What the council found — the narrative across all three rounds, findings tables, final-round rulings, confidence scores
14. Open questions for the owner — with recommended answers
15. Appendix — conventions summary, skills index, glossary, source documents
