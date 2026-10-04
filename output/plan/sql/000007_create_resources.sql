-- Create resources table (rooms, equipment, bookable items)

CREATE TABLE public.resources (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid NOT NULL REFERENCES public.tenants(id),
  branch_id     uuid NOT NULL REFERENCES public.branches(id),
  name          text NOT NULL,
  resource_type text NOT NULL DEFAULT 'room' CHECK (resource_type IN ('room', 'equipment', 'other')),
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_resources_tenant ON public.resources(tenant_id);
CREATE INDEX idx_resources_branch ON public.resources(branch_id);

CREATE TRIGGER set_updated_at_resources
  BEFORE UPDATE ON public.resources
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();