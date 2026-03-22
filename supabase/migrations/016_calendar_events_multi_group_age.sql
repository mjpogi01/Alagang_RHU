-- Multiple target groups per event + optional custom age range.
-- Keeps group_type in sync (first selected group) for legacy clients.

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS group_types public.health_event_group[];

UPDATE public.calendar_events
SET group_types = ARRAY[group_type]::public.health_event_group[]
WHERE group_types IS NULL;

ALTER TABLE public.calendar_events
  ALTER COLUMN group_types SET NOT NULL;

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS age_range_min integer,
  ADD COLUMN IF NOT EXISTS age_range_max integer;

ALTER TABLE public.calendar_events
  DROP CONSTRAINT IF EXISTS calendar_events_age_range_ok;

ALTER TABLE public.calendar_events
  ADD CONSTRAINT calendar_events_age_range_ok
  CHECK (
    age_range_min IS NULL OR age_range_max IS NULL OR age_range_min <= age_range_max
  );

ALTER TABLE public.calendar_events
  DROP CONSTRAINT IF EXISTS calendar_events_group_types_nonempty;

ALTER TABLE public.calendar_events
  ADD CONSTRAINT calendar_events_group_types_nonempty
  CHECK (cardinality(group_types) >= 1);

CREATE OR REPLACE FUNCTION public.calendar_events_sync_group_type()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.group_types IS NOT NULL AND cardinality(NEW.group_types) >= 1 THEN
    NEW.group_type := NEW.group_types[1];
  ELSIF NEW.group_type IS NOT NULL THEN
    NEW.group_types := ARRAY[NEW.group_type];
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_calendar_events_group_types ON public.calendar_events;
CREATE TRIGGER tr_calendar_events_group_types
  BEFORE INSERT OR UPDATE OF group_types, group_type ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION public.calendar_events_sync_group_type();

COMMENT ON COLUMN public.calendar_events.group_types IS 'One or more audience groups (buntis, bata, …).';
COMMENT ON COLUMN public.calendar_events.age_range_min IS 'Optional custom min age (years); use with age_range_max.';
COMMENT ON COLUMN public.calendar_events.age_range_max IS 'Optional custom max age (years).';
