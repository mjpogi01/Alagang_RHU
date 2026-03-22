-- Add facility (text) and start_time (time of day) for calendar events. Date + time.
ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS facility text,
  ADD COLUMN IF NOT EXISTS start_time time;

COMMENT ON COLUMN public.calendar_events.facility IS 'Optional facility/location name (text input).';
COMMENT ON COLUMN public.calendar_events.start_time IS 'Optional time of day when the event starts (e.g. 09:00).';
