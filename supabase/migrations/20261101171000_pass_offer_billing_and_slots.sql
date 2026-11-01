-- billing_model + franjas horarias (citas entrenador / acceso gym).
-- Idempotente; recarga PostgREST.

alter table public.business_pass_offers
  add column if not exists billing_model text not null default 'session_pack';

-- Ampliar check (drop + add) para incluir time_slot.
alter table public.business_pass_offers
  drop constraint if exists business_pass_offers_billing_model_check;
alter table public.business_pass_offers
  add constraint business_pass_offers_billing_model_check
  check (billing_model in ('session_pack','monthly','unlimited','time_slot'));

-- Cupo interno alto para mensual/ilimitado/franja.
alter table public.business_pass_offers
  drop constraint if exists business_pass_offers_credits_check;
alter table public.business_pass_offers
  add constraint business_pass_offers_credits_check
  check (credits between 1 and 9999);

alter table public.business_pass_offers
  add column if not exists access_scope text not null default 'trainer_appointments';
alter table public.business_pass_offers
  drop constraint if exists business_pass_offers_access_scope_check;
alter table public.business_pass_offers
  add constraint business_pass_offers_access_scope_check
  check (access_scope in ('trainer_appointments','gym_access'));

alter table public.business_pass_offers
  add column if not exists slot_weekdays int[] not null default '{1,2,3,4,5}'::int[],
  add column if not exists slot_start_minute int not null default 540,
  add column if not exists slot_end_minute int not null default 720;

alter table public.business_pass_offers
  drop constraint if exists business_pass_offers_slot_weekdays_check;
alter table public.business_pass_offers
  add constraint business_pass_offers_slot_weekdays_check
  check (
    cardinality(slot_weekdays) between 1 and 7
    and slot_weekdays <@ array[1,2,3,4,5,6,7]::int[]
  );

alter table public.business_pass_offers
  drop constraint if exists business_pass_offers_slot_minutes_check;
alter table public.business_pass_offers
  add constraint business_pass_offers_slot_minutes_check
  check (
    slot_start_minute between 0 and 1439
    and slot_end_minute between 1 and 1440
    and slot_end_minute > slot_start_minute
  );

-- Espejo en passes emitidos (por si cambia la oferta).
alter table public.service_passes
  add column if not exists billing_model text,
  add column if not exists access_scope text,
  add column if not exists slot_weekdays int[],
  add column if not exists slot_start_minute int,
  add column if not exists slot_end_minute int;

create or replace function private.pass_allows_occurrence(
  p_pass public.service_passes, p_occ public.service_occurrences
) returns boolean language plpgsql stable set search_path='' as $$
declare
  v_local timestamptz;
  v_dow int;
  v_minute int;
  v_scope text := coalesce(p_pass.access_scope,'trainer_appointments');
  v_model text := coalesce(p_pass.billing_model,'session_pack');
begin
  -- Alcance: citas 1:1 vs clases/acceso gym.
  if v_scope = 'trainer_appointments' and p_occ.kind <> 'appointment' then
    return false;
  end if;
  if v_scope = 'gym_access' and p_occ.kind <> 'class' then
    return false;
  end if;

  if v_model <> 'time_slot' then
    return true;
  end if;
  if p_pass.slot_weekdays is null or p_pass.slot_start_minute is null or p_pass.slot_end_minute is null then
    return false;
  end if;

  -- Día/hora en TZ Europe/Madrid (negocios ES).
  v_local := p_occ.starts_at at time zone 'Europe/Madrid';
  v_dow := extract(isodow from v_local)::int; -- 1=lun … 7=dom
  v_minute := (extract(hour from v_local)::int * 60) + extract(minute from v_local)::int;

  if not (v_dow = any (p_pass.slot_weekdays)) then
    return false;
  end if;
  if v_minute < p_pass.slot_start_minute or v_minute >= p_pass.slot_end_minute then
    return false;
  end if;
  return true;
end $$;

