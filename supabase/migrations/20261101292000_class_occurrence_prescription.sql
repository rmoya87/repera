-- Prescripción de clase a nivel occurrence (plantilla) + fan-out a inscritos vinculados.
-- Permite asociar el entreno antes de que haya apuntados; al reservar se materializa.

alter table public.service_occurrence_details
  add column if not exists training_title text,
  add column if not exists training_instructions text not null default '',
  add column if not exists prescription jsonb;

alter table public.service_occurrence_details
  drop constraint if exists service_occurrence_details_training_title_check;
alter table public.service_occurrence_details
  add constraint service_occurrence_details_training_title_check
  check (training_title is null or length(btrim(training_title)) between 2 and 120);

alter table public.service_occurrence_details
  drop constraint if exists service_occurrence_details_training_instructions_check;
alter table public.service_occurrence_details
  add constraint service_occurrence_details_training_instructions_check
  check (length(coalesce(training_instructions, '')) <= 10000);

comment on column public.service_occurrence_details.prescription is
  'Prescripción canónica v1 asociada a la clase; se publica a cada inscrito vinculado.';

create or replace function private.ensure_class_training_for_client(
  p_occurrence uuid,
  p_client uuid
) returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v public.service_occurrences%rowtype;
  d public.service_occurrence_details%rowtype;
  c public.clients%rowtype;
  existing_id uuid;
  plan_date date;
  title text;
begin
  select * into v from public.service_occurrences where id = p_occurrence;
  if not found or v.status <> 'active' then
    return null;
  end if;
  select * into d from public.service_occurrence_details where occurrence_id = p_occurrence;
  if not found or d.prescription is null
     or not private.validate_professional_prescription(d.prescription) then
    return null;
  end if;
  select * into c from public.clients where id = p_client and org_id = v.org_id;
  if not found or c.user_id is null or c.status <> 'active' then
    return null;
  end if;
  select (v.starts_at at time zone coalesce(o.timezone, 'Europe/Madrid'))::date
    into plan_date
  from public.organizations o where o.id = v.org_id;
  title := coalesce(nullif(btrim(d.training_title), ''), v.title);
  select id into existing_id
  from public.professional_training_sessions
  where org_id = v.org_id and client_id = p_client and source_occurrence_id = p_occurrence
    and status = 'scheduled'
  order by created_at desc limit 1
  for update;
  if found then
    perform private.update_professional_session_v2(
      existing_id, plan_date, title, coalesce(d.training_instructions, ''), d.prescription);
    return existing_id;
  end if;
  insert into public.professional_training_sessions
    (org_id, client_id, coach_user_id, scheduled_date, title, instructions,
     prescription, publish_request_id, source_occurrence_id)
  values (
    v.org_id, p_client, coalesce(v.coach_user_id, auth.uid()), plan_date, title,
    coalesce(d.training_instructions, ''), d.prescription, gen_random_uuid(), p_occurrence)
  returning id into existing_id;
  return existing_id;
end;
$$;

revoke all on function private.ensure_class_training_for_client(uuid, uuid) from public, anon, authenticated;

create or replace function private.publish_class_training(
  p_occurrence uuid, p_title text, p_instructions text, p_prescription jsonb
) returns int
language plpgsql
security definer
set search_path to ''
as $$
declare
  v public.service_occurrences%rowtype;
  enrolled record;
  published int := 0;
  title text := btrim(coalesce(p_title, ''));
  instructions text := coalesce(p_instructions, '');
