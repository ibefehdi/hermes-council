## Architecture

This section covers the system context, the containers, deployment and environments, the CI/CD pipeline, and Edge Function isolation.

#### C4 Level 1: System context

Who uses GlowDesk and what external systems does it connect to.

```mermaid
flowchart TB
  subgraph users["Users"]
    OWNER["Tenant Owner"]
    MGR["Branch Manager"]
    RECP["Receptionist"]
    STAFF["Staff Member"]
    PLATFORM["Platform Admin (ops)"]
  end

  GLOWDESK["GlowDesk SaaS\nMulti-tenant spa/salon platform"]

  subgraph external["External Services (post-MVP)"]
    SMS["SMS Provider\n(plan Phase 9)"]
    WHATSAPP["WhatsApp Business\n(plan Phase 9)"]
    EMAIL["Email Provider\n(plan Phase 9)"]
    MYFATOORAH["MyFatoorah / Tap\n(plan Phase 10)"]
  end

  OWNER --> GLOWDESK
  MGR --> GLOWDESK
  RECP --> GLOWDESK
  STAFF --> GLOWDESK
  PLATFORM --> GLOWDESK

  GLOWDESK -.-> SMS
  GLOWDESK -.-> WHATSAPP
  GLOWDESK -.-> EMAIL
  GLOWDESK -.-> MYFATOORAH
```

Context explanation: The system has four in-app roles (`tenant_owner`, `branch_manager`, `receptionist`, `staff`) plus a platform operations path (`platform_admin` via audited impersonation — never a membership role, per ADR-20 rule 9). All notification and payment integrations are post-MVP (plan Phases 9-10); the MVP is back-office only with manual/cash payments (ADR-1, ADR-34). External services are connected through Edge Functions behind provider abstractions so no provider-specific code leaks into the domain model (ADR-34).

#### C4 Level 2: Container diagram

The runtime containers and their communication paths.

```mermaid
flowchart TB
  subgraph browser["Browser"]
    BO["apps/back-office\nReact 18 SPA\n(Vite + TypeScript)"]
    BK_APP["apps/booking\n(plan Phase 9 scaffold)"]
  end

  subgraph supabase["Supabase Platform (production: eu-central-1, ADR-48)"]
    AUTH["Supabase Auth\nemail+password\nJWT = identity only"]
    
    subgraph edge["Edge Functions (Deno, one per bounded context)"]
      EF_BOOK["bookings\ncreate/reschedule/cancel/slots"]
      EF_CO["checkout\nsale/payment/refund/void/register"]
      EF_CAT["catalogue\nservices/categories/overrides"]
      EF_CL["clients\nCRUD/duplicate/import/merge(Ph11)"]
      EF_STAFF["staff\nrecords/assignments/shifts/blocks"]
      EF_RPT["reports\naggregation RPCs/CSV export stream"]
      EF_ON["onboarding\nplatform tenant/branch provisioning"]
    end

    subgraph data["Postgres + Extensions"]
      PG["Tables + RLS\n(tenant & branch scoped)"]
      RPC["SECURITY DEFINER RPCs\n(reports, booking, checkout, helpers)"]
      Q["pgmq queues + pg_cron\n(async imports/exports/cleanup)"]
    end

    RT["Realtime\n(postgres_changes)"]
    STORAGE["Storage\n(plan Phase 9+)"]
  end

  subgraph external["External"]
    SENTRY["Sentry\n(errors both sides)"]
    UPTIME["Uptime monitor\n(/health per function)"]
  end

  BO -->|"reads: supabase-js under RLS"| PG
  BO -->|"report reads: RPC"| RPC
  BO -->|"invariant writes: typed invoke()"| edge
  BO -->|"calendar liveness"| RT
  BO --> AUTH
  BO -.->|"plan Phase 9"| STORAGE

  edge -->|"user-scoped client (RLS)"| PG
  edge -->|"service-role client (verified scope)"| RPC
  edge --> Q
  RT --> PG

  edge --> SENTRY
  BO --> SENTRY
  UPTIME --> edge

  BK_APP -.->|"plan Phase 9"| edge
```

