-- Receive AI workouts over authenticated Supabase Realtime Postgres Changes.
-- ai_training_plans already has owner_id SELECT RLS for authenticated users.
-- Avoid publishing tokens or the broader private workout mirror.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'ai_training_plans'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ai_training_plans;
  END IF;
END
$$;
