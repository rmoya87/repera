-- Repera Business: publish dated professional prescriptions, not athlete workout histories.
create table public.professional_training_sessions (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null,
 client_id uuid not null,
 coach_user_id uuid not null references auth.users(id),
 scheduled_date date not null,
 title text not null check(length(btrim(title)) between 2 and 120),
 instructions text not null default '' check(length(instructions)<=10000),
 prescription jsonb not null default '{"blocks":[]}'::jsonb
   check(jsonb_typeof(prescription)='object' and octet_length(prescription::text)<=100000),
 status text not null default 'scheduled' check(status in ('scheduled','cancelled')),
 publish_request_id uuid not null unique,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade,
 unique(org_id,id)
);
create index professional_sessions_client_day on public.professional_training_sessions(org_id,client_id,scheduled_date);

alter table public.professional_training_sessions enable row level security;
create policy professional_sessions_read on public.professional_training_sessions
 for select to authenticated using(
   (select private.owns_org_client(org_id,client_id))
   or (select private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
   or (select private.is_assigned_coach(org_id,client_id))
 );
revoke all on public.professional_training_sessions from public,anon,authenticated;
grant select on public.professional_training_sessions to authenticated;

create function private.assign_coach_client(p_org uuid,p_client uuid,p_coach uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if not exists(select 1 from public.organization_memberships
  where organization_id=p_org and user_id=p_coach and role='coach' and status='active') then
  raise exception 'COACH_NOT_ACTIVE' using errcode='22023'; end if;
 if not exists(select 1 from public.clients
  where org_id=p_org and id=p_client and user_id is not null and status='active') then
  raise exception 'CLIENT_NOT_LINKED' using errcode='22023'; end if;
 insert into public.staff_client_assignments(org_id,client_id,coach_id)
 values(p_org,p_client,p_coach) on conflict do nothing;
 return true;
end; $$;

create function private.publish_professional_session(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid
) returns uuid language plpgsql security definer set search_path=''
as $$
declare
 v_actor uuid:=auth.uid();
 v_id uuid;
 v_existing public.professional_training_sessions%rowtype;
begin
 if v_actor is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if not (private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
    or private.is_assigned_coach(p_org,p_client)) then
   raise exception 'NOT_ASSIGNED' using errcode='42501'; end if;
 if not exists(select 1 from public.clients where org_id=p_org and id=p_client and user_id is not null and status='active') then
   raise exception 'CLIENT_NOT_LINKED' using errcode='22023'; end if;
 if p_day is null or p_day<current_date or p_day>current_date+interval '18 months'
    or length(btrim(p_title)) not between 2 and 120 or length(coalesce(p_instructions,''))>10000 then
   raise exception 'INVALID_PLAN_DAY' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('training_publish:'||p_request::text,0));
 select * into v_existing from public.professional_training_sessions where publish_request_id=p_request;
 if found then
   if v_existing.org_id<>p_org or v_existing.client_id<>p_client or
      v_existing.coach_user_id<>v_actor or v_existing.scheduled_date<>p_day
      or v_existing.title<>btrim(p_title) or v_existing.instructions<>coalesce(p_instructions,'') then
     raise exception 'REQUEST_ID_REUSED' using errcode='23505'; end if;
   return v_existing.id;
 end if;
 insert into public.professional_training_sessions
   (org_id,client_id,coach_user_id,scheduled_date,title,instructions,publish_request_id)
 values(p_org,p_client,v_actor,p_day,btrim(p_title),coalesce(p_instructions,''),p_request)
 returning id into v_id;
 return v_id;
end; $$;

create function private.cancel_professional_session(p_session uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
declare v_rec public.professional_training_sessions%rowtype;
begin
 if auth.uid() is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 select * into v_rec from public.professional_training_sessions where id=p_session for update;
 if not found then raise exception 'NOT_FOUND' using errcode='22023'; end if;
 if not (private.has_org_role(v_rec.org_id,array['owner','admin']::public.organization_role[])
    or (v_rec.coach_user_id=auth.uid() and private.is_assigned_coach(v_rec.org_id,v_rec.client_id))) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v_rec.status='cancelled' then return false; end if;
 update public.professional_training_sessions set status='cancelled',updated_at=now() where id=p_session;
 return true;
end; $$;

revoke all on function private.assign_coach_client(uuid,uuid,uuid),
 private.publish_professional_session(uuid,uuid,date,text,text,uuid),
 private.cancel_professional_session(uuid) from public,anon;
grant execute on function private.assign_coach_client(uuid,uuid,uuid),
 private.publish_professional_session(uuid,uuid,date,text,text,uuid),
 private.cancel_professional_session(uuid) to authenticated;

create function public.assign_coach_client(p_org uuid,p_client uuid,p_coach uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.assign_coach_client(p_org,p_client,p_coach) $$;
create function public.publish_professional_session(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid
) returns uuid language sql security invoker set search_path=''
as $$ select private.publish_professional_session(p_org,p_client,p_day,p_title,p_instructions,p_request) $$;
create function public.cancel_professional_session(p_session uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.cancel_professional_session(p_session) $$;
revoke all on function public.assign_coach_client(uuid,uuid,uuid),
 public.publish_professional_session(uuid,uuid,date,text,text,uuid),
 public.cancel_professional_session(uuid) from public,anon;
grant execute on function public.assign_coach_client(uuid,uuid,uuid),
 public.publish_professional_session(uuid,uuid,date,text,text,uuid),
 public.cancel_professional_session(uuid) to authenticated;
