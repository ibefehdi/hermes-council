# Backend & Edge Functions Audit — Phase 2 (Staff & shifts)

**Auditor**: auditor profile (t_ddad3fb0)
**Repo**: /Users/fahadasad/glowdesk (HEAD edfad11, main, working tree clean)
**Date**: 2026-10-05
**Gates**: 8/8 PASS (per parent t_b11bc7cd)

---

## Summary

Phase 2 (Staff & shifts) Edge Functions and backend work is substantially complete and correct. All three subphases have working Deno Edge Functions or database RPCs as specified. Test coverage is thorough (20 Deno staff tests, 159-line blocked_time concurrency tests, 240-line shift materialization tests including DST). The `_shared/` wrapper provides the ADR-29 envelope, auth modes, idempotency, CORS, logging and Sentry integration consistently.

**1 finding (minor).** No blockers.

---

## Subphase 2.1: Staff records

**Edge Functions specified**: `staff/upsert`, `staff/invite-login`
**Status**: DONE

### Evidence

| Check | Finding |
|---|---|
| **Function exists** | `/Users/fahadasad/glowdesk/supabase/functions/staff/index.ts` serves `routes` from `routes.ts` with `fn: "staff", auth: "user"`. Routes: `POST /upsert` → `handleUpsert`, `POST /invite-login` → `handleInviteLogin`, `POST /shifts-materialize` → `handleShiftsMaterialize`. |
| **Schema validation** | Shared Zod schema at `packages/validation/src/staff.ts:57` (`staffUpsertSchema`) enforces bilingual names, branch assignments, duplicate-branch check, at-most-one-default check. Tested: empty name → 400 VALIDATION, two defaults → 400, no branches → 400. |
| **Auth checks** | `user` mode (index.ts:4). `handleUpsert` calls `requireScope(caller, input.tenant_id, undefined, MANAGING_ROLES)` which checks caller holds `tenant_owner` or `branch_manager` for the tenant. Fine-grained branch scope is re-verified inside the `upsert_staff_member` RPC (ADR-20 rule 7). Tested: no session → 401; receptionist → 403; wrong tenant → 403; manager on Jahra (own branch) → 201. |
| **invite-login** | Creates auth user (or uses existing), grants `staff` role on assignable branches via `apply_membership_change`, links via `link_staff_login`. Cleanup on failure: deletes invited user if a later step fails. Tested: new invite → 201 with invited=true; existing user → linked with invited=false; duplicate email → 409 CONFLICT; manager grants only own branches; compensation test deletes on link failure. |
| **Transactional writes** | `upsert` goes through `upsert_staff_member` RPC (single DB transaction). `invite-login` spans auth admin API + DB RPCs; cleanup is best-effort (not transactional across auth.user → DB). This is a minor accepted pattern (see Finding F-BE-1). |

---

## Subphase 2.2: Shifts

**Edge Functions specified**: `staff/shifts-materialize` (week copy)
**Status**: DONE

### Evidence

| Check | Finding |
|---|---|
| **Function exists** | `routes.ts:9` maps `POST /shifts-materialize` → `handleShiftsMaterialize` in `shifts.ts`. |
| **Scope check** | `shifts.ts:45` calls `requireScope(caller, input.tenant_id, input.branch_id, ["tenant_owner", "branch_manager"])` — branch-scoped. Tested: Hawally manager cannot copy Jahra → 403; receptionist cannot copy → 403; other tenant's owner cannot copy → 403. |
| **Body validation** | Shared Zod schema (`ShiftWeekCopyInput`) validates source/target weeks, staff_ids, etc. Tested: same source/target → 400; wrong day-of-week → 400. |
| **Overnight shift handling** | Tested with 18:00-02:00 shifts, copied correctly in Asia/Kuwait. |
| **DST correctness** | Synthetic Europe/London branch test proves wall times are preserved across the 2027-03-28 DST change (BST switch). UTC storage is verified to shift by 1h. |
| **Conflict detection** | Copy over existing shifts → 409 CONFLICT with `shift_overlap` reason; passing `replace=true` deletes-and-reinserts. Verified. |
| **Audit trail** | Copied shifts are audited with the manager as actor (`shifts_test.ts:135-141`). |
| **Forged-scope re-check** | Test proves `copy_shift_week` re-checks branch authority in the database even when the caller's resolved scope claims "all" (shifts_test.ts:226-239). |

