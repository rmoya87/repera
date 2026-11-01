-- Borrar clase del calendario tras reembolsar; cancelada sigue visible (bloqueada).
-- status 'deleted' oculto en agendas; 'cancelled' permanece como bloqueada.

alter table public.service_occurrences
  drop constraint if exists service_occurrences_status_check;

alter table public.service_occurrences
  add constraint service_occurrences_status_check
  check (status in ('active', 'cancelled', 'deleted'));

create or replace function private.delete_managed_occurrence(p_id uuid)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v public.service_occurrences%rowtype;
  booking record;
  total int := 0;
begin
  select * into v from public.service_occurrences where id = p_id for update;
  if not found then
    raise exception 'CLASS_NOT_FOUND' using errcode = '22023';
  end if;
  if not private.has_org_role(v.org_id, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v.status = 'deleted' then
    return 0;
  end if;

  for booking in
    select id, pass_id, status, credited_on_cancel
    from public.service_bookings
    where occurrence_id = p_id
      and status in ('booked', 'waitlist')
    order by id
    for update
  loop
    if booking.status = 'booked' and coalesce(booking.credited_on_cancel, false) is not true then
      update public.service_bookings
        set status = 'cancelled',
            cancelled_at = now(),
            cancel_request_id = gen_random_uuid(),
            credited_on_cancel = true
      where id = booking.id;
      update public.service_passes
        set remaining_credits = remaining_credits + 1
      where id = booking.pass_id;
      insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
      values (v.org_id, booking.pass_id, booking.id, 'cancellation_credit', 1, auth.uid());
      total := total + 1;
    else
      update public.service_bookings
        set status = 'cancelled',
            cancelled_at = coalesce(cancelled_at, now()),
            cancel_request_id = coalesce(cancel_request_id, gen_random_uuid())
      where id = booking.id;
    end if;
  end loop;

  update public.professional_training_sessions
    set source_occurrence_id = null
  where org_id = v.org_id and source_occurrence_id = p_id;

  update public.service_occurrences
    set status = 'deleted'
  where id = p_id;

  return total;
end;
$function$;

create or replace function public.delete_managed_occurrence(p_id uuid)
returns integer
language sql
security definer
set search_path to ''
as $function$
  select private.delete_managed_occurrence(p_id);
$function$;

revoke all on function public.delete_managed_occurrence(uuid) from public;
grant execute on function public.delete_managed_occurrence(uuid) to authenticated;

comment on function public.delete_managed_occurrence(uuid) is
  'Gym manager: reembolsa reservas activas y marca la clase como deleted (fuera del calendario).';
