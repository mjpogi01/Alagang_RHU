-- =============================================================================
-- Read/unread tracking for appointment reminder notifications (Mga Abiso).
-- =============================================================================

create table if not exists public.appointment_reminder_notification_reads (
  user_id uuid not null references auth.users(id) on delete cascade,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  reminder_type text not null,
  read_at timestamptz not null default now(),
  primary key (user_id, appointment_id, reminder_type)
);

alter table public.appointment_reminder_notification_reads enable row level security;

drop policy if exists "user can read own appointment reminder reads" on public.appointment_reminder_notification_reads;
create policy "user can read own appointment reminder reads"
  on public.appointment_reminder_notification_reads
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user can insert own appointment reminder reads" on public.appointment_reminder_notification_reads;
create policy "user can insert own appointment reminder reads"
  on public.appointment_reminder_notification_reads
  for insert
  to authenticated
  with check (user_id = auth.uid());

