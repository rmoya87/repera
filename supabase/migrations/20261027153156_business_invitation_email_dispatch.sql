-- Authorization and rate limiting for center-initiated invitation emails.
-- An email is not acceptance: only accept_org_invitation() can link an account.
create table if not exists public.business_invitation_email_attempts(
 id uuid primary key default gen_random_uuid(),
 invitation_id uuid not null references public.organization_invitations(id) on delete cascade,
 actor_id uuid not null references auth.users(id),
 attempted_at timestamptz not null default now()
);
create index if not exists business_invitation_email_attempts_window
 on public.business_invitation_email_attempts(invitation_id,attempted_at desc);
alter table public.business_invitation_email_attempts enable row level security;
revoke all on public.business_invitation_email_attempts from public,anon,authenticated;

create or replace function private.business_invite_email_payload(p_invitation uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid();v_inv public.organization_invitations%rowtype;
 v_org public.organizations%rowtype;
begin
 if v_actor is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
 select * into v_inv from public.organization_invitations where id=p_invitation for update;
 if not found or v_inv.accepted_at is not null or v_inv.cancelled_at is not null or v_inv.expires_at<=now()
 then raise exception 'INVITATION_INACTIVE' using errcode='22023';end if;
 if not private.has_org_role(v_inv.organization_id,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 if (select count(*) from public.business_invitation_email_attempts
 where invitation_id=p_invitation and attempted_at>now()-interval '1 hour')>=3
 then raise exception 'INVITATION_RATE_LIMIT' using errcode='42900';end if;
 select * into v_org from public.organizations where id=v_inv.organization_id;
 insert into public.business_invitation_email_attempts(invitation_id,actor_id)
 values(v_inv.id,v_actor);
 return jsonb_build_object('invitation_id',v_inv.id,'recipient',v_inv.email,
  'org_name',v_org.name,'org_type',v_org.kind,'role',v_inv.invited_role,'expires',v_inv.expires_at);
end $$;
revoke all on function private.business_invite_email_payload(uuid) from public,anon,authenticated;
grant execute on function private.business_invite_email_payload(uuid) to authenticated;
create or replace function public.business_invite_email_payload(p_invitation uuid)
returns jsonb language sql security invoker set search_path='' as $$
 select private.business_invite_email_payload(p_invitation)
$$;
revoke all on function public.business_invite_email_payload(uuid) from public,anon;
grant execute on function public.business_invite_email_payload(uuid) to authenticated;
notify pgrst,'reload schema';
