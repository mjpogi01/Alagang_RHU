-- =============================================================================
-- Fix infinite recursion in RLS policies.
-- 1) "Admins can view all profiles" selected from profiles => recursion. Fixed
--    with current_user_is_admin() SECURITY DEFINER.
-- 2) "Users can view family members in their family" selected from family_members
--    => recursion. Fixed with user_belongs_to_family() SECURITY DEFINER.
-- =============================================================================

-- Function that returns true if the current user's profile has is_admin = true.
-- SECURITY DEFINER = runs with owner rights, so it can read profiles without RLS.
CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT COALESCE(
    (SELECT p.is_admin FROM public.profiles p WHERE p.user_id = auth.uid() LIMIT 1),
    false
  );
$$;

-- Returns true if the current user belongs to the given family (decision maker or member).
-- SECURITY DEFINER so the read from family_members does not trigger RLS => no recursion.
CREATE OR REPLACE FUNCTION public.user_belongs_to_family(p_family_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.families f
    WHERE f.id = p_family_id
      AND (f.decision_maker_user_id = auth.uid()
           OR EXISTS (
             SELECT 1 FROM public.family_members m
             WHERE m.family_id = f.id AND m.user_id = auth.uid()
           ))
  );
$$;

-- Drop and recreate admin policies to use the function instead of inline subquery.
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.current_user_is_admin());

DROP POLICY IF EXISTS "Admins can view all families" ON public.families;
CREATE POLICY "Admins can view all families"
  ON public.families FOR SELECT
  USING (public.current_user_is_admin());

DROP POLICY IF EXISTS "Admins can view all family members" ON public.family_members;
CREATE POLICY "Admins can view all family members"
  ON public.family_members FOR SELECT
  USING (public.current_user_is_admin());

-- Fix recursion on family_members: "Users can view family members in their family"
-- used a subquery on family_members. Replace with SECURITY DEFINER helper.
DROP POLICY IF EXISTS "Users can view family members in their family" ON public.family_members;
CREATE POLICY "Users can view family members in their family"
  ON public.family_members FOR SELECT
  USING (public.current_user_is_admin() OR public.user_belongs_to_family(family_id));
