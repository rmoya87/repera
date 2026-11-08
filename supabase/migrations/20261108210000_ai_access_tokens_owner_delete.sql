-- Owner may hard-delete own AI access rows (swipe-to-remove in Conecta tu IA),
-- including already-revoked connections that would otherwise clutter the list.
-- Soft revoke (Desactivar) remains UPDATE(revoked_at) only.

GRANT DELETE ON public.ai_access_tokens TO authenticated;

CREATE POLICY ai_tokens_own_delete ON public.ai_access_tokens
  FOR DELETE TO authenticated
  USING (owner_id = (SELECT auth.uid()));
