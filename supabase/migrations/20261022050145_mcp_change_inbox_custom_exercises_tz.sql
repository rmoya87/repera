-- AI requests are proposals, NOT direct writes to iCloud-authoritative records.
-- Athletes must approve every mutation on their own unlocked iPhone.
CREATE TABLE public.ai_athlete_change_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 token_id uuid REFERENCES public.ai_access_tokens(id) ON DELETE SET NULL,
 operation text NOT NULL CHECK (operation IN
  ('update_workout','delete_workout','create_exercise','update_exercise','delete_exercise')),
 target_id uuid,
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object' AND pg_column_size(payload)<32768),
 expected_updated_at timestamptz,
 status text NOT NULL DEFAULT 'pending' CHECK
  (status IN ('pending','applied','rejected','conflict')),
 created_at timestamptz NOT NULL DEFAULT now(),
 decided_at timestamptz,
 decision_message text,
 CHECK (
  (operation='create_exercise' AND target_id IS NULL)
  OR (operation<>'create_exercise' AND target_id IS NOT NULL)
 )
);
CREATE INDEX ai_athlete_changes_owner_queue ON public.ai_athlete_change_requests(owner_id,status,created_at);
ALTER TABLE public.ai_athlete_change_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_athlete_change_requests FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.ai_athlete_change_requests TO authenticated;
GRANT UPDATE(status,decided_at,decision_message) ON public.ai_athlete_change_requests TO authenticated;
CREATE POLICY ai_changes_owner_read ON public.ai_athlete_change_requests FOR SELECT TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY ai_changes_owner_decide ON public.ai_athlete_change_requests FOR UPDATE TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND status='pending' AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK (owner_id=(SELECT auth.uid()) AND status IN ('applied','rejected','conflict')
  AND decided_at IS NOT NULL AND (auth.jwt()->>'client_id') IS NULL);
-- Custom exercise catalog is a PRIVATE mirror, separate from curated public catalog.
CREATE TABLE public.athlete_custom_exercise_mirror (
 owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 exercise_id uuid NOT NULL,
 name text NOT NULL CHECK(char_length(name) BETWEEN 2 AND 120),
 muscle_group text NOT NULL CHECK(char_length(muscle_group) BETWEEN 2 AND 80),
 equipment text,
 target_muscle text,
 secondary_muscles text[] NOT NULL DEFAULT '{}',
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(owner_id,exercise_id),
 CHECK(cardinality(secondary_muscles)<=12)
);
CREATE INDEX athlete_custom_exercises_owner_name ON public.athlete_custom_exercise_mirror(owner_id,name);
ALTER TABLE public.athlete_custom_exercise_mirror ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.athlete_custom_exercise_mirror FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.athlete_custom_exercise_mirror TO authenticated;
CREATE POLICY custom_exercise_owner_select ON public.athlete_custom_exercise_mirror FOR SELECT TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY custom_exercise_owner_insert ON public.athlete_custom_exercise_mirror FOR INSERT TO authenticated
 WITH CHECK (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY custom_exercise_owner_update ON public.athlete_custom_exercise_mirror FOR UPDATE TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY custom_exercise_owner_delete ON public.athlete_custom_exercise_mirror FOR DELETE TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
-- Wall date + timezone + explicit DST-disambiguating UTC offset, plus resolved instant.
ALTER TABLE public.ai_training_plans
 ADD COLUMN scheduled_time_zone text,
 ADD COLUMN scheduled_utc_offset_minutes integer,
 ADD COLUMN scheduled_at timestamptz,
 ADD CONSTRAINT ai_plan_explicit_time_zone CHECK (
   (scheduled_time_minutes IS NULL AND scheduled_at IS NULL AND scheduled_utc_offset_minutes IS NULL)
   OR
   (scheduled_time_minutes IS NOT NULL AND scheduled_time_zone IS NOT NULL
    AND scheduled_at IS NOT NULL AND scheduled_utc_offset_minutes BETWEEN -840 AND 840)
 ),
 ADD CONSTRAINT ai_plan_time_zone_format CHECK (
   scheduled_time_zone IS NULL OR (char_length(scheduled_time_zone) BETWEEN 3 AND 80
   AND scheduled_time_zone ~ '^[A-Za-z_]+/[A-Za-z_+-]+(/[A-Za-z_+-]+)?$')
 );
-- Historical rows with a time but no explicit zone remain legible and editable;
-- the new constraint applies only to new or changed rows, not legacy data.
ALTER TABLE public.ai_training_plans DROP CONSTRAINT ai_plan_explicit_time_zone;
ALTER TABLE public.ai_training_plans
 ADD CONSTRAINT ai_plan_explicit_time_zone CHECK (
   (scheduled_at IS NULL AND scheduled_utc_offset_minutes IS NULL)
   OR (scheduled_time_minutes IS NOT NULL AND scheduled_time_zone IS NOT NULL
       AND scheduled_at IS NOT NULL AND scheduled_utc_offset_minutes BETWEEN -840 AND 840)
 );