-- Actualizar issue offline para copiar franja.
create or replace function private.business_issue_offline_pass(
 p_org uuid,p_client uuid,p_offer uuid,p_request uuid,
 p_payment_method text default 'other',
 p_paid_at timestamptz default null,
 p_paid_amount_cents integer default null,
 p_payment_note text default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_offer public.business_pass_offers%rowtype;
 v_id uuid;v_actor uuid:=auth.uid();v_previous public.service_passes%rowtype;
 v_kind text; v_cap integer; v_used integer;
 v_paid text; v_paid_until timestamptz; v_trial timestamptz;
 v_already boolean;
 v_method text := coalesce(nullif(btrim(p_payment_method),''),'other');
 v_paid_at timestamptz := coalesce(p_paid_at, now());
 v_amount integer;
 v_note text := nullif(btrim(coalesce(p_payment_note,'')),'');
 v_pass_kind text;
begin
 if v_actor is null or p_request is null or
   not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 if v_method not in ('card','transfer','cash','other','complimentary') then
  raise exception 'INVALID_PAYMENT_METHOD' using errcode='22023';
 end if;
 if v_note is not null and length(v_note) > 400 then
  raise exception 'INVALID_PAYMENT_NOTE' using errcode='22023';
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
   and c.user_id is not null and c.status='active' and c.account_deleted_at is null
 ) then raise exception 'OFFER_OR_CLIENT_UNAVAILABLE' using errcode='22023';end if;

 v_amount := coalesce(p_paid_amount_cents, v_offer.price_cents);
 if v_amount < 0 or v_amount > 10000000 then
  raise exception 'INVALID_PAYMENT_AMOUNT' using errcode='22023';
 end if;
 if v_method = 'complimentary' then v_amount := 0; end if;

 -- kind efectivo según alcance de la tarifa.
 v_pass_kind := case
   when coalesce(v_offer.access_scope,'trainer_appointments')='gym_access' then 'class'
   else coalesce(nullif(v_offer.kind,''),'appointment')
 end;
 if v_pass_kind not in ('class','appointment') then v_pass_kind:='appointment'; end if;

 select kind into v_kind from public.organizations where id=p_org;
 if v_kind='personal_trainer' then
  perform pg_advisory_xact_lock(hashtextextended('trainer_seats:'||p_org::text,0));
  select t.paid_plan,t.paid_until,t.trial_ends_at into v_paid,v_paid_until,v_trial
   from public.organization_trials t where t.org_id=p_org;
  if v_paid is not null and v_paid_until>now() then
   select bp.max_clients into v_cap from public.business_plans bp
    where bp.plan_key=v_paid and bp.audience='personal_trainer';
  else
   v_cap := case when v_trial>now() then 5 else 0 end;
  end if;
  if v_cap is null then v_cap:=0; end if;
  select exists(
    select 1 from public.service_passes p
    where p.org_id=p_org and p.client_id=p_client and p.status='active'
      and p.valid_until>=now() and p.remaining_credits>0
  ) into v_already;
  v_used := private.count_commercially_active_clients(p_org);
  if not v_already and v_used >= v_cap then
   raise exception 'TRAINER_CLIENT_LIMIT' using errcode='P0001';
  end if;
 end if;

 insert into public.service_passes(
  org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,
  issued_by,issuance_type,offer_id,issuance_request_id,
  payment_method,paid_at,paid_amount_cents,payment_note,
  billing_model,access_scope,slot_weekdays,slot_start_minute,slot_end_minute
 ) values(
  p_org,p_client,v_pass_kind,v_offer.credits,v_offer.credits,now(),
  now()+make_interval(days=>v_offer.validity_days),
  v_actor,'manual_offline',p_offer,p_request,
  v_method,v_paid_at,v_amount,v_note,
  v_offer.billing_model,v_offer.access_scope,v_offer.slot_weekdays,
  v_offer.slot_start_minute,v_offer.slot_end_minute
 ) returning id into v_id;
 insert into public.service_credit_ledger(org_id,pass_id,event,amount,created_by)
 values(p_org,v_id,'offline_pass_grant',v_offer.credits,v_actor);
 return v_id;
end $$;

