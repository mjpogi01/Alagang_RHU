-- =============================================================================
-- Rename family_members.role -> family_members.relation
-- =============================================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'family_members'
      AND column_name = 'role'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'family_members'
      AND column_name = 'relation'
  ) THEN
    ALTER TABLE public.family_members
      RENAME COLUMN role TO relation;
  END IF;
END $$;

-- Replace the old constraint name/definition with one for `relation`.
ALTER TABLE public.family_members
  DROP CONSTRAINT IF EXISTS family_members_role_check;

ALTER TABLE public.family_members
  DROP CONSTRAINT IF EXISTS family_members_relation_check;

ALTER TABLE public.family_members
  ADD CONSTRAINT family_members_relation_check
  CHECK (
    relation IS NULL OR relation IN (
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

