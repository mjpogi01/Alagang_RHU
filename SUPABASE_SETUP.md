# Supabase setup for Alagang RHU

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in.
2. Click **New project**, choose your org, name the project (e.g. `alagang-rhu`), set a database password, and create the project.
3. In the dashboard, go to **Project Settings** → **API**.
4. Copy:
   - **Project URL** (e.g. `https://xxxxx.supabase.co`)
   - **anon public** key (under "Project API keys")

## 2. Configure the app

**Option A – Edit config (quick for local dev)**

Open `lib/config/supabase_config.dart` and replace the default values:

- `defaultValue` for `url`: your Project URL
- `defaultValue` for `anonKey`: your anon public key

**Option B – Dart defines (better for not committing secrets)**

Run the app with:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Or add a run configuration in your IDE that includes these `--dart-define` arguments.

## 3. Database schema

A full schema is in **`supabase/migrations/001_initial_schema.sql`**. Apply it in the Supabase Dashboard → **SQL Editor** (paste and run the file contents).

It creates:

- **profiles** – user profile (name, email, age, sex, phone, address) linked to `auth.users`; a row is created automatically when a user signs up (trigger).
- **family_members** – family members (name, DOB, sex, pregnancy_status, comorbidities) owned by each user.
- **calendar_events** – RHU/system health events (date, group, title, description); optional for the calendar.
- **appointments** – user appointments/reminders, optionally linked to a family member.

RLS policies ensure users only access their own profiles, family members, and appointments.

Use `SupabaseService.client` in the app to query and mutate data:

```dart
import 'package:alagang_rhu/services/supabase_service.dart';

// Example: fetch from a table
final data = await SupabaseService.client.from('profiles').select();
```

## 4. Email confirmation → open the app (deep link)

So that **“Confirm your email”** opens the installed app instead of localhost:

1. In the dashboard go to **Authentication** → **URL Configuration**.
2. Set **Site URL** to: `alagangrhu://auth`
3. Under **Redirect URLs**, add: `alagangrhu://auth` and `alagangrhu://**` (then Save).

The app is set up to handle the `alagangrhu://auth` scheme on Android and iOS. When the user taps the confirmation link in the email, the device will open the app and the session will be set automatically.

## 5. Auth

The app uses Supabase Auth for login/sign-up and stores profile data in the `profiles` table.
