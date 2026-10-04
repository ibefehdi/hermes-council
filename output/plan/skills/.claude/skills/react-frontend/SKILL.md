---
name: react-frontend
description: Builds feature screens in the back-office React/TypeScript SPA of the multi-tenant spa/salon SaaS. Covers app structure (apps/back-office in the pnpm monorepo), TanStack Query with tenant+branch-scoped key factories, supabase-js vs Edge Function data-access rules, React Hook Form + Zod forms, ApiError envelope handling, realtime cache patching, and Vitest/Playwright testing. Use when adding or modifying a screen, route, query, mutation, or form in apps/back-office or packages/{ui,api,db,validation,core}.
---

# React frontend conventions

All visual decisions (colours, typography, spacing, component look) come from the **Airbnb design skill** (`airbnb-design`), wrapped exclusively by `packages/ui`. This skill defines everything around it: structure, data, forms, testing. Rules follow ADR-36..42.

## Quick start / rules

1. Import boundaries: features import `@repo/{ui,api,db,i18n,validation,core}` and other features' `index.ts` only - never internals. Cycles fail lint.
2. Data access (ADR-28, round 2): reads use the typed supabase client under RLS; report aggregates call `report_*` RPCs; invariant writes (bookings, checkout, refunds, register, blocked time, role/membership changes) go through `@repo/api` typed Edge Function wrappers. Direct single-table writes only for the allowlist (`profiles` self, `client_notes` receptionist+, `clients` contact/profile fields only — never `is_blocked`/`is_deleted`/`merged_into`, which route through the `clients` function, `settings`, `shifts`). `blocked_times` is NOT direct-write (locked staff RPC only). Refunds/voids are owner/manager-only, enforced server-side (ADR-10).
3. Query keys come from key factories and always carry scope (ADR-38, round 2): tenant segment for tenant-scoped entities, `[tenantId, branchId]` for branch-scoped entities, `[tenantId, id]` for client detail — a detail key without the tenant segment is prohibited:

```ts
export const qk = {
  appointments: {
    calendar: (tenantId: string, branchId: string, date: string) =>
      ['appointments', 'calendar', tenantId, branchId, date] as const,
  },
  clients: {
    all: (tenantId: string) => ['clients', tenantId] as const,
    list: (tenantId: string, f: ClientFilters) => ['clients', 'list', tenantId, f] as const,
    detail: (tenantId: string, id: string) => ['clients', 'detail', tenantId, id] as const,
  },
}
```

4. Define queries with `queryOptions` next to the fetcher; components only import options. StaleTime defaults: 30s lists, 60s reference data, 0 for money/report data. Retry: 2 queries, 0 mutations.
5. Mutations invalidate via factory prefixes; never bare `invalidateQueries()`. Optimistic updates only for drags/status toggles: `onMutate` → `cancelQueries` → snapshot → `setQueryData`; `onError` rollback (a server `CONFLICT` rolls the dragged event back with an explanatory toast); `onSettled` targeted revalidation.
6. Forms: React Hook Form + `zodResolver(schema)`; the schema lives in `@repo/validation` and is imported unchanged by the Edge Function. Zod errors map to fields via `fieldErrors`.
7. Errors: one `ApiError` with codes `NETWORK | UNAUTHENTICATED | FORBIDDEN | VALIDATION | NOT_FOUND | CONFLICT | IDEMPOTENCY_MISMATCH | RATE_LIMITED | INTERNAL | UNAVAILABLE` (ADR-29). Toast for transient, redirect for `UNAUTHENTICATED`, inline fields for `VALIDATION`, explanatory toast for `CONFLICT`. `NETWORK` is client-side only.
8. Money moves through state/cache as integer minor units (fils); durations as integer minutes; formatting only at render via `useFormat()` (ADR-17/40).
9. Every async view renders through `<AsyncBoundary>` (skeleton / actionable empty / error) - never conflate "empty" with "failed". Degraded network (round 2, F-fe-3): a timed-out mutation surfaces a "Reconnecting…" banner and its retry reuses the same idempotency key (never a duplicate charge); queries show stale cache with a "trying again in N seconds" indicator; no offline-first writes in MVP - a clear network error message is acceptable.
10. Route guards (`beforeLoad`) are UX only; RLS is the security boundary. Guards know only the membership roles (`tenant_owner`, `branch_manager`, `receptionist`, `staff`) - `platform_admin` is not a frontend role (round 2, F-perm-4); platform impersonation is an audited session mode that renders a persistent "Impersonating [tenant]" banner (ADR-20 rule 9). Branch lives in `?branch=` search param; tenant is session context with a switcher for multi-tenant users; switching tenant clears the query cache (ADR-37).

