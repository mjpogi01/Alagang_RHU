-- =============================================================================
-- Alagang RHU – Allow admins to read all profiles, families, and family_members
-- Run after 001 and 002. Requires profiles.is_admin column (add if missing).
-- =============================================================================

-- Ensure is_admin exists on profiles (e.g. added manually or by another migration)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;

-- -----------------------------------------------------------------------------
-- Profiles: admins can view all profiles (for admin Users tab)
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    (SELECT p.is_admin FROM public.profiles p WHERE p.user_id = auth.uid() LIMIT 1) = true
  );

-- -----------------------------------------------------------------------------
-- Families: admins can view all families
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can view all families"
  ON public.families FOR SELECT
  USING (
    (SELECT p.is_admin FROM public.profiles p WHERE p.user_id = auth.uid() LIMIT 1) = true
  );

-- -----------------------------------------------------------------------------
-- Family members: admins can view all family members (for member counts, etc.)
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can view all family members"
  ON public.family_members FOR SELECT
  USING (
    (SELECT p.is_admin FROM public.profiles p WHERE p.user_id = auth.uid() LIMIT 1) = true
  );
