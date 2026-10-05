# Phase 3 audit report: Service catalogue

## Verdict: PASS

Phase 3 is complete and meets its plan requirements. The service catalogue's database, transactional Edge Function operations, and management screens are implemented; the six phase exit criteria have supporting test and runtime evidence. All nine gates passed. The verifier accepted no findings: five reported minor findings were rejected because they either describe optional evidence or coverage, do not violate a Phase 3 requirement, or concern a later phase. No code fixes are required for this phase.

| Subphase | Status |
|---|---|
| 3.1 Catalogue data | Done |
| 3.2 Catalogue function | Done |
| 3.3 Catalogue UI | Done |

## What was audited

- Repository: `/Users/fahadasad/glowdesk`
- Branch: `main`
- Commit: `bfb3a3957893f55a87bb60d660a1ac5f9b65c6b0` (`chore(back-office): add Vercel config with SPA fallback rewrite`)
- Working tree: clean. The live read-only check returned `## main...origin/main`, and `git status --short` showed no changes. The gate report independently records a clean tree before and after the checks (`gates/GATES.md:7-11,158-160`).
- Audit date: 2026-10-05.
- Scope: the complete Phase 3 section, including subphases 3.1–3.3 and all six phase exit criteria (`plan/parts/11-delivery-plan.md:682-803`). The verifier reviewed all four audit reports, the gate results, and evidence for the acceptance criteria (`adjudication.md:7-31`).

## Gates

All gate commands exited successfully. Detailed results are recorded in `/Users/fahadasad/hermes-council/output/audit/phase-3/gates/GATES.md:84-160`.

| Gate | Command | Result | Key detail |
|---|---|---|---|
| Frozen-lockfile install | `pnpm install --frozen-lockfile` | PASS (exit 0) | Lockfile integrity confirmed; already up to date (`GATES.md:88,100-101`). |
| Initial database reset | `pnpm db:reset` | PASS (exit 0) | 33 migrations applied and seed data loaded (`GATES.md:89,103-104`). |
| Database tests | `pnpm db:test` | PASS (exit 0) | 15 pgTAP files, 684 tests, 0 failures (`GATES.md:90,106-110`; `gates/db-test.log:15-20`). |
| Database lint | `pnpm db:lint --level warning` | PASS (exit 0) | No schema errors (`GATES.md:91,112-113`). |
| Generated type drift | `supabase gen types typescript --local` compared with committed types | PASS (exit 0) | No generated-type drift (`GATES.md:92,115-116`). |
| Edge Function tests | `pnpm fn:test` | PASS (exit 0) | Six suites, 102 tests total, 0 failures; catalogue suite 8/8 (`GATES.md:93,118-125,154`; `gates/fn-test.log:144-155`). |
| Full verification | `pnpm verify` | PASS (exit 0) | Skills, i18n, eight-package typecheck, lint, CSS lint, Vitest 224/224, build, and size limits all passed (`GATES.md:94,127-136`). |
| Playwright end-to-end | `pnpm exec playwright test --output gates/playwright-results --reporter=list` | PASS (exit 0) | 50/50 tests passed: 25 English and 25 Arabic (`GATES.md:95,138-144`; `gates/playwright.log:14,34,56`). |
| Final database reset | `pnpm db:reset` | PASS (exit 0) | Completed and left a clean seeded database (`GATES.md:96,146-147`). |

Test totals: pgTAP 684/684, Deno 102/102, Vitest 224/224, and Playwright 50/50 (`GATES.md:149-156`).

## Exit and acceptance criteria

