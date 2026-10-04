## Key flows

Sequence and state diagrams for the journeys that carry the product's invariants: sign-in and scope selection, booking with the double-booking guard, cross-branch reschedule, checkout, refund, cash-up, onboarding, and the Edge Function call anatomy; then the appointment, sale, payment, shift, and tenant state machines.

#### Sign-in and tenant/branch selection

```mermaid
sequenceDiagram
  actor U as User
  participant FE as React SPA
  participant Auth as Supabase Auth
  participant DB as Postgres (RLS)
  participant EF as Edge Function

  U->>FE: Enter email + password
  FE->>Auth: signInWithPassword()
  Auth-->>FE: session (JWT)
  
  FE->>DB: SELECT memberships WHERE user_id = auth.uid() AND is_active = true
  DB-->>FE: [{tenant_id, role, branch_id, all_branches}]

  alt Single tenant, single branch
    FE->>FE: Set active tenant + branch (skip switcher)
  else Multi-tenant user
    FE->>U: Show tenant switcher
    U->>FE: Select tenant
    FE->>FE: Set active tenant context
  end

  alt Multiple branches (manager/receptionist)
    FE->>U: Show branch switcher
    U->>FE: Select branch
    FE->>FE: Set active branch (URL search param ?branch=uuid)
  end

  FE->>FE: Render app shell with tenant + branch context
  Note over FE: Every subsequent query key carries tenant+branch scope (ADR-38)
```

Sign-in explanation: `auth.uid()` from the JWT is the only trusted identity input (ADR-19). Authorization (tenant membership, role, branch scope) is derived on every request from the `memberships` table via `STABLE SECURITY DEFINER` helpers (`current_tenant_ids()`, `current_branch_scope()`, `has_tenant_role()`). The JWT carries no tenant or role claims. Memberships are filtered `is_active = true` — revoking a membership takes effect immediately without waiting for token expiry (ADR-19). A user may hold memberships in multiple tenants and different roles at different branches; the active tenant is application context persisted per user (ADR-37, F-fe-1). Branch context lives in the URL as a search param (`?branch=<uuid>|all`); RLS remains the real security boundary either way (ADR-37).

#### Creating a booking (double-booking guard)

```mermaid
sequenceDiagram
  actor R as Receptionist
  participant FE as React SPA
  participant EF as Edge Function (bookings)
  participant DB as Postgres
  participant Lock as Advisory Lock
  R->>FE: Select client, services, staff, time
  FE->>FE: Client-side slot computation (packages/core)
  Note over FE: Slot engine computes from opening hours shift duration buffers minus appointments blocked time closures
  R->>FE: Confirm booking
  FE->>EF: POST /bookings/create {clientId, branchId, items[{serviceId, staffId, start}], Idempotency-Key}
  Note over FE,EF: JWT sent via Authorization header EF verifies membership live
  EF->>DB: has_tenant_role(tenantId roles branchId)
  DB-->>EF: true
  EF->>DB: SELECT membership branch scope validation
  EF->>DB: SELECT resolve_service per item snapshot price duration buffers
  loop For each staff member in items
    EF->>Lock: pg_advisory_xact_lock(hashtextextended(staffId 0))
    Note over Lock: Serializes concurrent bookings per staff member
    EF->>DB: Check blocked_times overlap for this staff
    EF->>DB: Check appointment_items busy_range overlap for this staff
  end
  alt Conflict found
    EF-->>FE: {ok: false error: {code: CONFLICT details: {conflictingAppointmentId}}}
    FE->>R: Show conflict toast with details
  else No conflict
    EF->>DB: INSERT appointment branchId clientId refNumber status=booked
    EF->>DB: INSERT appointment_items staffId effectiveStartEnd snapshots busyRange
    EF->>DB: UPDATE invoice_counters SET next_number = next_number + 1 kind=appointment_ref
    Note over DB: Exclusion constraint is the final guard advisory lock prevents races
    EF-->>FE: {ok: true data: {appointment}}
    FE->>FE: Optimistic cache update via TanStack Query
    FE->>FE: Realtime subscription updates calendar
  end
```

