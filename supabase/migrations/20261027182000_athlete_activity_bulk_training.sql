-- Monthly activity counts and a day drilldown: backend paginates/limits personal data.
create or replace function private.platform_admin_athlete_activity(p_athlete uuid,p_month date)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_month date;v_result jsonb;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 if not exists(select 1 from auth.users where id=p_athlete) then
   raise exception 'ATHLETE_NOT_FOUND' using errcode='22023';end if;
 if p_month is null then raise exception 'INVALID_MONTH' using errcode='22023';end if;
 v_month:=date_trunc('month',p_month::timestamp)::date;
 select coalesce(jsonb_agg(jsonb_build_object('day',x.day,'count',x.n) order by x.day),'[]'::jsonb)
 into v_result from (
   select (w.started_at at time zone 'Europe/Madrid')::date as day,count(*) as n
   from public.athlete_workouts w where w.owner_id=p_athlete
   and w.started_at >= (v_month::timestamp at time zone 'Europe/Madrid')
   and w.started_at < ((v_month+interval '1 month')::timestamp at time zone 'Europe/Madrid')
   group by 1
 ) x;
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'athlete.activity.read',jsonb_build_object('athlete_id',p_athlete,'month',v_month));
 return v_result;
end $$;
revoke all on function private.platform_admin_athlete_activity(uuid,date) from public,anon,authenticated;
grant execute on function private.platform_admin_athlete_activity(uuid,date) to authenticated;
create or replace function public.platform_admin_athlete_activity(p_athlete uuid,p_month date)
returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_athlete_activity(p_athlete,p_month)
$$;
revoke all on function public.platform_admin_athlete_activity(uuid,date) from public,anon;
grant execute on function public.platform_admin_athlete_activity(uuid,date) to authenticated;

create or replace function private.platform_admin_athlete_day(p_athlete uuid,p_day date)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_result jsonb;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 if p_day is null or not exists(select 1 from auth.users where id=p_athlete) then
  raise exception 'ATHLETE_NOT_FOUND' using errcode='22023';end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',w.id,'title',w.title,'started_at',w.started_at,'finished_at',w.finished_at,
  'exercises',w.exercises,'wod_results',w.wod_results) order by w.started_at),'[]'::jsonb)
 into v_result from (select * from public.athlete_workouts
 where owner_id=p_athlete
 and started_at >= (p_day::timestamp at time zone 'Europe/Madrid')
 and started_at < ((p_day+1)::timestamp at time zone 'Europe/Madrid')
 order by started_at limit 100) w;
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'athlete.day.read',jsonb_build_object('athlete_id',p_athlete,'day',p_day));
 return v_result;
end $$;
revoke all on function private.platform_admin_athlete_day(uuid,date) from public,anon,authenticated;
grant execute on function private.platform_admin_athlete_day(uuid,date) to authenticated;
create or replace function public.platform_admin_athlete_day(p_athlete uuid,p_day date)
returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_athlete_day(p_athlete,p_day)
$$;
revoke all on function public.platform_admin_athlete_day(uuid,date) from public,anon;
grant execute on function public.platform_admin_athlete_day(uuid,date) to authenticated;

-- Atomic idempotent bulk publishing through the existing secure per-athlete writer.
create table if not exists public.business_bulk_training_batches(
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null unique,
 org_id uuid not null references public.organizations(id) on delete cascade,
 template_id uuid not null references public.professional_workout_templates(id),
 created_by uuid not null references auth.users(id),
 session_count integer not null check(session_count between 0 and 120),
 skipped_count integer not null default 0,
 date_from date not null,date_to date not null,
 created_at timestamptz not null default now()
);
alter table public.business_bulk_training_batches enable row level security;
revoke all on public.business_bulk_training_batches from public,anon,authenticated;

