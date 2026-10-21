-- Transactional E2E policy smoke. No permanent data changes.
BEGIN;
INSERT INTO public.ai_access_tokens(owner_id,label,token_prefix,token_hash,expires_at)
 SELECT id,'Temporary RLS smoke','rep_ai_smoke',repeat('a',64),now()+interval '1 day'
 FROM auth.users LIMIT 1;
INSERT INTO public.ai_training_plans(owner_id,title,scheduled_date,payload)
 SELECT id,'Temporary AI plan',CURRENT_DATE+1,
 '{"schemaVersion":1,"blocks":[{"kind":"strength","title":"Test","exercises":[],"movements":[]}]}'::jsonb
 FROM auth.users LIMIT 1;

SELECT set_config('request.jwt.claims',jsonb_build_object(
  'sub',(SELECT id::text FROM auth.users LIMIT 1),'role','authenticated'
)::text,true);
SET LOCAL ROLE authenticated;

DO $$
BEGIN
  IF has_column_privilege('authenticated','public.ai_access_tokens','token_hash','SELECT')
    THEN RAISE EXCEPTION 'Unauthorized SELECT on token_hash'; END IF;
  IF (SELECT count(*) FROM public.ai_access_tokens WHERE label='Temporary RLS smoke') <> 1
    THEN RAISE EXCEPTION 'Owner token metadata not visible'; END IF;
  IF (SELECT count(*) FROM public.ai_training_plans WHERE title='Temporary AI plan') <> 1
    THEN RAISE EXCEPTION 'Owner training inbox not visible'; END IF;
END $$;
UPDATE public.ai_access_tokens SET revoked_at=now() WHERE label='Temporary RLS smoke';
UPDATE public.ai_training_plans SET status='applied',applied_at=now() WHERE title='Temporary AI plan';
DO $$
BEGIN
  IF (SELECT count(*) FROM public.ai_access_tokens WHERE label='Temporary RLS smoke' AND revoked_at IS NOT NULL) <> 1
    THEN RAISE EXCEPTION 'Native revoke failed'; END IF;
  IF (SELECT count(*) FROM public.ai_training_plans WHERE title='Temporary AI plan' AND status='applied') <> 1
    THEN RAISE EXCEPTION 'Native plan ack failed'; END IF;
END $$;

SELECT set_config('request.jwt.claims',jsonb_build_object(
  'sub',gen_random_uuid()::text,'role','authenticated'
)::text,true);
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.ai_access_tokens)
    OR EXISTS (SELECT 1 FROM public.ai_training_plans)
    OR EXISTS (SELECT 1 FROM public.athlete_workouts)
    THEN RAISE EXCEPTION 'Cross-athlete data disclosure'; END IF;
END $$;
ROLLBACK;
