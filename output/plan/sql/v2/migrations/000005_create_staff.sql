-- ADRs implemented: ADR-12 (one staff row per person per tenant, nullable user_id),
--   ADR-15 (glossary names: staff_members, staff_branch_assignments),
--   ADR-16 (bilingual names), ADR-20 rule 5 (composite FKs),
--   ADR-20 rule 6 (all-branches for blocked_times), ADR-24 (exclusion constraints),
--   ADR-26 (shifts, blocked_times), ADR-44 (uuid PKs), ADR-46 (is_active)

-- ============================================================================
-- STAFF_MEMBERS
-- ============================================================================
create table public.staff_members (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  user_id         uuid references auth.users(id),               -- nullable: non-login staff (ADR-12)
  full_name_en    text not null,
  full_name_ar    text,
  phone           text,
  email           text,
  is_active       boolean not null default true,                -- ADR-46
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (id, tenant_id)
);

-- F-DB-9: one row per person per tenant
create unique index idx_staff_members_tenant_user
  on public.staff_members(tenant_id, user_id)
  where user_id is not null;

create index idx_staff_members_tenant on public.staff_members(tenant_id);
create index idx_staff_members_active on public.staff_members(tenant_id, is_active);

create trigger set_updated_at_staff_members
  before update on public.staff_members
  for each row execute function public.set_updated_at();

-- ============================================================================
-- STAFF_BRANCH_ASSIGNMENTS (ADR-12)
-- ============================================================================
create table public.staff_branch_assignments (
  id              uuid primary key default gen_random_uuid(),
  staff_id        uuid not null,
  tenant_id       uuid not null,
  branch_id       uuid not null,
  is_default      boolean not null default false,
  is_bookable     boolean not null default true,
  created_at      timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id) on delete cascade,
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id) on delete cascade,
  unique (staff_id, branch_id)
);

create index idx_sba_staff on public.staff_branch_assignments(staff_id);
create index idx_sba_branch on public.staff_branch_assignments(branch_id);

-- ============================================================================
-- SHIFTS (ADR-26)
-- ============================================================================
create table public.shifts (
  id          uuid primary key default gen_random_uuid(),
  staff_id    uuid not null,
  branch_id   uuid not null,
  tenant_id   uuid not null,
  starts_at   timestamptz not null,
  ends_at     timestamptz not null check (ends_at > starts_at),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id) on delete cascade,
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id) on delete cascade
);

create index idx_shifts_staff on public.shifts(staff_id);
create index idx_shifts_branch_range on public.shifts(branch_id, starts_at, ends_at);
create index idx_shifts_staff_range on public.shifts(staff_id, starts_at, ends_at);

create trigger set_updated_at_shifts
  before update on public.shifts
  for each row execute function public.set_updated_at();

-- ============================================================================
-- BLOCKED_TIME_TYPES (ADR-26, ADR-16 bilingual names)
-- ============================================================================
create table public.blocked_time_types (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  name_en     text not null,
  name_ar     text,
  color       text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_btt_tenant on public.blocked_time_types(tenant_id);

create trigger set_updated_at_blocked_time_types
  before update on public.blocked_time_types
  for each row execute function public.set_updated_at();

-- ============================================================================
-- BLOCKED_TIMES (ADR-26, ADR-24 exclusion constraint)
--   F-DB-6: NOT a direct-write table -- all writes go through locked staff/blocked-time RPC
-- ============================================================================
create table public.blocked_times (
  id                    uuid primary key default gen_random_uuid(),
  staff_id              uuid not null,
  tenant_id             uuid not null,
  branch_id             uuid,                                        -- ADR-20 rule 6
  all_branches          boolean not null default false,              -- ADR-20 rule 6
  blocked_time_type_id  uuid references public.blocked_time_types(id),
  starts_at             timestamptz not null,
  ends_at               timestamptz not null check (ends_at > starts_at),
  blocked_range         tstzrange generated always as (
                          tstzrange(starts_at, ends_at, '[)')
                        ) stored,
  notes                 text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  -- ADR-20 rule 6: check constraint
  constraint chk_blocked_times_all check (all_branches = (branch_id is null)),
  -- ADR-20 rule 5: composite FKs
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id) on delete cascade,
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id) on delete cascade
);

-- ADR-24: exclusion constraint prevents overlapping blocked times for same staff
-- (block-vs-block only; cross-entity check is in the RPC with advisory lock)
create extension if not exists btree_gist with schema extensions;
alter table public.blocked_times
  add constraint excl_blocked_times_staff
  exclude using gist (staff_id with =, blocked_range with &&);

create index idx_bt_staff on public.blocked_times(staff_id);
create index idx_bt_range on public.blocked_times(staff_id, starts_at, ends_at);

create trigger set_updated_at_blocked_times
  before update on public.blocked_times
  for each row execute function public.set_updated_at();