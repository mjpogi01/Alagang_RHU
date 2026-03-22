-- Add archived_at for soft-archive on categories and services (admin can hide without deleting).
ALTER TABLE public.primary_care_categories
  ADD COLUMN IF NOT EXISTS archived_at timestamptz;

ALTER TABLE public.primary_care_services
  ADD COLUMN IF NOT EXISTS archived_at timestamptz;

COMMENT ON COLUMN public.primary_care_categories.archived_at IS 'When set, category is archived (hidden from directory; admin can unarchive).';
COMMENT ON COLUMN public.primary_care_services.archived_at IS 'When set, service is archived (hidden from directory; admin can unarchive).';

CREATE INDEX IF NOT EXISTS idx_primary_care_categories_archived_at
  ON public.primary_care_categories(archived_at) WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_primary_care_services_archived_at
  ON public.primary_care_services(archived_at) WHERE archived_at IS NULL;
