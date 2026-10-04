-- ADRs implemented: ADR-19 (live membership lookup), ADR-20 rule 6 (all-branches
--   = branch_id NULL + all_branches flag), ADR-20 rule 9 (role enum: no platform_admin),
--   ADR-20 rule 5 (composite FKs), ADR-37 (multi-tenant memberships),
--   ADR-44 (uuid PKs), ADR-46 (is_active)

-- ============================================================================
-- MEMBERSHIPS
-- ============================================================================
-- ADR-20 rule 9: role enum is exactly tenant_owner|branch_manager|receptionist|staff.
-- platform_admin is NOT a membership role (NFR-1: audited impersonation only).
create table public.memberships (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid not null references public.tenants(id),
  user_id       uuid not null references auth.users(id) on delete cascade,
  role          text not null check (role in ('tenant_owner', 'branch_manager', 'receptionist', 'staff')),
  branch_id     uuid,                                              -- NULL = all branches
  all_branches  boolean not null default false,                    -- ADR-20 rule 6
  is_active     boolean not null default true,                     -- ADR-46
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  created_by    uuid references auth.users(id),
  -- ADR-20 rule 6: all_branches <=> branch_id IS NULL
  constraint chk_memberships_all_branches check (all_branches = (branch_id is null)),
  -- ADR-20 rule 5: composite FK to branches
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id),
  -- ADR-12 / ADR-19: one active membership per (tenant, user) is NOT unique --
  -- a user may hold memberships at different branches. The membership
  -- uniqueness is per (tenant_id, user_id, branch_id, role).
  unique (tenant_id, user_id, branch_id, role)
);

-- Hot lookup paths (ADR-19)
create index idx_memberships_user_tenant on public.memberships(user_id, tenant_id) where is_active = true;
create index idx_memberships_tenant on public.memberships(tenant_id);
create index idx_memberships_role on public.memberships(tenant_id, role) where is_active = true;

-- F-DB-4: prevent duplicate (user, tenant, role) for branch_id IS NULL + all_branches
create unique index idx_memberships_tenant_wide
  on public.memberships(tenant_id, user_id, role)
  where branch_id is null and is_active = true;

create trigger set_updated_at_memberships
  before update on public.memberships
  for each row execute function public.set_updated_at();

-- ============================================================================
-- AUTHORIZATION HELPERS (ADR-19, ADR-20 rules 4/6)
-- Defined here because they depend on the memberships table.
-- ============================================================================

-- Get all tenant IDs the current user is a member of
create or replace function public.current_tenant_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select tenant_id from public.memberships
  where user_id = auth.uid() and is_active = true;
$$;

-- Get current branch scope for a tenant: branch_ids the user has access to
create or replace function public.current_branch_scope(p_tenant_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select branch_id from public.memberships
  where user_id = auth.uid()
    and tenant_id = p_tenant_id
    and is_active = true
    and branch_id is not null;
$$;

-- Check if user has any of the given roles in the tenant at a specific branch.
-- F-DB-2: p_branch_id has NO default - every call site passes the row's branch explicitly.
create or replace function public.has_tenant_role(
  p_tenant_id uuid,
  p_roles text[],
  p_branch_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = auth.uid()
      and m.tenant_id = p_tenant_id
      and m.is_active = true
      and m.role = any (p_roles)
      and (
        m.all_branches = true
        or m.branch_id = p_branch_id
      )
  );
$$;

-- Tenant-wide role check (no branch scoping) - explicit separate helper (F-DB-2)
create or replace function public.has_tenant_role_any_branch(
  p_tenant_id uuid,
  p_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = auth.uid()
      and m.tenant_id = p_tenant_id
      and m.is_active = true
      and m.role = any (p_roles)
  );
$$;

-- Grants for helper functions
grant execute on function public.current_tenant_ids() to authenticated;
grant execute on function public.current_branch_scope(uuid) to authenticated;
grant execute on function public.has_tenant_role(uuid, text[], uuid) to authenticated;
grant execute on function public.has_tenant_role_any_branch(uuid, text[]) to authenticated;