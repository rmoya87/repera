-- Fine-grained, revocable personal MCP permissions.
-- Legacy credentials keep existing read/write behavior. New credentials may
-- be restricted to training:read. This is NOT a third-party OAuth grant.
ALTER TABLE public.ai_access_tokens
 ADD COLUMN IF NOT EXISTS scopes text[] NOT NULL
 DEFAULT ARRAY['training:read','training:write']::text[];
ALTER TABLE public.ai_access_tokens
 ADD CONSTRAINT ai_access_tokens_scope_vocabulary
 CHECK (scopes <@ ARRAY['training:read','training:write']::text[]
    AND scopes @> ARRAY['training:read']::text[]
    AND cardinality(scopes) BETWEEN 1 AND 2);
