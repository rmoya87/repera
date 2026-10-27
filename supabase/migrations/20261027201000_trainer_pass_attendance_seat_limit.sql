-- Repera Business: bonificaciones manuales verificadas externamente,
-- asistencia presencial con descuento atómico y aforo de planes de entrenador.
-- NUNCA constituye prueba de cobro en la pasarela Repera.

alter table public.service_passes
 drop constraint if exists service_passes_issuance_type_check;
alter table public.service_passes
 add constraint service_passes_issuance_type_check
 check(issuance_type in ('complimentary','manual_offline'));
alter table public.service_passes
 add column if not exists offer_id uuid references public.business_pass_offers(id),
 add column if not exists issuance_request_id uuid unique;

alter table public.service_credit_ledger
 drop constraint if exists service_credit_ledger_event_check;
alter table public.service_credit_ledger
 add constraint service_credit_ledger_event_check
 check(event in ('complimentary_grant','booking_debit','cancellation_credit',
                 'offline_pass_grant','trainer_attendance_debit'));
alter table public.service_credit_ledger
 drop constraint if exists service_ledger_amount_ck;
alter table public.service_credit_ledger
 add constraint service_ledger_amount_ck check(
  (event in ('complimentary_grant','offline_pass_grant')
    and amount between 1 and 1000 and booking_id is null)
  or (event='booking_debit' and amount=-1 and booking_id is not null)
  or (event='cancellation_credit' and amount=1 and booking_id is not null)
  or (event='trainer_attendance_debit' and amount=-1 and booking_id is null)
 );

create table if not exists public.business_trainer_attendance (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id),
 client_id uuid not null,
 pass_id uuid not null,
 booking_id uuid unique,
 occurrence_id uuid references public.service_occurrences(id),
 request_id uuid not null unique,
 performed_at timestamptz not null default now(),
 recorded_by uuid not null references auth.users(id),
 note text not null default '' check(length(note)<=1000),
 foreign key(org_id,client_id) references public.clients(org_id,id),
 foreign key(org_id,pass_id) references public.service_passes(org_id,id),
 foreign key(org_id,booking_id) references public.service_bookings(org_id,id)
);
create unique index if not exists business_attendance_once_per_occurrence
 on public.business_trainer_attendance(occurrence_id,client_id)
 where occurrence_id is not null;
create index if not exists business_attendance_client_date
 on public.business_trainer_attendance(org_id,client_id,performed_at desc);
alter table public.business_trainer_attendance enable row level security;
revoke all on public.business_trainer_attendance from public,anon,authenticated;
grant select on public.business_trainer_attendance to authenticated;
create policy business_attendance_read on public.business_trainer_attendance
 for select to authenticated using (
  private.has_org_role(org_id,array['owner','admin']::public.organization_role[])
  or private.is_assigned_coach(org_id,client_id)
 );

alter table public.service_credit_ledger
 add column if not exists attendance_id uuid references public.business_trainer_attendance(id);
create unique index if not exists service_credit_ledger_attendance_once
 on public.service_credit_ledger(attendance_id) where attendance_id is not null;

