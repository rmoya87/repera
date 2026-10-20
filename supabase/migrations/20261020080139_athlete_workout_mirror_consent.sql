-- Workout mirrors remain private to the athlete; sync does not grant staff access.
create table public.athlete_workout_mirror(
 id uuid primary key,
 owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(length(btrim(title)) between 1 and 200),
 started_at timestamptz,finished_at timestamptz,
 payload jsonb not null default '{}'::jsonb check(jsonb_typeof(payload)='object' and octet_length(payload::text)<=250000),
 deleted_at timestamptz,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 constraint valid_workout_times check(finished_at is null or started_at is null or finished_at>=started_at)
);
create index athlete_workout_mirror_owner_finished_idx on public.athlete_workout_mirror(owner_id,finished_at desc);
alter table public.athlete_workout_mirror enable row level security;
create policy athlete_workout_private_select on public.athlete_workout_mirror for select to authenticated
 using(owner_id=(select auth.uid()));
create policy athlete_workout_private_insert on public.athlete_workout_mirror for insert to authenticated
 with check(owner_id=(select auth.uid()));
create policy athlete_workout_private_update on public.athlete_workout_mirror for update to authenticated
 using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
revoke all on public.athlete_workout_mirror from public,anon,authenticated;
grant select,insert on public.athlete_workout_mirror to authenticated;
grant update(title,started_at,finished_at,payload,deleted_at,updated_at) on public.athlete_workout_mirror to authenticated;
-- Intentional soft deletes: tombstones stop another device reviving a deletion.

create table public.athlete_workout_sharing(
 athlete_id uuid not null references auth.users(id) on delete cascade,
 org_id uuid not null references public.organizations(id) on delete cascade,
 enabled boolean not null default false,
 updated_at timestamptz not null default now(),
 primary key(athlete_id,org_id)
);
create index athlete_workout_sharing_org_idx on public.athlete_workout_sharing(org_id,athlete_id) where enabled;
alter table public.athlete_workout_sharing enable row level security;
create policy workout_sharing_read_own on public.athlete_workout_sharing for select to authenticated
 using(athlete_id=(select auth.uid()));
create policy workout_sharing_write_own on public.athlete_workout_sharing for insert to authenticated
 with check(
 athlete_id=(select auth.uid())
 and private.has_org_role(org_id,array['athlete']::public.organization_role[])
 and exists(select 1 from public.clients c
  where c.org_id=athlete_workout_sharing.org_id and c.user_id=auth.uid() and c.status='active')
 );
create policy workout_sharing_update_own on public.athlete_workout_sharing for update to authenticated
 using(athlete_id=(select auth.uid()))
 with check(
 athlete_id=(select auth.uid())
 and private.has_org_role(org_id,array['athlete']::public.organization_role[])
 and exists(select 1 from public.clients c
  where c.org_id=athlete_workout_sharing.org_id and c.user_id=auth.uid() and c.status='active')
 );
revoke all on public.athlete_workout_sharing from public,anon,authenticated;
grant select,insert(athlete_id,org_id,enabled),update(enabled,updated_at)
 on public.athlete_workout_sharing to authenticated;

-- Staff must be explicitly authorized and athlete must opt in per organization.
-- Never grant staff direct SELECT on mirrored workouts or return location/Health data.
create function private.shared_athlete_results(p_org uuid,p_client uuid,p_limit integer default 40)
returns table(id uuid,title text,started_at timestamptz,finished_at timestamptz,result jsonb)
language plpgsql stable security definer set search_path=''
as $$
declare v_athlete uuid;
begin
 if auth.uid() is null or p_limit is null or p_limit<1 or p_limit>100 then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 if not (
  private.is_assigned_coach(p_org,p_client)
  or private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
 ) then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 select c.user_id into v_athlete from public.clients c
 join public.organization_memberships m
   on m.organization_id=c.org_id and m.user_id=c.user_id
 where c.id=p_client and c.org_id=p_org and c.status='active'
   and m.status='active' and m.role='athlete';
 if v_athlete is null or not exists(
    select 1 from public.athlete_workout_sharing s
    where s.athlete_id=v_athlete and s.org_id=p_org and s.enabled
 ) then return; end if;
 return query select w.id,w.title,w.started_at,w.finished_at,
  jsonb_build_object(
   'exercises',coalesce(w.payload->'exercises','[]'::jsonb),
   'wodResults',coalesce(w.payload->'wodResults','[]'::jsonb),
   'durationSeconds',case when w.started_at is not null and w.finished_at is not null
    then greatest(0,extract(epoch from(w.finished_at-w.started_at))) else null end
  )
 from public.athlete_workout_mirror w
 where w.owner_id=v_athlete and w.deleted_at is null
 order by w.finished_at desc nulls last limit p_limit;
end;
$$;
revoke all on function private.shared_athlete_results(uuid,uuid,integer) from public,anon;
grant execute on function private.shared_athlete_results(uuid,uuid,integer) to authenticated;
create function public.get_shared_athlete_results(p_org uuid,p_client uuid,p_limit integer default 40)
returns table(id uuid,title text,started_at timestamptz,finished_at timestamptz,result jsonb)
language sql stable security invoker set search_path=''
as $$select * from private.shared_athlete_results(p_org,p_client,p_limit)$$;
revoke all on function public.get_shared_athlete_results(uuid,uuid,integer) from public,anon;
grant execute on function public.get_shared_athlete_results(uuid,uuid,integer) to authenticated;