create or replace function private.book_service_occurrence(p_occurrence uuid,p_pass uuid,p_request uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare
 v_actor uuid:=auth.uid(); v_occ public.service_occurrences%rowtype;
 v_pass public.service_passes%rowtype; v_client_id uuid; v_booking uuid;
 v_existing public.service_bookings%rowtype;
begin
 if v_actor is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('service_book:'||p_request::text,0));
 select * into v_existing from public.service_bookings where request_id=p_request;
 if found then
  if v_existing.occurrence_id<>p_occurrence or v_existing.pass_id<>p_pass
     or v_existing.requested_by<>v_actor then
   raise exception 'REQUEST_ID_REUSED' using errcode='23505';
  end if;
  return v_existing.id;
 end if;
 select * into v_occ from public.service_occurrences where id=p_occurrence for update;
 if not found or v_occ.status<>'active' or v_occ.starts_at<=now() then
   raise exception 'OCCURRENCE_UNAVAILABLE' using errcode='22023'; end if;
 if not private.has_org_role(v_occ.org_id,array['athlete']::public.organization_role[]) then
   raise exception 'NOT_A_MEMBER' using errcode='42501'; end if;
 select * into v_pass from public.service_passes where id=p_pass and org_id=v_occ.org_id for update;
 if not found or v_pass.kind<>v_occ.kind or v_pass.status<>'active'
    or v_pass.remaining_credits<1 or v_pass.valid_from>v_occ.starts_at
    or v_pass.valid_until<v_occ.starts_at then
   raise exception 'NO_VALID_PASS' using errcode='22023'; end if;
 if not private.pass_allows_occurrence(v_pass, v_occ) then
   raise exception 'PASS_OUTSIDE_SLOT' using errcode='22023';
 end if;
 v_client_id:=v_pass.client_id;
 if not private.owns_org_client(v_occ.org_id,v_client_id) then
   raise exception 'NOT_OWN_PASS' using errcode='42501'; end if;
 if exists(select 1 from public.service_bookings b
   where b.occurrence_id=v_occ.id and b.client_id=v_client_id
     and b.status in ('booked','attended')) then
   raise exception 'ALREADY_BOOKED' using errcode='23505'; end if;
 if (select count(*) from public.service_bookings b
       where b.occurrence_id=v_occ.id and b.status in ('booked','attended'))>=v_occ.capacity then
   raise exception 'NO_AVAILABILITY' using errcode='22023'; end if;
 insert into public.service_bookings(org_id,occurrence_id,client_id,pass_id,requested_by,request_id)
 values(v_occ.org_id,v_occ.id,v_client_id,v_pass.id,v_actor,p_request) returning id into v_booking;
 update public.service_passes set remaining_credits=remaining_credits-1 where id=v_pass.id;
 insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
 values(v_occ.org_id,v_pass.id,v_booking,'booking_debit',-1,v_actor);
 return v_booking;
end; $$;

create or replace function private.enroll_managed_client(
 p_occ uuid,p_client uuid,p_pass uuid,p_request uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.service_occurrences%rowtype; pass public.service_passes%rowtype; row_id uuid;
begin
 if auth.uid() is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('managed_enroll:'||p_request::text,0));
 if exists(select 1 from public.service_bookings where request_id=p_request and (occurrence_id<>p_occ or client_id<>p_client or pass_id<>p_pass or requested_by<>auth.uid())) then
  raise exception 'REQUEST_ID_REUSED' using errcode='23505'; end if;
 select id into row_id from public.service_bookings where request_id=p_request;
 if found then return row_id; end if;
 select * into v from public.service_occurrences where id=p_occ for update;
 if not found or v.status<>'active' or v.starts_at<=now() then
   raise exception 'CLASS_UNAVAILABLE' using errcode='22023'; end if;
 if not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 select * into pass from public.service_passes where id=p_pass and org_id=v.org_id and client_id=p_client for update;
 if not found or pass.status<>'active' or pass.kind<>v.kind or pass.remaining_credits<1
 or pass.valid_from>v.starts_at or pass.valid_until<v.starts_at then
   raise exception 'NO_VALID_PASS' using errcode='22023'; end if;
 if not private.pass_allows_occurrence(pass, v) then
   raise exception 'PASS_OUTSIDE_SLOT' using errcode='22023';
 end if;
 if exists(select 1 from public.service_bookings where occurrence_id=p_occ and client_id=p_client and status in ('booked','attended'))
    or (select count(*) from public.service_bookings where occurrence_id=p_occ and status in ('booked','attended'))>=v.capacity then
   raise exception 'CLASS_FULL_OR_DUPLICATE' using errcode='22023'; end if;
 insert into public.service_bookings(org_id,occurrence_id,client_id,pass_id,requested_by,request_id)
 values(v.org_id,p_occ,p_client,p_pass,auth.uid(),p_request) returning id into row_id;
 update public.service_passes set remaining_credits=remaining_credits-1 where id=p_pass;
 insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
 values(v.org_id,p_pass,row_id,'booking_debit',-1,auth.uid());
 return row_id;
end; $$;

notify pgrst, 'reload schema';