create or replace function private.business_issue_offline_pass(
 p_org uuid,p_client uuid,p_offer uuid,p_request uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_offer public.business_pass_offers%rowtype;
 v_id uuid;v_actor uuid:=auth.uid();v_previous public.service_passes%rowtype;
begin
 if v_actor is null or p_request is null or
   not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 perform pg_advisory_xact_lock(hashtextextended('manual_pass:'||p_request::text,0));
 select * into v_previous from public.service_passes
  where issuance_request_id=p_request;
 if found then
  if v_previous.org_id<>p_org or v_previous.client_id<>p_client
    or v_previous.offer_id is distinct from p_offer
    or v_previous.issued_by<>v_actor then
   raise exception 'REQUEST_REUSE' using errcode='23505';
  end if;
  return v_previous.id;
 end if;
 select * into v_offer from public.business_pass_offers
  where id=p_offer and org_id=p_org and is_active;
 if not found or not exists(
  select 1 from public.clients c where c.id=p_client and c.org_id=p_org
   and c.user_id is not null and c.status='active'
 ) then raise exception 'OFFER_OR_CLIENT_UNAVAILABLE' using errcode='22023';end if;
 insert into public.service_passes(
  org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,
  issued_by,issuance_type,offer_id,issuance_request_id
 ) values(
  p_org,p_client,v_offer.kind,v_offer.credits,v_offer.credits,now(),
  now()+make_interval(days=>v_offer.validity_days),
  v_actor,'manual_offline',p_offer,p_request
 ) returning id into v_id;
 insert into public.service_credit_ledger(org_id,pass_id,event,amount,created_by)
 values(p_org,v_id,'offline_pass_grant',v_offer.credits,v_actor);
 return v_id;
end $$;
revoke all on function private.business_issue_offline_pass(uuid,uuid,uuid,uuid)
 from public,anon,authenticated;
grant execute on function private.business_issue_offline_pass(uuid,uuid,uuid,uuid) to authenticated;
create or replace function public.business_issue_offline_pass(
 p_org uuid,p_client uuid,p_offer uuid,p_request uuid
) returns uuid language sql security invoker set search_path='' as $$
 select private.business_issue_offline_pass(p_org,p_client,p_offer,p_request)
$$;
revoke all on function public.business_issue_offline_pass(uuid,uuid,uuid,uuid) from public,anon;
grant execute on function public.business_issue_offline_pass(uuid,uuid,uuid,uuid) to authenticated;

create or replace function private.business_record_trainer_attendance(
 p_org uuid,p_client uuid,p_pass uuid,p_occurrence uuid,p_note text,p_request uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_pass public.service_passes%rowtype;
 v_id uuid;v_actor uuid:=auth.uid();v_existing public.business_trainer_attendance%rowtype;
 v_booking uuid;v_occ public.service_occurrences%rowtype;
begin
 if v_actor is null or p_request is null or length(coalesce(p_note,''))>1000
  or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 perform pg_advisory_xact_lock(hashtextextended('trainer_attendance:'||p_request::text,0));
 select * into v_existing from public.business_trainer_attendance where request_id=p_request;
 if found then
  if v_existing.org_id<>p_org or v_existing.client_id<>p_client
    or v_existing.pass_id<>p_pass or v_existing.recorded_by<>v_actor
    or v_existing.occurrence_id is distinct from p_occurrence then
   raise exception 'REQUEST_REUSE' using errcode='23505';end if;
  return v_existing.id;
 end if;
 if not exists(select 1 from public.organizations o
  where o.id=p_org and o.kind='personal_trainer') then
  raise exception 'ONLY_PERSONAL_TRAINER' using errcode='22023';end if;
 if not exists(select 1 from public.clients c
  where c.id=p_client and c.org_id=p_org and c.status='active' and c.user_id is not null) then
  raise exception 'CLIENT_NOT_LINKED' using errcode='22023';end if;
 if p_occurrence is not null then
  select * into v_occ from public.service_occurrences where id=p_occurrence for update;
  if not found or v_occ.org_id<>p_org or v_occ.kind<>'appointment'
    or v_occ.status<>'active'
    or v_occ.starts_at>now()+interval '1 hour'
    or v_occ.starts_at<now()-interval '7 days' then
   raise exception 'APPOINTMENT_NOT_STARTED' using errcode='22023';end if;
  if exists(select 1 from public.business_trainer_attendance a
   where a.occurrence_id=p_occurrence and a.client_id=p_client) then
   raise exception 'ALREADY_RECORDED' using errcode='23505';end if;
  -- Una reserva existente YA descontó el crédito: registrar asistencia sin doble cobro.
  select b.id into v_booking from public.service_bookings b
    where b.occurrence_id=p_occurrence and b.client_id=p_client and b.status='booked'
    for update;
 end if;
 select * into v_pass from public.service_passes where id=p_pass
    and org_id=p_org and client_id=p_client for update;
 if not found or (v_booking is not null and not exists(select 1 from public.service_bookings b where b.id=v_booking and b.pass_id=p_pass))
  or v_pass.kind<>'appointment' or v_pass.status<>'active'
  or (v_booking is null and v_pass.remaining_credits<1)
  or v_pass.valid_from>now() or v_pass.valid_until<now()
 then raise exception 'INSUFFICIENT_PASS' using errcode='22023';end if;
 insert into public.business_trainer_attendance(
  org_id,client_id,pass_id,booking_id,occurrence_id,request_id,recorded_by,note
 ) values(p_org,p_client,p_pass,v_booking,p_occurrence,p_request,v_actor,btrim(coalesce(p_note,'')))
 returning id into v_id;
 if v_booking is null then
  update public.service_passes set remaining_credits=remaining_credits-1 where id=p_pass;
  insert into public.service_credit_ledger(org_id,pass_id,attendance_id,event,amount,created_by)
  values(p_org,p_pass,v_id,'trainer_attendance_debit',-1,v_actor);
 end if;
 return v_id;
end $$;
revoke all on function private.business_record_trainer_attendance(
 uuid,uuid,uuid,uuid,text,uuid) from public,anon,authenticated;
grant execute on function private.business_record_trainer_attendance(
 uuid,uuid,uuid,uuid,text,uuid) to authenticated;
create or replace function public.business_record_trainer_attendance(
 p_org uuid,p_client uuid,p_pass uuid,p_occurrence uuid,p_note text,p_request uuid
) returns uuid language sql security invoker set search_path='' as $$
 select private.business_record_trainer_attendance(
  p_org,p_client,p_pass,p_occurrence,p_note,p_request)
$$;
revoke all on function public.business_record_trainer_attendance(
 uuid,uuid,uuid,uuid,text,uuid) from public,anon;
grant execute on function public.business_record_trainer_attendance(
 uuid,uuid,uuid,uuid,text,uuid) to authenticated;

-- A linked client occupies one capacity slot. Leads/pending invitations do not.
create or replace function private.enforce_trainer_client_limit()
 returns trigger language plpgsql security definer set search_path='' as $$
declare v_kind text;v_cap integer;v_used integer;
begin
 if new.user_id is null or new.status not in('active','paused','trial') then return new;end if;
 if tg_op='UPDATE' and old.user_id is not distinct from new.user_id
   and old.status in('active','paused','trial') and old.org_id=new.org_id then return new;end if;
 select kind into v_kind from public.organizations where id=new.org_id;
 if v_kind<>'personal_trainer' then return new;end if;
 perform pg_advisory_xact_lock(hashtextextended('trainer_seats:'||new.org_id::text,0));
 select case when t.paid_plan is not null and t.paid_until>now()
  then (select bp.max_clients from public.business_plans bp
    where bp.plan_key=t.paid_plan and bp.audience='personal_trainer')
  when t.trial_ends_at>now() then 5
  else 0 end into v_cap
 from public.organization_trials t where t.org_id=new.org_id;
 v_cap:=coalesce(v_cap,0);
 select count(*) into v_used from public.clients c
  where c.org_id=new.org_id and c.user_id is not null
    and c.status in('active','paused','trial') and c.id is distinct from new.id;
 if v_used>=v_cap then
  raise exception 'TRAINER_CLIENT_LIMIT_REACHED: % of %',v_used,v_cap
   using errcode='23514';
 end if;
 return new;
end $$;
drop trigger if exists enforce_trainer_client_limit on public.clients;
create trigger enforce_trainer_client_limit before insert or update of
 org_id,user_id,status on public.clients
 for each row execute function private.enforce_trainer_client_limit();
revoke all on function private.enforce_trainer_client_limit() from public,anon,authenticated;
notify pgrst,'reload schema';


-- Planificación masiva sin obligar a guardar previamente una plantilla.
-- El lote es atómico: todas las asignaciones se guardan o ninguna.
create table if not exists private.business_custom_bulk_requests (
 request_id uuid primary key,
 org_id uuid not null,
 created_by uuid not null,
 fingerprint text not null,
 created_count integer not null,
 skipped_count integer not null,
 created_at timestamptz not null default now()
);
revoke all on private.business_custom_bulk_requests from public,anon,authenticated;

create or replace function private.business_publish_custom_training_bulk(
 p_org uuid,p_clients uuid[],p_start date,p_end date,p_weekdays integer[],
 p_title text,p_instructions text,p_prescription jsonb,p_request uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid();v_client uuid;v_day date;
 v_days integer;v_created integer:=0;v_skipped integer:=0;v_fingerprint text;
 v_old private.business_custom_bulk_requests%rowtype;
begin
 if v_actor is null or p_request is null or not private.has_org_role(
  p_org,array['owner','admin','coach']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 if p_start is null or p_end is null or p_start<current_date
  or p_end<p_start or p_end>p_start+55 or p_end>current_date+interval '18 months'
 then raise exception 'INVALID_DATE_RANGE' using errcode='22023';end if;
 if p_clients is null or cardinality(p_clients) not between 1 and 20
  or cardinality(array(select distinct unnest(p_clients)))<>cardinality(p_clients)
  or array_position(p_clients,null) is not null
 then raise exception 'INVALID_CLIENTS' using errcode='22023';end if;
 if p_weekdays is null or cardinality(p_weekdays) not between 1 and 7
  or exists(select 1 from unnest(p_weekdays) d where d not between 1 and 7)
 then raise exception 'INVALID_WEEKDAYS' using errcode='22023';end if;
 if length(btrim(coalesce(p_title,''))) not between 2 and 120
  or length(coalesce(p_instructions,''))>10000
  or not private.validate_professional_prescription(p_prescription)
 then raise exception 'INVALID_WORKOUT' using errcode='22023';end if;
 v_days:=(select count(*) from generate_series(p_start,p_end,interval '1 day') d
   where extract(isodow from d)::int=any(p_weekdays));
 if v_days=0 or v_days*cardinality(p_clients)>120 then
  raise exception 'BULK_LIMIT_EXCEEDED' using errcode='22023';end if;
 v_fingerprint:=md5(jsonb_build_object(
  'org',p_org,'clients',p_clients,'start',p_start,'end',p_end,
  'weekdays',p_weekdays,'title',p_title,'instructions',p_instructions,
  'prescription',p_prescription)::text);
 perform pg_advisory_xact_lock(hashtextextended('custom_bulk:'||p_request::text,0));
 select * into v_old from private.business_custom_bulk_requests
   where request_id=p_request;
 if found then
  if v_old.org_id<>p_org or v_old.created_by<>v_actor
   or v_old.fingerprint<>v_fingerprint then
   raise exception 'REQUEST_ID_REUSED' using errcode='23505';end if;
  return jsonb_build_object('created',v_old.created_count,
    'skipped',v_old.skipped_count,'replayed',true);
 end if;
 foreach v_client in array p_clients loop
  for v_day in select d::date from generate_series(p_start,p_end,interval '1 day') d
   where extract(isodow from d)::int=any(p_weekdays) loop
   if exists(select 1 from public.professional_training_sessions s
     where s.org_id=p_org and s.client_id=v_client and s.scheduled_date=v_day
      and s.title=p_title and s.status='scheduled') then
    v_skipped:=v_skipped+1;
   else
    perform private.publish_professional_session_v2(p_org,v_client,v_day,
       p_title,coalesce(p_instructions,''),gen_random_uuid(),p_prescription);
    v_created:=v_created+1;
   end if;
  end loop;
 end loop;
 insert into private.business_custom_bulk_requests(
  request_id,org_id,created_by,fingerprint,created_count,skipped_count)
 values(p_request,p_org,v_actor,v_fingerprint,v_created,v_skipped);
 return jsonb_build_object('created',v_created,'skipped',v_skipped,'replayed',false);
end $$;
revoke all on function private.business_publish_custom_training_bulk(
 uuid,uuid[],date,date,integer[],text,text,jsonb,uuid) from public,anon,authenticated;
grant execute on function private.business_publish_custom_training_bulk(
 uuid,uuid[],date,date,integer[],text,text,jsonb,uuid) to authenticated;
create or replace function public.business_publish_custom_training_bulk(
 p_org uuid,p_clients uuid[],p_start date,p_end date,p_weekdays integer[],
 p_title text,p_instructions text,p_prescription jsonb,p_request uuid
) returns jsonb language sql security invoker set search_path='' as $$
 select private.business_publish_custom_training_bulk(
  p_org,p_clients,p_start,p_end,p_weekdays,p_title,p_instructions,p_prescription,p_request)
$$;
revoke all on function public.business_publish_custom_training_bulk(
 uuid,uuid[],date,date,integer[],text,text,jsonb,uuid) from public,anon;
grant execute on function public.business_publish_custom_training_bulk(
 uuid,uuid[],date,date,integer[],text,text,jsonb,uuid) to authenticated;
notify pgrst,'reload schema';
