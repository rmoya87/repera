-- Never expose SECURITY DEFINER RPCs in public PostgREST schema.
-- Public API wrappers run as the authenticated invoker, delegating to gated private routines.
alter function public.issue_org_invitation(uuid,text,public.organization_role) set schema private;
alter function public.accept_org_invitation(uuid) set schema private;
alter function public.cancel_org_invitation(uuid) set schema private;

revoke all on function private.issue_org_invitation(uuid,text,public.organization_role) from public, anon;
revoke all on function private.accept_org_invitation(uuid) from public, anon;
revoke all on function private.cancel_org_invitation(uuid) from public, anon;
grant execute on function private.issue_org_invitation(uuid,text,public.organization_role) to authenticated;
grant execute on function private.accept_org_invitation(uuid) to authenticated;
grant execute on function private.cancel_org_invitation(uuid) to authenticated;

create function public.issue_org_invitation(p_org uuid,p_email text,p_role public.organization_role)
returns uuid language sql security invoker set search_path=''
as $$ select private.issue_org_invitation(p_org,p_email,p_role) $$;
create function public.accept_org_invitation(p_invitation_id uuid)
returns uuid language sql security invoker set search_path=''
as $$ select private.accept_org_invitation(p_invitation_id) $$;
create function public.cancel_org_invitation(p_invitation_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.cancel_org_invitation(p_invitation_id) $$;

revoke all on function public.issue_org_invitation(uuid,text,public.organization_role) from public,anon;
revoke all on function public.accept_org_invitation(uuid) from public,anon;
revoke all on function public.cancel_org_invitation(uuid) from public,anon;
grant execute on function public.issue_org_invitation(uuid,text,public.organization_role) to authenticated;
grant execute on function public.accept_org_invitation(uuid) to authenticated;
grant execute on function public.cancel_org_invitation(uuid) to authenticated;
