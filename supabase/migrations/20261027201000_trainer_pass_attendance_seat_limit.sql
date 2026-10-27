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
