-- ============================================================================
-- SUPERSEDED ROUND-1 DRAFT (quarantined in round 2, finding F-1).
-- This file is NOT an active migration and must never be applied by any
-- tooling (`supabase db reset`, CI, or hand). The active migration set is
-- written fresh under supabase/migrations/ in Phase 0/1 from the binding
-- ADRs (decisions.md) and CONVENTIONS.md.
-- Known defects in this draft (numeric money, 'started' status, sentinel
-- branch UUID, separate refunds table, tenant-only RLS, missing
-- security_invoker, race-prone booking trigger, rejected table names,
-- service_charge_total column) are catalogued in review2/adjudication.md
-- and REVISION_LOG.md.
-- ============================================================================

-- Create appointments and appointment_items tables with double-booking prevention

-- ============================================================================
-- APPOINTMENTS
-- ============================================================================
CREATE TABLE public.appointments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL REFERENCES public.tenants(id),
  branch_id        uuid NOT NULL REFERENCES public.branches(id),
  client_id        uuid REFERENCES public.clients(id),
  ref_number       text NOT NULL,
  scheduled_start  timestamptz NOT NULL,
  scheduled_end    timestamptz NOT NULL,
  duration_minutes int NOT NULL CHECK (duration_minutes > 0),
  during           tstzrange GENERATED ALWAYS AS (
                     tstzrange(scheduled_start, scheduled_end, '[)')
                   ) STORED,
  status           text NOT NULL DEFAULT 'booked'
                   CHECK (status IN ('booked', 'confirmed', 'arrived', 'started', 'completed', 'cancelled', 'no_show')),
  total_price      numeric(12,3) NOT NULL DEFAULT 0 CHECK (total_price >= 0),
  notes            text,
  channel          text DEFAULT 'offline',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  created_by       uuid REFERENCES auth.users(id),
  updated_by       uuid REFERENCES auth.users(id),
  CHECK (scheduled_end > scheduled_start)
);

CREATE INDEX idx_appointments_tenant ON public.appointments(tenant_id);
CREATE INDEX idx_appointments_branch ON public.appointments(branch_id);
CREATE INDEX idx_appointments_client ON public.appointments(client_id);
CREATE INDEX idx_appointments_start ON public.appointments(tenant_id, scheduled_start);
CREATE INDEX idx_appointments_status ON public.appointments(tenant_id, status, scheduled_start);

CREATE TRIGGER set_updated_at_appointments
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- APPOINTMENT_ITEMS
-- ============================================================================
CREATE TABLE public.appointment_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL REFERENCES public.tenants(id),
  appointment_id   uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  service_id       uuid NOT NULL REFERENCES public.services(id),
  staff_id         uuid REFERENCES public.staff(id),
  resource_id      uuid REFERENCES public.resources(id),
  price            numeric(12,3) NOT NULL CHECK (price >= 0),
  duration_minutes int NOT NULL CHECK (duration_minutes > 0),
  display_order    int NOT NULL DEFAULT 0
);

CREATE INDEX idx_ai_appointment ON public.appointment_items(appointment_id);
CREATE INDEX idx_ai_tenant ON public.appointment_items(tenant_id);
CREATE INDEX idx_ai_staff ON public.appointment_items(staff_id);
CREATE INDEX idx_ai_service ON public.appointment_items(tenant_id, service_id);

-- ============================================================================
-- DOUBLE-BOOKING PREVENTION TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_staff_double_booking()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_start timestamptz;
  v_end   timestamptz;
  v_conflict_count int;
BEGIN
  -- Get the appointment's time range
  SELECT scheduled_start, scheduled_end
  INTO v_start, v_end
  FROM public.appointments
  WHERE id = NEW.appointment_id;

  -- Check for overlapping appointments with same staff
  IF NEW.staff_id IS NOT NULL THEN
    SELECT count(*) INTO v_conflict_count
    FROM public.appointment_items ai
    JOIN public.appointments a ON a.id = ai.appointment_id
    WHERE ai.staff_id = NEW.staff_id
      AND ai.id != NEW.id
      AND a.status NOT IN ('cancelled', 'no_show')
      AND tstzrange(a.scheduled_start, a.scheduled_end, '[)') && tstzrange(v_start, v_end, '[)');

    IF v_conflict_count > 0 THEN
      RAISE EXCEPTION 'Staff member is already booked during this time slot (SQLSTATE 23P01)'
        USING ERRCODE = '23P01';
    END IF;
  END IF;

  -- Check for overlapping appointments with same resource
  IF NEW.resource_id IS NOT NULL THEN
    SELECT count(*) INTO v_conflict_count
    FROM public.appointment_items ai
    JOIN public.appointments a ON a.id = ai.appointment_id
    WHERE ai.resource_id = NEW.resource_id
      AND ai.id != NEW.id
      AND a.status NOT IN ('cancelled', 'no_show')
      AND tstzrange(a.scheduled_start, a.scheduled_end, '[)') && tstzrange(v_start, v_end, '[)');

    IF v_conflict_count > 0 THEN
      RAISE EXCEPTION 'Resource is already booked during this time slot (SQLSTATE 23P01)'
        USING ERRCODE = '23P01';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_staff_double_booking
  BEFORE INSERT OR UPDATE ON public.appointment_items
  FOR EACH ROW EXECUTE FUNCTION public.check_staff_double_booking();