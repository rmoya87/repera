-- Harden invoker-safe catalog view; the underlying table already permits authenticated SELECT and enforces RLS.
ALTER VIEW public.training_exercise_catalog SET (security_invoker = true);
-- Prevent any unauthenticated invocation of privileged business operations.
REVOKE ALL ON FUNCTION public.class_occurrence_roster(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.delete_managed_occurrence(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_org_booking_window(uuid,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.class_occurrence_roster(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_managed_occurrence(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_org_booking_window(uuid,integer) TO authenticated, service_role;
-- Immutable helper uses no objects or unqualified identifiers; immutable behavior remains unchanged.
ALTER FUNCTION private.pass_kind_matches_occurrence(text,text) SET search_path TO '';