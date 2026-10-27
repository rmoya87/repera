-- Regression: an authenticated user may query membership rows under RLS
-- without a 42501 error for the admin-only delegation ledger.
-- The policy with a direct subselect on platform_admin_delegations is removed.
-- No seed rows, password or user identity is needed.
begin;
set local role authenticated;
select count(*) as visible_memberships from public.organization_memberships;
rollback;