Booking explanation: The double-booking prevention uses three layers (ADR-24): (1) A database exclusion constraint `EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&) WHERE status_active` on `appointment_items` is the final guard. (2) The booking RPC takes `pg_advisory_xact_lock` per staff member, serializing concurrent bookings and making the check-then-insert race impossible. (3) An RPC pre-check computes conflicts first for good error messages. Cross-entity conflicts (appointment vs blocked time) are checked inside the same locked transaction (ADR-26). The conflict engine checks busy time across all branches the staff member is assigned to (ADR-12). Buffers are included in `busy_range` (ADR-25). All appointment writes go through the `bookings` Edge Function — never direct supabase-js (ADR-28). The `Idempotency-Key` header prevents double-booking on retry (ADR-31).

#### Rescheduling across branches (price re-resolution)

```mermaid
sequenceDiagram
  actor R as Receptionist
  participant FE as React SPA
  participant EF as Edge Function (bookings)
  participant DB as Postgres

  R->>FE: Drag appointment item to different branch/time
  FE->>FE: Optimistic UI update (drag to new slot)
  FE->>EF: POST /bookings/reschedule {appointment_item_id, new_branch_id, new_start, Idempotency-Key}

  EF->>DB: Verify membership + branch scope for BOTH old and new branches
  DB-->>EF: Authorized

  alt New branch != old branch
    EF->>DB: resolve_service(new_branch_id, service_id)
    Note over DB: Re-resolve price/duration/buffers at target branch (ADR-13, F-walk-1)
    DB-->>EF: {price_minor: new_price, duration_minutes: new_dur, buffers: new_bufs}
  else Same branch
    EF->>DB: Reuse existing resolved values
  end

  EF->>DB: Take advisory lock for the staff member
  EF->>DB: Check conflicts at new time/branch
  alt Conflict
    EF-->>FE: {ok: false, error: {code: "CONFLICT", ...}}
    FE->>FE: Rollback optimistic update, show conflict
  else Available
    EF->>DB: UPDATE appointment_item SET effective_start/end, price_minor, buffer_*, busy_range, branch_id (if changed)
    EF->>DB: INSERT audit_log (old values + new values, cross-branch flag)
    EF-->>FE: {ok: true, data: {updated_item}}
    FE->>FE: Confirm optimistic update, invalidate calendar cache
  end
```

Reschedule explanation: A cross-branch reschedule must re-resolve price, duration, and buffers via `resolve_service(target_branch_id, service_id)` — reusing the old branch's snapshot is a billing error (ADR-13, F-walk-1). The audit record carries both old and new resolved values. Direct updates of `scheduled_start/end` or item spans are prohibited — reschedule goes through the same locked RPC path as creation, closing the "reschedule bypasses the trigger" hole (ADR-24).

#### Check-in and checkout with cash payment

```mermaid
sequenceDiagram
  actor R as Receptionist
  participant FE as React SPA
  participant EF as Edge Function (checkout)
  participant DB as Postgres

  Note over R,DB: Check-in
  R->>FE: Client arrives tap Check In
  FE->>EF: POST /bookings/status {appointmentId status: arrived}
  EF->>DB: Verify role and branch scope
  EF->>DB: UPDATE appointments SET status = arrived legal transition check
  EF->>DB: INSERT audit_log
  EF-->>FE: {ok: true}
  Note over FE: Appointment moves to In Progress when service starts
  Note over R,DB: Service completes then checkout
  R->>FE: Open checkout screen for appointment
  FE->>FE: Load resolved items compute totals per ADR-51
  R->>FE: Apply discount line or sale-level confirm
  R->>FE: Select payment method cash
  R->>FE: Confirm sale
  FE->>EF: POST /checkout/sale {appointmentId items discounts tips payments cash amountMinor Idempotency-Key}
  EF->>DB: idempotency check tenantId key
  alt Replay
    EF-->>FE: Cached response
  else New
    EF->>DB: has_tenant_role(tenantId roles branchId)
    EF->>DB: Verify register session is OPEN cash payment requires open register
    EF->>DB: Take invoice counter lock UPDATE invoice_counters SET next = next + 1 RETURNING next - 1
    EF->>DB: Recompute totals server-side per ADR-51 order reject client-supplied mismatches
    EF->>DB: INSERT sale invoiceSeq totals status
    EF->>DB: INSERT sale_items snapshotted from appointment_items
    EF->>DB: INSERT payments method=cash amountMinor registerSessionId
    EF->>DB: INSERT tips per staff outside taxable base
    EF->>DB: UPDATE appointments SET status = completed
    EF->>DB: INSERT audit_log entries
    EF-->>FE: {ok: true data: {sale receiptData}}
  end
  FE->>R: Show receipt choice to print or email
```

