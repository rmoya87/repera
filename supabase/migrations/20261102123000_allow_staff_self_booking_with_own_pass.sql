-- Una persona con rol propietario/administración/entrenador/recepción también
-- puede ser cliente del mismo centro y consumir SU PROPIO bono.
-- La autorización continúa exigiendo membresía activa, identidad vinculada
-- al cliente, cliente activo, bono propio y reglas de aforo/fecha/créditos.
-- No autoriza reservar para otras personas ni cambia los roles existentes.

create or replace function private.owns_org_client(p_org uuid, p_client uuid)
returns boolean language sql stable security definer set search_path=''
as $$
    select auth.uid() is not null and exists (
        select 1
          from public.clients c
          join public.organization_memberships m
            on m.organization_id = c.org_id
           and m.user_id = c.user_id
         where c.org_id = p_org
           and c.id = p_client
           and c.user_id = auth.uid()
           and c.status = 'active'
           and m.status = 'active'::public.organization_membership_status
           and m.role = any (array[
                'athlete','owner','admin','coach','reception'
           ]::public.organization_role[])
    );
$$;
revoke all on function private.owns_org_client(uuid, uuid) from public, anon;
grant execute on function private.owns_org_client(uuid, uuid) to authenticated;

-- El RPC de reserva sigue usando SECURITY DEFINER pero valida tanto la
-- pertenencia activa como la titularidad estricta del bono consumido.

create or replace function private.book_service_occurrence(p_occurrence uuid, p_pass uuid, p_request uuid)
returns uuid
language plpgsql
security definer
set search_path to ''
as $$
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
  v_eff_cap int;
  v_room_cap int;
  v_settings public.org_operation_settings%rowtype;
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
  select * into v_settings from public.org_operation_settings where org_id = v_occ.org_id;
  if v_occ.kind = 'open_access' and coalesce(v_settings.open_access_enabled, false) is not true then
    raise exception 'OPEN_ACCESS_DISABLED' using errcode = '22023';
  end if;
  if v_occ.kind = 'open_access' and coalesce(v_settings.open_access_requires_booking, true) is not true then
    raise exception 'OPEN_ACCESS_CHECKIN_ONLY' using errcode = '22023';
  end if;
  select class_booking_open_hours into v_open_hours
    from public.organizations where id = v_occ.org_id;
  v_open_hours := coalesce(v_open_hours, 168);
  if v_occ.starts_at > now() + make_interval(hours => v_open_hours) then
    raise exception 'BOOKING_NOT_OPEN_YET' using errcode = '22023';
  end if;
  if not private.has_org_role(v_occ.org_id, array['athlete','owner','admin','coach','reception']::public.organization_role[]) then
    raise exception 'NOT_A_MEMBER' using errcode = '42501';
  end if;
  select * into v_pass from public.service_passes where id = p_pass and org_id = v_occ.org_id for update;
  if not found
     or not private.pass_kind_matches_occurrence(v_pass.kind, v_occ.kind)
     or v_pass.status <> 'active'
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
  v_eff_cap := v_occ.capacity;
  if v_occ.room_id is not null then
    select capacity into v_room_cap from public.facility_rooms
     where id = v_occ.room_id and org_id = v_occ.org_id;
    if found then v_eff_cap := least(v_eff_cap, v_room_cap); end if;
  end if;
  select count(*) into v_reserved from public.service_bookings b
   where b.occurrence_id = v_occ.id and b.status in ('booked','attended');
  v_status := case when v_reserved >= v_eff_cap then 'waitlist' else 'booked' end;
  insert into public.service_bookings(org_id, occurrence_id, client_id, pass_id, requested_by, request_id, status)
  values (v_occ.org_id, v_occ.id, v_client_id, v_pass.id, v_actor, p_request, v_status)
  returning id into v_booking;
  if v_status = 'booked' then
    update public.service_passes set remaining_credits = remaining_credits - 1 where id = v_pass.id;
    insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
    values (v_occ.org_id, v_pass.id, v_booking, 'booking_debit', -1, v_actor);
    if v_occ.kind = 'class' then
      perform private.ensure_class_training_for_client(v_occ.id, v_client_id);
    end if;
  end if;
  return v_booking;
end;
$$;