Container explanation: Three rules define the system (per CONVENTIONS §1): (1) The database is the security boundary — RLS enforces tenant and branch isolation, never application code (ADR-20). (2) The JWT carries identity only — `auth.uid()` is the only trusted input; tenant, role, and branch scope are looked up live from `memberships` on every request (ADR-19). (3) Edge Functions are isolated per bounded context — a failing or redeploying function never takes down another domain (ADR-27, NFR-2). The MVP has seven functions (`bookings`, `checkout`, `catalogue`, `clients`, `staff`, `reports`, `onboarding`); Storage and `apps/booking` are plan Phase 9 (ADR-43). The `_shared/` directory holds shared modules imported by relative path (ADR-32). Async work uses `pg_cron` + `pgmq` with idempotent consumers (ADR-33).

---

### Deployment and environments

#### Environment topology

```mermaid
flowchart LR
  subgraph local["Local Development"]
    LCLI["Supabase CLI\n(supabase start)"]
    LSERVE["supabase functions serve"]
    LVITE["Vite dev server"]
  end

  subgraph staging["Staging\n(Supabase preview branch)"]
    SDB["Preview-branch Postgres"]
    SEF["Edge Functions"]
    SFE["Frontend deploy"]
  end

  subgraph prod["Production\n(paid plan, ADR-48 region)"]
    PDB["Postgres + PITR\n(daily backups, ADR-49)"]
    PEF["Edge Functions"]
    PFE["Frontend deploy"]
  end

  DEV["Feature branch\n(ephemeral preview DB)"] -->|"PR merge"| staging
  staging -->|"merge to main"| prod

  local -.->|"supabase db push"| DEV
```

Environment explanation: Local development uses the Supabase CLI stack (`supabase start`, `supabase functions serve`, Vite). Feature branches get ephemeral preview-branch databases for migration testing. CI deploys migrations, functions, and the frontend to staging on merges to `staging`, and to production only from `main` (CONVENTIONS §8). Production runs on a paid-plan Supabase project with managed daily backups and PITR (ADR-49). The region defaults to `eu-central-1` as an assumption, with a legal verification gate before Phase 8 go-live (ADR-48).

#### CI/CD pipeline

```mermaid
flowchart TB
  PR["Pull Request opened"] --> CI["ci.yml triggered"]

  subgraph ci_jobs["CI Jobs (parallel where possible)"]
    TYPECHECK["Typecheck\n(Deno + TypeScript)"]
    LINT["Lint\n(ESLint + stylelint logical-CSS + import boundaries)"]
    UNIT["Unit tests\n(Vitest + Deno test)"]
    BUILD["Build + size-limit\ngenerated-types drift check"]
  end

  CI --> TYPECHECK
  CI --> LINT
  CI --> UNIT
  CI --> BUILD

  TYPECHECK --> CLEAN_MIG["Clean-migration gate\n(supabase db reset on pinned CLI\n→ gen types drift → functions build\n→ supabase test db → adversarial fixtures)"]

  LINT --> CLEAN_MIG
  UNIT --> CLEAN_MIG
  BUILD --> CLEAN_MIG

  CLEAN_MIG -->|"green + merge to staging"| DEPLOY["deploy.yml"]
  
  DEPLOY --> DEP_MIG["Deploy migrations\n(supabase db push)"]
  DEP_MIG --> DEP_FN["Deploy functions\n(supabase functions deploy --use-api)"]
  DEP_FN --> DEP_FE["Deploy frontend\n(build + upload)"]

  DEP_FE --> E2E["Playwright E2E\n(critical journeys en+ar, nightly)"]
```

Pipeline explanation: CI gates every PR on typecheck, lint, unit tests, and build. The clean-migration gate (`F-verifier-2`) applies the full active migration set to an empty database on the pinned CLI version, regenerates types (drift fails CI), typechecks/builds every function, runs `supabase test db` (pgTAP), and executes the adversarial fixture suite (cross-tenant, cross-branch, money, and booking negatives). The gate fails if anything under `sql/drafts-v1/` is referenced by the active migration path. Frontend and backend deploy from the same commit (monorepo rule, ADR-30). E2E tests run nightly and pre-release.

#### Edge Function isolation

Each Edge Function is an independent Deno deployable. A failing or redeploying function never takes down another domain because:

- Each function is a separate Supabase Edge Function slug with its own deployment lifecycle (`supabase functions deploy --slug <name>`).
- Internal routing within a function (`/<function>/<action>`, ADR-30) means most code changes touch one function.
- Shared code lives in `_shared/` — a change to `_shared` redeploys all functions in the same CI run (documented blast radius, ADR-32).
- Per-function cold starts (~50-200ms) amortize across actions in the same function; Supabase limits apply per-request (256MB memory, wall-clock CPU caps per ADR-27).
- Each function exposes `/health` for external uptime monitoring.

---

