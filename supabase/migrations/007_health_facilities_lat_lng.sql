-- =============================================================================
-- Add map coordinates to health_facilities (for DBs that ran 006 before lat/lng
-- were in the schema). Safe to run: ADD COLUMN IF NOT EXISTS. Skip if 006
-- already created the table with latitude/longitude.
-- =============================================================================

ALTER TABLE public.health_facilities
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision;

COMMENT ON COLUMN public.health_facilities.latitude IS 'Map pin latitude (e.g. from admin tap-to-pin).';
COMMENT ON COLUMN public.health_facilities.longitude IS 'Map pin longitude.';
