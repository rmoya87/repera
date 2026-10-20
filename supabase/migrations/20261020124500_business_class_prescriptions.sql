
-- Publicación de entreno para clase: genera prescripciones INDIVIDUALES
-- solo a deportistas que aceptaron la vinculación y mantienen reserva activa.
alter table public.professional_training_sessions
 add column if not exists source_occurrence_id uuid;
alter table public.professional_training_sessions
 add constraint professional_training_source_occurrence_fk
 foreign key(org_id,source_occurrence_id) references public.service_occurrences(org_id,id);
create unique index professional_training_class_client_unique
 on public.professional_training_sessions(org_id,client_id,source_occurrence_id)
 where source_occurrence_id is not null and status='scheduled';
create function private.publish_class_training(
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
 or p_prescription is null or jsonb_typeof(p_prescription->'blocks')<>'array'
 or jsonb_array_length(p_prescription->'blocks') not between 1 and 24 then
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
revoke all on function private.publish_class_training(uuid,text,text,jsonb) from public,anon,authenticated;
grant execute on function private.publish_class_training(uuid,text,text,jsonb) to authenticated;
create function public.publish_class_training(p_occurrence uuid,p_title text,p_instructions text,p_prescription jsonb)
 returns int language sql security invoker set search_path=''
 as $$select private.publish_class_training(p_occurrence,p_title,p_instructions,p_prescription)$$;
revoke all on function public.publish_class_training(uuid,text,text,jsonb) from public,anon;
grant execute on function public.publish_class_training(uuid,text,text,jsonb) to authenticated;
