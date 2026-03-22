-- Add end_time so time is a range (e.g. 8:00 AM - 9:00 AM).
ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS end_time time;

COMMENT ON COLUMN public.calendar_events.end_time IS 'Optional time when the event ends (time range with start_time).';
