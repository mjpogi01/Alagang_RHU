-- =============================================================================
-- Alagang RHU – Notification templates for admin-created calendar events.
--
-- Admin can toggle "Send notification" when creating/editing a sched and
-- provide the notification title/body. The user app uses these templates to
-- generate upcoming reminders at:
--   - 1 week before
--   - 1 day before
--   - 1 hour before
-- =============================================================================

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS send_notifications boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notification_title text,
  ADD COLUMN IF NOT EXISTS notification_body text;

