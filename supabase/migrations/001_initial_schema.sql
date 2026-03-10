-- =============================================================================
-- Alagang RHU – Initial database schema (Supabase / PostgreSQL)
-- Run in Supabase Dashboard → SQL Editor, or via Supabase CLI.
-- =============================================================================

-- Enable UUID extension (usually already on in Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. PROFILES – extended user data (from sign-up step 2: age, sex, phone, address)
-- Links to auth.users. One row per app user.
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  email text,
  age int CHECK (age IS NULL OR (age >= 1 AND age <= 150)),
  sex text CHECK (sex IS NULL OR sex IN ('male', 'female', 'other')),
  phone text,
  address text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);

COMMENT ON TABLE public.profiles IS 'User profile (name, age, sex, phone, address) linked to auth.users';

-- -----------------------------------------------------------------------------
-- 2. FAMILY_MEMBERS – family members belonging to a user
-- -----------------------------------------------------------------------------
CREATE TABLE public.family_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  date_of_birth date NOT NULL,
  sex text NOT NULL CHECK (sex IN ('male', 'female', 'other')),
  pregnancy_status boolean,
  comorbidities text[] DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_family_members_user_id ON public.family_members(user_id);

COMMENT ON TABLE public.family_members IS 'Family members (demographics) owned by the logged-in user';

-- -----------------------------------------------------------------------------
-- 3. CALENDAR_EVENTS – RHU / system health events (e.g. clinic schedule)
-- Optional: used for “what’s on” on the calendar.
-- -----------------------------------------------------------------------------
CREATE TYPE public.health_event_group AS ENUM (
  'buntis',
  'bata',
  'adolescent',
  'adult',
  'elderly'
);

CREATE TABLE public.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_date date NOT NULL,
  group_type public.health_event_group NOT NULL,
  title text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_calendar_events_date ON public.calendar_events(event_date);

COMMENT ON TABLE public.calendar_events IS 'System/RHU health events (e.g. prenatal day, immunization day)';

-- -----------------------------------------------------------------------------
-- 4. APPOINTMENTS – user-specific appointments / reminders
-- Optional: links to a family member.
-- -----------------------------------------------------------------------------
CREATE TABLE public.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id uuid REFERENCES public.family_members(id) ON DELETE SET NULL,
  event_date date NOT NULL,
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX idx_appointments_event_date ON public.appointments(event_date);

COMMENT ON TABLE public.appointments IS 'User appointments / reminders; optionally tied to a family member';

-- -----------------------------------------------------------------------------
-- 5. Trigger: update updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER family_members_updated_at
  BEFORE UPDATE ON public.family_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 6. Row Level Security (RLS)
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Profiles: user can read/update own row only; insert allowed for own user_id
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Family members: user can CRUD only their own rows
CREATE POLICY "Users can view own family members"
  ON public.family_members FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own family members"
  ON public.family_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own family members"
  ON public.family_members FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own family members"
  ON public.family_members FOR DELETE
  USING (auth.uid() = user_id);

-- Calendar events: readable by all authenticated users (system data)
CREATE POLICY "Authenticated users can view calendar events"
  ON public.calendar_events FOR SELECT
  TO authenticated
  USING (true);

-- Appointments: user can CRUD only their own
CREATE POLICY "Users can view own appointments"
  ON public.appointments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own appointments"
  ON public.appointments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own appointments"
  ON public.appointments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own appointments"
  ON public.appointments FOR DELETE
  USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 7. Optional: create profile on signup (Supabase Auth trigger)
-- Inserts a row into profiles when a new user signs up.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