---

## Subphase 2.3: Blocked time

**Edge Functions specified**: RPC-only (no Edge Function wrapper)
**Status**: DONE

### Evidence

| Check | Finding |
|---|---|
| **No Edge Function** | There is no `blocked-time` Edge Function; all writes go through locked RPCs (`create_blocked_time`, etc.) as specified. This matches the phase text "Edge Functions: blocked-time actions are RPC-only". |
| **Locked RPC** | `create_blocked_time` uses advisory lock + cross-entity appointment check per ADR-24 layer 2. Tested via `blocked_time_test.ts`. |
| **RLS select-only** | `blocked_times` table has select-only policies; all mutations through the locked RPC. Verified in pgTAP. |
| **Concurrency** | Two racing blocks for one staff member: exactly one lands, the other gets `23P01 blocked_time_overlap`. Six parallel creates for the same slot: one success only (`blocked_time_test.ts:61-91`). |
| **Cross-entity conflict** | Block over an appointment item (including 15min buffers) is refused with `blocked_time_appointment_conflict`. Buffer edge (11:15 where buffer ends at 11:15) is free as expected. |
| **Schedule endpoint** | `branch_staff_schedule` returns both shifts and typed blocks. Blocked-time notes are trimmed. |

---

## Phase-level checks

### Exit criteria
| Criterion | Status | Evidence |
|---|---|---|
| Staff assigned to two branches appears in both lists | DONE | Staff branch assignments tested via upsert at two branches; pgTAP matrix tests cover this (gates GATES.md shows `008_staff_matrix.test.sql` PASS). |
| Branch manager A cannot see branch B's shifts | DONE | shifts_test.ts:211-224 (manager A at Hawally gets 403 for Jahra). |
| Non-login staff can be created and scheduled | DONE | staff_test.ts creates staff without email, assigns shifts. |
| Blocked time with type appears in schedule endpoint | DONE | blocked_time_test.ts:126-158 verifies `branch_staff_schedule` returns typed blocks. |
| Overlapping blocks rejected | DONE | blocked_time_test.ts:61-79; constraint `23P01`. |
| Block over existing appointment rejected | DONE | blocked_time_test.ts:93-124. |

---

## Cross-cutting checks

### 1. Layout and isolation (CONVENTIONS §3.3, skill §Layout)
| Check | Status | Evidence |
|---|---|---|
| Function slug = bounded-context name ("staff") | PASS | Function lives under `supabase/functions/staff/`. |
| `_shared/` modules used | PASS | Imports from `../_shared/server.ts`, `auth.ts`, `db.ts`, `errors.ts` by relative path. |
| Import from `packages/validation` via Deno-compatible export | PASS | `deno.json` maps `@repo/validation` to `../../../packages/validation/src/index.ts`. |
| Never imports from `apps/` or other packages | PASS | All imports verified: only `_shared/` and `@repo/validation` / `@repo/db-types`. |
| Dependencies pinned | PASS | `deno.json` pins `npm:@supabase/supabase-js@2.117.2`, `npm:zod@4.6.5`, `npm:@sentry/deno@11.4.0`, `jsr:@std/assert@1.0.19`. |
| `verify_jwt = false` in config.toml | PASS | `[functions.staff] verify_jwt = false` with correct comment (wrapper enforces auth per route). |
| Health endpoint unauthenticated | PASS | `GET /functions/v1/staff/health` returns `{"ok":true,"data":{"status":"ok"}}` without auth (tested). |

### 2. Auth modes (ADR-19, ADR-20, skill §Auth modes)
| Check | Status | Evidence |
|---|---|---|
| User auth mode validates JWT via `auth.getUser` | PASS | `server.ts:125-127` calls `admin.auth.getUser(jwt)`. |
| `resolveCaller` loads live memberships, not JWT claims | PASS | `auth.ts:22-39` queries `memberships` table filtering `is_active = true`. |
| `requireScope` checks branch scope where applicable | PASS | `shifts.ts:45` passes `input.branch_id`; `handlers.ts:79` passes `undefined` for tenant-level check (RPC does fine-grained). |
| Constant-time secret comparison | PASS | `auth.ts:74-79` hashes both sides before comparing via XOR. |
| No service role used for per-user requests | PASS | Admin client (`createAdminClient`) used for privileged writes only; user reads go through `userClient` which forwards the JWT. |

