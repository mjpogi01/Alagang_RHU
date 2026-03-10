# Supabase migrations

## Apply the schema

Run migrations in order in the Supabase Dashboard → **SQL Editor** (paste and run each file):

1. `migrations/001_initial_schema.sql`
2. `migrations/002_family_decision_maker_and_invites.sql`

Or with [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase db push
```

(Ensure `supabase link` is done for your project.)

## Schema overview

| Table                 | Purpose |
|-----------------------|--------|
| `profiles`            | User profile (name, email, age, sex, phone, address). One row per `auth.users`; created on signup, updated from the app. |
| `families`            | A household/family. Has a shareable `family_code` and one `decision_maker_user_id` (family health decision maker). |
| `family_members`      | Members of a family (name, DOB, sex, pregnancy_status, comorbidities). `family_id` → family; `user_id` = linked auth account if the member has their own login. One user can be in at most one family. |
| `family_invitations`  | Invitations from the decision maker (email, token, status). Invitee accepts via `accept_family_invitation(token)`. |
| `calendar_events`     | RHU/system health events (date, group, title, description). Read-only for the app. |
| `appointments`        | User appointments/reminders. Optional link to `family_members`. |

## Family flow

- **Create a family**: A user with no family can call `select public.create_my_family('Optional Name');` to create a family and become the **family health decision maker**. They get a unique **family code** to share.
- **Decision maker**: Can add members (with or without accounts), invite by email, and share the **family code**.
- **Join by code**: Any user can call `select public.join_family_by_code('ABCD1234');` (with the shared code) to join that family (if they are not already in one).
- **Join by invite**: Decision maker creates a row in `family_invitations` (email + token). Invitee signs up or logs in, then calls `select public.accept_family_invitation('token');` to join.
- **Members with accounts**: A `family_members` row with `user_id` set is a member who has their own account; they see the same family when they log in.
