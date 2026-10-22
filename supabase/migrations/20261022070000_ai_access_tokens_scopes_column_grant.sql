-- Fix Acceso IA: the MCP PAT scopes column was added in 20261022004000,
-- but the original per-column SELECT whitelist did not include it.
-- The iOS screen explicitly selects scopes; PostgreSQL rejected the request.
--
-- Keep column-level grants. NEVER grant SELECT on token_hash or blanket
-- SELECT on the table. Existing owner-only RLS policies remain unchanged.
GRANT SELECT (scopes) ON TABLE public.ai_access_tokens TO authenticated;

DO $$
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.ai_access_tokens'::regclass) THEN
    RAISE EXCEPTION 'RLS must remain enabled on ai_access_tokens';
  END IF;
  IF has_column_privilege('authenticated','public.ai_access_tokens','token_hash','SELECT') THEN
    RAISE EXCEPTION 'PAT digest must not be readable by authenticated';
  END IF;
  IF has_column_privilege('anon','public.ai_access_tokens','scopes','SELECT') THEN
    RAISE EXCEPTION 'Anonymous roles must not read token scopes';
  END IF;
END $$;
