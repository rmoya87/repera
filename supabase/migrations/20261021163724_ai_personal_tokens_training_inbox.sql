-- PAT-only Repera AI integration. Physical tokens never stored or retrievable.
-- SHA-256 digest of a server-generated 256-bit random token is sufficient:
-- reversible encryption would create unnecessary risk.
CREATE TABLE public.ai_access_tokens (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 label text NOT NULL CHECK (char_length(label) BETWEEN 1 AND 80),
 token_prefix text NOT NULL CHECK (char_length(token_prefix) BETWEEN 8 AND 36),
 token_hash text NOT NULL UNIQUE CHECK (token_hash ~ '^[a-f0-9]{64}$'),
 created_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz,
 revoked_at timestamptz,
 last_used_at timestamptz,
 CONSTRAINT ai_token_expiry_later CHECK (expires_at IS NULL OR expires_at > created_at)
);
CREATE INDEX ai_access_tokens_owner_idx ON public.ai_access_tokens(owner_id,created_at DESC);
ALTER TABLE public.ai_access_tokens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_access_tokens FROM PUBLIC,anon,authenticated;
GRANT SELECT(id,owner_id,label,token_prefix,created_at,expires_at,revoked_at,last_used_at) ON public.ai_access_tokens TO authenticated;
GRANT UPDATE(revoked_at) ON public.ai_access_tokens TO authenticated;
CREATE POLICY ai_tokens_own_read ON public.ai_access_tokens FOR SELECT TO authenticated
 USING (owner_id = (SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY ai_tokens_own_revoke ON public.ai_access_tokens FOR UPDATE TO authenticated
 USING (owner_id = (SELECT auth.uid()) AND revoked_at IS NULL AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK (owner_id = (SELECT auth.uid()) AND revoked_at IS NOT NULL AND (auth.jwt()->>'client_id') IS NULL);

-- The AI server writes pending drafts only. The authenticated iPhone converts
-- these to native, dated Routine/Block/WOD and ACKs after local persistence.
CREATE TABLE public.ai_training_plans (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 created_by_token_id uuid REFERENCES public.ai_access_tokens(id) ON DELETE SET NULL,
 batch_id uuid NOT NULL DEFAULT gen_random_uuid(),
 title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 120),
 scheduled_date date NOT NULL,
 scheduled_time_minutes int CHECK (scheduled_time_minutes BETWEEN 0 AND 1439),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object' AND pg_column_size(payload) < 65536),
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','applied','dismissed')),
 created_at timestamptz NOT NULL DEFAULT now(),
 applied_at timestamptz
);
CREATE INDEX ai_training_plans_owner_pending_idx ON public.ai_training_plans(owner_id,status,scheduled_date);
ALTER TABLE public.ai_training_plans ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_training_plans FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.ai_training_plans TO authenticated;
GRANT UPDATE(status,applied_at) ON public.ai_training_plans TO authenticated;
CREATE POLICY ai_plans_own_read ON public.ai_training_plans FOR SELECT TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY ai_plans_own_accept ON public.ai_training_plans FOR UPDATE TO authenticated
 USING (owner_id=(SELECT auth.uid()) AND status='pending' AND (auth.jwt()->>'client_id') IS NULL)
 WITH CHECK (owner_id=(SELECT auth.uid()) AND status IN ('applied','dismissed') AND (auth.jwt()->>'client_id') IS NULL);
