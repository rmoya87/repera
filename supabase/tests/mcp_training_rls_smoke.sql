-- Safe, read-only RLS acceptance smoke. Requires an Auth user to make the test
-- meaningful; if no user exists, the synthetic ID still checks default denial.
-- Does not modify any Repera row. Full 2-user and write-denial E2E tests
-- remain a release gate (see docs/MCP_PLAN.md).
BEGIN;
SELECT set_config('request.jwt.claims',
  jsonb_build_object(
    'sub', coalesce((SELECT id::text FROM auth.users LIMIT 1), gen_random_uuid()::text),
    'role', 'authenticated',
    'client_id', 'repera-negative-smoke-client'
  )::text, true);
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.athlete_workouts LIMIT 1) THEN
    RAISE EXCEPTION 'Security regression: unapproved OAuth client sees private workouts';
  END IF;
  IF EXISTS (SELECT 1 FROM public.mcp_user_consents WHERE enabled LIMIT 1) THEN
    RAISE EXCEPTION 'Security regression: unapproved OAuth client sees another grant';
  END IF;
END
$$;
ROLLBACK;
