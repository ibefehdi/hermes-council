-- ADRs implemented: ADR-13 (service_branch_overrides), ADR-15 (glossary names),
--   ADR-16 (bilingual names), ADR-17 (money _minor bigint), ADR-20 rule 5 (composite FKs),
--   ADR-25 (buffers: buffer_before/after_minutes), ADR-44 (uuid PKs), ADR-46 (is_active)

-- ============================================================================
-- SERVICE_CATEGORIES
-- ============================================================================
create table public.service_categories (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  name_en     text not null,
  name_ar     text,
  sort_order  int not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_sc_tenant on public.service_categories(tenant_id);

create trigger set_updated_at_service_categories
  before update on public.service_categories
  for each row execute function public.set_updated_at();

-- ============================================================================
-- SERVICES (tenant-level defaults)
-- ============================================================================
create table public.services (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references public.tenants(id),
  category_id              uuid references public.service_categories(id),
  name_en                  text not null,
  name_ar                  text,
  description_en           text,
  description_ar           text,
  duration_minutes         int not null check (duration_minutes > 0),
  price_minor              bigint not null default 0 check (price_minor >= 0),  -- ADR-17
  buffer_before_minutes    int not null default 0 check (buffer_before_minutes >= 0),  -- ADR-25
  buffer_after_minutes     int not null default 0 check (buffer_after_minutes >= 0),   -- ADR-25
  color                    text,
  is_active                boolean not null default true,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  unique (id, tenant_id)
);

create index idx_services_tenant on public.services(tenant_id);
create index idx_services_category on public.services(category_id);

create trigger set_updated_at_services
  before update on public.services
  for each row execute function public.set_updated_at();

-- ============================================================================
-- SERVICE_BRANCH_OVERRIDES (ADR-13)
-- ============================================================================
create table public.service_branch_overrides (
  id                       uuid primary key default gen_random_uuid(),
  service_id               uuid not null,
  tenant_id                uuid not null,
  branch_id                uuid not null,
  price_minor              bigint check (price_minor >= 0),          -- ADR-17; NULL = use default
  duration_minutes         int check (duration_minutes > 0),        -- NULL = use default
  buffer_before_minutes     int check (buffer_before_minutes >= 0), -- NULL = use default
  buffer_after_minutes     int check (buffer_after_minutes >= 0),  -- NULL = use default
  is_enabled               boolean not null default true,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (service_id, tenant_id) references public.services(id, tenant_id) on delete cascade,
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id) on delete cascade,
  unique (service_id, branch_id)
);

create index idx_sbo_service on public.service_branch_overrides(service_id);
create index idx_sbo_branch on public.service_branch_overrides(branch_id);

create trigger set_updated_at_service_branch_overrides
  before update on public.service_branch_overrides
  for each row execute function public.set_updated_at();

-- ============================================================================
-- RESOLVE_SERVICE: returns effective (price, duration, buffers) for a service at a branch.
-- ADR-20 rule 10: SECURITY DEFINER with search_path.
-- ============================================================================
create or replace function public.resolve_service(
  p_service_id uuid,
  p_branch_id  uuid
)
returns record
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  rec record;
begin
  select
    coalesce(o.price_minor, s.price_minor)        as price_minor,
    coalesce(o.duration_minutes, s.duration_minutes) as duration_minutes,
    coalesce(o.buffer_before_minutes, s.buffer_before_minutes) as buffer_before_minutes,
    coalesce(o.buffer_after_minutes, s.buffer_after_minutes)   as buffer_after_minutes
  into rec
  from public.services s
  left join public.service_branch_overrides o
    on o.service_id = s.id and o.branch_id = p_branch_id
  where s.id = p_service_id;
  return rec;
end;
$$;

-- ============================================================================
-- SERVICE_STAFF (staff eligibility per service per branch, ADR-13)
-- ============================================================================
create table public.service_staff (
  id          uuid primary key default gen_random_uuid(),
  service_id  uuid not null,
  tenant_id   uuid not null,
  staff_id    uuid not null,
  created_at  timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (service_id, tenant_id) references public.services(id, tenant_id) on delete cascade,
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id) on delete cascade,
  unique (service_id, staff_id)
);

create index idx_ss_service on public.service_staff(service_id);
create index idx_ss_staff on public.service_staff(staff_id);