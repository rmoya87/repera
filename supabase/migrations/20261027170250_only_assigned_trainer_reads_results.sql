-- Only the assigned coach, or the owner who IS the personal trainer,
-- can read an athlete's shared exercise results. Keep athlete consent mandatory.
create or replace function private.can_view_client_results(p_org uuid,p_client uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (
   private.is_assigned_coach(p_org,p_client)
   or exists(
     select 1 from public.organizations o
     where o.id=p_org and o.kind='personal_trainer'
       and private.has_org_role(p_org,array['owner']::public.organization_role[])
   )
 );
$$;
revoke all on function private.can_view_client_results(uuid,uuid)
 from public,anon,authenticated;

create or replace function private.shared_athlete_results(
 p_org uuid,p_client uuid,p_limit integer default 40
) returns table(id uuid,title text,started_at timestamptz,
  finished_at timestamptz,result jsonb)
language plpgsql stable security definer set search_path='' as $$
declare v_athlete uuid;
begin
 if auth.uid() is null or p_limit is null or p_limit<1 or p_limit>100
    or not private.can_view_client_results(p_org,p_client) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 select c.user_id into v_athlete from public.clients c
 join public.organization_memberships m
   on m.organization_id=c.org_id and m.user_id=c.user_id
 where c.id=p_client and c.org_id=p_org and c.status='active'
   and m.status='active' and m.role='athlete';
 if v_athlete is null or not exists (
  select 1 from public.athlete_workout_sharing s
  where s.athlete_id=v_athlete and s.org_id=p_org and s.enabled
 ) then return;end if;
 return query select w.id,w.title,w.started_at,w.finished_at,
 jsonb_build_object(
  'exercises',coalesce(w.payload->'exercises','[]'::jsonb),
  'wodResults',coalesce(w.payload->'wodResults','[]'::jsonb),
  'durationSeconds',case when w.started_at is not null and w.finished_at is not null
   then greatest(0,extract(epoch from (w.finished_at-w.started_at))) else null end
 )
 from public.athlete_workout_mirror w
 where w.owner_id=v_athlete and w.deleted_at is null
 order by w.finished_at desc nulls last limit p_limit;
end;
$$;

create or replace function private.get_shared_client_history(
 p_org uuid,p_client uuid
) returns table(id uuid,title text,started_at timestamptz,finished_at timestamptz)
language plpgsql stable security definer set search_path='' as $$
declare athlete uuid;
begin
 if auth.uid() is null or not private.can_view_client_results(p_org,p_client) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 select user_id into athlete from public.clients
 where org_id=p_org and id=p_client and status='active';
 if athlete is null then return; end if;
 if not exists(
  select 1 from public.athlete_business_history_consents c
  where c.org_id=p_org and c.client_id=p_client and c.athlete_user_id=athlete
    and c.revoked_at is null
 ) then return;end if;
 return query select w.id,w.title,w.started_at,w.finished_at
 from public.athlete_workout_mirror w
 where w.owner_id=athlete and w.deleted_at is null and w.started_at is not null
 order by w.started_at desc limit 200;
end;
$$;
-- Existing public RPCs remain security-invoker wrappers; these private
-- implementations never expose history without existing athlete consent.
notify pgrst,'reload schema';
