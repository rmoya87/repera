-- Asistencia / no-show en reservas de clase o cita.
-- El crédito ya se descuenta al reservar (booking_debit); marcar asistencia NO vuelve a cobrar.
-- Idempotente por attendance_request_id.

alter table public.service_bookings
 drop constraint if exists service_bookings_status_check;
alter table public.service_bookings
 drop constraint if exists service_bookings_cancel_ck;
alter table public.service_bookings
 drop constraint if exists service_bookings_check;

-- Columnas de asistencia antes del CHECK compuesto (filas booked existentes: attendance_marked_at null).
alter table public.service_bookings
 add column if not exists attendance_marked_at timestamptz,
 add column if not exists attendance_marked_by uuid references auth.users(id),
 add column if not exists attendance_request_id uuid;

alter table public.service_bookings
 add constraint service_bookings_status_check
 check(status in ('booked','cancelled','attended','no_show'));

alter table public.service_bookings
 add constraint service_bookings_cancel_ck
 check (
  (status='booked' and cancelled_at is null and attendance_marked_at is null)
  or (status='cancelled' and cancelled_at is not null)
  or (status in ('attended','no_show') and cancelled_at is null and attendance_marked_at is not null)
 );

create unique index if not exists service_bookings_attendance_request_uidx
 on public.service_bookings(attendance_request_id)
 where attendance_request_id is not null;

-- Capacidad: plazas ocupadas = booked + attended (no_show libera aforo operativo).
drop index if exists public.service_bookings_one_active_per_client;
create unique index service_bookings_one_active_per_client
 on public.service_bookings(occurrence_id,client_id)
 where status in ('booked','attended');

create or replace function private.business_mark_class_attendance(
 p_booking uuid,p_status text,p_request uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare
 v_actor uuid:=auth.uid();
 v_booking public.service_bookings%rowtype;
 v_prev public.service_bookings%rowtype;
begin
 if v_actor is null or p_request is null
  or p_status not in ('attended','no_show') then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 perform pg_advisory_xact_lock(hashtextextended('class_attendance:'||p_request::text,0));

 select * into v_prev from public.service_bookings
  where attendance_request_id=p_request;
 if found then
  if v_prev.id<>p_booking or v_prev.status<>p_status
    or v_prev.attendance_marked_by is distinct from v_actor then
   raise exception 'REQUEST_REUSE' using errcode='23505';
  end if;
  return v_prev.id;
 end if;

 select * into v_booking from public.service_bookings
  where id=p_booking for update;
 if not found then
  raise exception 'BOOKING_NOT_FOUND' using errcode='22023';
 end if;
 if not private.has_org_role(v_booking.org_id,array['owner','admin','coach','reception']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 if v_booking.status='cancelled' then
  raise exception 'BOOKING_CANCELLED' using errcode='22023';
 end if;
 if v_booking.status in ('attended','no_show') then
  if v_booking.status=p_status then return v_booking.id; end if;
  raise exception 'ALREADY_RECORDED' using errcode='23505';
 end if;
 if v_booking.status<>'booked' then
  raise exception 'INVALID_BOOKING_STATE' using errcode='22023';
 end if;

 update public.service_bookings set
  status=p_status,
  attendance_marked_at=now(),
  attendance_marked_by=v_actor,
  attendance_request_id=p_request
 where id=p_booking;

 return p_booking;
end $$;

revoke all on function private.business_mark_class_attendance(uuid,text,uuid)
 from public,anon,authenticated;
grant execute on function private.business_mark_class_attendance(uuid,text,uuid)
 to authenticated;

create or replace function public.business_mark_class_attendance(
 p_booking uuid,p_status text,p_request uuid
) returns uuid language sql security invoker set search_path='' as $$
 select private.business_mark_class_attendance(p_booking,p_status,p_request)
$$;

revoke all on function public.business_mark_class_attendance(uuid,text,uuid)
 from public,anon;
grant execute on function public.business_mark_class_attendance(uuid,text,uuid)
 to authenticated;

-- Aforo operativo: booked + attended. no_show libera plaza.
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

create or replace function private.manage_service_occurrence(
 p_id uuid,p_title text,p_start timestamptz,p_end timestamptz,p_capacity int,
 p_description text,p_location text,p_color text,p_image text
) returns boolean language plpgsql security definer set search_path='' as $$
declare v public.service_occurrences%rowtype; occupied int;
begin
 select * into v from public.service_occurrences where id=p_id for update;
 if not found then raise exception 'CLASS_NOT_FOUND' using errcode='22023'; end if;
 if not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[]) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v.starts_at<=now() or v.status<>'active' then
   raise exception 'CLASS_LOCKED' using errcode='22023'; end if;
 select count(*) into occupied from public.service_bookings
  where occurrence_id=p_id and status in ('booked','attended');
 if p_start<=now() or p_end<=p_start or p_end>p_start+interval '12 hours'
 or length(btrim(coalesce(p_title,''))) not between 2 and 120
 or p_capacity<greatest(occupied,1) or p_capacity>200 then
   raise exception 'CLASS_INVALID' using errcode='22023'; end if;
 update public.service_occurrences set title=btrim(p_title), starts_at=p_start,ends_at=p_end,capacity=p_capacity where id=p_id;
 insert into public.service_occurrence_details(occurrence_id,org_id,description,location,color,image_url)
 values(p_id,v.org_id,left(coalesce(p_description,''),2000),left(coalesce(p_location,''),250),p_color,left(coalesce(p_image,''),2000))
 on conflict (occurrence_id) do update
 set description=excluded.description,location=excluded.location,color=excluded.color,image_url=excluded.image_url;
 return true;
end; $$;

create or replace function private.cancel_service_booking(p_booking uuid,p_request uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare
 v_actor uuid:=auth.uid(); v_booking public.service_bookings%rowtype;
 v_occ public.service_occurrences%rowtype; v_refund boolean;
begin
 if v_actor is null or p_request is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('service_cancel:'||p_booking::text,0));
 select * into v_booking from public.service_bookings where id=p_booking for update;
 if not found then raise exception 'BOOKING_NOT_FOUND' using errcode='22023'; end if;
 if not (private.owns_org_client(v_booking.org_id,v_booking.client_id)
    or private.has_org_role(v_booking.org_id,array['owner','admin']::public.organization_role[])) then
   raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v_booking.status='cancelled' then return v_booking.credited_on_cancel; end if;
 if v_booking.status in ('attended','no_show') then
   raise exception 'ATTENDANCE_ALREADY_RECORDED' using errcode='22023';
 end if;
 select * into v_occ from public.service_occurrences where id=v_booking.occurrence_id;
 v_refund:=v_occ.starts_at>now()+interval '12 hours';
 update public.service_bookings set status='cancelled',cancelled_at=now(),
   cancel_request_id=p_request,credited_on_cancel=v_refund
 where id=v_booking.id;
 if v_refund then
   update public.service_passes set remaining_credits=remaining_credits+1 where id=v_booking.pass_id;
   insert into public.service_credit_ledger(org_id,pass_id,booking_id,event,amount,created_by)
    values(v_booking.org_id,v_booking.pass_id,v_booking.id,'cancellation_credit',1,v_actor);
 end if;
 return v_refund;
end; $$;
