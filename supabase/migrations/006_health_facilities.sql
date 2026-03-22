-- =============================================================================
-- Alagang RHU – Health facilities (admin-managed, visible in app provider network).
-- Run after 005 (uses current_user_is_admin()). Safe to re-run (idempotent).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.health_facilities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL DEFAULT 'Barangay Health Center',
  address text,
  phone text,
  hours text,
  rating numeric(3,2) NOT NULL DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  is_open boolean NOT NULL DEFAULT true,
  services text[] NOT NULL DEFAULT '{}',
  latitude double precision,
  longitude double precision,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Add map columns if table was created before they were in the schema
ALTER TABLE public.health_facilities
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision;

COMMENT ON COLUMN public.health_facilities.latitude IS 'Map pin latitude (from admin tap-to-pin).';
COMMENT ON COLUMN public.health_facilities.longitude IS 'Map pin longitude.';
COMMENT ON TABLE public.health_facilities IS 'Healthcare facilities managed by admin; shown in app provider network.';

CREATE INDEX IF NOT EXISTS idx_health_facilities_name ON public.health_facilities(name);
CREATE INDEX IF NOT EXISTS idx_health_facilities_type ON public.health_facilities(type);

-- Trigger: updated_at
DROP TRIGGER IF EXISTS health_facilities_updated_at ON public.health_facilities;
CREATE TRIGGER health_facilities_updated_at
  BEFORE UPDATE ON public.health_facilities
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.health_facilities ENABLE ROW LEVEL SECURITY;

-- Policies (drop first so re-run does not fail)
DROP POLICY IF EXISTS "Authenticated users can view health facilities" ON public.health_facilities;
CREATE POLICY "Authenticated users can view health facilities"
  ON public.health_facilities FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins can insert health facilities" ON public.health_facilities;
CREATE POLICY "Admins can insert health facilities"
  ON public.health_facilities FOR INSERT
  WITH CHECK (public.current_user_is_admin());

DROP POLICY IF EXISTS "Admins can update health facilities" ON public.health_facilities;
CREATE POLICY "Admins can update health facilities"
  ON public.health_facilities FOR UPDATE
  USING (public.current_user_is_admin());

DROP POLICY IF EXISTS "Admins can delete health facilities" ON public.health_facilities;
CREATE POLICY "Admins can delete health facilities"
  ON public.health_facilities FOR DELETE
  USING (public.current_user_is_admin());
