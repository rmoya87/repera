-- Applied to Repera Supabase as version 20261021161255.
-- Keep the backing table for existing TestFlight/iOS upsert(onConflict: "id") callers.
-- Guard destructive operations: fail atomically if an old table gained real rows.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.routine_exercises LIMIT 1)
     OR EXISTS (SELECT 1 FROM public.workout_sets LIMIT 1)
     OR EXISTS (SELECT 1 FROM public.routines LIMIT 1)
     OR EXISTS (SELECT 1 FROM public.workouts LIMIT 1)
     OR EXISTS (SELECT 1 FROM public.exercises LIMIT 1)
  THEN
    RAISE EXCEPTION 'Refusing to remove non-empty legacy training tables';
  END IF;
END $$;
DROP TABLE public.routine_exercises RESTRICT;
DROP TABLE public.workout_sets RESTRICT;
DROP TABLE public.routines RESTRICT;
DROP TABLE public.workouts RESTRICT;
DROP TABLE public.exercises RESTRICT;

-- Read-only interface for AI and reporting: excludes GPS/HealthKit/private notes.
-- Postgres 17 security_invoker makes the original workout RLS apply to the view.
CREATE VIEW public.athlete_workouts
WITH (security_invoker = true)
AS SELECT id, owner_id, title, started_at, finished_at,
          coalesce(payload -> 'exercises', '[]'::jsonb) AS exercises,
          coalesce(payload -> 'wodResults', '[]'::jsonb) AS wod_results,
          created_at, updated_at
   FROM public.athlete_workout_mirror
   WHERE deleted_at IS NULL;
REVOKE ALL ON public.athlete_workouts FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.athlete_workouts TO authenticated;

-- Non-breaking read alias while the professional panel uses its existing table.
CREATE VIEW public.training_exercise_catalog
WITH (security_invoker = true)
AS SELECT catalog_key, name, category FROM public.business_exercise_catalog;
REVOKE ALL ON public.training_exercise_catalog FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.training_exercise_catalog TO authenticated;
