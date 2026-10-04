-- ADRs implemented: ADR-9 (merged_into, duplicate warning), ADR-11 (tenant-scoped,
--   financial aggregates branch-scoped via RPC, not raw columns),
--   ADR-15 (glossary names), ADR-16 (bilingual name columns),
--   ADR-20 rule 5 (composite FKs), ADR-44 (uuid PKs), ADR-46 (is_deleted, merged_into),
--   ADR-52 (client source)

-- ============================================================================
-- CLIENTS (tenant-scoped -- ADR-11)
-- ============================================================================
create table public.clients (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  first_name      text not null,
  last_name       text,
  first_name_alt  text,                              -- name in other script (ADR-16)
  last_name_alt   text,                              -- name in other script (ADR-16)
  phone           text,
  email           text,
  date_of_birth   date,
  gender          text,
  allergies       text,                              -- safety field (ADR-11): tenant-visible
  notes           text,
  tags            text[],
  -- Protected columns (F-4): only the clients Edge Function may set
  is_blocked      boolean not null default false,    -- F-4: carved out from direct writes
  is_deleted      boolean not null default false,    -- ADR-46: soft delete
  merged_into     uuid,                              -- ADR-9: tombstone pointer
  -- ADR-52: attribution source
  source          text,                              -- walk-in, imported, etc.
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id),
  updated_by      uuid references auth.users(id),
  unique (id, tenant_id)
);

create index idx_clients_tenant on public.clients(tenant_id);
create index idx_clients_phone on public.clients(tenant_id, phone);
create index idx_clients_email on public.clients(tenant_id, email);
create index idx_clients_deleted on public.clients(tenant_id, is_deleted);
-- Duplicate check (ADR-9): name + phone + email matching
create index idx_clients_search on public.clients(tenant_id, first_name, phone, email)
  where is_deleted = false;

create trigger set_updated_at_clients
  before update on public.clients
  for each row execute function public.set_updated_at();

-- ============================================================================
-- CLIENT_NOTES (ADR-11: receptionist and above write; staff read-only)
-- ============================================================================
create table public.client_notes (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  client_id   uuid not null,
  content     text not null,
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id),
  -- ADR-20 rule 5: composite FK
  foreign key (client_id, tenant_id) references public.clients(id, tenant_id) on delete cascade
);

create index idx_cn_client on public.client_notes(client_id);