The phase exit criteria are set out in `plan/parts/11-delivery-plan.md:696`. All six pass; the criterion wording and evidence below are cross-checked in `adjudication.md:22-31` and `conformance.md:78-87`.

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| A service with English and Arabic names, buffers, and a default price is enabled by default at every branch. | 3.1 / 3.3 | DONE | Phase exit test checks the default at every branch (`apps/back-office/evidence/phase3-exit.spec.ts:392-432`); stored results are recorded in `plan/evidence/3.3/05-bookable-by-default-stored-as-fils.json:1-40`. |
| Disabling a service at one branch hides it only at that branch. | 3.1 / 3.3 | DONE | Exit test checks branch-specific visibility (`phase3-exit.spec.ts:434-455`); adjudication records Jahra hides it while Hawally remains available (`adjudication.md:24`). |
| Effective values resolve correctly, with and without branch overrides. | 3.1 | DONE | Resolver and view cases are covered by `supabase/tests/013_catalogue_resolution.test.sql:66-78` and `phase3-exit.spec.ts:102-120`; captured responses are in `plan/evidence/3.1/01-resolve-service-with-and-without-override.json:1-56`. |
| Only staff eligible for the service at that branch appear. | 3.1 | DONE | Eligible-staff tests are in `phase3-exit.spec.ts:122-135` and `packages/core/src/catalogue.test.ts:118-147`; branch-specific runtime output is recorded in `plan/evidence/3.1/03-eligible-staff-swedish-massage.json:1-21`. |
| Duration is restricted to five-minute steps. | 3.1 / 3.3 | DONE | UI rejection test: `phase3-exit.spec.ts:376-390`; database constraints: `supabase/tests/012_catalogue_matrix.test.sql:77-108`; validation rule: `packages/validation/src/catalogue.ts:21-23`. |
| Price is stored and edited as fils and displays three decimals in both locales. | 3.1 / 3.3 | DONE | Both-locale assertions are in `phase3-exit.spec.ts:458-469`; captured output is in `plan/evidence/3.3/11-price-display-both-locales.json:1-6`. |

Subphase-specific acceptance criteria also pass:

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| Values resolve with and without overrides; eligible staff are filtered and “any” assignment uses round-robin. | 3.1 | DONE | `packages/core/src/catalogue.test.ts:118-184`; pgTAP resolution suite (`database.md:178-186`). |
| One request creates a service with three branch overrides and five eligible staff atomically. | 3.2 | DONE | `phase3-exit.spec.ts:212-269`; catalogue Deno acceptance tests (`backend.md:35-40`; `gates/fn-test.log:144-155`). |
| A manager for branch A cannot write an override for branch B. | 3.2 | DONE | `phase3-exit.spec.ts:276-309`; the catalogue Deno scope-denial test passes (`backend.md:38-40`). |
| The catalogue journey, including reorder, works in English and Arabic. | 3.3 | DONE | Playwright passes 25 tests in each locale; the catalogue reorder journey is in `apps/back-office/e2e/catalogue.spec.ts:36-49` (`GATES.md:138-144`; `adjudication.md:47-49`). |
| The interface identifies branches with overrides, and enforces duration and price display rules. | 3.3 | DONE | Badge assertions at `phase3-exit.spec.ts:452-454`; duration at `:376-390`; prices at `:458-469`. |

## Plan checklist

Statuses below reflect the verifier's adjudication. Every Phase 3 subphase and plan section is covered in `conformance.md:28-88`; the independent database, backend, and frontend reviews add implementation and security checks. Evidence for gate totals is in `GATES.md:149-156`.

- Phase goal and business outcome: DONE. The tenant-level catalogue supports branch-specific service prices, durations, buffers, and eligible staff (`plan/parts/11-delivery-plan.md:684-688`; `conformance.md:32-76`).
- Phase dependency: DONE. Phase 1 branches exist and are referenced by catalogue records and scope checks (`plan/parts/11-delivery-plan.md:692`; `conformance.md:208-213`).
- Phase risk: DONE. The plan calls out confusion about overrides; the UI uses explicit branch deviation badges (`plan/parts/11-delivery-plan.md:694`; `conformance.md:68,74`).

### Subphase 3.1: Catalogue data.

- Features delivered
  - DONE: Bilingual service categories and services, descriptions, ordering, five-minute duration steps, buffers, and default minor-unit prices (`plan/parts/11-delivery-plan.md:704-708`; `conformance.md:32-35`).
  - DONE: Per-branch price, duration, and enabled overrides with default fallback (`conformance.md:33-34`; `database.md:86-98`).
  - DONE: Per-service, per-branch staff eligibility (`conformance.md:34`; `database.md:93-98`).
  - DONE: Typed effective-values view and `resolve_service` RPC (`conformance.md:35,40`; `database.md:110-114`).
- Database work
  - DONE: Catalogue, override, and eligibility migrations, including composite foreign keys, RLS, grants, search normalization, and audit triggers (`conformance.md:36-41`; `database.md:20-65,69-101`).
  - DONE: Security-invoker effective-values view; branch-scoped reads and restricted writes (`database.md:86-98,110-142`).
  - DONE: Seed data for categories, services, overrides, and staff eligibility (`backend.md:235-243`).
