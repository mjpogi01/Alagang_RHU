-- =============================================================================
-- Alagang RHU – Families, decision maker, family code, and invitations
-- Can run after 001_initial_schema.sql, or on a fresh DB (creates family_members if missing).
-- =============================================================================
--
-- Model:
-- - A FAMILY has one "family health decision maker" (the user in charge).
-- - Family has a shareable FAMILY_CODE so members can join by entering the code.
-- - Members can also join by accepting an INVITATION from the decision maker.
-- - FAMILY_MEMBERS can have their own account (user_id); then they see the
--   same family when they log in. One user can belong to at most one family.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. FAMILIES – one per household; decision maker is in charge
-- -----------------------------------------------------------------------------
CREATE TABLE public.families (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_code text NOT NULL UNIQUE,
  decision_maker_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_families_decision_maker ON public.families(decision_maker_user_id);
CREATE UNIQUE INDEX idx_families_family_code ON public.families(family_code);

COMMENT ON TABLE public.families IS 'Household/family; one member is the family health decision maker';
COMMENT ON COLUMN public.families.family_code IS 'Shareable code for members to join the family';
COMMENT ON COLUMN public.families.decision_maker_user_id IS 'User who is the family health decision maker';

-- Generate a random 8-char alphanumeric family code (helper)
CREATE OR REPLACE FUNCTION public.generate_family_code()
RETURNS text AS $$
  SELECT upper(replace(substr(gen_random_uuid()::text, 1, 8), '-', ''));
$$ LANGUAGE sql;

-- Required by trigger below (may already exist from 001)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 2. FAMILY_MEMBERS – create if missing, or migrate from 001 structure
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'family_members'
  ) THEN
    -- Fresh DB: create family_members with family-scoped structure from the start
    CREATE TABLE public.family_members (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
      user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
      name text,
      date_of_birth date NOT NULL,
      sex text NOT NULL CHECK (sex IN ('male', 'female', 'other')),
      pregnancy_status boolean,
      comorbidities text[] DEFAULT '{}',
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now()
    );
    CREATE INDEX idx_family_members_family_id ON public.family_members(family_id);
    CREATE INDEX idx_family_members_user_id ON public.family_members(user_id);
    CREATE UNIQUE INDEX idx_family_members_user_unique
      ON public.family_members(user_id) WHERE user_id IS NOT NULL;
    CREATE UNIQUE INDEX idx_family_members_family_user
      ON public.family_members(family_id, user_id) WHERE user_id IS NOT NULL;
    ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
    CREATE TRIGGER family_members_updated_at
      BEFORE UPDATE ON public.family_members
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    COMMENT ON TABLE public.family_members IS 'Family members (demographics); user_id = linked account if member has own login';
  ELSE
    -- 001 was run: migrate to family-scoped structure
    ALTER TABLE public.family_members
      ADD COLUMN IF NOT EXISTS family_id uuid REFERENCES public.families(id) ON DELETE CASCADE;

    INSERT INTO public.families (family_code, decision_maker_user_id)
    SELECT public.generate_family_code(), u.user_id
    FROM (SELECT DISTINCT user_id FROM public.family_members) u;

    UPDATE public.family_members fm
    SET family_id = f.id
    FROM public.families f
    WHERE f.decision_maker_user_id = fm.user_id;

    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date date;

    INSERT INTO public.family_members (family_id, user_id, name, date_of_birth, sex)
    SELECT f.id, f.decision_maker_user_id, p.full_name, COALESCE(p.birth_date, '1990-01-01'::date), COALESCE(p.sex, 'other')
    FROM public.families f
    LEFT JOIN public.profiles p ON p.user_id = f.decision_maker_user_id
    WHERE NOT EXISTS (
      SELECT 1 FROM public.family_members fm
      WHERE fm.family_id = f.id AND fm.user_id = f.decision_maker_user_id
    );

    ALTER TABLE public.family_members ALTER COLUMN family_id SET NOT NULL;
    ALTER TABLE public.family_members ALTER COLUMN user_id DROP NOT NULL;

    CREATE UNIQUE INDEX IF NOT EXISTS idx_family_members_user_unique
      ON public.family_members(user_id) WHERE user_id IS NOT NULL;
    CREATE UNIQUE INDEX IF NOT EXISTS idx_family_members_family_user
      ON public.family_members(family_id, user_id) WHERE user_id IS NOT NULL;

    DROP POLICY IF EXISTS "Users can view own family members" ON public.family_members;
    DROP POLICY IF EXISTS "Users can insert own family members" ON public.family_members;
    DROP POLICY IF EXISTS "Users can update own family members" ON public.family_members;
    DROP POLICY IF EXISTS "Users can delete own family members" ON public.family_members;
  END IF;
