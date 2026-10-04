-- ADRs implemented: ADR-15 (glossary names), ADR-20 rule 5 (composite FKs),
--   ADR-20 rule 6 (all-branches = branch_id NULL + all_branches flag),
--   ADR-26 (opening hours, closed periods), ADR-44 (uuid PKs),
--   ADR-45 (timestamptz + IANA zone), ADR-46 (soft delete: is_active),
--   ADR-52 (calendar prefs on branches)

-- ============================================================================
-- BRANCHES
-- ============================================================================
create table public.branches (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references public.tenants(id),
  name_en             text not null,
  name_ar             text,
  timezone            text not null default 'Asia/Kuwait',     -- IANA zone (ADR-45)
  address             text,
  phone               text,
  invoice_prefix      text not null default 'INV',            -- ADR-14 per-branch prefix
  is_active           boolean not null default true,          -- ADR-46
  -- ADR-52: calendar preferences
  first_day_of_week   smallint not null default 6,            -- 0=Sun..6=Sat; Gulf default Sat
  time_format         smallint not null default 24 check (time_format in (12, 24)),
  slot_step_minutes   smallint not null default 15 check (slot_step_minutes in (5, 10, 15, 30)),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  -- ADR-20 rule 5: composite FK support
  unique (id, tenant_id)
);

create index idx_branches_tenant on public.branches(tenant_id);
create index idx_branches_active on public.branches(tenant_id, is_active);

create trigger set_updated_at_branches
  before update on public.branches
  for each row execute function public.set_updated_at();

-- ============================================================================
-- BRANCH_OPENING_HOURS (ADR-26)
-- ============================================================================
create table public.branch_opening_hours (
  id          uuid primary key default gen_random_uuid(),
  branch_id   uuid not null,
  tenant_id   uuid not null,
  day_of_week smallint not null check (day_of_week between 0 and 6),  -- 0=Sun..6=Sat
  seq         smallint not null default 1,                -- discriminator for split intervals
  opens_at    time not null,
  closes_at   time not null,                              -- closes_at < opens_at means overnight; opens_at = closes_at is only allowed on is_closed rows (final round, F-final-db-5)
  is_closed   boolean not null default false,
  -- Zero-length intervals are meaningless: a closed day is is_closed = true;
  -- a 24-hour day is expressed as 00:00 - 23:59. Equality is rejected otherwise.
  constraint boh_nonzero_length check (is_closed or opens_at <> closes_at),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- ADR-20 rule 5: composite FK
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id) on delete cascade,
  unique (branch_id, day_of_week, seq)
);

create index idx_boh_branch on public.branch_opening_hours(branch_id);

create trigger set_updated_at_branch_opening_hours
  before update on public.branch_opening_hours
  for each row execute function public.set_updated_at();

-- ============================================================================
-- CLOSED_PERIODS (ADR-26)
-- ============================================================================
create table public.closed_periods (
  id          uuid primary key default gen_random_uuid(),
  branch_id   uuid not null,
  tenant_id   uuid not null,
  starts_on   date not null,
  ends_on     date not null check (ends_on >= starts_on),
  name_en     text,
  name_ar     text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- ADR-20 rule 5: composite FK
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id) on delete cascade
);

create index idx_cp_branch on public.closed_periods(branch_id);
create index idx_cp_range on public.closed_periods(branch_id, starts_on, ends_on);

create trigger set_updated_at_closed_periods
  before update on public.closed_periods
  for each row execute function public.set_updated_at();