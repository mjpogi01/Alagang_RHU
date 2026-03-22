-- =============================================================================
-- Add relationship role to family_members
-- =============================================================================

ALTER TABLE public.family_members
  ADD COLUMN IF NOT EXISTS role text;

ALTER TABLE public.family_members
  DROP CONSTRAINT IF EXISTS family_members_role_check;

ALTER TABLE public.family_members
  ADD CONSTRAINT family_members_role_check
  CHECK (
    role IS NULL OR role IN (
      'anak',
      'apo',
      'asawa',
      'pamangkin',
      'ina',
      'ama',
      'lolo',
      'lola',
      'tita',
      'tito',
      'lola_sa_tuhod',
      'lolo_sa_tuhod',
      'pinsan'
    )
  );

