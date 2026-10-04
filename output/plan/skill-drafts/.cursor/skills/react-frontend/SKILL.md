---
name: react-frontend
description: Builds feature screens in the back-office React/TypeScript SPA of the multi-tenant spa/salon SaaS. Covers app structure (apps/back-office under the pnpm monorepo), TanStack Query data access with key factories, supabase-js vs Edge Function routing rules, React Hook Form + Zod forms, component architecture, and Vitest/Playwright testing. Use when adding or modifying a screen, route, query, mutation, or form in apps/back-office or packages/{ui,api,db,validation,core}.
---

# React frontend conventions

All visual decisions (colours, typography, spacing, component look) come from the owner's **Airbnb design skill**. This skill defines everything around it: structure, data, forms, testing.

## Quick start / rules

1. Import boundaries: features import from `@repo/ui`, `@repo/api`, `@repo/db`, `@repo/i18n`, `@repo/validation`, `@repo/core` — never from another feature's internals, only its `index.ts`.
2. Reads use the typed supabase client (`@repo/db`) under RLS; complex read aggregations call a Postgres RPC. Invariant-bearing writes (booking create/reschedule, checkout, shifts) call the typed Edge Function wrappers in `@repo/api`. Single-table writes with RLS-expressible rules may use supabase-js directly.
3. Every query key comes from a key factory and includes the branch scope:

```ts
export const qk = {
  bookings: {
    calendar: (branchId: string, date: string) => ['bookings', 'calendar', branchId, date] as const,
  },
}
```

4. Define queries with `queryOptions` next to the fetch function; components only import options.
5. Mutations must invalidate via factory prefixes in `onSuccess`; never bare `invalidateQueries()`.
6. Optimistic updates only for drags and status toggles: `onMutate` → `cancelQueries` → snapshot → `setQueryData`; `onError` rollback; `onSettled` targeted revalidation.
7. Forms: React Hook Form + `zodResolver(schema)`; the schema lives in `@repo/validation` and is imported unchanged by the Edge Function. Field errors from Zod map to RHF fields.
8. Errors: normalize through `ApiError` (`NETWORK | UNAUTHENTICATED | FORBIDDEN | VALIDATION | CONFLICT | NOT_FOUND | INTERNAL`); toast for transient, redirect for UNAUTHENTICATED, inline fields for VALIDATION.
9. Every async view renders through `<AsyncBoundary>` (skeleton / actionable empty / error). No view distinguishes "empty" from "failed" by accident.
10. Money and durations are integers (fils, minutes) in state and cache; render-only formatting via `useFormat()` from `@repo/i18n`.

## Adding a new feature screen, step by step

1. `features/<name>/routes/<name>.tsx` — define the route with TanStack Router, typed search params (`validateSearch` with Zod) for filters; add `beforeLoad` role guard if restricted.
2. `features/<name>/queries.ts` — key factory additions + `queryOptions` per read (include `branchId` in every key; read it from the route search param).
3. `features/<name>/mutations.ts` — one `useMutation` per operation, invalidating the narrowest useful key prefix.
4. `features/<name>/validation.ts` — re-export the operation schemas from `@repo/validation`; add form-only refinements here.
5. `features/<name>/components/` — screen layout + `<AsyncBoundary>`; shared-looking primitives go to `@repo/ui` only when a second feature needs them.
6. `features/<name>/index.ts` — public exports; register the route in the app route tree.
7. Tests: Vitest for mappers/mutation invalidation; add a Playwright journey only for critical flows.
8. Run `pnpm verify` (typecheck + lint + unit + build) before opening a PR.

## Examples

Minimal list screen (clients):

```tsx
// features/clients/queries.ts
import { queryOptions } from '@tanstack/react-query'
import { typedClient } from '@repo/db'

export const clientsListOptions = (branchId: string, filters: ClientFilters) =>
  queryOptions({
    queryKey: qk.clients.list(branchId, filters),
    queryFn: async () => {
      const { data, error } = await typedClient
        .from('clients')
        .select('id, full_name, phone, created_at')
        .eq('branch_id', branchId)   // RLS also enforces this; never rely on it client-side only
        .ilike('full_name', `%${filters.q}%`)
        .order('created_at')
      if (error) throw ApiError.from(error)
      return data
    },
    staleTime: 30_000,
  })

// features/clients/queries.ts (keys)
export const qk = {
  clients: {
    all: () => ['clients'] as const,
    list: (branchId: string, f: ClientFilters) => ['clients', 'list', branchId, f] as const,
    detail: (id: string) => ['clients', 'detail', id] as const,
  },
}
```

Mutation with scoped invalidation:

```ts
export const useUpdateClient = (branchId: string) => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: ClientUpdateInput) => clientApi.update(input), // Edge Function, Zod-validated
    onSuccess: (_d, vars) => {
      void qc.invalidateQueries({ queryKey: qk.clients.list(branchId, currentFilters()) })
      void qc.invalidateQueries({ queryKey: qk.clients.detail(vars.id) })
    },
  })
}
```

Realtime: use `useRealtime('bookings', branchId)` from `@repo/api`; it patches cache keys via `setQueriesData` — components stay unaware.

## Component rules

- Components PascalCase, one per file; hooks `useX.ts`; feature-internal components stay in the feature; only shared ones promote to `@repo/ui`. `@repo/ui` is the only layer allowed to touch design-skill tokens/primitives.
- Accessibility: keyboard-operable everything; drawers/modals trap and restore focus; icon-only buttons need `aria-label`; errors announced via `aria-describedby` + live region; tables use real table semantics.
- Responsive: usable at 1024px (front-desk tablets); sidebar collapses; drawers full-width under 768px; touch targets ≥ 44px.

## Testing and quality gates

- Vitest + Testing Library; `packages/core` ≥ 95% coverage, feature logic ≥ 70%; no snapshots.
- Playwright for critical journeys (login, create/ drag-reschedule booking, checkout, client CRUD, branch switch); RTL smoke suite runs the same flows in `ar`/RTL.
- `pnpm verify` must pass: strict TS (`noUncheckedIndexedAccess`), ESLint (boundaries, jsx-a11y, no `any`), stylelint logical-properties rule, size-limit budgets (initial ≤ 250 kB gzip; calendar chunk ≤ 150 kB).

## Additional resources

- [reference.md](reference.md): full folder layout, `ApiError` contract, realtime hook contract, calendar integration notes.
