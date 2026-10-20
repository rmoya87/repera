-- Unify visual business prescriptions with the production iOS schemaVersion:1 wire contract.
-- Supabase must reject WOD-only blocks with invalid movement payloads.
create or replace function private.publish_professional_session_v2(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid,p_prescription jsonb
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid; v_previous jsonb;
begin
 if not private.validate_professional_prescription(p_prescription) then
  raise exception 'INVALID_PRESCRIPTION' using errcode='22023';
 end if;
 -- Lock por idempotency key: solicitudes iguales son repetibles, distintas se rechazan.
 perform pg_advisory_xact_lock(hashtextextended('training_publish:'||p_request::text,0));
 select id,prescription into v_id,v_previous from public.professional_training_sessions where publish_request_id=p_request;
 if v_id is not null and v_previous is distinct from p_prescription then
  raise exception 'REQUEST_ID_REUSED' using errcode='23505'; end if;
 v_id := private.publish_professional_session(p_org,p_client,p_day,p_title,p_instructions,p_request);
 update public.professional_training_sessions set prescription=p_prescription where id=v_id
   and (prescription is distinct from p_prescription);
 return v_id;
end; $$;

create or replace function private.update_professional_session_v2(
 p_session uuid,p_day date,p_title text,p_instructions text,p_prescription jsonb
) returns boolean language plpgsql security definer set search_path=''
as $$
declare v_rec public.professional_training_sessions%rowtype;
begin
 select * into v_rec from public.professional_training_sessions where id=p_session for update;
 if not found then raise exception 'NOT_FOUND' using errcode='22023'; end if;
 if auth.uid() is null or not (
   private.has_org_role(v_rec.org_id,array['owner','admin']::public.organization_role[])
   or (v_rec.coach_user_id=auth.uid() and private.is_assigned_coach(v_rec.org_id,v_rec.client_id))
 ) then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v_rec.status<>'scheduled' or v_rec.scheduled_date < current_date then
  raise exception 'SESSION_LOCKED' using errcode='22023'; end if;
 if p_day is null or p_day<current_date or p_day>current_date+interval '18 months'
 or length(btrim(coalesce(p_title,''))) not between 2 and 120
 or length(coalesce(p_instructions,''))>10000
 or not private.validate_professional_prescription(p_prescription) then
  raise exception 'INVALID_PRESCRIPTION' using errcode='22023'; end if;
 update public.professional_training_sessions set scheduled_date=p_day,title=btrim(p_title),
  instructions=coalesce(p_instructions,''),prescription=p_prescription,updated_at=now()
  where id=p_session;
 return true;
end; $$;

create or replace function private.publish_class_training(
 p_occurrence uuid,p_title text,p_instructions text,p_prescription jsonb
) returns int language plpgsql security definer set search_path=''
as $$
declare v public.service_occurrences%rowtype; enrolled record; existing_id uuid; published int:=0; plan_date date;
begin
 select * into v from public.service_occurrences where id=p_occurrence;
 if not found or v.status<>'active' or v.starts_at<=now() then
  raise exception 'CLASS_NOT_EDITABLE' using errcode='22023'; end if;
 if not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if length(btrim(coalesce(p_title,''))) not between 2 and 120
 or length(coalesce(p_instructions,''))>10000
 or not private.validate_professional_prescription(p_prescription) then
  raise exception 'INVALID_PRESCRIPTION' using errcode='22023'; end if;
 select (v.starts_at at time zone coalesce(o.timezone,'Europe/Madrid'))::date
 into plan_date from public.organizations o where o.id=v.org_id;
 for enrolled in
  select b.client_id from public.service_bookings b
  join public.clients c on c.id=b.client_id and c.org_id=b.org_id
  where b.occurrence_id=p_occurrence and b.status='booked' and c.user_id is not null and c.status='active'
 loop
  select id into existing_id from public.professional_training_sessions
   where org_id=v.org_id and client_id=enrolled.client_id and source_occurrence_id=p_occurrence
      and status='scheduled' order by created_at desc limit 1 for update;
  if found then
   perform private.update_professional_session_v2(existing_id,plan_date,p_title,p_instructions,p_prescription);
  else
   insert into public.professional_training_sessions
     (org_id,client_id,coach_user_id,scheduled_date,title,instructions,prescription,publish_request_id,source_occurrence_id)
   values(v.org_id,enrolled.client_id,auth.uid(),plan_date,btrim(p_title),coalesce(p_instructions,''),p_prescription,gen_random_uuid(),p_occurrence);
  end if;
  published:=published+1;existing_id:=null;
 end loop;
 return published;
end; $$;
