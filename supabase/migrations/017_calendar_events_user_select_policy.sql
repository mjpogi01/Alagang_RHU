-- Ensure non-admin authenticated users can view calendar_events.
-- Without this, users may only see their own `appointments` and not the admin-created calendar schedules.

DROP POLICY IF EXISTS "Authenticated users can view calendar events"
  ON public.calendar_events;

CREATE POLICY "Authenticated users can view calendar events"
  ON public.calendar_events FOR SELECT
  TO authenticated
  USING (true);

