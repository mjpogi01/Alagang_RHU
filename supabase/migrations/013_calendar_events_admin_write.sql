-- =============================================================================
-- Alagang RHU – Allow admins to create, update, delete calendar_events.
-- Run after 005 (current_user_is_admin). Events created here appear on the app calendar.
-- =============================================================================

DROP POLICY IF EXISTS "Admins can manage calendar_events" ON public.calendar_events;
CREATE POLICY "Admins can manage calendar_events"
  ON public.calendar_events FOR ALL TO authenticated
  USING (public.current_user_is_admin())
  WITH CHECK (public.current_user_is_admin());
