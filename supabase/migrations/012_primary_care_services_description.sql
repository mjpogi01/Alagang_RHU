-- Add optional description for primary care services.
ALTER TABLE public.primary_care_services
  ADD COLUMN IF NOT EXISTS description text;

COMMENT ON COLUMN public.primary_care_services.description IS 'Optional short description of the service.';
