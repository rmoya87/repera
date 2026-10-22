-- Transactional acceptance smoke: NO durable user data written.
BEGIN;
SELECT set_config('repera.test_owner',(SELECT id::text FROM auth.users LIMIT 1),true);
INSERT INTO public.ai_athlete_change_requests(owner_id,operation,target_id,payload)
VALUES(current_setting('repera.test_owner')::uuid,'delete_workout',gen_random_uuid(),'{}');
INSERT INTO public.athlete_custom_exercise_mirror(owner_id,exercise_id,name,muscle_group)
VALUES(current_setting('repera.test_owner')::uuid,gen_random_uuid(),'RLS check','strength');
SELECT set_config('request.jwt.claims',
 jsonb_build_object('sub',current_setting('repera.test_owner'),'role','authenticated')::text,true);
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 IF (SELECT count(*) FROM public.ai_athlete_change_requests)<>1
  OR (SELECT count(*) FROM public.athlete_custom_exercise_mirror)<>1
 THEN RAISE EXCEPTION 'Owner cannot read AI private change/catalog'; END IF;
 IF has_table_privilege('authenticated','public.ai_athlete_change_requests','INSERT')
  OR has_table_privilege('authenticated','public.ai_athlete_change_requests','DELETE')
  OR has_column_privilege('authenticated','public.ai_athlete_change_requests','payload','UPDATE')
 THEN RAISE EXCEPTION 'Native app can insert/delete/change AI proposals'; END IF;
END $$;
SELECT set_config('request.jwt.claims',
 jsonb_build_object('sub',gen_random_uuid()::text,'role','authenticated')::text,true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.ai_athlete_change_requests)
  OR EXISTS(SELECT 1 FROM public.athlete_custom_exercise_mirror)
 THEN RAISE EXCEPTION 'Cross-user workout change/custom exercise leak'; END IF;
END $$;
ROLLBACK;