### 3. Contract (ADR-29, CONVENTIONS §4)
| Check | Status | Evidence |
|---|---|---|
| Success envelope `{"ok":true,"data":...}` | PASS | `server.ts:78-79`: success returns `{ok:true, data}`. Verified: `{"ok":true,"data":{"staffId":"..."}}`. |
| Failure envelope `{"ok":false,"error":{"code","message",...}}` | PASS | `errors.ts:23-33` builds the error body. Verified: 400, 401, 403, 404, 409 all produce the correct envelope. |
| Error codes match catalogue | PASS | VALIDATION(400), UNAUTHENTICATED(401), FORBIDDEN(403), NOT_FOUND(404), CONFLICT(409), INTERNAL(500) all used correctly. |
| `fieldErrors` on validation failures | PASS | Body schema failures produce `fieldErrors` map (verified: test with empty name returned fieldErrors for multiple fields). |
| Request IDs propagated | PASS | `logging.ts:9-12` reuses inbound `x-request-id` or mints UUID; `server.ts:177` sets `x-request-id` on response. |
| CORS handled | PASS | `cors.ts` handles preflight, sets headers; `server.ts:178` adds CORS to every response. |
| Unhandled errors → INTERNAL without stack leaks | PASS | `server.ts:90-91`: caught `INTERNAL` with generic message, actual error reported to Sentry. |
| Health endpoint unauthenticated | PASS | Verified: `GET /staff/health` returns 200 without auth. |

### 4. Invariants (ADR-31, ADR-28)
| Check | Status | Evidence |
|---|---|---|
| Money-moving mutations use Idempotency-Key | N/A (Phase 2 has no money mutations) | Staff operations do not move money. Checkout function (Phase 6) will use this. |
| Multi-row writes run in one DB transaction | PASS | `upsert` calls RPC `upsert_staff_member` which is a single transaction. `shifts-materialize` calls `copy_shift_week` RPC (single transaction). |
| No orphan state from partial failure | PARTIAL | `invite-login` has best-effort cleanup: if `link_staff_login` fails, the newly created auth user is deleted (handlers.ts:207-209). But if the process crashes between the auth user creation and the `apply_membership_change` calls, an auth user with no memberships could remain. This is a minor accepted risk of the cross-system pattern. See F-BE-1. |

### 5. Exercise it (API tests)
| Test | Input | Expected | Actual |
|---|---|---|---|
| GET /staff/health | None (no auth) | 200 | 200 `{"ok":true,"data":{"status":"ok"}}` |
| POST /staff/upsert | No auth | 401 UNAUTHENTICATED | 401 `{"code":"UNAUTHENTICATED"}` |
| POST /staff/upsert | Valid owner, full data | 201 | 201 `{"data":{"staffId":"<uuid>"}}` |
| POST /staff/upsert | Owner, existing staff id | 200 | 200 (update) |
| POST /staff/upsert | Wrong tenant | 403 FORBIDDEN | 403 `{"reason":"scope_denied"}` |
| POST /staff/upsert | Empty name | 400 VALIDATION | 400 with fieldErrors |
| POST /staff/nonexistent | Any auth | 404 NOT_FOUND | 404 `{"code":"NOT_FOUND"}` |

### 6. Tests
| Suite | Tests | Gate result | Coverage highlights |
|---|---|---|---|
| `staff` Deno | 20 passed / 0 failed | PASS (gate 6) | staff_test.ts: upsert (no session, validation, owner create, manager scope, reception denial, cross-tenant), invite-login (email validation, invite+grant, manager scope, existing account, conflict, compensation on failure). shifts_test.ts: 401, body validation, overnight copy, CONFLICT/replace, DST, branch scope, forged scope. blocked_time_test.ts: racing blocks, burst, appointment conflict, buffer edge, schedule endpoint. |
| pgTAP staff_matrix | PASS | `008_staff_matrix.test.sql` (Gate 3 PASS: 536 total pgTAP) |
| pgTAP shifts_matrix | PASS | `009_shifts_matrix.test.sql` |
| pgTAP blocked_times_matrix | PASS | `010_blocked_times_matrix.test.sql` |
| pgTAP blocked_times_conflicts | PASS | `011_blocked_times_conflicts.test.sql` |

