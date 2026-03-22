-- Add optional price for primary care services. Null or 0 = free.
ALTER TABLE public.primary_care_services
  ADD COLUMN IF NOT EXISTS price numeric(12, 2);

COMMENT ON COLUMN public.primary_care_services.price IS 'Optional fee; null or 0 means free.';