Checkout explanation: The checkout RPC implements the deterministic calculation order from ADR-51: line base → line discounts (fixed then percent) → invoice-level pro-rata allocation → tax extraction → tips (separate) → sale total. Client-supplied totals that differ from the server recomputation are rejected (tampered-total negative test). Cash payments require an open register session (ADR-6). The invoice number is assigned inside the sale transaction via row-locked `UPDATE ... RETURNING` on `invoice_counters` (ADR-14). All money mutations carry an `Idempotency-Key` (ADR-31). All checkout writes go through the `checkout` Edge Function — never direct supabase-js (ADR-28). Receptionists keep checkout, discounts, and tips; refunds and voids are owner/manager-only (ADR-10 round 2, F-perm-1).

#### Refund by a manager

```mermaid
sequenceDiagram
  actor M as Branch Manager
  participant FE as React SPA
  participant EF as Edge Function (checkout)
  participant DB as Postgres

  M->>FE: Open sale detail tap Refund Payment
  M->>FE: Select payment to refund enter reason
  FE->>EF: POST /checkout/refund {paymentId amountMinor reason Idempotency-Key}
  EF->>DB: has_tenant_role(tenantId managerRoles branchId)
  Note over DB: Receptionist is FORBIDDEN per ADR-10 round 2
  EF->>DB: SELECT payment verify exists branch scope type=payment
  EF->>DB: SELECT sum refunded amounts for this payment
  alt Refund exceeds original
    EF-->>FE: {ok: false error: {code: VALIDATION message: Refund exceeds payment amount}}
  else Valid
    EF->>DB: INSERT payments type=refund refundsPaymentId positive amountMinor reason registerSessionId=NULL if no open session
    Note over DB: Trigger enforces sum refunds <= original out-of-session refunds flagged in audit
    EF->>DB: UPDATE sale SET status and due_minor recalculated
    EF->>DB: INSERT audit_log refund action manager id
    EF-->>FE: {ok: true data: {refund}}
  end
  FE->>M: Refund confirmed daily summary flags out-of-session refunds
```

Refund explanation: Refunds are a `payments` row with `payment_type = 'refund'` and a **positive** `amount_minor` referencing `refunds_payment_id` (ADR-34 round 2, F-PLAN-2). No separate refunds table exists; no negative ledger amounts exist. A trigger enforces `sum(refund amounts) ≤ original payment amount`. Refunds are owner/branch-manager only — receptionists are forbidden (ADR-10 round 2, F-perm-1). Cash refunds executed when the branch has no open register session are allowed (manager-approved) and recorded with `register_session_id IS NULL`, flagged in the daily summary and audit (ADR-6, F-walk-2). The original payment record is never mutated.

#### End-of-day cash-up

```mermaid
sequenceDiagram
  actor M as Branch Manager
  participant FE as React SPA
  participant EF as Edge Function (checkout)
  participant DB as Postgres

  M->>FE: Open register tap Close Register
  M->>FE: Enter counted cash amount
  FE->>EF: POST /checkout/close-register {registerSessionId countedCashMinor}
  EF->>DB: has_tenant_role(tenantId managerRoles branchId)
  EF->>DB: Verify session is OPEN and belongs to this branch
  EF->>DB: SELECT sum cash payments for this session
  EF->>DB: UPDATE register_sessions SET countedCashMinor differenceMinor closedBy closedAt status=closed
  alt Difference != 0
    EF->>DB: INSERT audit_log cash difference flagged
  end
  EF-->>FE: {ok: true data: {sessionSummary expected counted difference}}
  FE->>M: Show cash-up summary discrepancies flagged
```