No tests mock away what they claim to test. All staff, shifts, and blocked-time tests hit the live database through a running Supabase stack.

### 7. Secrets and config
| Check | Status | Evidence |
|---|---|---|
| Local .env.example committed | PASS | `supabase/functions/.env.example` documents PLATFORM_ADMIN_SECRET, INTERNAL_FUNCTION_SECRET, SENTRY_DSN. |
| Actual secrets gitignored | PASS | `.env` files are in `.gitignore`. Git history shows no secret values committed (verified via `git log -p` — only the `.env.example` template was committed). |
| Required secrets documented | PASS | README documents PLATFORM_ADMIN_SECRET format; env.example has all required names. |
| Service role key not in function code | PASS | `db.ts` reads `SUPABASE_SERVICE_ROLE_KEY` from environment, never hardcoded. |
| ANON key placeholder in testing.ts | PASS | `testing.ts` has local-stack placeholders for `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` (documented test helpers for `supabase start` local stack only). |

---

## Findings

### F-BE-1: invite-login cross-system cleanup is best-effort, not transactional

- **Severity**: minor
- **Location**: `/Users/fahadasad/glowdesk/supabase/functions/staff/handlers.ts:172-213`
- **Problem**: The `inviteLogin` function creates an auth user via `admin.auth.admin.inviteUserByEmail()` (Supabase Auth Admin API) and then grants memberships via `apply_membership_change` RPC, then links via `link_staff_login` RPC. If the process crashes between auth user creation and the first RPC call, the auth user exists but has no memberships and no staff link. The code handles the specific case of `link_staff_login` failure (catches and deletes the invited user), but a crash between line 181 (`userId = data.user.id`) and line 186 (`for... apply_membership_change`) would leave an orphan auth user.
- **Evidence**: The code at handlers.ts:207-209 only catches errors thrown during the try block (RPC calls). A process crash does not throw; it terminates. The `invited` flag tracks whether the account was newly created so only new accounts are cleaned up on error, but this only runs if a JS exception propagates.
- **Fix**: This is a known architectural limitation of cross-system (Auth API + DB) operations. The standard mitigation is to log sufficient context so ops can clean up manually. Add a structured `invite_login_orphan` event to the audit log when the function detects it is cleaning up, with the target user ID. Alternatively, accept it as-is — the existing test at `staff_test.ts:260-285` verifies the catch-path works, and production ops have Supabase dashboard access to find and remove orphan users.
- **Plan item**: Phase 2.1 Backlog — `[Edge Function] staff/invite-login`

### F-BE-2: Invite-login does not use idempotency key (potential duplicate on network retry)

- **Severity**: minor
- **Location**: `/Users/fahadasad/glowdesk/supabase/functions/staff/handlers.ts:215-218`
- **Problem**: `handleInviteLogin` does not wrap its handler in `ctx.idempotent()`. If the caller retries the same invite request (e.g., network timeout), two auth users will be created for the same staff member — the first invite succeeds, the second attempt's `already_linked` CONFLICT is caught at the DB level only at the very end (link_staff_login). Meanwhile a second auth user invitation email has already been sent (line 176), confusing the staff member.
- **Evidence**: handlers.ts:215-218 — the handler calls `reply(await inviteLogin(...), 201)` without any idempotency wrapper. Compare to how `upsert` works: it also lacks `ctx.idempotent()` but `upsert` is inherently idempotent (running it twice with the same payload updates in place). `invite-login` is **not** idempotent — running it twice after the first succeeds returns 409, but only after already having sent a second invite email.
- **Fix**: Wrap `handleInviteLogin`'s body in `ctx.idempotent()` using the staff_id as the payload hash. When the key is replayed, the cached 201 response (with the same userId) is returned without sending a second email. The function_name boundary (`staff-invite-login`) prevents collision with other staff actions.
- **Plan item**: Phase 2.1 Backlog — `[Edge Function] staff/invite-login`

---

## Summary table

| ID | Severity | One-line title |
|---|---|---|
| F-BE-1 | minor | invite-login cross-system cleanup is best-effort, not fully transactional |
| F-BE-2 | minor | invite-login does not use idempotency key, can send duplicate invite emails |

**Count by severity**: 0 blocker, 0 major, 2 minor