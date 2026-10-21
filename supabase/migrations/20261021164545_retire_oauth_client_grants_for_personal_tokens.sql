-- Applied Supabase migration version 20261021164545. No OAuth user grants
-- existed; migrate to personal tokens without deleting athlete history.
DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM public.mcp_user_consents LIMIT 1) THEN
   RAISE EXCEPTION 'Cannot retire OAuth consents: grants are not empty';
 END IF;
END $$;
ALTER POLICY athlete_workout_private_select ON public.athlete_workout_mirror
 USING (
   owner_id = (SELECT auth.uid())
   AND (auth.jwt() ->> 'client_id') IS NULL
 );
DROP TABLE public.mcp_user_consents RESTRICT;
