-- Requests sent from the existing iOS "request_org_athlete_link" action.
-- Pending requests are visible only to the requester and center managers.
create table if not exists public.organization_athlete_requests(
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id) on delete cascade,
 athlete_id uuid not null references auth.users(id) on delete cascade,
 pass_kind text not null check(pass_kind in ('class','appointment')),
 note text not null default '' check(length(note)<=500),
 status text not null default 'pending' check(status in ('pending','accepted','rejected','cancelled')),
 created_at timestamptz not null default now(),
 decided_at timestamptz,decided_by uuid references auth.users(id)
);
create unique index if not exists org_athlete_one_pending_request
 on public.organization_athlete_requests(org_id,athlete_id) where status='pending';
create index if not exists org_athlete_requests_org_date
 on public.organization_athlete_requests(org_id,created_at desc);
alter table public.organization_athlete_requests enable row level security;
revoke all on public.organization_athlete_requests from public,anon,authenticated;
grant select on public.organization_athlete_requests to authenticated;
create policy org_athlete_requests_read on public.organization_athlete_requests
 for select to authenticated using(athlete_id=auth.uid() or
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));

create or replace function private.request_org_athlete_link(p_org uuid,p_pass_kind text,p_note text default '')
returns uuid language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid();v_id uuid;v_verified boolean;
begin
 if v_actor is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
 select email_confirmed_at is not null into v_verified from auth.users where id=v_actor;
 if not coalesce(v_verified,false) then raise exception 'VERIFIED_EMAIL_REQUIRED' using errcode='42501';end if;
 if p_pass_kind not in ('class','appointment') or length(coalesce(p_note,''))>500 then
  raise exception 'INVALID_REQUEST' using errcode='22023';end if;
 if not exists(select 1 from public.organizations o
  where o.id=p_org and o.is_discoverable=true and
    not exists(select 1 from public.platform_org_controls c where c.org_id=o.id and c.status='suspended'))
 then raise exception 'CENTER_UNAVAILABLE' using errcode='22023';end if;
 if exists(select 1 from public.organization_memberships m
 where m.organization_id=p_org and m.user_id=v_actor and m.status='active')
 then raise exception 'ALREADY_LINKED' using errcode='22023';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_org::text||v_actor::text,0));
 select id into v_id from public.organization_athlete_requests
 where org_id=p_org and athlete_id=v_actor and status='pending';
 if v_id is not null then return v_id;end if;
 insert into public.organization_athlete_requests(org_id,athlete_id,pass_kind,note)
 values(p_org,v_actor,p_pass_kind,btrim(coalesce(p_note,''))) returning id into v_id;
 return v_id;
end $$;
revoke all on function private.request_org_athlete_link(uuid,text,text) from public,anon,authenticated;
grant execute on function private.request_org_athlete_link(uuid,text,text) to authenticated;
create or replace function public.request_org_athlete_link(
 p_org uuid,p_pass_kind text,p_note text default '')
returns uuid language sql security invoker set search_path='' as $$
 select private.request_org_athlete_link(p_org,p_pass_kind,p_note)
$$;
revoke all on function public.request_org_athlete_link(uuid,text,text) from public,anon;
grant execute on function public.request_org_athlete_link(uuid,text,text) to authenticated;

create or replace function private.business_enrollment_requests(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object(
 'id',r.id,'org_id',r.org_id,'athlete_id',r.athlete_id,'name',
 coalesce(nullif(p.display_name,''),nullif(u.raw_user_meta_data->>'name',''),split_part(u.email,'@',1)),
 'email',u.email,'avatar_url',coalesce(p.avatar_url,u.raw_user_meta_data->>'avatar_url'),
 'pass_kind',r.pass_kind,'note',r.note,'status',r.status,'created_at',r.created_at,
 'decided_at',r.decided_at) order by r.created_at desc)
 from (select * from public.organization_athlete_requests
 where org_id=p_org order by created_at desc limit 100) r
 join auth.users u on u.id=r.athlete_id left join public.profiles p on p.id=r.athlete_id),'[]'::jsonb);
end $$;
revoke all on function private.business_enrollment_requests(uuid) from public,anon,authenticated;
grant execute on function private.business_enrollment_requests(uuid) to authenticated;
create or replace function public.business_enrollment_requests(p_org uuid)
returns jsonb language sql security invoker set search_path='' as $$
 select private.business_enrollment_requests(p_org)
$$;
revoke all on function public.business_enrollment_requests(uuid) from public,anon;
grant execute on function public.business_enrollment_requests(uuid) to authenticated;

