# Supabase migrations

## Apply the schema

Run migrations **in order** in the Supabase Dashboard → **SQL Editor** (paste and run each file):

1. `migrations/001_initial_schema.sql`
2. `migrations/002_family_decision_maker_and_invites.sql`
3. `migrations/003_admin_read_policies.sql` – admin can read all profiles, families, family_members
4. `migrations/004_grant_admin_09276319866.sql` – optional: grant admin to a specific account
5. `migrations/005_fix_admin_policy_recursion.sql` – fixes RLS recursion; adds `current_user_is_admin()`, `user_belongs_to_family()`
6. `migrations/006_health_facilities.sql` – health facilities table (name, type, phone, hours, services, **latitude**, **longitude**, etc.)
7. `migrations/007_health_facilities_lat_lng.sql` – add latitude/longitude if missing (safe if 006 already had them)
8. `migrations/008_primary_care_services.sql` – primary care categories and services (admin-managed); seeds default categories when empty
9. `migrations/009_primary_care_official_list.sql` – **official** primary care list (Population-Based, Individual-Based, Maternal & Newborn, Nutrition, Vaccination 1–17). Replaces existing seed; admin can still add/edit/delete after.
10. `migrations/010_primary_care_archived_at.sql` – archive support for primary care tables.
11. `migrations/011_primary_care_services_price.sql` – optional price on services.
12. `migrations/012_primary_care_services_description.sql` – optional description on services.
13. `migrations/013_calendar_events_admin_write.sql` – admins can insert/update/delete `calendar_events` (fixes RLS on create sched).
14. `migrations/014_calendar_events_facility_and_time.sql` – **`facility`**, **`start_time`** on `calendar_events` (required for admin calendar; without this you get PGRST204 on `facility`).
15. `migrations/015_calendar_events_end_time.sql` – **`end_time`** on `calendar_events`.
16. `migrations/016_calendar_events_multi_group_age.sql` – **`group_types`** (array), optional **`age_range_min` / `age_range_max`**; trigger keeps **`group_type`** in sync.
17. `migrations/018_calendar_events_notification_fields.sql` – notification templates (`send_notifications`, `notification_title`, `notification_body`) for user reminders.
18. `migrations/019_admin_notification_reads.sql` – admin notification read tracking for bell dot.
19. `migrations/020_appointment_reminder_notification_reads.sql` – appointment reminder read tracking for Abiso.
20. `migrations/021_family_members_role.sql` – add family member relationship roles (anak/apo/asawa/etc).
21. `migrations/022_family_members_relation.sql` – rename family member column `role` -> `relation`.
22. `migrations/023_calendar_events_announcement_fields.sql` – admin announcement fields (`send_announcement`, `announcement_title`, `announcement_body`).

Or with [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase db push
```

(Ensure `supabase link` is done for your project.)

## Schema overview

| Table                 | Purpose |
|-----------------------|--------|
| `profiles`            | User profile (name, email, age, sex, phone, address, `is_admin`). One row per `auth.users`; created on signup, updated from the app. |
| `families`            | A household/family. Has a shareable `family_code` and one `decision_maker_user_id` (family health decision maker). |
| `family_members`      | Members of a family (name, DOB, sex, pregnancy_status, comorbidities). `family_id` → family; `user_id` = linked auth account if the member has their own login. One user can be in at most one family. |
| `family_invitations`  | Invitations from the decision maker (email, token, status). Invitee accepts via `accept_family_invitation(token)`. |
| `calendar_events`     | RHU/system health events (date, group, title, description, facility, start/end time). Admins create via app (migration 013+). |
| `appointments`        | User appointments/reminders. Optional link to `family_members`. |
| `health_facilities`   | Admin-managed facilities (name, type, phone, hours, services, is_open, **latitude**, **longitude**). Shown on the user map when coordinates are set. |
| `primary_care_categories` | Service directory categories (title, color_hex, icon_name, sort_order). Admin CRUD. |
| `primary_care_services`    | Services under each category (category_id, name, sort_order). Admin CRUD. User app shows these in the Primary Care Services / Service Directory screen. |

## Family flow

- **Create a family**: A user with no family can call `select public.create_my_family('Optional Name');` to create a family and become the **family health decision maker**. They get a unique **family code** to share.
- **Decision maker**: Can add members (with or without accounts), invite by email, and share the **family code**.
- **Join by code**: Any user can call `select public.join_family_by_code('ABCD1234');` (with the shared code) to join that family (if they are not already in one).
- **Join by invite**: Decision maker creates a row in `family_invitations` (email + token). Invitee signs up or logs in, then calls `select public.accept_family_invitation('token');` to join.
- **Members with accounts**: A `family_members` row with `user_id` set is a member who has their own account; they see the same family when they log in.