Cash-up explanation: One register session per branch at a time (ADR-6). Daily reconciliation: expected = `starting_cash_minor + sum(cash payments during session) − sum(cash refunds)`. Difference = `counted − expected`. Out-of-session cash refunds (with `register_session_id IS NULL`) are flagged in the daily summary and audit (ADR-6, F-walk-2). Register sessions and their close go through the `checkout` Edge Function.

#### Tenant onboarding

```mermaid
sequenceDiagram
  actor P as Platform Admin
  participant OPS as Ops Script / UI
  participant EF as Edge Function (onboarding)
  participant DB as Postgres (service role)

  P->>OPS: Create tenant: company name, owner email, plan, currency, default branch details
  OPS->>EF: POST /onboarding/provision {tenant, owner_user, branch, plan} (service_role auth)

  EF->>DB: CREATE tenant row (service role — no authenticated insert policy)
  EF->>DB: CREATE or find auth user for owner
  EF->>DB: INSERT profile (trigger on auth.users)
  EF->>DB: INSERT membership (tenant_owner, all_branches=true)
  EF->>DB: INSERT branch (default, timezone='Asia/Kuwait')
  EF->>DB: INSERT branch_opening_hours (default business hours)
  EF->>DB: INSERT invoice_counters (invoice + appointment_ref, starting at 1)
  EF->>DB: INSERT plan_features row
  EF->>DB: INSERT currency or link existing (KWD, exponent=3)
  EF->>DB: SEED cancellation_reasons, blocked_time_types (bilingual defaults)
  EF->>DB: INSERT audit_log entries

  EF-->>OPS: {ok: true, data: {tenant, owner_user_id, branch}}
  OPS->>P: Done. Owner receives credentials.
```

Onboarding explanation: Tenant creation is platform-admin-only through the `onboarding` Edge Function under the service role (ADR-20 rule 3). No `authenticated` insert policy exists on `tenants` (open question 7 ruled). Provisioning is idempotent (re-run safe, ADR-31 pattern). The owner gets `tenant_owner` role with `all_branches = true`. Default seeded data includes bilingual cancellation reasons and blocked time types (ADR-16). Branch defaults use `Asia/Kuwait` timezone, Saturday as first day of week for Arabic-first tenants (ADR-52).

#### Edge Function call: JWT verification, tenant checks, idempotency, error format

```mermaid
sequenceDiagram
  participant FE as React SPA (packages/api)
  participant EF as Edge Function (_shared/server.ts)
  participant Auth as Supabase Auth
  participant DB as Postgres

  FE->>EF: POST /functions/v1/bookings/create\nAuthorization: Bearer <JWT>\nIdempotency-Key: <UUID>\nBody: {tenant_id, branch_id, ...}

  Note over EF: _shared/server.ts wrapper extracts auth mode = 'user'

  EF->>Auth: supabase.auth.getUser(jwt)
  Auth-->>EF: {user: {id}, session} or error
  alt Invalid/expired JWT
    EF-->>FE: {ok: false, error: {code: "UNAUTHENTICATED", message: "..."}}
  end

  EF->>DB: SELECT memberships WHERE user_id = $1 AND tenant_id = $2 AND is_active = true
  DB-->>EF: [{role, branch_id, all_branches}]
  alt No active membership
    EF-->>FE: {ok: false, error: {code: "FORBIDDEN", message: "..."}}
  end

  EF->>DB: has_tenant_role(tenant_id, required_roles, branch_id)
  DB-->>EF: false
  alt Insufficient role for branch
    EF-->>FE: {ok: false, error: {code: "FORBIDDEN", message: "..."}}
  end

  EF->>DB: idempotency_keys check (tenant_id, key)
  alt status = 'completed'
    EF-->>FE: Cached response (200 with prior body)
  else status = 'processing'
    EF-->>FE: {ok: false, error: {code: "CONFLICT", message: "Request in progress"}}
  else new key
    EF->>DB: INSERT idempotency_keys (status='processing')
    EF->>DB: Execute business logic (book appointment, create sale, etc.)
    alt Success
      EF->>DB: UPDATE idempotency_keys SET status='completed', response_body
      EF-->>FE: {ok: true, data: {...}}
    else Validation error
      EF-->>FE: {ok: false, error: {code: "VALIDATION", message: "...", fieldErrors: {...}}}
    else Internal error
      EF->>DB: UPDATE idempotency_keys SET status='failed'
      EF-->>FE: {ok: false, error: {code: "INTERNAL", message: "..."}}
    end
  end
```

