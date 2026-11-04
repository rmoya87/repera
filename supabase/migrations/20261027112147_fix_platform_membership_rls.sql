-- Fix 42501 when authenticated members read organization_memberships.
-- The old permissive policy referenced platform_admin_delegations directly:
-- authenticated has no SELECT on that table, intentionally.
-- PostgreSQL evaluates applicable RLS policies even when the actor has no
-- delegation, causing the whole membership read to fail.
-- The original memberships_select_authorized policy already delegates to
-- private.has_org_role(), a SECURITY DEFINER helper which verifies active
-- platform delegation and actual owner/admin roles securely.
drop policy if exists memberships_platform_delegated_read on public.organization_memberships;

-- Keep delegated access mediated by private.has_org_role(); do not expose
-- platform_admin_delegations to the browser or widen authenticated grants.
notify pgrst, 'reload schema';
