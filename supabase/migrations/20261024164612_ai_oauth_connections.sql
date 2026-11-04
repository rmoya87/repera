-- OAuth credentials are confined to MCP; existing personal tokens remain valid.
CREATE SCHEMA IF NOT EXISTS repera_oauth;
REVOKE ALL ON SCHEMA repera_oauth FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA repera_oauth TO service_role, supabase_auth_admin;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'repera_mcp') THEN
    CREATE ROLE repera_mcp NOLOGIN NOINHERIT;
  END IF;
END $$;
-- Intentionally NOT granted to authenticator: OAuth JWTs cannot call Data API,
-- RPC or Storage with the athlete's normal authenticated role.
CREATE TABLE public.ai_oauth_providers (
  id text PRIMARY KEY CHECK (id IN ('chatgpt','claude')),
  name text NOT NULL,
  client_id uuid UNIQUE,
  directory_url text,
  enabled boolean NOT NULL DEFAULT false,
  CHECK (NOT enabled OR client_id IS NOT NULL),
  CHECK (directory_url IS NULL OR directory_url LIKE 'https://%')
);
ALTER TABLE public.ai_oauth_providers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_oauth_providers FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.ai_oauth_providers TO service_role;
INSERT INTO public.ai_oauth_providers(id,name) VALUES ('chatgpt','ChatGPT'),('claude','Claude');

ALTER TABLE public.ai_access_tokens ADD COLUMN oauth_client_id uuid;
GRANT SELECT(oauth_client_id) ON public.ai_access_tokens TO authenticated;
CREATE UNIQUE INDEX ai_oauth_active_client ON public.ai_access_tokens(owner_id,oauth_client_id)
  WHERE oauth_client_id IS NOT NULL AND revoked_at IS NULL;

-- Supabase's access-token hook must be enabled BEFORE enabling OAuth Server.
-- All delegated clients receive an isolated role, including unknown clients.
-- No user_metadata or client-supplied scopes can elevate these permissions.
CREATE FUNCTION repera_oauth.access_token_hook(event jsonb) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = '' AS $$
DECLARE claims jsonb := event->'claims';
BEGIN
  IF coalesce(event->>'client_id', claims->>'client_id') IS NOT NULL THEN
    claims := jsonb_set(claims, '{role}', '"repera_mcp"'::jsonb);
    claims := jsonb_set(claims, '{aud}', '"https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp"'::jsonb);
    RETURN jsonb_set(event, '{claims}', claims);
  END IF;
  RETURN event;
END $$;
REVOKE ALL ON FUNCTION repera_oauth.access_token_hook(jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION repera_oauth.access_token_hook(jsonb) TO supabase_auth_admin;

-- Called only by the verified native-session Edge Function. Lock the athlete
-- so simultaneous consent screens cannot leave multiple active grants.
CREATE FUNCTION public.create_ai_oauth_grant(p_owner uuid,p_client uuid,p_write boolean,p_hash text)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE provider public.ai_oauth_providers; grant_id uuid;
BEGIN
  SELECT * INTO provider FROM public.ai_oauth_providers WHERE client_id=p_client AND enabled;
  IF NOT FOUND THEN RAISE EXCEPTION 'Client unavailable'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  UPDATE public.ai_access_tokens SET revoked_at=now()
    WHERE owner_id=p_owner AND oauth_client_id=p_client AND revoked_at IS NULL;
  INSERT INTO public.ai_access_tokens(owner_id,label,token_prefix,token_hash,scopes,oauth_client_id)
    VALUES(p_owner,provider.name,'oauth_access',p_hash,
      CASE WHEN p_write THEN ARRAY['training:read','training:write'] ELSE ARRAY['training:read'] END,p_client)
    RETURNING id INTO grant_id;
  RETURN grant_id;
END $$;
REVOKE ALL ON FUNCTION public.create_ai_oauth_grant(uuid,uuid,boolean,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.create_ai_oauth_grant(uuid,uuid,boolean,text) TO service_role;

-- Auth.sessions is private; this narrowly scoped function exposes no session
-- data. It also prevents an old refresh session reviving a reconnected grant.
CREATE FUNCTION repera_oauth.resolve_grant(p_owner uuid,p_client uuid,p_session uuid)
RETURNS SETOF public.ai_access_tokens LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT t.* FROM public.ai_access_tokens t
 JOIN public.ai_oauth_providers p ON p.client_id=t.oauth_client_id AND p.enabled
 JOIN auth.sessions s ON s.id=p_session AND s.user_id=t.owner_id AND s.oauth_client_id=p_client
 WHERE t.owner_id=p_owner AND t.oauth_client_id=p_client AND t.revoked_at IS NULL
   AND (t.expires_at IS NULL OR t.expires_at>now())
   AND s.created_at>=t.created_at AND (s.not_after IS NULL OR s.not_after>now())
$$;
REVOKE ALL ON FUNCTION repera_oauth.resolve_grant(uuid,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION repera_oauth.resolve_grant(uuid,uuid,uuid) TO service_role;
CREATE FUNCTION public.resolve_ai_oauth_grant(p_owner uuid,p_client uuid,p_session uuid)
RETURNS TABLE(id uuid,owner_id uuid,expires_at timestamptz,scopes text[])
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
 SELECT g.id,g.owner_id,g.expires_at,g.scopes FROM repera_oauth.resolve_grant(p_owner,p_client,p_session) g
$$;
REVOKE ALL ON FUNCTION public.resolve_ai_oauth_grant(uuid,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_ai_oauth_grant(uuid,uuid,uuid) TO service_role;