Edge Function explanation: Every function uses the shared `_shared/server.ts` wrapper (ADR-35), which handles JWT verification via `supabase.auth.getUser()`, assembles context (tenant, branch, role from live membership lookup), and emits the versioned envelope `{ok, data}` / `{ok, error: {code, message, fieldErrors?, details?}}` (ADR-29). Authorization is never derived from JWT claims (ADR-19). The `Idempotency-Key` header is required on money mutations; the `idempotency_keys` table caches responses and detects `processing` collisions (ADR-31). The error code catalogue is defined once in `packages/validation` (TS) and mirrored in `_shared/errors.ts` (Deno): `VALIDATION(400)`, `UNAUTHENTICATED(401)`, `FORBIDDEN(403)`, `NOT_FOUND(404)`, `CONFLICT(409)`, `IDEMPOTENCY_MISMATCH(422)`, `RATE_LIMITED(429)`, `INTERNAL(500)`, `UNAVAILABLE(503)` (ADR-29).

---

### State diagrams

#### Appointment state machine

```mermaid
stateDiagram-v2
  [*] --> booked : Receptionist/Manager\ncreates booking
  booked --> confirmed : Receptionist/Manager\nconfirms (opt)
  confirmed --> arrived : Client arrives\nCheck-in
  booked --> arrived : Client arrives\nCheck-in (skip confirm)
  arrived --> in_progress : Service begins
  in_progress --> completed : Service completes\n→ Checkout flow
  booked --> cancelled : Cancelled with reason\n(any state before completed)
  confirmed --> cancelled : Cancelled with reason
  arrived --> cancelled : Cancelled with reason
  booked --> no_show : Client does not arrive\n(manager action or cron)
  confirmed --> no_show : Client does not arrive
  completed --> [*]
  cancelled --> [*]
  no_show --> [*]

  note right of booked
    Status enum (ADR-7):
    booked, confirmed, arrived,
    in_progress, completed,
    cancelled, no_show
  end note

  note right of cancelled
    appointment_items.status_active
    = false on cancel/no_show
    (drops out of exclusion constraint)
  end note
```

Appointment state explanation: The appointment status enum is fixed: `booked, confirmed, arrived, in_progress, completed, cancelled, no_show` (ADR-7). `in_progress` is the canonical value — `started` is banned. Only legal transitions are allowed; backward moves require manager override and are audit-logged (ADR-7). Custom statuses are deferred non-committed (ADR-7, F-cov-5). When an appointment is cancelled or marked no_show, `appointment_items.status_active` is set to `false`, dropping the item out of the exclusion constraint and freeing the slot (ADR-24). The checkout flow transitions the appointment to `completed` as part of the sale transaction.

#### Sale state machine

```mermaid
stateDiagram-v2
  [*] --> unpaid : Checkout creates sale
  unpaid --> part_paid : First payment received\n(total > 0, due > 0)
  part_paid --> completed : Final payment\n(due = 0)
  unpaid --> completed : Full payment\nin single transaction
  unpaid --> voided : Manager voids\nsame-day only, reason required
  part_paid --> voided : Manager voids\nsame-day only
  completed --> [*]
  voided --> [*]

  note right of unpaid
    Status enum (ADR-7):
    unpaid, part_paid,
    completed, voided
  end note

  note left of voided
    Void: same-day only,
    reason required,
    sale preserved with
    status = 'voided',
    never deleted (ADR-10)
  end note
```