begin
  select * into v from public.service_occurrences where id = p_occurrence;
  if not found or v.status <> 'active' or v.starts_at <= now() then
    raise exception 'CLASS_NOT_EDITABLE' using errcode = '22023';
  end if;
  if not private.has_org_role(v.org_id, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if length(title) not between 2 and 120
     or length(instructions) > 10000
     or not private.validate_professional_prescription(p_prescription) then
    raise exception 'INVALID_PRESCRIPTION' using errcode = '22023';
  end if;

  insert into public.service_occurrence_details as det
    (occurrence_id, org_id, training_title, training_instructions, prescription)
  values (v.id, v.org_id, title, instructions, p_prescription)
  on conflict (occurrence_id) do update set
    training_title = excluded.training_title,
    training_instructions = excluded.training_instructions,
    prescription = excluded.prescription;

  for enrolled in
    select b.client_id
    from public.service_bookings b
    join public.clients c on c.id = b.client_id and c.org_id = b.org_id
    where b.occurrence_id = p_occurrence
      and b.status in ('booked', 'attended')
      and c.user_id is not null
      and c.status = 'active'
  loop
    if private.ensure_class_training_for_client(p_occurrence, enrolled.client_id) is not null then
      published := published + 1;
    end if;
  end loop;
  return published;
end;
$$;

-- Tras apuntarse / inscripción manual, materializar el plan de clase si existe.
create or replace function private.book_service_occurrence(p_occurrence uuid, p_pass uuid, p_request uuid)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_actor uuid := auth.uid();
  v_occ public.service_occurrences%rowtype;
  v_pass public.service_passes%rowtype;
  v_client_id uuid;
  v_booking uuid;
  v_existing public.service_bookings%rowtype;
  v_reserved int;
  v_status text;
  v_open_hours int;
begin
  if v_actor is null or p_request is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('service_book:' || p_request::text, 0));
  select * into v_existing from public.service_bookings where request_id = p_request;
  if found then
    if v_existing.occurrence_id <> p_occurrence or v_existing.pass_id <> p_pass or v_existing.requested_by <> v_actor then
      raise exception 'REQUEST_ID_REUSED' using errcode = '23505';
    end if;
    return v_existing.id;
  end if;
  select * into v_occ from public.service_occurrences where id = p_occurrence for update;
  if not found or v_occ.status <> 'active' or v_occ.starts_at <= now() then
    raise exception 'OCCURRENCE_UNAVAILABLE' using errcode = '22023';
  end if;
  select class_booking_open_hours into v_open_hours
    from public.organizations where id = v_occ.org_id;
  v_open_hours := coalesce(v_open_hours, 168);
  if v_occ.starts_at > now() + make_interval(hours => v_open_hours) then
    raise exception 'BOOKING_NOT_OPEN_YET' using errcode = '22023';
  end if;
  if not private.has_org_role(v_occ.org_id, array['athlete']::public.organization_role[]) then
    raise exception 'NOT_A_MEMBER' using errcode = '42501';
  end if;
  select * into v_pass from public.service_passes where id = p_pass and org_id = v_occ.org_id for update;
  if not found or v_pass.kind <> v_occ.kind or v_pass.status <> 'active'
     or v_pass.remaining_credits < 1 or v_pass.valid_from > v_occ.starts_at
     or v_pass.valid_until < v_occ.starts_at then
    raise exception 'NO_VALID_PASS' using errcode = '22023';
  end if;
  v_client_id := v_pass.client_id;
  if not private.owns_org_client(v_occ.org_id, v_client_id) then
    raise exception 'NOT_OWN_PASS' using errcode = '42501';
  end if;
  if exists(
    select 1 from public.service_bookings b
    where b.occurrence_id = v_occ.id and b.client_id = v_client_id
      and b.status in ('booked','waitlist','attended')
  ) then
    raise exception 'ALREADY_BOOKED' using errcode = '23505';
  end if;
  select count(*) into v_reserved from public.service_bookings b
   where b.occurrence_id = v_occ.id and b.status in ('booked','attended');
  v_status := case when v_reserved >= v_occ.capacity then 'waitlist' else 'booked' end;
  insert into public.service_bookings(org_id, occurrence_id, client_id, pass_id, requested_by, request_id, status)
  values (v_occ.org_id, v_occ.id, v_client_id, v_pass.id, v_actor, p_request, v_status)
  returning id into v_booking;
  if v_status = 'booked' then
    update public.service_passes set remaining_credits = remaining_credits - 1 where id = v_pass.id;
    insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
    values (v_occ.org_id, v_pass.id, v_booking, 'booking_debit', -1, v_actor);
    perform private.ensure_class_training_for_client(v_occ.id, v_client_id);
  end if;
  return v_booking;
end;
$function$;

create or replace function private.enroll_managed_client(
  p_occ uuid, p_client uuid, p_pass uuid, p_request uuid
) returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v public.service_occurrences%rowtype;
  pass public.service_passes%rowtype;
  row_id uuid;
begin
  if auth.uid() is null or p_request is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('managed_enroll:' || p_request::text, 0));
  if exists(
    select 1 from public.service_bookings
    where request_id = p_request
      and (occurrence_id <> p_occ or client_id <> p_client or pass_id <> p_pass or requested_by <> auth.uid())
  ) then
    raise exception 'REQUEST_ID_REUSED' using errcode = '23505';
  end if;
  select id into row_id from public.service_bookings where request_id = p_request;
  if found then return row_id; end if;
  select * into v from public.service_occurrences where id = p_occ for update;
  if not found or v.status <> 'active' or v.starts_at <= now() then
    raise exception 'CLASS_UNAVAILABLE' using errcode = '22023';
  end if;
  if not private.has_org_role(v.org_id, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select * into pass
  from public.service_passes
  where id = p_pass and org_id = v.org_id and client_id = p_client
  for update;
  if not found or pass.status <> 'active' or pass.kind <> v.kind or pass.remaining_credits < 1
     or pass.valid_from > v.starts_at or pass.valid_until < v.starts_at then
    raise exception 'NO_VALID_PASS' using errcode = '22023';
  end if;
  if not private.pass_allows_occurrence(pass, v) then
    raise exception 'PASS_OUTSIDE_SLOT' using errcode = '22023';
  end if;
  if exists(
       select 1 from public.service_bookings
       where occurrence_id = p_occ and client_id = p_client
         and status in ('booked','attended')
     )
     or (
       select count(*) from public.service_bookings
       where occurrence_id = p_occ and status in ('booked','attended')
     ) >= v.capacity then
    raise exception 'CLASS_FULL_OR_DUPLICATE' using errcode = '22023';
  end if;
  insert into public.service_bookings(org_id, occurrence_id, client_id, pass_id, requested_by, request_id)
  values (v.org_id, p_occ, p_client, p_pass, auth.uid(), p_request)
  returning id into row_id;
  update public.service_passes set remaining_credits = remaining_credits - 1 where id = p_pass;
  insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
  values (v.org_id, p_pass, row_id, 'booking_debit', -1, auth.uid());
  perform private.ensure_class_training_for_client(p_occ, p_client);
  return row_id;
end;
$$;

notify pgrst, 'reload schema';