create or replace function private.business_decide_enrollment(p_request uuid,p_accept boolean)
returns uuid language plpgsql security definer set search_path='' as $$
declare v public.organization_athlete_requests%rowtype;v_user auth.users%rowtype;
 v_name text;v_client uuid;
begin
 select * into v from public.organization_athlete_requests where id=p_request for update;
 if not found then raise exception 'REQUEST_NOT_FOUND' using errcode='22023';end if;
 if auth.uid() is null or not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 if v.status<>'pending' then raise exception 'REQUEST_ALREADY_HANDLED' using errcode='22023';end if;
 if p_accept is null then raise exception 'DECISION_REQUIRED' using errcode='22023';end if;
 if p_accept then
  select * into v_user from auth.users where id=v.athlete_id;
  if not found or v_user.email_confirmed_at is null then
   raise exception 'ATHLETE_NOT_VERIFIED' using errcode='42501';end if;
  v_name:=left(coalesce(nullif(btrim(v_user.raw_user_meta_data->>'name'),''),
            split_part(v_user.email,'@',1),'Atleta'),120);
  if length(v_name)<2 then v_name:='Atleta';end if;
  select id into v_client from public.clients where org_id=v.org_id and
   (user_id=v.athlete_id or lower(email)=lower(v_user.email))
   order by (user_id=v.athlete_id) desc limit 1 for update;
  if v_client is not null then
   if exists(select 1 from public.clients where id=v_client and
    user_id is not null and user_id<>v.athlete_id)
   then raise exception 'CLIENT_ALREADY_LINKED' using errcode='23505';end if;
   update public.clients set user_id=v.athlete_id,status='active',updated_at=now() where id=v_client;
  else
   insert into public.clients(org_id,created_by,user_id,name,email,status)
   values(v.org_id,auth.uid(),v.athlete_id,v_name,lower(v_user.email),'active');
  end if;
  insert into public.organization_memberships(organization_id,user_id,role,status)
   values(v.org_id,v.athlete_id,'athlete','active')
   on conflict(organization_id,user_id) do update set role='athlete',status='active';
 end if;
 update public.organization_athlete_requests set status=case when p_accept then 'accepted' else 'rejected' end,
 decided_by=auth.uid(),decided_at=now() where id=v.id;
 return v.org_id;
end $$;
revoke all on function private.business_decide_enrollment(uuid,boolean) from public,anon,authenticated;
grant execute on function private.business_decide_enrollment(uuid,boolean) to authenticated;
create or replace function public.business_decide_enrollment(p_request uuid,p_accept boolean)
 returns uuid language sql security invoker set search_path='' as $$
 select private.business_decide_enrollment(p_request,p_accept)
$$;
revoke all on function public.business_decide_enrollment(uuid,boolean) from public,anon;
grant execute on function public.business_decide_enrollment(uuid,boolean) to authenticated;

-- The center operating state is not the future owner's onboarding state.
-- Pending verification remains represented by registration_status separately.
create or replace function private.platform_admin_directory()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object(
 'id',o.id,'name',o.name,'kind',o.kind::text,'slug',o.slug,'created_at',o.created_at,
 'email',o.public_email,'phone',o.phone,'website',o.website,'address',o.address,
 'description',o.description,'timezone',o.timezone,'avatar_url',coalesce(o.avatar_url,p.avatar_url),
 'client_count',(select count(*) from public.clients c where c.org_id=o.id),
 'active_clients',(select count(*) from public.clients c where c.org_id=o.id and c.status='active'),
 'member_count',(select count(*) from public.organization_memberships m where m.organization_id=o.id and m.status='active'),
 'sessions',(select count(*) from public.service_occurrences s where s.org_id=o.id),
 'trial_ends_at',t.trial_ends_at,'paid_plan',t.paid_plan,'paid_until',t.paid_until,
 'registration_status',coalesce(p.status,'claimed'),
 'owner_email',p.owner_email,'provisioning_id',p.id,
 'status',coalesce(st.status,'active'),
 'status_reason',coalesce(st.reason,''),
 'last_activity',(select max(x.booked_at) from public.service_bookings x where x.org_id=o.id)
 ) order by o.created_at desc) from public.organizations o
 left join public.organization_trials t on t.org_id=o.id
 left join public.platform_org_controls st on st.org_id=o.id
 left join lateral(select pr.id,pr.status,pr.owner_email,pr.avatar_url from public.platform_org_provisioning pr
 where pr.claimed_org_id=o.id order by pr.created_at desc limit 1) p on true),'[]'::jsonb);
end $$;
notify pgrst,'reload schema';
