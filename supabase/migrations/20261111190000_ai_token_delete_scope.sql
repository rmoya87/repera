-- Fine-grained delete permission for MCP PATs (archive/delete tools).
-- Read remains mandatory; write and delete are optional.

ALTER TABLE public.ai_access_tokens
  DROP CONSTRAINT IF EXISTS ai_access_tokens_scope_vocabulary;

ALTER TABLE public.ai_access_tokens
  ADD CONSTRAINT ai_access_tokens_scope_vocabulary
  CHECK (
    scopes <@ ARRAY['training:read','training:write','training:delete']::text[]
    AND scopes @> ARRAY['training:read']::text[]
    AND cardinality(scopes) BETWEEN 1 AND 3
  );

COMMENT ON CONSTRAINT ai_access_tokens_scope_vocabulary ON public.ai_access_tokens IS
  'PAT scopes: training:read required; training:write and training:delete optional.';
