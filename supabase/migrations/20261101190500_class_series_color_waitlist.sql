-- Series con color/intervalo; waitlist; coach editable por clase.

-- ——— Reservas: estados + waitlist ———
alter table public.service_bookings drop constraint if exists service_bookings_status_check;
alter table public.service_bookings drop constraint if exists service_bookings_cancel_ck;
alter table public.service_bookings drop constraint if exists service_bookings_check;

alter table public.service_bookings
  add column if not exists attendance_marked_at timestamptz,
  add column if not exists attendance_marked_by uuid references auth.users(id),
  add column if not exists attendance_request_id uuid;

alter table public.service_bookings
  add constraint service_bookings_status_check
  check (status in ('booked','waitlist','cancelled','attended','no_show'));

alter table public.service_bookings
  add constraint service_bookings_cancel_ck
  check (
    (status = 'booked' and cancelled_at is null and attendance_marked_at is null)
    or (status = 'waitlist' and cancelled_at is null and attendance_marked_at is null)
    or (status = 'cancelled' and cancelled_at is not null)
    or (status in ('attended','no_show') and cancelled_at is null and attendance_marked_at is not null)
  );

drop index if exists public.service_bookings_one_active_per_client;
create unique index service_bookings_one_active_per_client
  on public.service_bookings(occurrence_id, client_id)
  where status in ('booked','waitlist','attended');

-- ——— create_service_series ampliado ———
drop function if exists public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int);
drop function if exists private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int);
drop function if exists public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text);
drop function if exists private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text);

create function private.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int,
  p_color text default '#22834d',
  p_interval_days int default null,
  p_location text default null,
  p_description text default null
) returns uuid[]
language plpgsql security definer set search_path='' as $$
declare
  generated uuid[] := '{}';
  next_start timestamptz; next_end timestamptz;
  idx int := 0; offset_days int := 0; new_id uuid;
  v_color text := coalesce(nullif(btrim(p_color), ''), '#22834d');
  v_loc text := left(nullif(btrim(coalesce(p_location, '')), ''), 250);
  v_desc text := left(nullif(btrim(coalesce(p_description, '')), ''), 2000);
  v_interval int := p_interval_days;
  v_repeat text := coalesce(p_repeat, 'none');
begin
  if auth.uid() is null or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if not exists(
    select 1 from public.organization_memberships
    where organization_id = p_org and user_id = p_coach and status = 'active'
      and role in ('owner','admin','coach')
  ) then
    raise exception 'COACH_NOT_AUTHORIZED: el entrenador debe ser miembro activo (owner/admin/coach) del centro' using errcode = 'P0001';
  end if;
  if v_color !~ '^#[0-9a-fA-F]{6}$' then
    raise exception 'INVALID_COLOR' using errcode = '22023';
  end if;
  if v_interval is not null and v_interval not between 1 and 14 then
    raise exception 'INVALID_INTERVAL' using errcode = '22023';
  end if;
  if p_kind not in ('class','appointment')
     or (v_interval is null and v_repeat not in ('none','daily','weekly','weekdays'))
     or p_count not between 1 and 62
     or (v_repeat = 'none' and v_interval is null and p_count <> 1)
     or p_start <= now() or p_start > now() + interval '18 months'
     or p_end <= p_start or p_end > p_start + interval '12 hours'
     or length(btrim(coalesce(p_title, ''))) not between 2 and 120
     or p_capacity not between 1 and 200
     or (p_kind = 'appointment' and p_capacity <> 1)
  then
    raise exception 'INVALID_SERIES: revisa horario futuro, duración (máx 12h), repetición y aforo' using errcode = '22023';
  end if;

  while idx < p_count loop
    if v_interval is not null then
      offset_days := idx * v_interval;
    elsif v_repeat = 'none' then
      offset_days := 0;
    elsif v_repeat = 'daily' then
      offset_days := idx;
    elsif v_repeat = 'weekly' then
      offset_days := idx * 7;
    else
      if idx = 0 then offset_days := 0;
      else offset_days := offset_days + 1;
      end if;
      while extract(isodow from p_start + offset_days * interval '1 day') not between 1 and 5 loop
        offset_days := offset_days + 1;
      end loop;
    end if;
    next_start := p_start + offset_days * interval '1 day';
    next_end := p_end + offset_days * interval '1 day';
    if next_start > now() + interval '18 months' then
      raise exception 'SERIES_TOO_FAR' using errcode = '22023';
    end if;
    insert into public.service_occurrences(org_id, coach_user_id, kind, title, starts_at, ends_at, capacity)
    values (p_org, p_coach, p_kind, btrim(p_title), next_start, next_end, p_capacity)
    returning id into new_id;
    insert into public.service_occurrence_details(occurrence_id, org_id, description, location, color, repeat_rule)
    values (
      new_id, p_org, v_desc, v_loc, v_color,
      case when v_interval is not null then 'daily' else v_repeat end
    );
    generated := array_append(generated, new_id);
    idx := idx + 1;
  end loop;
  return generated;
