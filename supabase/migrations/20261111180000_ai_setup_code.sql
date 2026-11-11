-- One-time setup codes (15 min) for revealing a PAT on repera.app/ai/?code=
-- Ciphertext is only readable by service_role (Edge). No GRANT to authenticated/anon.
-- (Column privileges stay revoked; Edge uses service_role.)

ALTER TABLE public.ai_access_tokens
  ADD COLUMN IF NOT EXISTS setup_code_hash text,
  ADD COLUMN IF NOT EXISTS setup_code_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS setup_code_used_at timestamptz,
  ADD COLUMN IF NOT EXISTS setup_reveal_ciphertext text;

CREATE UNIQUE INDEX IF NOT EXISTS ai_setup_code_hash_active
  ON public.ai_access_tokens (setup_code_hash)
  WHERE setup_code_hash IS NOT NULL AND setup_code_used_at IS NULL;

COMMENT ON COLUMN public.ai_access_tokens.setup_code_hash IS
  'SHA-256 hex of one-time setup code; cleared or marked used after redeem.';
COMMENT ON COLUMN public.ai_access_tokens.setup_reveal_ciphertext IS
  'AES-GCM blob (b64url) of PAT encrypted with key derived from setup code; wiped after redeem/expiry.';
