-- =============================================================================
-- Calendar event announcements (admin-posted notifications)
-- =============================================================================

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS send_announcement boolean NOT NULL DEFAULT false;

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS announcement_title text;

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS announcement_body text;

