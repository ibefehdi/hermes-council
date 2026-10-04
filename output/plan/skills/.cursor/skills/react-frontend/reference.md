# react-frontend reference

## Repository layout

```
apps/back-office/          Vite SPA (staff/manager/owner) - MVP
apps/booking/              client-facing booking app (Phase 2, scaffold only)
packages/ui/               wraps Airbnb design-skill primitives/tokens - only layer allowed to import them
packages/db/               database.types.ts (supabase gen types, committed, CI drift-checked) + createTypedClient
packages/api/              typed Edge Function invoke wrappers + ApiError + useRealtime
packages/validation/       Zod schemas shared with Edge Functions (pure JS, Deno-importable) + error code catalogue
packages/i18n/             Lingui catalogs (en/ar) + useFormat + normalizeSearch
packages/core/             pure domain logic: slot engine, time math, money math (no React)
supabase/functions/<fn>/   one folder per bounded-context Edge Function
```

## Feature folder contract

`features/<name>/{routes,components,queries.ts,mutations.ts,mappers.ts,validation.ts,index.ts}`. Other features import only via `index.ts`. Feature-import cycles fail `eslint-plugin-boundaries`.

## ApiError / invoke contract (ADR-29/30)

```ts
type ApiErrorCode =
  | 'NETWORK' | 'UNAUTHENTICATED' | 'FORBIDDEN' | 'VALIDATION' | 'NOT_FOUND'
  | 'CONFLICT' | 'IDEMPOTENCY_MISMATCH' | 'RATE_LIMITED' | 'INTERNAL' | 'UNAVAILABLE'

class ApiError extends Error {
  code: ApiErrorCode
  fieldErrors?: Record<string, string>   // VALIDATION only
  details?: Record<string, unknown>      // e.g. conflicting_appointment_id on CONFLICT
  static from(error: unknown): ApiError
}
```

`invoke()` in `@repo/api`: attaches the Supabase JWT and active tenant/branch context; parses the envelope `{ ok: true, data }` / `{ ok: false, error: { code, message, fieldErrors?, details? } }`; attaches `Idempotency-Key` (client-generated UUID, stable per mutation attempt) for money mutations; retries only 5xx/network on queries (max 2), never retries mutations on 4xx. Function slugs/paths appear only inside `packages/api` wrappers (`bookingApi.create` → `POST /functions/v1/bookings/create`).

## useRealtime contract

`useRealtime(table: 'appointments' | 'clients' | 'sales', tenantId: string, branchId: string)` - subscribes to `postgres_changes` scoped to the branch; on INSERT/UPDATE/DELETE patches matching cache keys via `queryClient.setQueriesData` and invalidates the affected calendar-day key. Events never write component state. Channel authorization is CI-tested: a branch-B session must receive zero branch-A payloads (ADR-38); polling (≤5s staleness, NFR-5) is the documented fallback.

## Tenant and branch context (ADR-37)

Branch scope lives in the URL search param `?branch=<uuid>|all` (TanStack Router `validateSearch`), driven by the top-bar switcher; default branch persisted in localStorage. `SessionContext` (loaded once after auth from `memberships`) carries the user's tenants, roles, and branch scopes; multi-tenant users get a tenant switcher; switching tenant clears the query cache. The server verifies membership live on every privileged call - client context is routing/display, never authorization. Receptionists with a single branch get a locked switcher. Route guards in `beforeLoad` are UX only; RLS is the boundary.

## Calendar integration notes

schedule-x (premium resource views if the ADR-41 spike said go; otherwise core + custom resource columns) is wrapped by `features/calendar/components/BookingCalendar`; never imported outside `features/calendar`. `mappers.ts` converts `Appointment` (UTC timestamptz envelope + item spans) ↔ calendar events (branch-local datetimes, `resourceId: staffId`); the library never sees timezone math. Drag-to-reschedule: the drag is the optimistic update; `bookingApi.reschedule` confirms or the event rolls back on `CONFLICT` with `details.conflicting_appointment_id` shown in the toast. Views: day (one column per working staff member of the selected branch, honouring shifts), week, and "my day" for single-staff logins (all assigned branches merged, labelled). Staff columns virtualize beyond ~8. Performance budgets: drag frame ≤ 16ms; busy-branch day view (30 staff / 200 appointments) ≤ 2s p95; calendar chunk ≤ 150kB gzip.

## Money and time in components

- Money values are integers in minor units everywhere in state/cache/props; render via `useFormat().money(fils, currency)` only (KWD shows 3 decimals; exponent comes from tenant currency data).
- Timestamps on the wire are UTC; render via `useFormat().dateTime(iso)` in the selected branch's IANA zone; date pickers operate in branch-local time; conversions live in `packages/core` (pure, tested, including overnight and DST cases).
