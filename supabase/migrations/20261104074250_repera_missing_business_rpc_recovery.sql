-- Forward-only recovery of missing native/business RPCs found in the production schema audit, 2026-11-04.
-- Extracted unmodified from already-versioned source migrations.
-- Preserve newer booking/chat/scheduling functions; do not replay old full migrations.
-- Requires verified organizational role checks and RLS.
create or replace function public.athlete_send_org_message(
  p_org uuid,
  p_title text,
  p_body text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_client uuid;
  v_id uuid;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if not private.has_org_role(p_org, array['athlete']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select id into v_client
  from public.clients
  where org_id = p_org and user_id = v_actor and status = 'active'
  limit 1;
  if v_client is null
     or length(btrim(coalesce(p_title, ''))) not between 2 and 120
     or length(btrim(coalesce(p_body, ''))) not between 2 and 1000 then
    raise exception 'INVALID_MESSAGE' using errcode = '22023';
  end if;

  insert into public.business_client_notifications(org_id, client_id, sender_user_id, title, body)
  values (p_org, v_client, v_actor, btrim(p_title), btrim(p_body))
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.athlete_send_org_message(uuid, text, text) from public, anon;
grant execute on function public.athlete_send_org_message(uuid, text, text) to authenticated;

-- Managers can update branding (avatar / discoverability / tagline).
create or replace function public.update_organization_branding(
  p_org uuid,
  p_avatar_url text default null,
  p_tagline text default null,
  p_is_discoverable boolean default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner', 'admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  update public.organizations
  set avatar_url = case
        when p_avatar_url is null then avatar_url
        when btrim(p_avatar_url) = '' then null
        else left(btrim(p_avatar_url), 2000)
      end,
      tagline = case
        when p_tagline is null then tagline
        when btrim(p_tagline) = '' then null
        else left(btrim(p_tagline), 160)
      end,
      is_discoverable = coalesce(p_is_discoverable, is_discoverable),
      updated_at = now()
  where id = p_org;
  return found;
end;
$$;

revoke all on function public.update_organization_branding(uuid, text, text, boolean) from public, anon;
grant execute on function public.update_organization_branding(uuid, text, text, boolean) to authenticated;

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


create or replace function private.decline_org_invitation(p_invitation_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare v_inv public.organization_invitations%rowtype; v_actor uuid:=auth.uid();
begin
  if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  select * into v_inv from public.organization_invitations where id=p_invitation_id for update;
  if not found then raise exception 'INVITATION_NOT_FOUND' using errcode='P0002'; end if;
  if not private.is_verified_invitation_recipient(v_inv.email) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if v_inv.accepted_at is not null or v_inv.cancelled_at is not null then
    return false;
  end if;
  if v_inv.expires_at < now() then
    update public.organization_invitations set cancelled_at=now() where id=p_invitation_id;
    return false;
  end if;
  update public.organization_invitations set cancelled_at=now() where id=p_invitation_id;
  return true;
end $$;
revoke all on function private.decline_org_invitation(uuid) from public,anon,authenticated;
grant execute on function private.decline_org_invitation(uuid) to authenticated;
create or replace function public.decline_org_invitation(p_invitation_id uuid)
returns boolean language sql security invoker set search_path='' as $$
  select private.decline_org_invitation(p_invitation_id)
$$;
revoke all on function public.decline_org_invitation(uuid) from public,anon;
grant execute on function public.decline_org_invitation(uuid) to authenticated;

-- PT: aceptar clases de gym asignadas + billing_model en tarifas (sin Stripe).

alter table public.service_occurrences
  add column if not exists coach_ack text not null default 'accepted'
  check (coach_ack in ('pending','accepted','declined'));

alter table public.business_pass_offers
  add column if not exists billing_model text not null default 'session_pack'
  check (billing_model in ('session_pack','monthly','unlimited'));

-- Al crear clase con coach distinto del actor → pendiente de aceptar.
create or replace function private.mark_coach_ack_pending()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.coach_user_id is distinct from auth.uid()
     and new.kind='class'
     and tg_op='INSERT' then
    new.coach_ack := 'pending';
  end if;
  return new;
end $$;
drop trigger if exists service_occurrence_coach_ack on public.service_occurrences;
create trigger service_occurrence_coach_ack
 before insert on public.service_occurrences
 for each row execute function private.mark_coach_ack_pending();

create or replace function public.list_my_coach_assignments()
returns table(
  id uuid, org_id uuid, org_name text, title text, starts_at timestamptz,
  ends_at timestamptz, status text, coach_ack text, capacity int, kind text
) language sql stable security definer set search_path='' as $$
  select o.id, o.org_id, org.name, o.title, o.starts_at, o.ends_at, o.status,
         o.coach_ack, o.capacity, o.kind
  from public.service_occurrences o
  join public.organizations org on org.id=o.org_id
  where o.coach_user_id=auth.uid()
    and o.status='active'
    and org.kind in ('gym','sports_center')
    and private.has_org_role(o.org_id, array['owner','admin','coach']::public.organization_role[])
  order by o.starts_at asc
  limit 200;
$$;
revoke all on function public.list_my_coach_assignments() from public,anon;
grant execute on function public.list_my_coach_assignments() to authenticated;

create or replace function public.coach_ack_occurrence(p_occurrence uuid, p_ack text)
returns void language plpgsql security definer set search_path='' as $$
declare v_row public.service_occurrences%rowtype;
begin
  if auth.uid() is null or p_ack not in ('accepted','declined') then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  select * into v_row from public.service_occurrences where id=p_occurrence for update;
  if not found or v_row.coach_user_id is distinct from auth.uid() then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  if not private.has_org_role(v_row.org_id, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  update public.service_occurrences
     set coach_ack=p_ack,
         status=case when p_ack='declined' then 'cancelled' else status end
   where id=p_occurrence;
end $$;
revoke all on function public.coach_ack_occurrence(uuid,text) from public,anon;
grant execute on function public.coach_ack_occurrence(uuid,text) to authenticated;

-- Ampliar check de créditos en ofertas si existía tope 1000 vía constraint de app;
-- la tabla no limita credits en SQL habitualmente.

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
