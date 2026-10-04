# react-frontend reference

## Repository layout

```
apps/back-office/          Vite SPA (staff/manager/owner)
apps/booking/              client-facing booking app (Phase 2)
packages/ui/               wraps Airbnb design-skill primitives/tokens — only layer allowed to import them
packages/db/               database.types.ts (supabase gen types) + createTypedClient
packages/api/              typed Edge Function invoke wrappers + ApiError + useRealtime
packages/validation/       Zod schemas shared with Edge Functions (Deno-compatible)
packages/i18n/             Lingui catalogs (en/ar) + useFormat
packages/core/             pure domain logic: time math, price math, booking rules (no React)
supabase/functions/<fn>/   one folder per Edge Function
```

## Feature folder contract

`features/<name>/{routes,components,queries.ts,mutations.ts,mappers.ts,validation.ts,index.ts}`. Other features import only via `index.ts`. Feature-import cycles fail `eslint-plugin-boundaries`.

## ApiError contract

```ts
type ApiErrorCode = 'NETWORK' | 'UNAUTHENTICATED' | 'FORBIDDEN' | 'VALIDATION' | 'CONFLICT' | 'NOT_FOUND' | 'INTERNAL'
class ApiError extends Error {
  code: ApiErrorCode
  fieldErrors?: Record<string, string>  // VALIDATION only
  static from(error: unknown): ApiError
}
```

`invoke()` in `@repo/api`: attaches the Supabase JWT, Zod-parses the response envelope `{ ok, data }` or `{ ok: false, error: { code, message, fieldErrors } }`, retries only 5xx/network (max 2), never retries mutations on 4xx.

## useRealtime contract

`useRealtime(table: 'bookings' | 'clients' | 'staff', branchId: string)` — subscribes to `postgres_changes` scoped to the branch; on INSERT/UPDATE/DELETE patches matching cache keys via `queryClient.setQueriesData` and invalidates the affected calendar-day key. Realtime events never write component state directly.

## Branch context

Branch scope lives in the URL search param `?branch=` (TanStack Router `validateSearch`), switcher in the top bar; `SessionContext` (loaded once after auth) carries `tenantId`, `role`, and accessible `branchIds`. Route guards in `beforeLoad` are UX only — RLS is the security boundary. Every query key contains the branch id.

## Calendar integration notes

schedule-x is wrapped by `features/calendar/components/BookingCalendar`; the library is never imported outside `features/calendar`. `mappers.ts` converts `Booking` (UTC timestamptz) ↔ schedule-x event (branch-local datetimes, `resourceId: staffId`). Drag-to-reschedule calls `useRescheduleBooking` with the drag as the optimistic update; a server `CONFLICT` rolls the event back to its original slot with an explanatory toast. Staff columns virtualize beyond ~8 per branch. Views: day (resource scheduler: one column per working staff member), week, "my day" for single-staff logins.
