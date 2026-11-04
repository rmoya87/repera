-- Repera AI coach: additive, privacy-minimizing, backwards compatible.
-- No HealthKit, location, notes, medical or body measurements.
CREATE TABLE public.training_exercise_metadata (
 catalog_key text PRIMARY KEY REFERENCES public.business_exercise_catalog(catalog_key) ON DELETE CASCADE,
 aliases text[] NOT NULL DEFAULT '{}',
 primary_muscles text[] NOT NULL DEFAULT '{}',
 secondary_muscles text[] NOT NULL DEFAULT '{}',
 equipment text[] NOT NULL DEFAULT '{}',
 movement_pattern text,
 skill_level text CHECK (skill_level IS NULL OR skill_level IN ('beginner','intermediate','advanced')),
 alternatives text[] NOT NULL DEFAULT '{}',
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (cardinality(aliases)<=30 AND cardinality(primary_muscles)<=12 AND cardinality(secondary_muscles)<=12 AND cardinality(equipment)<=12 AND cardinality(alternatives)<=20)
);
INSERT INTO public.training_exercise_metadata(catalog_key)
SELECT catalog_key FROM public.business_exercise_catalog ON CONFLICT DO NOTHING;
ALTER TABLE public.training_exercise_metadata ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.training_exercise_metadata FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.training_exercise_metadata TO authenticated;
CREATE POLICY training_exercise_metadata_read ON public.training_exercise_metadata
 FOR SELECT TO authenticated USING (true);

-- Opt-in coaching settings: only sporting goals, availability and equipment.
CREATE TABLE public.athlete_training_profiles (
 owner_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 primary_goal text NOT NULL DEFAULT 'general' CHECK (primary_goal IN ('general','strength','hypertrophy','endurance','crossfit','weightlifting','mobility')),
 experience_level text NOT NULL DEFAULT 'unspecified' CHECK (experience_level IN ('unspecified','beginner','intermediate','advanced')),
 training_days_per_week int CHECK (training_days_per_week BETWEEN 1 AND 7),
 preferred_weekdays int[] NOT NULL DEFAULT '{}',
 session_minutes int CHECK (session_minutes BETWEEN 15 AND 240),
 equipment text[] NOT NULL DEFAULT '{}',
 preferences jsonb NOT NULL DEFAULT '{}'::jsonb,
 coaching_enabled boolean NOT NULL DEFAULT false,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (cardinality(preferred_weekdays)<=7 AND preferred_weekdays <@ ARRAY[1,2,3,4,5,6,7]::int[]),
 CHECK (cardinality(equipment)<=30),
 CHECK (jsonb_typeof(preferences)='object' AND pg_column_size(preferences)<8192)
);
ALTER TABLE public.athlete_training_profiles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.athlete_training_profiles FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.athlete_training_profiles TO authenticated;
CREATE POLICY training_profile_owner_select ON public.athlete_training_profiles FOR SELECT TO authenticated
 USING(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY training_profile_owner_insert ON public.athlete_training_profiles FOR INSERT TO authenticated
 WITH CHECK(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY training_profile_owner_update ON public.athlete_training_profiles FOR UPDATE TO authenticated
 USING(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY training_profile_owner_delete ON public.athlete_training_profiles FOR DELETE TO authenticated
 USING(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);

-- Atomic snapshot solves stale deletion and concurrent day edits without uploading
-- raw Routine or its notes. Only the most recently synced phone snapshot is present.
CREATE TABLE public.athlete_training_calendar_snapshots (
 owner_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 items jsonb NOT NULL DEFAULT '[]'::jsonb,
 horizon_start date NOT NULL DEFAULT current_date,
 horizon_end date NOT NULL DEFAULT current_date + 90,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (jsonb_typeof(items)='array' AND jsonb_array_length(items)<=500 AND pg_column_size(items)<300000),
 CHECK (horizon_end >= horizon_start AND horizon_end <= horizon_start + 180)
);
ALTER TABLE public.athlete_training_calendar_snapshots ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.athlete_training_calendar_snapshots FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.athlete_training_calendar_snapshots TO authenticated;
CREATE POLICY training_calendar_owner_select ON public.athlete_training_calendar_snapshots FOR SELECT TO authenticated
 USING(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY training_calendar_owner_insert ON public.athlete_training_calendar_snapshots FOR INSERT TO authenticated
 WITH CHECK(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY training_calendar_owner_update ON public.athlete_training_calendar_snapshots FOR UPDATE TO authenticated
 USING(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY training_calendar_owner_delete ON public.athlete_training_calendar_snapshots FOR DELETE TO authenticated
 USING(owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);

-- Durable medium/long term programme macrocycles. Proposal-only: never
-- overwrites athlete sessions. Phases are bounded, versioned and inspectable.
CREATE TABLE public.athlete_training_programs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 created_by_token_id uuid REFERENCES public.ai_access_tokens(id) ON DELETE SET NULL,
 title text NOT NULL CHECK (length(title) BETWEEN 2 AND 120),
 primary_goal text NOT NULL CHECK (length(primary_goal) BETWEEN 2 AND 500),
 start_date date NOT NULL,
 duration_weeks int NOT NULL CHECK (duration_weeks BETWEEN 1 AND 52),
 phases jsonb NOT NULL CHECK (jsonb_typeof(phases)='array' AND jsonb_array_length(phases) BETWEEN 1 AND 12 AND pg_column_size(phases)<16000),
 status text NOT NULL DEFAULT 'proposed' CHECK(status IN ('proposed','active','paused','completed','cancelled')),
 revision int NOT NULL DEFAULT 1 CHECK(revision BETWEEN 1 AND 10000),
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX training_programs_owner_idx ON public.athlete_training_programs(owner_id,start_date DESC);
ALTER TABLE public.athlete_training_programs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.athlete_training_programs FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.athlete_training_programs TO authenticated;
GRANT UPDATE(status,updated_at) ON public.athlete_training_programs TO authenticated;
CREATE POLICY programs_owner_select ON public.athlete_training_programs FOR SELECT TO authenticated
 USING (owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY programs_owner_status ON public.athlete_training_programs FOR UPDATE TO authenticated
 USING (owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK (owner_id=(select auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
ALTER TABLE public.ai_training_plans ADD COLUMN program_id uuid REFERENCES public.athlete_training_programs(id) ON DELETE SET NULL;
CREATE INDEX ai_training_plans_program_idx ON public.ai_training_plans(program_id,scheduled_date);
