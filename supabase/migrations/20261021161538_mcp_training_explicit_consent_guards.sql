-- Applied in Supabase Repera on 2026-10-21 (version 20261021161538).
-- OAuth clients never inherit unrestricted workout reads or write permissions.
-- Grants must be created from a normal signed-in app session, not an OAuth token.
CREATE TABLE public.mcp_user_consents (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id text NOT NULL CHECK (length(client_id) BETWEEN 2 AND 200),
  enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id,client_id)
);
ALTER TABLE public.mcp_user_consents ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.mcp_user_consents FROM PUBLIC, anon, authenticated;
GRANT SELECT,INSERT,UPDATE(enabled,updated_at),DELETE ON public.mcp_user_consents TO authenticated;
CREATE POLICY mcp_grants_select ON public.mcp_user_consents FOR SELECT TO authenticated
  USING (
    user_id = (select auth.uid()) AND
    ((auth.jwt() ->> 'client_id') IS NULL OR client_id = (auth.jwt() ->> 'client_id'))
  );
CREATE POLICY mcp_grants_insert ON public.mcp_user_consents FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL
  );
CREATE POLICY mcp_grants_update ON public.mcp_user_consents FOR UPDATE TO authenticated
  USING (user_id=(select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL)
  WITH CHECK (user_id=(select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL);
CREATE POLICY mcp_grants_delete ON public.mcp_user_consents FOR DELETE TO authenticated
  USING (user_id=(select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL);
ALTER POLICY athlete_workout_private_select ON public.athlete_workout_mirror
  USING (
    owner_id = (select auth.uid()) AND
    ((auth.jwt() ->> 'client_id') IS NULL OR EXISTS (
      SELECT 1 FROM public.mcp_user_consents c
      WHERE c.user_id = (select auth.uid())
        AND c.client_id = (auth.jwt() ->> 'client_id') AND c.enabled
    ))
  );
ALTER POLICY athlete_workout_private_insert ON public.athlete_workout_mirror
  WITH CHECK (owner_id = (select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL);
ALTER POLICY athlete_workout_private_update ON public.athlete_workout_mirror
  USING (owner_id = (select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL)
  WITH CHECK (owner_id = (select auth.uid()) AND (auth.jwt() ->> 'client_id') IS NULL);
