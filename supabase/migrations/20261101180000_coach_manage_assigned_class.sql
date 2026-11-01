-- Coach asignado puede mover/cancelar clases aceptadas del gimnasio (sin ser owner).

create or replace function public.coach_reschedule_occurrence(
  p_occurrence uuid, p_start timestamptz, p_end timestamptz
) returns boolean language plpgsql security definer set search_path='' as $$
declare v public.service_occurrences%rowtype;
begin
  if auth.uid() is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  select * into v from public.service_occurrences where id=p_occurrence for update;
  if not found then raise exception 'CLASS_NOT_FOUND' using errcode='22023'; end if;
  if v.coach_user_id is distinct from auth.uid() or v.coach_ack<>'accepted' then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if not private.has_org_role(v.org_id, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if v.status<>'active' or v.starts_at<=now() then
    raise exception 'CLASS_LOCKED' using errcode='22023';
  end if;
  if p_start<=now() or p_end<=p_start or p_end>p_start+interval '12 hours' then
    raise exception 'CLASS_INVALID' using errcode='22023';
  end if;
  update public.service_occurrences set starts_at=p_start, ends_at=p_end where id=p_occurrence;
  return true;
end $$;
revoke all on function public.coach_reschedule_occurrence(uuid,timestamptz,timestamptz) from public,anon;
grant execute on function public.coach_reschedule_occurrence(uuid,timestamptz,timestamptz) to authenticated;

create or replace function public.coach_cancel_occurrence(p_occurrence uuid)
returns int language plpgsql security definer set search_path='' as $$
declare v public.service_occurrences%rowtype; booking record; total int:=0;
begin
  if auth.uid() is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  select * into v from public.service_occurrences where id=p_occurrence for update;
  if not found then raise exception 'CLASS_NOT_FOUND' using errcode='22023'; end if;
  if v.coach_user_id is distinct from auth.uid() or v.coach_ack<>'accepted' then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if not private.has_org_role(v.org_id, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if v.status='cancelled' then return 0; end if;
  if v.starts_at <= now() then raise exception 'PAST_CLASS' using errcode='22023'; end if;
  update public.service_occurrences set status='cancelled' where id=p_occurrence;
  for booking in select id,pass_id from public.service_bookings
   where occurrence_id=p_occurrence and status='booked' order by id for update loop
    update public.service_bookings set status='cancelled',cancelled_at=now(),
      cancel_request_id=gen_random_uuid(),credited_on_cancel=true where id=booking.id;
    update public.service_passes set remaining_credits=remaining_credits+1 where id=booking.pass_id;
    insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
     values(v.org_id,booking.pass_id,booking.id,'cancellation_credit',1,auth.uid());
    total:=total+1;
  end loop;
  return total;
end $$;
revoke all on function public.coach_cancel_occurrence(uuid) from public,anon;
grant execute on function public.coach_cancel_occurrence(uuid) to authenticated;