- Edge Functions: NONE REQUIRED in 3.1 (`plan/parts/11-delivery-plan.md:718`). Mutations for overrides and eligibility are handled transactionally in 3.2.
- Screens: NONE REQUIRED in 3.1 (`plan/parts/11-delivery-plan.md:720`).
- i18n/RTL: Bilingual data fields are DONE; UI-specific RTL requirements are in 3.3 (`database.md:55`; `plan/parts/11-delivery-plan.md:704-720,786`).
- Acceptance criteria: DONE for effective-value resolution and eligible-staff filtering/round-robin (`conformance.md:42-45`; `packages/core/src/catalogue.test.ts:118-184`).
- Tests: DONE. pgTAP covers role and branch access, resolution, and database matrix; Vitest covers resolver and round-robin (`conformance.md:42-45`; `GATES.md:106-110,149-156`).
- Dependencies: DONE. Phase 1.2 branches are present and referenced by catalogue data (`plan/parts/11-delivery-plan.md:728`; `conformance.md:208-213`).
- Backlog: DONE. The four Phase 3.1 database backlog items are represented by migrations, resolution/RPC work, and pgTAP tests (`plan/parts/11-delivery-plan.md:730-735`; `conformance.md:36-45`).

### Subphase 3.2: Catalogue function

- Features delivered
  - DONE: `catalogue/upsert-service` transactionally writes the definition, overrides, and staff eligibility (`plan/parts/11-delivery-plan.md:742-745`; `backend.md:35-40`).
  - DONE: `catalogue/reorder` with stale-order detection (`backend.md:35-37,130-135`).
  - DONE: Contract tests cover response envelope, validation, and scope denial (`backend.md:37,150-158`).
- Database work: The plan specifies none (`plan/parts/11-delivery-plan.md:747`). The RPC migration required for transactional multi-table operations is a declared, justified deviation; see “Deviations.”
- Edge Functions: DONE for both endpoints and contract tests (`plan/parts/11-delivery-plan.md:749-752`; `backend.md:31-40`).
- Screens: NONE REQUIRED in 3.2 (`plan/parts/11-delivery-plan.md:754`).
- i18n/RTL: NONE REQUIRED for this subphase's function endpoints; UI locale requirements are in 3.3 (`plan/parts/11-delivery-plan.md:738-760`).
- Acceptance criteria: DONE for atomic create and cross-branch denial (`backend.md:38-40`; `phase3-exit.spec.ts:212-309`).
- Tests: DONE. Catalogue Deno suite passes 8/8 and includes contract, transaction, rollback, and scope tests (`GATES.md:118-125`; `gates/fn-test.log:144-155`).
- Dependencies: DONE. The 3.1 tables and RPCs are in place for the 3.2 function (`plan/parts/11-delivery-plan.md:762`; `conformance.md:208-213`).
- Backlog: DONE. All three planned Edge Function backlog entries are present and tested (`plan/parts/11-delivery-plan.md:764-767`; `backend.md:35-40`).

### Subphase 3.3: Catalogue UI

- Features delivered
  - DONE: Branch-aware catalogue hub, service editor with definition/override/eligibility tabs, category editor and reorder, and deviation badges (`plan/parts/11-delivery-plan.md:775-779`; `conformance.md:65-68`).
- Database work: NONE REQUIRED by the 3.3 specification; data operations use the prior subphases (`plan/parts/11-delivery-plan.md:771-803`).
- Edge Functions: NONE IMPLEMENTED in 3.3; the screen mutations use the 3.2 endpoints through typed API wrappers (`frontend.md:63-74`).
- Screens: DONE for the hub, service editor, and category editor/reorder (`plan/parts/11-delivery-plan.md:781-784`; `conformance.md:69-71`).
- i18n/RTL: DONE. Bilingual names and descriptions, translated UI strings, locale formatting, bidi isolation, and RTL-safe reorder controls are covered by the frontend review; both locale journeys pass (`frontend.md:84-146,201-206`; `GATES.md:138-144`).
- Acceptance criteria: DONE for default bookability, branch-specific disable, deviation badges, duration steps, and three-decimal prices in both locales (`conformance.md:72-76`; `phase3-exit.spec.ts:376-469`).
- Tests: DONE. Catalogue Playwright journey passes in English and Arabic; Vitest and the phase evidence test also pass (`frontend.md:199-233`; `GATES.md:94-95`).
- Dependencies: DONE. The 3.2 catalogue function is available to the UI through typed API wrappers (`plan/parts/11-delivery-plan.md:795`; `frontend.md:63-74`).
- Backlog: DONE. All four planned front-end backlog entries are implemented (`plan/parts/11-delivery-plan.md:797-801`; `conformance.md:65-76`).

## Deviations

