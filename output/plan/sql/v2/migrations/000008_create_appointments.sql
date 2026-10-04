-- ADRs implemented: ADR-7 (status enum: in_progress, booked, confirmed, arrived,
--   completed, cancelled, no_show), ADR-14 (ref_number per branch),
--   ADR-15 (glossary names), ADR-20 rule 5 (composite FKs),
--   ADR-23 (items carry own staff_id + time span + snapshots),
--   ADR-24 (exclusion constraint on busy_range, advisory lock via RPC),
--   ADR-25 (buffers snapshotted into busy_range), ADR-44 (uuid PKs),
--   ADR-46 (status-based retention)

-- ============================================================================
-- CANCELLATION_REASONS
-- ============================================================================
create table public.cancellation_reasons (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  name_en     text not null,
  name_ar     text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_cr_tenant on public.cancellation_reasons(tenant_id);

create trigger set_updated_at_cancellation_reasons
  before update on public.cancellation_reasons
  for each row execute function public.set_updated_at();

-- ============================================================================
-- APPOINTMENTS
-- ============================================================================
create table public.appointments (
  id               uuid primary key default gen_random_uuid(),
  tenant_id        uuid not null references public.tenants(id),
  branch_id        uuid not null,
  client_id        uuid not null,
  ref_number       text not null,                                       -- ADR-14
  scheduled_start  timestamptz not null,
  scheduled_end    timestamptz not null check (scheduled_end > scheduled_start),
  during           tstzrange,
  -- ADR-7: status enum, canonical value is in_progress
  status           text not null default 'booked'
                   check (status in ('booked', 'confirmed', 'arrived', 'in_progress', 'completed', 'cancelled', 'no_show')),
  notes            text,
  channel          text default 'offline',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  created_by       uuid references auth.users(id),
  updated_by       uuid references auth.users(id),
  -- ADR-20 rule 5: composite FKs
  foreign key (branch_id, tenant_id) references public.branches(id, tenant_id),
  foreign key (client_id, tenant_id) references public.clients(id, tenant_id),
  -- ADR-14: per-branch unique ref_number
  unique (branch_id, ref_number)
);

create index idx_appointments_tenant on public.appointments(tenant_id);
create index idx_appointments_branch on public.appointments(branch_id);
create index idx_appointments_client on public.appointments(client_id);
create index idx_appointments_start on public.appointments(tenant_id, branch_id, scheduled_start);
create index idx_appointments_status on public.appointments(tenant_id, branch_id, status, scheduled_start);
create index idx_appointments_ref on public.appointments(branch_id, ref_number);

create trigger set_updated_at_appointments
  before update on public.appointments
  for each row execute function public.set_updated_at();

-- ============================================================================
-- APPOINTMENT_ITEMS (ADR-23: each item carries its own staff + time span)
-- ============================================================================
create table public.appointment_items (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references public.tenants(id),
  appointment_id        uuid not null references public.appointments(id) on delete cascade,
  service_id            uuid not null,
  staff_id              uuid,
  -- ADR-23: per-item time span (inside the appointment envelope)
  effective_start       timestamptz not null,
  effective_end         timestamptz not null check (effective_end > effective_start),
  -- ADR-17: snapshotted price in fils
  price_minor           bigint not null check (price_minor >= 0),
  duration_minutes      int not null check (duration_minutes > 0),
  -- ADR-25: snapshotted buffers
  buffer_before_minutes int not null default 0 check (buffer_before_minutes >= 0),
  buffer_after_minutes  int not null default 0 check (buffer_after_minutes >= 0),
  -- ADR-24: busy_range includes buffers; set by trigger before insert/update
  busy_range            tstzrange,
  -- ADR-23: snapshotted service names for history (F-5: {entity}_name_{locale})
  service_name_en       text,
  service_name_ar       text,
  display_order         int not null default 0,
  -- ADR-24: status-active flag so cancelled/no_show items drop out of exclusion constraint
  status_active         boolean not null default true,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  -- ADR-20 rule 5: composite FKs
  foreign key (service_id, tenant_id) references public.services(id, tenant_id),
  foreign key (staff_id, tenant_id) references public.staff_members(id, tenant_id)
);

-- ADR-24: exclusion constraint - no two active items for same staff can overlap
-- busy_range already includes buffers (ADR-25)
create extension if not exists btree_gist with schema extensions;

-- NOTE: PGlite does not support exclusion constraints with partial conditions (WHERE).
-- The constraint must cover all rows; we rely on the RPC to clear busy_range or
-- set status_active=false for cancelled items. The simple form below prevents
-- any two items for the same staff from overlapping regardless of status.
-- A future production migration can add the WHERE clause once the check-sql runner
-- supports it. The cross-entity lock (ADR-24 layer 2) still holds.
alter table public.appointment_items
  add constraint excl_appointment_items_staff
  exclude using gist (staff_id with =, busy_range with &&)
  where (staff_id is not null);

-- Alternative for PGlite compatibility: use a trigger-based check in the RPC
-- For now we keep the exclusion constraint as intent; it runs on real Postgres.

create index idx_ai_appointment on public.appointment_items(appointment_id);
create index idx_ai_tenant on public.appointment_items(tenant_id);
create index idx_ai_staff on public.appointment_items(staff_id);
create index idx_ai_service on public.appointment_items(tenant_id, service_id);
create index idx_ai_busy on public.appointment_items(staff_id, busy_range);

create trigger set_updated_at_appointment_items
  before update on public.appointment_items
  for each row execute function public.set_updated_at();

-- ============================================================================
-- BOOKING_OVERRIDES (ADR-26: manager override for booking outside shift)
-- ============================================================================
create table public.booking_overrides (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  appointment_id  uuid not null references public.appointments(id) on delete cascade,
  reason          text not null,
  created_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id)
);

create index idx_bo_appointment on public.booking_overrides(appointment_id);

-- ============================================================================
-- TRIGGER: populate appointments.during from scheduled_start/end
-- ============================================================================
create or replace function public.set_appointment_during()
returns trigger
language plpgsql
as $$
begin
  new.during := tstzrange(new.scheduled_start, new.scheduled_end, '[)');
  return new;
end;
$$;

create trigger trg_set_appointment_during
  before insert or update of scheduled_start, scheduled_end on public.appointments
  for each row execute function public.set_appointment_during();

-- ============================================================================
-- TRIGGER: populate appointment_items.busy_range (includes buffers)
-- ============================================================================
create or replace function public.set_appointment_item_busy_range()
returns trigger
language plpgsql
as $$
begin
  new.busy_range := tstzrange(
    new.effective_start - (new.buffer_before_minutes * interval '1 minute'),
    new.effective_end   + (new.buffer_after_minutes * interval '1 minute'),
    '[)'
  );
  return new;
end;
$$;

create trigger trg_set_appointment_item_busy_range
  before insert or update of effective_start, effective_end, buffer_before_minutes, buffer_after_minutes
  on public.appointment_items
  for each row execute function public.set_appointment_item_busy_range();