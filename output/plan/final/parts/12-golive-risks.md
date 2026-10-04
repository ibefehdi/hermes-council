## Go-live checklist and risk register

Phase 8 executes the SpaCorner rollout. Every checklist item must be green before each branch cutover; rollback is per branch (a branch stops using GlowDesk and resumes its old process; its data stays intact). The risk register is program-level and reviewed at every phase gate.

### SpaCorner go-live checklist

**Go-live checklist (all must be green before each branch cutover)**
- [ ] Production migrations applied and verified; `supabase db diff` clean.
- [ ] pgTAP full matrix green against a production-schema clone.
- [ ] Restore drill completed on a production snapshot (timed).
- [ ] Uptime monitoring + Sentry alerting live; on-call rotation named.
- [ ] Branch data imported, dry-run report signed off by the owner.
- [ ] Test booking → test checkout → test refund → voided; receipt printed in EN+AR.
- [ ] Register opened/closed with zero delta on test data.
- [ ] All seven reports reconcile against the pilot week's hand-kept numbers.
- [ ] Every staff member trained; reception shifts covered by trained users.
- [ ] Rollback path rehearsed once in staging.
- [ ] Owner has export of all imported data (portability check, NFR-10/11).
- [ ] Legal/privacy: client-data privacy notice published (AR+EN) and data-processing terms agreed with SpaCorner (NFR-11); ADR-48 region assumption confirmed by legal; audit-log access and export paths demonstrated to the owner (round 2, F-PLAN-11).
- [ ] Arabic content review: migrated client/service names, receipt header/footer text, and UI copy reviewed by an Arabic-speaking reviewer for every cutover branch (NFR-7; round 2, F-PLAN-11).

#### Program-level risk register

| # | Risk | Phase(s) | Likelihood | Impact | Mitigation | Owner (role) | Owner signal |
|---|---|---|---|---|---|---|---|
| R1 | Branch-scoped RLS gaps leak data across branches | all | Medium | Critical | ADR-20 binding rules; pgTAP full-matrix gate in CI; no phase exits with uncovered cells; verifier-style review of every migration PR | DB lead | pgTAP matrix coverage report |
| R2 | Double-booking race survives to production | 5 | Medium | Critical | Constraints + advisory locks (ADR-24); concurrency suite is a phase gate; load test pre-GA | DB lead | CI concurrency suite |
| R3 | Money bugs (rounding, reconciliation) | 6, 7 | Medium | High | Integer minor units only (ADR-17); ADR-51 calculation order + golden fixtures; property tests; daily-summary reconciliation gate | Checkout owner (full-stack lead) | Reconciliation fixture results |
| R4 | schedule-x premium fails RTL/perf needs | 0, 5 | Medium | Medium | Phase 0 spike with go/no-go and scoped fallback (ADR-41) | Frontend lead | Spike verdict in ADR-41 |
| R5 | Arabic UX quality lags English | all | Medium | High | RTL is a release gate (ADR-40); both-locale Playwright; missing translations fail CI; AR-first training material | Frontend lead | Locale-parity E2E run |
| R6 | Gateway assumptions wrong (fees, recurring, APIs) | 10, 14 | Medium | High | ADR-34 binding re-verification at discovery (incl. KNET-no-recurring assumption); provider abstraction; tokenized-card design avoids KNET recurring | Payments lead (full-stack) | Phase 10 discovery doc |
| R7 | SpaCorner data quality blocks go-live | 8 | High | Medium | Dry-run reports + owner sign-off gate; import idempotent; skip historical sales; Epic 8.0 import software | Ops/owner liaison | Dry-run validation report |
| R8 | Realtime channel leakage | 5 | Low | Critical | Channel-authorization tests in CI before Phase 5 exit (ADR-38); polling fallback ready | DB lead | Realtime auth test suite |
| R9 | `_shared` change breaks all functions at once | all | Medium | Medium | All-functions redeploy in one CI run + stricter review of `_shared` (ADR-32); per-function rollback via `--slug` | Ops | Deploy logs |
| R10 | Scope creep into post-MVP features during MVP | 1–8 | High | Medium | ADR-1..10 phase placements are contractual; backlog tasks reference ADRs; chair re-rules if a task challenges placement | Product owner | Plan review each phase exit |
| R11 | Key-person dependency (small team) | all | Medium | Medium | Skills + CONVENTIONS make context portable; PR reviews cross-pollinate; runbooks for ops paths | Engineering manager | Skill/doc coverage in PRs |
| R12 | Supabase platform limits/behavior changes | all | Low | Medium | Pinned CLI/package versions; limits documented in ADR-27; CI smoke tests against the real platform | Ops | Dependency audit job |
| R13 | WhatsApp provider API changes | 9 | Low | Medium | Provider abstraction with Twilio/WATI adapter; contract tests in CI; fallback to SMS-only operation | Notifications lead | WhatsApp contract test |
| R14 | Liability accounting errors (packages, gift cards, loyalty, memberships) | 12, 14 | Medium | High | Deferred-revenue pattern requires reconciliation tests per phase; liability views reconciled daily against transaction tables; accounting review gate at each phase exit | Full-stack lead | Liability reconciliation report |
| R15 | Self-serve signup fraud/abuse | 17 | Medium | High | Rate limiting, CAPTCHA, email verification, fraud checks; tenant-quarantine mode for suspicious signups | Ops/Security lead | Signup fraud detection dashboard |

Round 2 (F-PLAN-10): the "Owner" column names an accountable role per risk; "Owner signal" remains the monitoring artifact.

---