create or replace function private.business_publish_training_bulk(
 p_org uuid,p_template uuid,p_clients uuid[],p_start date,p_end date,
 p_weekdays integer[],p_request uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid();v_template public.professional_workout_templates%rowtype;
 v_client uuid;v_day date;v_created integer:=0;v_skipped integer:=0;
 v_batch public.business_bulk_training_batches%rowtype;v_targets integer;v_days integer;
begin
 if v_actor is null or p_request is null or not private.has_org_role(p_org,
 array['owner','admin','coach']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 if p_start is null or p_end is null or p_start<current_date or p_end<p_start
 or p_end>p_start+55 or p_end>current_date+interval '18 months'
 then raise exception 'INVALID_DATE_RANGE' using errcode='22023';end if;
 if p_clients is null or cardinality(p_clients) not between 1 and 20
 or cardinality(array(select distinct unnest(p_clients)))<>cardinality(p_clients)
 or array_position(p_clients,null) is not null
 then raise exception 'INVALID_CLIENT_SELECTION' using errcode='22023';end if;
 if p_weekdays is null or cardinality(p_weekdays) not between 1 and 7
 or exists(select 1 from unnest(p_weekdays) d where d<1 or d>7)
 then raise exception 'INVALID_WEEKDAY_SELECTION' using errcode='22023';end if;
 select * into v_template from public.professional_workout_templates
 where id=p_template and org_id=p_org;
 if not found or not private.validate_professional_prescription(v_template.prescription)
 then raise exception 'INVALID_TEMPLATE' using errcode='22023';end if;
 v_days:=(select count(*) from generate_series(p_start,p_end,interval '1 day') d
 where extract(isodow from d)::int=any(p_weekdays));
 if v_days*cardinality(p_clients)>120 or v_days=0 then
  raise exception 'BULK_LIMIT_EXCEEDED' using errcode='22023';end if;
 perform pg_advisory_xact_lock(hashtextextended('bulktraining:'||p_request::text,0));
 select * into v_batch from public.business_bulk_training_batches where request_id=p_request;
 if found then
  if v_batch.org_id<>p_org or v_batch.template_id<>p_template or
    v_batch.date_from<>p_start or v_batch.date_to<>p_end or v_batch.created_by<>v_actor
  then raise exception 'REQUEST_ID_REUSED' using errcode='23505';end if;
  return jsonb_build_object('created',v_batch.session_count,'skipped',v_batch.skipped_count,'replayed',true);
 end if;
 foreach v_client in array p_clients loop
  for v_day in select d::date from generate_series(p_start,p_end,interval '1 day') d
   where extract(isodow from d)::int=any(p_weekdays) loop
    if exists(select 1 from public.professional_training_sessions s
       where s.org_id=p_org and s.client_id=v_client and s.scheduled_date=v_day
       and s.title=v_template.name and s.status='scheduled') then
       v_skipped:=v_skipped+1;
    else
       perform private.publish_professional_session_v2(p_org,v_client,v_day,v_template.name,
          coalesce(v_template.description,''),gen_random_uuid(),v_template.prescription);
       v_created:=v_created+1;
    end if;
   end loop;
 end loop;
 insert into public.business_bulk_training_batches(
  request_id,org_id,template_id,created_by,session_count,skipped_count,date_from,date_to)
 values(p_request,p_org,p_template,v_actor,v_created,v_skipped,p_start,p_end);
 return jsonb_build_object('created',v_created,'skipped',v_skipped,'replayed',false);
end $$;
revoke all on function private.business_publish_training_bulk(uuid,uuid,uuid[],date,date,integer[],uuid)
 from public,anon,authenticated;
grant execute on function private.business_publish_training_bulk(uuid,uuid,uuid[],date,date,integer[],uuid)
 to authenticated;
create or replace function public.business_publish_training_bulk(
 p_org uuid,p_template uuid,p_clients uuid[],p_start date,p_end date,
 p_weekdays integer[],p_request uuid)
returns jsonb language sql security invoker set search_path='' as $$
 select private.business_publish_training_bulk(p_org,p_template,p_clients,p_start,p_end,p_weekdays,p_request)
$$;
revoke all on function public.business_publish_training_bulk(uuid,uuid,uuid[],date,date,integer[],uuid)
 from public,anon;
grant execute on function public.business_publish_training_bulk(uuid,uuid,uuid[],date,date,integer[],uuid)
 to authenticated;

notify pgrst,'reload schema';