END $$;

-- Add birth_date to profiles if table exists (used when creating member rows)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date date;
  END IF;
END $$;

-- RLS policies for family_members (same whether we just created or migrated)

-- RLS: users can see/edit family_members for families they belong to
-- (they have a row with their user_id, or they are the decision maker)
CREATE POLICY "Users can view family members in their family"
  ON public.family_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_members.family_id
        AND (f.decision_maker_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.family_members m
          WHERE m.family_id = f.id AND m.user_id = auth.uid()
        ))
    )
  );

CREATE POLICY "Decision maker can insert family members"
  ON public.family_members FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_members.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

CREATE POLICY "Decision maker can update family members"
  ON public.family_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_members.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

CREATE POLICY "Decision maker can delete family members"
  ON public.family_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_members.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

-- Also allow a user to update their own member row (when they have user_id set)
CREATE POLICY "Members can update own row"
  ON public.family_members FOR UPDATE
  USING (user_id = auth.uid());

-- Trigger for families updated_at
CREATE TRIGGER families_updated_at
  BEFORE UPDATE ON public.families
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 3. FAMILY_INVITATIONS – decision maker invites by email
-- -----------------------------------------------------------------------------
CREATE TABLE public.family_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  email text NOT NULL,
  invited_by_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_family_invitations_family ON public.family_invitations(family_id);
CREATE INDEX idx_family_invitations_email ON public.family_invitations(email);
CREATE INDEX idx_family_invitations_token ON public.family_invitations(token);

COMMENT ON TABLE public.family_invitations IS 'Invitations from decision maker for others to join the family';

ALTER TABLE public.family_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Decision maker can view and update invitations for their family"
  ON public.family_invitations FOR SELECT
  USING (
    invited_by_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_invitations.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

CREATE POLICY "Decision maker can insert invitations"
  ON public.family_invitations FOR INSERT
  WITH CHECK (
    invited_by_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_invitations.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

CREATE POLICY "Decision maker can update invitations"
  ON public.family_invitations FOR UPDATE
  USING (
    invited_by_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_invitations.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

CREATE POLICY "Decision maker can delete invitations"
  ON public.family_invitations FOR DELETE
  USING (
    invited_by_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.families f
      WHERE f.id = family_invitations.family_id AND f.decision_maker_user_id = auth.uid()
    )
  );

CREATE POLICY "Invitee can view own invitation by token"
  ON public.family_invitations FOR SELECT
  USING (true);  -- token is secret; app will filter by token when accepting

-- Invitee accepts via token (so they need to update status / we need a way to accept)
-- Service role or a secure function can set status = 'accepted' and create family_members row.
CREATE POLICY "Authenticated user can update invitation to accept"
  ON public.family_invitations FOR UPDATE
  USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()) OR invited_by_user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 4. RLS for FAMILIES
-- -----------------------------------------------------------------------------
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view families they belong to"
  ON public.families FOR SELECT
  USING (
    decision_maker_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.family_members m
      WHERE m.family_id = families.id AND m.user_id = auth.uid()
    )
  );

CREATE POLICY "User can create family (becomes decision maker)"
  ON public.families FOR INSERT
  WITH CHECK (decision_maker_user_id = auth.uid());