end;
$$;

revoke all on function private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text)
  from public, anon, authenticated;
grant execute on function private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text)
  to authenticated;

create function public.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int,
  p_color text default '#22834d',
  p_interval_days int default null,
  p_location text default null,
  p_description text default null
) returns uuid[]
language sql security invoker set search_path='' as $$
  select private.create_service_series(
    p_org, p_coach, p_kind, p_title, p_start, p_end, p_capacity, p_repeat, p_count,
    p_color, p_interval_days, p_location, p_description
  );
$$;
revoke all on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text)
  from public, anon;
grant execute on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text)
  to authenticated;

-- Compat firma 9 args
create function public.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int
) returns uuid[]
language sql security invoker set search_path='' as $$
  select public.create_service_series(
    p_org, p_coach, p_kind, p_title, p_start, p_end, p_capacity, p_repeat, p_count,
    '#22834d', null::int, null::text, null::text
  );
$$;
revoke all on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int)
  from public, anon;
grant execute on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int)
  to authenticated;

-- ——— manage_service_occurrence + coach ———
drop function if exists public.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text);
drop function if exists private.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text);
drop function if exists public.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text,uuid);
drop function if exists private.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text,uuid);

create function private.manage_service_occurrence(
  p_id uuid, p_title text, p_start timestamptz, p_end timestamptz, p_capacity int,
  p_description text, p_location text, p_color text, p_image text,
  p_coach uuid default null
) returns boolean language plpgsql security definer set search_path='' as $$
declare
  v public.service_occurrences%rowtype;
  occupied int;
begin
  select * into v from public.service_occurrences where id = p_id for update;
  if not found then raise exception 'CLASS_NOT_FOUND' using errcode = 'P0002'; end if;
  if not private.has_org_role(v.org_id, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v.starts_at <= now() or v.status <> 'active' then
    raise exception 'CLASS_LOCKED' using errcode = '22023';
  end if;
  select count(*) into occupied from public.service_bookings
   where occurrence_id = p_id and status in ('booked','attended');
  if p_start <= now() or p_end <= p_start or p_end > p_start + interval '12 hours'
     or length(btrim(coalesce(p_title, ''))) not between 2 and 120
     or p_capacity < greatest(occupied, 1) or p_capacity > 200 then
    raise exception 'CLASS_INVALID' using errcode = '22023';
  end if;
  if p_coach is not null and p_coach is distinct from v.coach_user_id then
    if not exists(
      select 1 from public.organization_memberships
      where organization_id = v.org_id and user_id = p_coach and status = 'active'
        and role in ('owner','admin','coach')
    ) then
      raise exception 'COACH_NOT_AUTHORIZED' using errcode = 'P0001';
    end if;
    update public.service_occurrences set coach_user_id = p_coach where id = p_id;
  end if;
  update public.service_occurrences
  set title = btrim(p_title), starts_at = p_start, ends_at = p_end, capacity = p_capacity
  where id = p_id;
  insert into public.service_occurrence_details(occurrence_id, org_id, description, location, color, image_url)
  values (
    p_id, v.org_id,
    left(coalesce(p_description, ''), 2000),
    left(coalesce(p_location, ''), 250),
    coalesce(nullif(btrim(p_color), ''), '#22834d'),
    left(coalesce(p_image, ''), 2000)
  )
  on conflict (occurrence_id) do update set
    description = excluded.description,
    location = excluded.location,
    color = excluded.color,
    image_url = excluded.image_url;
  return true;
end;
$$;
revoke all on function private.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text,uuid)
  from public, anon, authenticated;