## Adding a feature screen, step by step

1. `features/<name>/routes/` - TanStack Router route with `validateSearch` (Zod) for filters (include `branch`); `beforeLoad` guard if role-restricted.
2. `features/<name>/queries.ts` - key factory additions + `queryOptions` per read (tenant + branch in every scope-varying key).
3. `features/<name>/mutations.ts` - one `useMutation` per operation via `@repo/api` wrappers or allowlisted direct writes; narrowest useful invalidation.
4. `features/<name>/validation.ts` - re-export operation schemas from `@repo/validation`; form-only refinements here.
5. `features/<name>/components/` - layout + `<AsyncBoundary>`; promote to `@repo/ui` only when a second feature needs it.
6. `features/<name>/index.ts` - public exports; register the route in the tree.
7. Tests: Vitest for mappers/invalidation; Playwright journey only for critical flows; both locales if user-facing.
8. `pnpm verify` green before opening the PR (see `feature-delivery`).

## Examples

List read under RLS:

```ts
// features/clients/queries.ts
export const clientsListOptions = (tenantId: string, filters: ClientFilters) =>
  queryOptions({
    queryKey: qk.clients.list(tenantId, filters),
    queryFn: async () => {
      const { data, error } = await typedClient
        .from('clients')
        .select('id, first_name, last_name, phone, is_blocked, created_at')
        .eq('tenant_id', tenantId)          // RLS also enforces scope; this narrows, not secures
        .eq('is_deleted', false)
        .ilike('search_text', normalizeSearch(filters.q))  // Arabic-normalized column (ADR-40)
        .order('created_at', { ascending: false })
      if (error) throw ApiError.from(error)
      return data
    },
    staleTime: 30_000,
  })
```

Invariant write via wrapper:

```ts
export const useCreateAppointment = (tenantId: string, branchId: string) => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: BookingCreateInput) => bookingApi.create(input), // POST /bookings/create, Zod-validated both ends, Idempotency-Key attached
    onSuccess: (_d, vars) => {
      void qc.invalidateQueries({ queryKey: qk.appointments.calendar(tenantId, branchId, vars.date) })
    },
  })
}
```

Realtime: `useRealtime('appointments', tenantId, branchId)` patches cache keys via `setQueriesData` and invalidates the affected day key - components stay unaware; events never write component state. Channel authorization (no cross-tenant/branch payloads) is CI-tested (ADR-38).

## Component rules

- Components PascalCase one per file; hooks `useX.ts`; feature-internal components stay in the feature; only `@repo/ui` touches design-skill tokens/primitives.
- Accessibility (WCAG 2.1 AA): keyboard-operable everything; documented calendar key bindings; drawers/modals trap and restore focus; icon-only buttons get `aria-label`; errors announced (`aria-describedby` + live region); tables use real table semantics.
- Responsive: front-desk tablets (1024px+) first-class; sidebar collapses to icons; drawers full-width under 768px; touch targets ≥ 44px.
- Calendar: schedule-x (per ADR-41 verdict) wrapped in `features/calendar/components/BookingCalendar`; the library is never imported outside `features/calendar`; mappers convert UTC ↔ branch-local so the library never sees tz math; staff columns virtualize beyond ~8.

## Testing and quality gates

- Vitest + Testing Library; `packages/core` ≥ 95% coverage, feature logic ≥ 70%; no snapshot tests except design-skill wrappers.
- Playwright critical journeys: login, create booking (form + drag), reschedule with conflict rollback, cash checkout, refund/void, register day, client CRUD, branch switch, report reconciliation - each in `en`/LTR and `ar`/RTL.
- `pnpm verify`: strict TS (`noUncheckedIndexedAccess`, no `any`), ESLint (boundaries, jsx-a11y), stylelint logical-properties rule, size-limit (initial ≤ 250kB gzip; calendar chunk ≤ 150kB), unit, build.

## Additional resources

- [reference.md](reference.md): folder layout, ApiError/invoke contract, realtime contract, branch/tenant context, calendar integration notes.
