-- Professional workouts need an optional local start time (minutes after midnight).
-- When unset, clients display only the date; no time is inferred.
alter table public.professional_training_sessions
  add column if not exists scheduled_time_minutes integer
  check (scheduled_time_minutes between 0 and 1439);

create or replace function private.set_professional_session_time(
  p_session uuid, p_minutes integer
) returns boolean language plpgsql security definer set search_path = '' as $$
declare v_org uuid; v_author uuid; v_client uuid;
begin
  if auth.uid() is null or (p_minutes is not null and (p_minutes < 0 or p_minutes >= 1440)) then
    raise exception 'INVALID_TIME_OR_AUTH' using errcode = '22023';
  end if;
  select org_id,coach_user_id,client_id into v_org,v_author,v_client
  from public.professional_training_sessions where id = p_session for update;
  if not found or not (v_author = auth.uid()
    or private.has_org_role(v_org,array['owner','admin']::public.organization_role[])) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  update public.professional_training_sessions
  set scheduled_time_minutes = p_minutes,updated_at = now()
  where id = p_session;
  return true;
end $$;
revoke all on function private.set_professional_session_time(uuid,integer)
  from public,anon,authenticated;
grant execute on function private.set_professional_session_time(uuid,integer) to authenticated;
create or replace function public.set_professional_session_time(
  p_session uuid,p_minutes integer
) returns boolean language sql security invoker set search_path = '' as $$
  select private.set_professional_session_time(p_session,p_minutes);
$$;
revoke all on function public.set_professional_session_time(uuid,integer) from public,anon;
grant execute on function public.set_professional_session_time(uuid,integer) to authenticated;

-- Athletes can revoke THEIR OWN active membership, not another athlete's
-- nor a coach/owner membership. Historical business records remain retained.
create or replace function private.leave_org_as_athlete(p_org uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare v_actor uuid := auth.uid();
begin
  if v_actor is null or p_org is null or not exists (
    select 1 from public.organization_memberships m
    where m.organization_id = p_org and m.user_id = v_actor
      and m.role = 'athlete' and m.status = 'active'
  ) then
    raise exception 'NOT_LINKED_ATHLETE' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('athlete_leave:'||p_org::text||':'||v_actor::text,0));
  -- Release capacity for future reservations without deleting audit history.
  update public.service_bookings b set status='cancelled',
    cancelled_at=now(), cancel_request_id=gen_random_uuid(), credited_on_cancel=false
  where b.org_id=p_org and b.status='booked'
    and exists (select 1 from public.clients c
      where c.id=b.client_id and c.org_id=p_org and c.user_id=v_actor)
    and exists (select 1 from public.service_occurrences o
      where o.id=b.occurrence_id and o.starts_at>now());
  update public.athlete_workout_sharing
    set enabled=false,updated_at=now()
    where org_id=p_org and athlete_id=v_actor;
  update public.athlete_business_history_consents
    set revoked_at=now()
    where org_id=p_org and athlete_user_id=v_actor and revoked_at is null;
  update public.professional_training_sessions s
    set status='cancelled',updated_at=now()
    where s.org_id=p_org and s.status='scheduled'
    and exists (select 1 from public.clients c
      where c.org_id=p_org and c.id=s.client_id and c.user_id=v_actor);
  update public.service_passes p set status='cancelled'
    where p.org_id=p_org and p.status in ('active','paused')
    and exists (select 1 from public.clients c
      where c.org_id=p_org and c.id=p.client_id and c.user_id=v_actor);
  -- A cancelled CRM row is retained for billing/audit, but no longer linked.
  update public.clients
    set status='cancelled',user_id=null,updated_at=now()
    where org_id=p_org and user_id=v_actor;
  update public.organization_memberships
    set status='revoked'
    where organization_id=p_org and user_id=v_actor
      and role='athlete' and status='active';
  return true;
end $$;
revoke all on function private.leave_org_as_athlete(uuid)
  from public,anon,authenticated;
grant execute on function private.leave_org_as_athlete(uuid) to authenticated;
create or replace function public.leave_org_as_athlete(p_org uuid)
returns boolean language sql security invoker set search_path = '' as $$
  select private.leave_org_as_athlete(p_org);
$$;
revoke all on function public.leave_org_as_athlete(uuid) from public,anon;
grant execute on function public.leave_org_as_athlete(uuid) to authenticated;
notify pgrst,'reload schema';