Sale state explanation: The sale status enum is fixed: `unpaid, part_paid, completed, voided` (ADR-7). `completed` means fully paid and closed. Voids are same-day only with a required reason; the sale record is preserved with status `voided` — never deleted (ADR-10, ADR-46). Refunds do not change the sale status — they are separate `payments` rows of type `refund` (ADR-34). The derived `due_minor` value (`total - sum(payments)`, never hand-edited) drives the `unpaid → part_paid → completed` transitions.

#### Payment and refund state

```mermaid
stateDiagram-v2
  [*] --> payment_recorded : Cash/manual payment\nrecorded at checkout
  
  state payment_recorded {
    [*] --> active : Payment row created\n(type = 'payment')
    active --> fully_refunded : Refund(s) sum = amount
    active --> partially_refunded : Refund(s) sum < amount
  }

  payment_recorded --> [*] : Payment exists in immutable ledger

  note right of payment_recorded
    Payments table (ADR-34):
    - payment_type: payment | refund
    - All amounts positive (bigint _minor)
    - Trigger: sum(refunds) <= original
    - Never mutated or deleted
  end note
```

Payment state explanation: There is no separate refunds table — all money movements are `payments` rows (ADR-34). A refund is a `payments` row with `payment_type = 'refund'` and a **positive** `amount_minor` referencing `refunds_payment_id`. All amounts are `CHECK (amount_minor >= 0)` — no signed ledger columns. A trigger enforces `sum(refund amounts) <= original payment amount`. Financial rows are immutable (ADR-46); corrections are new rows (refunds). Full refunds are in MVP; partial refunds arrive in plan Phase 10 with online payments (ADR-34).

#### Staff shift lifecycle

```mermaid
stateDiagram-v2
  [*] --> scheduled : Manager creates shift\n(starts_at, ends_at)
  scheduled --> in_progress : Current time >= starts_at
  in_progress --> completed : Current time >= ends_at
  scheduled --> cancelled : Manager cancels shift
  scheduled --> [*]
  in_progress --> [*]
  completed --> [*]
  cancelled --> [*]
```

Shift explanation: Shifts are dated rows (`timestamptz` ranges), not weekly templates (ADR-26). The shift grid materializes a week of rows and supports copy-previous-week. Overnight shifts (`ends_at` next day) are natural with `timestamptz`. Shifts are a soft constraint on booking — booking outside a shift produces a warning with manager override recorded in `booking_overrides` (ADR-26).

#### Tenant lifecycle

```mermaid
stateDiagram-v2
  [*] --> trial : Platform admin provisions\n(onboarding function)
  trial --> active : Owner completes setup\n(checklist done)
  active --> suspended : Platform admin suspends\n(payment or TOS)
  suspended --> active : Platform admin reactivates
  active --> offboarding : Owner requests offboarding\n(ADR-50)
  
  state offboarding {
    [*] --> export : Full tenant export\n(ADR-43)
    export --> soft_archive : Marked inactive\nmemberships deactivated\n28-day read-only
    soft_archive --> anonymize : Personal fields\nreplaced via RPC
    anonymize --> financial_retention : Financial records\nretained 10 years
    financial_retention --> deleted : Hard delete\nafter retention period
  }

  offboarding --> [*]
```

Tenant lifecycle explanation: Tenants begin as `trial` when provisioned by platform operations (the audited impersonation path, ADR-20 rule 9 — not an in-app role) via the `onboarding` Edge Function (ADR-18, ADR-20 rule 3). Setup checklist completion transitions to `active`. The offboarding contract follows ADR-50: export -> 28-day soft archive -> anonymize personal data via the NFR-11 RPC -> retain financials for the Kuwaiti commercial period (default 10 years, legal confirmed at plan Phase 17 scheduling, ADR-50) -> hard delete. The anonymize RPC built in plan Phase 4 is the same machinery used for offboarding. Subscription billing and self-serve signup arrive in plan Phase 17 (ADR-18).

---

