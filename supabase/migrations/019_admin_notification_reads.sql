-- =============================================================================
-- Read/unread tracking for admin calendar event notifications (bell dot).
--
-- Key idea: store which authenticated user already acknowledged a given
-- calendar_events row that has send_notifications = true.
-- =============================================================================

create table if not exists public.admin_calendar_event_notification_reads (
  user_id uuid not null references auth.users(id) on delete cascade,
  calendar_event_id uuid not null references public.calendar_events(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (user_id, calendar_event_id)
);

alter table public.admin_calendar_event_notification_reads enable row level security;

drop policy if exists "user can read own admin notification reads" on public.admin_calendar_event_notification_reads;
create policy "user can read own admin notification reads"
  on public.admin_calendar_event_notification_reads
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user can insert own admin notification reads" on public.admin_calendar_event_notification_reads;
create policy "user can insert own admin notification reads"
  on public.admin_calendar_event_notification_reads
  for insert
  to authenticated
  with check (user_id = auth.uid());

