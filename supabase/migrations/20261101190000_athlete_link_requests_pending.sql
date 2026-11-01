-- Solicitudes app → bandeja PT/gym (pending). Sustituye el RPC antiguo que
-- vinculaba al instante sin crear organization_athlete_requests.
-- unlimited (Android) se normaliza a appointment.

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
drop policy if exists org_athlete_requests_read on public.organization_athlete_requests;
create policy org_athlete_requests_read on public.organization_athlete_requests
 for select to authenticated using(athlete_id=auth.uid() or
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));

create or replace function private.request_org_athlete_link(
 p_org uuid,p_pass_kind text default 'class',p_note text default ''
) returns uuid language plpgsql security definer set search_path='' as $$
declare
 v_actor uuid:=auth.uid();
 v_id uuid;
 v_verified boolean;
 v_kind text:=lower(btrim(coalesce(p_pass_kind,'class')));
 v_note text:=left(btrim(coalesce(p_note,'')),500);
begin
 if v_actor is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select email_confirmed_at is not null into v_verified from auth.users where id=v_actor;
 if not coalesce(v_verified,false) then raise exception 'VERIFIED_EMAIL_REQUIRED' using errcode='42501'; end if;
 -- Android enviaba "unlimited"; la bandeja solo admite class|appointment.
 if v_kind='unlimited' then v_kind:='appointment'; end if;
 if v_kind not in ('class','appointment') or length(v_note)>500 then
  raise exception 'INVALID_REQUEST' using errcode='22023'; end if;
 if not exists(
  select 1 from public.organizations o
  where o.id=p_org and o.is_discoverable=true
    and not exists(select 1 from public.platform_org_controls c where c.org_id=o.id and c.status='suspended')
 ) then raise exception 'CENTER_UNAVAILABLE' using errcode='22023'; end if;
 if exists(
  select 1 from public.organization_memberships m
  where m.organization_id=p_org and m.user_id=v_actor and m.status='active'
 ) then raise exception 'ALREADY_LINKED' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_org::text||v_actor::text,0));
 select id into v_id from public.organization_athlete_requests
  where org_id=p_org and athlete_id=v_actor and status='pending';
 if v_id is not null then return v_id; end if;
 insert into public.organization_athlete_requests(org_id,athlete_id,pass_kind,note)
 values(p_org,v_actor,v_kind,v_note) returning id into v_id;
 return v_id;
end $$;

revoke all on function private.request_org_athlete_link(uuid,text,text) from public,anon,authenticated;
grant execute on function private.request_org_athlete_link(uuid,text,text) to authenticated;

create or replace function public.request_org_athlete_link(
 p_org uuid,p_pass_kind text default 'class',p_note text default ''
) returns uuid language sql security invoker set search_path='' as $$
 select private.request_org_athlete_link(p_org,p_pass_kind,p_note)
$$;
revoke all on function public.request_org_athlete_link(uuid,text,text) from public,anon;
grant execute on function public.request_org_athlete_link(uuid,text,text) to authenticated;

create or replace function private.business_enrollment_requests(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object(
  'id',r.id,'org_id',r.org_id,'athlete_id',r.athlete_id,
  'name',coalesce(nullif(p.display_name,''),nullif(u.raw_user_meta_data->>'name',''),split_part(u.email,'@',1)),
  'email',u.email,'avatar_url',coalesce(p.avatar_url,u.raw_user_meta_data->>'avatar_url'),
  'pass_kind',r.pass_kind,'note',r.note,'status',r.status,'created_at',r.created_at,
  'decided_at',r.decided_at) order by r.created_at desc)
  from (
   select * from public.organization_athlete_requests
   where org_id=p_org and status='pending'
   order by created_at desc limit 100
  ) r
  join auth.users u on u.id=r.athlete_id
  left join public.profiles p on p.id=r.athlete_id),'[]'::jsonb);
end $$;

revoke all on function private.business_enrollment_requests(uuid) from public,anon,authenticated;
grant execute on function private.business_enrollment_requests(uuid) to authenticated;
create or replace function public.business_enrollment_requests(p_org uuid)
returns jsonb language sql security invoker set search_path='' as $$
 select private.business_enrollment_requests(p_org)
$$;
revoke all on function public.business_enrollment_requests(uuid) from public,anon;
grant execute on function public.business_enrollment_requests(uuid) to authenticated;