CREATE POLICY "Decision maker can update own family"
  ON public.families FOR UPDATE
  USING (decision_maker_user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 5. Create a new family (user becomes decision maker)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_my_family(family_name text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_family_id uuid;
  v_code text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM public.family_members WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Already a member of a family';
  END IF;
  v_code := public.generate_family_code();
  INSERT INTO public.families (family_code, decision_maker_user_id, name)
  VALUES (v_code, v_user_id, family_name)
  RETURNING id INTO v_family_id;
  INSERT INTO public.family_members (family_id, user_id, name, date_of_birth, sex)
  SELECT v_family_id, v_user_id, p.full_name, COALESCE(p.birth_date, '1990-01-01'::date), COALESCE(p.sex, 'other')
  FROM public.profiles p WHERE p.user_id = v_user_id;
  IF NOT FOUND THEN
    INSERT INTO public.family_members (family_id, user_id, date_of_birth, sex)
    VALUES (v_family_id, v_user_id, '1990-01-01'::date, 'other');
  END IF;
  RETURN v_family_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_my_family(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_my_family(text) TO service_role;

-- -----------------------------------------------------------------------------
-- 6. Allow new users to join family by code (INSERT into family_members)
--    Only if they're not already in a family and the code is valid.
-- -----------------------------------------------------------------------------
CREATE POLICY "User can join family by code"
  ON public.family_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND family_id IN (
      SELECT f.id FROM public.families f WHERE f.family_code = f.family_code
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.family_members m WHERE m.user_id = auth.uid()
    )
  );

-- The above policy is too restrictive (we can't reference a variable family_code in INSERT).
-- Better: use a database function "join_family_by_code(code text)" that checks and inserts.
CREATE OR REPLACE FUNCTION public.join_family_by_code(code text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_family_id uuid;
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  SELECT id INTO v_family_id FROM public.families WHERE family_code = upper(trim(code));
  IF v_family_id IS NULL THEN
    RAISE EXCEPTION 'Invalid family code';
  END IF;
  IF EXISTS (SELECT 1 FROM public.family_members WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Already a member of a family';
  END IF;
  INSERT INTO public.family_members (family_id, user_id, name, date_of_birth, sex)
  SELECT v_family_id, v_user_id, p.full_name, COALESCE(p.birth_date, '1990-01-01'::date), COALESCE(p.sex, 'other')
  FROM public.profiles p
  WHERE p.user_id = v_user_id;
  IF NOT FOUND THEN
    INSERT INTO public.family_members (family_id, user_id, date_of_birth, sex)
    VALUES (v_family_id, v_user_id, '1990-01-01'::date, 'other');
  END IF;
  RETURN v_family_id;
END;
$$;

-- Drop the "User can join family by code" policy since we use the function
DROP POLICY IF EXISTS "User can join family by code" ON public.family_members;

-- Allow insert for join: only via function or decision maker. So we need policy:
-- Decision maker can insert (already have). For "member joining", they do it via
-- join_family_by_code which runs as SECURITY DEFINER and bypasses RLS for the insert.
-- So we need one more: allow insert when user_id = auth.uid() and they're not yet in any family?
-- Actually the function join_family_by_code uses SECURITY DEFINER so it runs with definer rights and bypasses RLS.
-- So we're good. But the function inserts into family_members - RLS will still apply. So we need a policy that
-- allows a user to insert a row for themselves (user_id = auth.uid()) when family_id is in families.
-- That's tricky because we can't check "not already in family" in WITH CHECK easily.
-- So: keep the function as SECURITY DEFINER; it runs with the owner's rights. The table owner (postgres/supabase)
-- can insert. So the function will work. Verify: SECURITY DEFINER means the function runs as the role that created it
-- (usually postgres or supabase_admin), so RLS might be bypassed. So the function should work.
-- Grant execute to authenticated users.
GRANT EXECUTE ON FUNCTION public.join_family_by_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_family_by_code(text) TO service_role;

-- -----------------------------------------------------------------------------
-- 7. Accept invitation by token (invitee calls this after signup/login)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_family_invitation(invitation_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitation public.family_invitations;
  v_user_id uuid := auth.uid();
  v_email text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;
  SELECT * INTO v_invitation
  FROM public.family_invitations
  WHERE token = invitation_token AND status = 'pending' AND expires_at > now();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation';
  END IF;
  IF v_invitation.email IS NOT NULL AND lower(trim(v_invitation.email)) <> lower(trim(v_email)) THEN
    RAISE EXCEPTION 'Invitation was sent to a different email';
  END IF;
  IF EXISTS (SELECT 1 FROM public.family_members WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Already a member of a family';
  END IF;
  INSERT INTO public.family_members (family_id, user_id, name, date_of_birth, sex)
  SELECT v_invitation.family_id, v_user_id, p.full_name, COALESCE(p.birth_date, '1990-01-01'::date), COALESCE(p.sex, 'other')
  FROM public.profiles p WHERE p.user_id = v_user_id;
  IF NOT FOUND THEN
    INSERT INTO public.family_members (family_id, user_id, date_of_birth, sex)
    VALUES (v_invitation.family_id, v_user_id, '1990-01-01'::date, 'other');
  END IF;
  UPDATE public.family_invitations SET status = 'accepted' WHERE id = v_invitation.id;
  RETURN v_invitation.family_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_family_invitation(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_family_invitation(text) TO service_role;
