-- Antelación de inscripción a clases + roster visible para miembros del centro.

alter table public.organizations
  add column if not exists class_booking_open_hours integer not null default 168
  check (class_booking_open_hours between 1 and 8760);

comment on column public.organizations.class_booking_open_hours is
  'Horas antes del inicio en las que un atleta puede apuntarse (p. ej. 168 = 7 días).';

-- Enforce window on athlete booking.
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
  end if;
  return v_booking;
end;
$function$;

-- Roster: coach + apuntados (nombre/avatar públicos) para miembros del centro.
create or replace function private.class_occurrence_roster(p_occurrence uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_occ public.service_occurrences%rowtype;
  v_coach jsonb;
  v_people jsonb;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select * into v_occ from public.service_occurrences where id = p_occurrence;
  if not found or v_occ.status = 'deleted' then
    raise exception 'CLASS_NOT_FOUND' using errcode = '22023';
  end if;
  if not (
    private.has_org_role(v_occ.org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[])
  ) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'display_name', coalesce(nullif(btrim(p.display_name), ''), 'Entrenador'),
    'avatar_url', p.avatar_url
  )
  into v_coach
  from public.profiles p
  where p.id = v_occ.coach_user_id;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'display_name', coalesce(nullif(btrim(c.name), ''), 'Socio'),
      'avatar_url', c.avatar_url,
      'status', b.status
    ) order by c.name
  ), '[]'::jsonb)
  into v_people
  from public.service_bookings b
  join public.clients c on c.id = b.client_id and c.org_id = b.org_id
  where b.occurrence_id = p_occurrence
    and b.status in ('booked', 'waitlist', 'attended');

  return jsonb_build_object(
    'occurrence_id', v_occ.id,
    'coach', v_coach,
    'attendees', v_people,
    'capacity', v_occ.capacity,
    'reserved', (
      select count(*)::int from public.service_bookings b
      where b.occurrence_id = p_occurrence and b.status in ('booked', 'attended')
    )
  );
end;
$function$;

create or replace function public.class_occurrence_roster(p_occurrence uuid)
returns jsonb
language sql
security definer
set search_path to ''
as $function$
  select private.class_occurrence_roster(p_occurrence);
$function$;

revoke all on function public.class_occurrence_roster(uuid) from public;
grant execute on function public.class_occurrence_roster(uuid) to authenticated;

create or replace function private.update_org_booking_window(p_org uuid, p_hours integer)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if auth.uid() is null or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if p_hours is null or p_hours < 1 or p_hours > 8760 then
    raise exception 'INVALID_HOURS' using errcode = '22023';
  end if;
  update public.organizations set class_booking_open_hours = p_hours, updated_at = now()
  where id = p_org;
end;
$function$;

create or replace function public.update_org_booking_window(p_org uuid, p_hours integer)
returns void
language sql
security definer
set search_path to ''
as $function$
  select private.update_org_booking_window(p_org, p_hours);
$function$;

revoke all on function public.update_org_booking_window(uuid, integer) from public;
grant execute on function public.update_org_booking_window(uuid, integer) to authenticated;