grant execute on function private.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text,uuid)
  to authenticated;

create function public.manage_service_occurrence(
  p_id uuid, p_title text, p_start timestamptz, p_end timestamptz, p_capacity int,
  p_description text, p_location text, p_color text, p_image text,
  p_coach uuid default null
) returns boolean language sql security invoker set search_path='' as $$
  select private.manage_service_occurrence(
    p_id, p_title, p_start, p_end, p_capacity, p_description, p_location, p_color, p_image, p_coach
  );
$$;
revoke all on function public.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text,uuid)
  from public, anon;
grant execute on function public.manage_service_occurrence(uuid,text,timestamptz,timestamptz,int,text,text,text,text,uuid)
  to authenticated;

-- ——— book con waitlist ———
create or replace function private.book_service_occurrence(p_occurrence uuid, p_pass uuid, p_request uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid := auth.uid();
  v_occ public.service_occurrences%rowtype;
  v_pass public.service_passes%rowtype;
  v_client_id uuid;
  v_booking uuid;
  v_existing public.service_bookings%rowtype;
  v_reserved int;
  v_status text;
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
$$;

-- ——— cancel + promover waitlist ———
create or replace function private.cancel_service_booking(p_booking uuid, p_request uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid := auth.uid();
  v_booking public.service_bookings%rowtype;
  v_occ public.service_occurrences%rowtype;
  v_refund boolean;
  v_was_booked boolean;
  v_next public.service_bookings%rowtype;
  v_pass public.service_passes%rowtype;
begin
  if v_actor is null or p_request is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('service_cancel:' || p_booking::text, 0));
  select * into v_booking from public.service_bookings where id = p_booking for update;
  if not found then raise exception 'BOOKING_NOT_FOUND' using errcode = '22023'; end if;
  if not (
    private.owns_org_client(v_booking.org_id, v_booking.client_id)
    or private.has_org_role(v_booking.org_id, array['owner','admin']::public.organization_role[])
  ) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_booking.status = 'cancelled' then return v_booking.credited_on_cancel; end if;
  if v_booking.status in ('attended','no_show') then
    raise exception 'ATTENDANCE_ALREADY_RECORDED' using errcode = '22023';
  end if;
  select * into v_occ from public.service_occurrences where id = v_booking.occurrence_id;
  v_was_booked := v_booking.status = 'booked';
  v_refund := v_was_booked and v_occ.starts_at > now() + interval '12 hours';
  update public.service_bookings
  set status = 'cancelled', cancelled_at = now(),
      cancel_request_id = p_request, credited_on_cancel = v_refund
  where id = v_booking.id;
  if v_refund then
    update public.service_passes set remaining_credits = remaining_credits + 1 where id = v_booking.pass_id;
    insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
    values (v_booking.org_id, v_booking.pass_id, v_booking.id, 'cancellation_credit', 1, v_actor);
  end if;

  if v_was_booked and v_occ.status = 'active' and v_occ.starts_at > now() then
    select * into v_next from public.service_bookings
     where occurrence_id = v_booking.occurrence_id and status = 'waitlist'
     order by booked_at nulls last
     for update skip locked
     limit 1;
    if found then
      select * into v_pass from public.service_passes where id = v_next.pass_id for update;
      if found and v_pass.status = 'active' and v_pass.remaining_credits >= 1
         and v_pass.valid_until >= v_occ.starts_at and v_pass.valid_from <= v_occ.starts_at then
        update public.service_bookings set status = 'booked' where id = v_next.id;
        update public.service_passes set remaining_credits = remaining_credits - 1 where id = v_pass.id;
        insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
        values (v_next.org_id, v_pass.id, v_next.id, 'booking_debit', -1, v_actor);
        insert into public.business_client_notifications(org_id, client_id, sender_user_id, title, body)
        values (
          v_next.org_id, v_next.client_id, v_actor,
          'Plaza confirmada',
          'Ya estás apuntado a «' || v_occ.title || '». Había una plaza libre y has salido de la lista de espera.'
        );
      end if;
    end if;
  end if;
  return v_refund;
end;
$$;

notify pgrst, 'reload schema';
