-- Run manually as database admin in staging. Test is transactional and leaves
-- neither profiles nor calendar examples in production.
BEGIN;
SELECT set_config('repera.ai_test_owner',(SELECT id::text FROM auth.users LIMIT 1),true);
INSERT INTO public.athlete_training_profiles(owner_id,primary_goal,coaching_enabled)
VALUES(current_setting('repera.ai_test_owner')::uuid,'strength',true)
ON CONFLICT(owner_id) DO UPDATE SET primary_goal='strength',coaching_enabled=true;
INSERT INTO public.athlete_training_calendar_snapshots(owner_id,items,horizon_start,horizon_end)
VALUES(current_setting('repera.ai_test_owner')::uuid,
  '[{"title":"RLS smoke, sports only"}]'::jsonb,current_date,current_date+90)
ON CONFLICT(owner_id) DO UPDATE SET items=EXCLUDED.items;
SELECT set_config('request.jwt.claims',jsonb_build_object(
  'sub',current_setting('repera.ai_test_owner'),'role','authenticated')::text,true);
SET LOCAL ROLE authenticated;
DO $$BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.athlete_training_profiles)
    OR NOT EXISTS(SELECT 1 FROM public.athlete_training_calendar_snapshots)
  THEN RAISE EXCEPTION 'Owner cannot read AI profile/calendar'; END IF;
  IF has_table_privilege('authenticated','public.athlete_training_programs','INSERT')
  THEN RAISE EXCEPTION 'Native user can create server-only program'; END IF;
END$$;
SELECT set_config('request.jwt.claims',jsonb_build_object(
  'sub',gen_random_uuid()::text,'role','authenticated')::text,true);
DO $$BEGIN
  IF EXISTS(SELECT 1 FROM public.athlete_training_profiles)
    OR EXISTS(SELECT 1 FROM public.athlete_training_calendar_snapshots)
    OR EXISTS(SELECT 1 FROM public.athlete_training_programs)
  THEN RAISE EXCEPTION 'Cross-user AI training data leak'; END IF;
END$$;
ROLLBACK;
