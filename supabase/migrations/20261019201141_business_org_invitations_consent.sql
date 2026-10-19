-- Secure consent-based Repera Business organization invitation workflow.
-- No share of athlete-owned history or HealthKit data.
create table public.organization_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  email text not null check (email=lower(btrim(email)) and length(email) between 5 and 254 and position('@' in email)>1),
  invited_role public.organization_role not null check (invited_role in ('admin','coach','reception','athlete')),
  invited_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now()+interval '14 days'),
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id) on delete set null,
  cancelled_at timestamptz,
  constraint invitation_accepted_once check (
    (accepted_at is null and accepted_by is null) or (accepted_at is not null and accepted_by is not null)
  ),
  constraint invitation_single_resolution check (accepted_at is null or cancelled_at is null)
);
create unique index org_invitations_pending_idx
  on public.organization_invitations(organization_id,email)
  where accepted_at is null and cancelled_at is null;
create index org_invitations_by_email_idx on public.organization_invitations(email,expires_at)
  where accepted_at is null and cancelled_at is null;

create function private.is_verified_invitation_recipient(p_email text)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and exists(
   select 1 from auth.users u
   where u.id=auth.uid() and u.email_confirmed_at is not null
     and lower(btrim(u.email))=p_email
 );
$$;
revoke all on function private.is_verified_invitation_recipient(text) from public,anon;
grant execute on function private.is_verified_invitation_recipient(text) to authenticated;

alter table public.organization_invitations enable row level security;
create policy org_invitations_select_allowed on public.organization_invitations
 for select to authenticated
 using (
   (select private.has_org_role(organization_id,array['owner','admin']::public.organization_role[]))
   or (select private.is_verified_invitation_recipient(email))
 );
revoke all on public.organization_invitations from public,anon,authenticated;
grant select on public.organization_invitations to authenticated;

-- An authenticated active owner/admin issues an invitation. No arbitrary role escalation.
-- Invites are private and do not email contacts until a consent-respecting mail workflow exists.
create function public.issue_org_invitation(p_org uuid,p_email text,p_role public.organization_role)
returns uuid language plpgsql security definer set search_path=''
as $$
declare
 v_actor uuid:=auth.uid();
 v_email text:=lower(btrim(p_email));
 v_id uuid;
begin
 if v_actor is null or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 if p_role is null or p_role not in ('admin','coach','reception','athlete') then
   raise exception 'INVALID_ROLE' using errcode='22023';
 end if;
 if length(v_email) not between 5 and 254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then
   raise exception 'INVALID_EMAIL' using errcode='22023';
 end if;
 if exists (
   select 1 from public.organization_memberships m
   join auth.users u on u.id=m.user_id
   where m.organization_id=p_org and m.status='active'
     and lower(btrim(u.email))=v_email
 ) then
   raise exception 'ALREADY_A_MEMBER' using errcode='23505';
 end if;

 -- Serialize new invitations for the same org/contact, including concurrent requests.
 perform pg_advisory_xact_lock(hashtextextended(p_org::text||':'||v_email,0));
 update public.organization_invitations set cancelled_at=now()
 where organization_id=p_org and email=v_email
   and accepted_at is null and cancelled_at is null;
 insert into public.organization_invitations(organization_id,email,invited_role,invited_by)
 values(p_org,v_email,p_role,v_actor) returning id into v_id;
 return v_id;
end; $$;

-- Only the VERIFIED recipient may accept an invitation. The acceptance itself is consent.
-- For athletes, bind existing CRM client record only on acceptance, never by e-mail similarity alone.
create function public.accept_org_invitation(p_invitation_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare
 v_actor uuid:=auth.uid();
 v_inv public.organization_invitations%rowtype;
 v_verified_email text;
 v_display_name text;
 v_client_id uuid;
begin
 if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 select lower(btrim(email)) into v_verified_email
 from auth.users where id=v_actor and email_confirmed_at is not null;
 if v_verified_email is null then
   raise exception 'VERIFIED_EMAIL_REQUIRED' using errcode='42501';
 end if;
 select * into v_inv from public.organization_invitations
 where id=p_invitation_id for update;
 if not found or v_inv.email<>v_verified_email then
   raise exception 'INVITATION_NOT_FOUND' using errcode='42501';
 end if;
 if v_inv.accepted_at is not null or v_inv.cancelled_at is not null or v_inv.expires_at<=now() then
   raise exception 'INVITATION_INACTIVE' using errcode='22023';
 end if;

 insert into public.organization_memberships(organization_id,user_id,role,status)
 values(v_inv.organization_id,v_actor,v_inv.invited_role,'active')
 on conflict (organization_id,user_id) do update
  set role=excluded.role,status='active';

 if v_inv.invited_role='athlete' then
   select id into v_client_id from public.clients
   where org_id=v_inv.organization_id and lower(email)=v_verified_email
   for update;
   if v_client_id is not null then
     if exists (select 1 from public.clients where id=v_client_id
                and user_id is not null and user_id<>v_actor) then
       raise exception 'CLIENT_ALREADY_LINKED' using errcode='23505';
     end if;
     update public.clients set user_id=v_actor,status='active',updated_at=now()
       where id=v_client_id;
   else
     select coalesce(nullif(btrim(p.display_name),''),
                     split_part(v_verified_email,'@',1),'Deportista')
       into v_display_name from public.profiles p where p.id=v_actor;
     v_display_name:=left(coalesce(v_display_name,'Deportista'),120);
     if length(v_display_name)<2 then v_display_name:='Deportista'; end if;
     insert into public.clients(org_id,created_by,user_id,name,email,status)
       values(v_inv.organization_id,v_inv.invited_by,v_actor,v_display_name,v_verified_email,'active');
   end if;
 end if;
 update public.organization_invitations
   set accepted_at=now(),accepted_by=v_actor where id=v_inv.id;
 return v_inv.organization_id;
end; $$;

create function public.cancel_org_invitation(p_invitation_id uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
declare v_actor uuid:=auth.uid(); v_org uuid;
begin
 if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 select organization_id into v_org from public.organization_invitations
   where id=p_invitation_id for update;
 if v_org is null or not private.has_org_role(v_org,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 update public.organization_invitations set cancelled_at=now()
  where id=p_invitation_id and accepted_at is null and cancelled_at is null;
 return found;
end; $$;

revoke all on function public.issue_org_invitation(uuid,text,public.organization_role)
  from public,anon;
revoke all on function public.accept_org_invitation(uuid)
  from public,anon;
revoke all on function public.cancel_org_invitation(uuid)
  from public,anon;
grant execute on function public.issue_org_invitation(uuid,text,public.organization_role) to authenticated;
grant execute on function public.accept_org_invitation(uuid) to authenticated;
grant execute on function public.cancel_org_invitation(uuid) to authenticated;