The conformance review found nine declared deviations, all justified. They are recorded in `plan/REVISION_LOG.md:137-149` and enumerated in `conformance.md:150-166`. No unjustified deviation was found.

| Deviation | Ruling and reason |
|---|---|
| `service_staff` includes `branch_id` and a composite foreign key to branch staff assignments. | DEVIATED-JUSTIFIED. This enforces per-branch eligibility and assignment integrity (`REVISION_LOG.md:141`; `conformance.md:156`). |
| Subphase 3.2 adds `20261007110000_catalogue_rpcs.sql` although its plan says no database work. | DEVIATED-JUSTIFIED. The RPCs provide atomic multi-table operations; the reason is recorded in `REVISION_LOG.md:142` and confirmed in `conformance.md:157`. |
| Additional duration, buffer, and category constraints. | DEVIATED-JUSTIFIED. They enforce conservative validation consistent with the grid step (`REVISION_LOG.md:143`; `conformance.md:158`). |
| No-change override rows are deleted; override rows must represent a deviation. | DEVIATED-JUSTIFIED. This keeps the override badge aligned with actual differences (`REVISION_LOG.md:144`; `conformance.md:159`). |
| `resolve_service` takes branch first and returns name snapshots. | DEVIATED-JUSTIFIED. The snapshot behavior follows the stated snapshot contract (`REVISION_LOG.md:145`; `conformance.md:160`). |
| Reorder uses move-up/down controls; the UI uses the Tabs primitive and “Show N disabled here” control. | DEVIATED-JUSTIFIED. The declared keyboard- and RTL-safe alternative preserves the user outcome (`REVISION_LOG.md:146`; `conformance.md:161`). |
| Seed and test data use RFC 4122 variant IDs; evidence provisions an extra branch. | DEVIATED-JUSTIFIED. The additional branch supports the three-override acceptance test (`REVISION_LOG.md:147`; `conformance.md:162`). |
| SQLSTATE `55000` maps to conflict, and `staff_not_assigned` maps to a field error. | DEVIATED-JUSTIFIED. The mapping provides clearer validation and conflict responses (`REVISION_LOG.md:148`; `conformance.md:163`). |
| UI labels follow the glossary: Definition, Branches, Eligible staff. | DEVIATED-JUSTIFIED. This matches the domain terminology (`REVISION_LOG.md:149`; `conformance.md:164`). |

## Findings

### Accepted findings

None. The verifier's final tally is zero blockers, zero majors, and zero minors (`adjudication.md:3-5,63-65`).

### Rejected findings

| Reported finding | Ruling |
|---|---|
| F-BE-1: Reorder endpoint lacks an idempotency key. | REJECTED. ADR-31 requires keys for money-moving mutations, and catalogue reorder does not move money. The plan does not require an idempotency key here; the stale-order check is tested (`plan/decisions.md:488-493`; `adjudication.md:35-37`). |
| F-BE-2: No dedicated typed API wrapper test for catalogue routes. | REJECTED. The plan requires contract and Deno transaction tests, which pass; it does not require a separate Vitest test per typed wrapper. Shared invoke behavior and catalogue routes are covered (`plan/parts/11-delivery-plan.md:742-760`; `adjudication.md:39-41`). |
| F-BE-3: Category archival needs a future-appointment guard. | REJECTED. This is a Phase 5 integration concern, not a Phase 3 acceptance criterion; no present tenant or branch access defect was demonstrated (`adjudication.md:43-45`). |
| F-CONF-1: No Arabic reorder screenshot. | REJECTED. The plan requires RTL-safe reorder and a catalogue journey in both locales, not a separate screenshot for every action. The Arabic journey, including reorder, passed (`plan/parts/11-delivery-plan.md:786-793`; `adjudication.md:47-49`). |
| F-CONF-2: Evidence test contains credentials. | REJECTED. The cited value is the truncated placeholder `eyJhbG...n_I0`, not a usable credential (`apps/back-office/evidence/phase3-exit.spec.ts:32-35`; `adjudication.md:51-53`). |
| F-DB-1: Database report's “no findings” summary row. | NOT A FINDING. The database report explicitly says there are no findings; the row is a formatting artifact (`database.md:271-305`; `adjudication.md:55-57`). |

## Not verifiable locally

None. The verifier found no Phase 3 criterion that requires a cloud-only check (`adjudication.md:59-61`).

## Fix prompt

No Phase 3 fixes are required. The verdict is PASS, and the verifier accepted no blockers, majors, or minors. Do not make code changes solely to address the rejected findings above.
