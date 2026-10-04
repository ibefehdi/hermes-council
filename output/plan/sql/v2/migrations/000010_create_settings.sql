-- ADRs implemented: ADR-15 (glossary names), ADR-20 rule 5 (composite FKs),
--   ADR-20 rule 6 (all-branches = branch_id NULL + all_branches + partial unique index),
--   ADR-22 (audit_log: append-only, trigger-driven, SECURITY DEFINER),
--   ADR-44 (uuid PKs)

-- ============================================================================
-- SETTINGS (ADR-20 rule 6: branch-scoped + tenant-wide via all_branches)
-- ============================================================================
create table public.settings (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid not null references public.tenants(id),
  branch_id     uuid,                                                  -- NULL = tenant-wide
  all_branches  boolean not null default false,                        -- ADR-20 rule 6
  key           text not null check (key ~ '^[a-z0-9._-]+$'),
  value         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  -- ADR-20 rule 6: check constraint
  constraint chk_settings_all check (all_branches = (branch_id is null)),
  -- ADR-20 rule 5: composite FK
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id),
  unique (tenant_id, branch_id, key)
);

-- ADR-20 rule 6: partial unique index for tenant-wide settings (one row per key)
create unique index idx_settings_tenant_wide_key
  on public.settings(tenant_id, key)
  where branch_id is null;

create index idx_settings_tenant on public.settings(tenant_id);
create index idx_settings_branch on public.settings(branch_id);

create trigger set_updated_at_settings
  before update on public.settings
  for each row execute function public.set_updated_at();

-- ============================================================================
-- AUDIT_LOG (ADR-22: append-only, written by trigger/Edge Function)
-- ============================================================================
create table public.audit_log (
  id              bigint generated always as identity primary key,
  tenant_id       uuid not null references public.tenants(id),
  branch_id       uuid,
  actor_id        uuid references auth.users(id),
  entity_type     text not null,          -- table name or 'function'
  entity_id       uuid,
  action          text not null,          -- INSERT, UPDATE, DELETE, LOGIN, EXPORT, IMPERSONATE, etc.
  changed_fields  jsonb,                  -- { "field": {"old": ..., "new": ...}, ... }
  created_at      timestamptz not null default now(),
  -- ADR-20 rule 5: composite FK
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)
);

-- Partition-friendly (not partitioned in MVP, but bigint PK supports it)
create index idx_audit_tenant on public.audit_log(tenant_id, created_at);
create index idx_audit_entity on public.audit_log(tenant_id, entity_type, entity_id);
create index idx_audit_actor on public.audit_log(actor_id);

-- ============================================================================
-- AUDIT TRIGGER FUNCTION (ADR-22: SECURITY DEFINER + search_path)
--   Attached to key tables in migration 000012 (RLS).
-- ============================================================================
create or replace function public.audit_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id  uuid;
  v_branch_id  uuid;
  v_entity_id  uuid;
  v_changed    jsonb := '{}'::jsonb;
  v_old_json   jsonb;
  v_new_json   jsonb;
  v_field      text;
begin
  -- Determine tenant_id from the row
  v_tenant_id := coalesce(new.tenant_id, old.tenant_id);

  -- Determine branch_id if the row has one
  begin
    v_branch_id := coalesce(new.branch_id, old.branch_id);
  exception when undefined_column then
    v_branch_id := null;
  end;

  -- Determine entity_id
  v_entity_id := coalesce(new.id, old.id);

  -- Compute changed fields
  if tg_op = 'INSERT' then
    v_new_json := to_jsonb(new);
    for v_field in select jsonb_object_keys(v_new_json) loop
      if v_field not in ('created_at', 'updated_at') then
        v_changed := v_changed || jsonb_build_object(v_field, jsonb_build_object('new', v_new_json -> v_field));
      end if;
    end loop;
  elsif tg_op = 'UPDATE' then
    v_old_json := to_jsonb(old);
    v_new_json := to_jsonb(new);
    for v_field in select jsonb_object_keys(v_new_json) loop
      if v_old_json -> v_field is distinct from v_new_json -> v_field
         and v_field not in ('created_at', 'updated_at') then
        v_changed := v_changed || jsonb_build_object(v_field, jsonb_build_object(
          'old', v_old_json -> v_field,
          'new', v_new_json -> v_field
        ));
      end if;
    end loop;
  elsif tg_op = 'DELETE' then
    v_old_json := to_jsonb(old);
    for v_field in select jsonb_object_keys(v_old_json) loop
      if v_field not in ('created_at', 'updated_at') then
        v_changed := v_changed || jsonb_build_object(v_field, jsonb_build_object('old', v_old_json -> v_field));
      end if;
    end loop;
  end if;

  insert into public.audit_log (tenant_id, branch_id, actor_id, entity_type, entity_id, action, changed_fields)
  values (v_tenant_id, v_branch_id, auth.uid(), tg_table_name, v_entity_id, tg_op, v_changed);

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;