-- Al desapuntarse de una clase, cancelar también el fan-out de entreno
-- (professional_training_sessions con source_occurrence_id). Si no, Inicio
-- seguía mostrando «Clase · entreno…» sin reserva activa.

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

  -- Quitar el plan materializado de esa clase para este cliente.
  if v_occ.kind = 'class' then
    update public.professional_training_sessions
       set status = 'cancelled', updated_at = now()
     where org_id = v_booking.org_id
       and client_id = v_booking.client_id
       and source_occurrence_id = v_booking.occurrence_id
       and status = 'scheduled';
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
        perform private.ensure_class_training_for_client(v_occ.id, v_next.client_id);
      end if;
    end if;
  end if;
  return v_refund;
end;
$$;

-- Huérfanos: sesión de clase scheduled sin reserva booked/waitlist/attended activa.
update public.professional_training_sessions pts
   set status = 'cancelled', updated_at = now()
 where pts.status = 'scheduled'
   and pts.source_occurrence_id is not null
   and not exists (
     select 1
       from public.service_bookings b
      where b.occurrence_id = pts.source_occurrence_id
        and b.client_id = pts.client_id
        and b.status in ('booked', 'waitlist', 'attended')
   );

notify pgrst, 'reload schema';
