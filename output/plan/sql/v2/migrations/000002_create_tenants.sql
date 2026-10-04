-- ADRs implemented: ADR-15 (glossary names), ADR-16 (bilingual name columns),
--   ADR-17 (money _minor bigint), ADR-18 (plan_features, ADR-19 (JWT identity only),
--   ADR-20 (RLS skeleton), ADR-44 (uuid PKs), ADR-45 (timestamptz, IANA zone),
--   ADR-46 (soft delete)

-- ============================================================================
-- TENANTS
-- ============================================================================
create table public.tenants (
  id                uuid primary key default gen_random_uuid(),
  display_name_en   text not null,
  display_name_ar   text,
  slug              text not null unique,
  plan              text not null default 'core',
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create unique index idx_tenants_slug on public.tenants(slug);

-- ============================================================================
-- CURRENCIES (ADR-17: ISO-4217 exponent per currency)
-- ============================================================================
create table public.currencies (
  code            text primary key,          -- ISO-4217 (e.g. 'KWD')
  name_en         text not null,
  name_ar         text,
  minor_exponent  smallint not null default 3,       -- digits after decimal
  symbol          text,
  is_active       boolean not null default true
);

insert into public.currencies (code, name_en, name_ar, minor_exponent, symbol) values
  ('KWD', 'Kuwaiti Dinar', 'دينار كويتي', 3, 'د.ك');

-- ============================================================================
-- PLAN_FEATURES (ADR-18: entitlement model)
-- ============================================================================
create table public.plan_features (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  feature     text not null check (feature ~ '^[a-z0-9._-]+$'),
  enabled     boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (tenant_id, feature)
);

-- ============================================================================
-- PROFILES (extends auth.users)
-- ============================================================================
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  avatar_url  text,
  phone       text,
  locale      text default 'en',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Auto-create profile on signup (ADR-20 rule 10: SECURITY DEFINER with search_path)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email)
  );
  return new;
end;
$$;

-- check-sql: skip-begin
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
-- check-sql: skip-end

-- ============================================================================
-- UPDATED_AT TRIGGER (used by all tables) - ADR-20 rule 10
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at_tenants
  before update on public.tenants
  for each row execute function public.set_updated_at();

create trigger set_updated_at_profiles
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Authorization helpers are defined in 000004_create_memberships.sql
-- after the memberships table is created.