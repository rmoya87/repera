-- Editor Repera: prescripción por bloques, biblioteca de plantillas y datos del negocio.
-- La información deportiva privada del atleta NO se almacena aquí.
alter table public.organizations
 add column if not exists public_email text,
 add column if not exists phone text,
 add column if not exists website text,
 add column if not exists address text,
 add column if not exists description text,
 add column if not exists timezone text not null default 'Europe/Madrid';
alter table public.organizations add constraint organization_profile_lengths check (
 length(coalesce(public_email,''))<=180 and length(coalesce(phone,''))<=40
 and length(coalesce(website,''))<=255 and length(coalesce(address,''))<=300
 and length(coalesce(description,''))<=2000 and length(timezone) between 1 and 80
);
grant update(name,public_email,phone,website,address,description,timezone) on public.organizations to authenticated;

create table if not exists public.professional_workout_templates (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id) on delete cascade,
 created_by uuid not null references auth.users(id),
 name text not null check(length(btrim(name)) between 2 and 120),
 description text not null default '' check(length(description)<=1000),
 prescription jsonb not null check(
  jsonb_typeof(prescription)='object' and jsonb_typeof(prescription->'blocks')='array'
  and octet_length(prescription::text)<=100000
 ),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(org_id,id)
);
create index if not exists professional_workout_templates_org on public.professional_workout_templates(org_id,updated_at desc);
alter table public.professional_workout_templates enable row level security;
create policy workout_templates_read on public.professional_workout_templates for select to authenticated
 using(private.has_org_role(org_id,array['owner','admin','coach']::public.organization_role[]));
create policy workout_templates_insert on public.professional_workout_templates for insert to authenticated
 with check(created_by=auth.uid() and private.has_org_role(org_id,array['owner','admin','coach']::public.organization_role[]));
create policy workout_templates_update on public.professional_workout_templates for update to authenticated
 using(private.has_org_role(org_id,array['owner','admin','coach']::public.organization_role[]))
 with check(private.has_org_role(org_id,array['owner','admin','coach']::public.organization_role[]));
create policy workout_templates_delete on public.professional_workout_templates for delete to authenticated
 using(private.has_org_role(org_id,array['owner','admin']::public.organization_role[]) or created_by=auth.uid());
revoke all on public.professional_workout_templates from public,anon,authenticated;
grant select,insert,delete on public.professional_workout_templates to authenticated;
grant update(name,description,prescription,updated_at) on public.professional_workout_templates to authenticated;

-- El RPC original continúa para clientes existentes; v2 valida y guarda la receta JSON.
create function private.publish_professional_session_v2(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid,p_prescription jsonb
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid; v_previous jsonb;
begin
 if p_prescription is null or jsonb_typeof(p_prescription) <> 'object'
 or jsonb_typeof(p_prescription->'blocks') <> 'array'
 or jsonb_array_length(p_prescription->'blocks') not between 1 and 24
 or octet_length(p_prescription::text)>100000 then
  raise exception 'INVALID_PRESCRIPTION' using errcode='22023';
 end if;
 if exists(
  select 1 from jsonb_array_elements(p_prescription->'blocks') b
  where jsonb_typeof(b->'exercises') <> 'array'
    or jsonb_array_length(b->'exercises') not between 1 and 40
 ) then raise exception 'INVALID_BLOCK' using errcode='22023'; end if;
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

create function private.update_professional_session_v2(
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
 or p_prescription is null or jsonb_typeof(p_prescription->'blocks')<>'array'
 or jsonb_array_length(p_prescription->'blocks') not between 1 and 24
 or octet_length(p_prescription::text)>100000 then
  raise exception 'INVALID_PRESCRIPTION' using errcode='22023'; end if;
 if exists(
  select 1 from jsonb_array_elements(p_prescription->'blocks') b
  where jsonb_typeof(b->'exercises') <> 'array'
     or jsonb_array_length(b->'exercises') not between 1 and 40
 ) then raise exception 'INVALID_BLOCK' using errcode='22023'; end if;
 update public.professional_training_sessions set scheduled_date=p_day,title=btrim(p_title),
  instructions=coalesce(p_instructions,''),prescription=p_prescription,updated_at=now()
  where id=p_session;
 return true;
end; $$;
revoke all on function private.publish_professional_session_v2(uuid,uuid,date,text,text,uuid,jsonb),
 private.update_professional_session_v2(uuid,date,text,text,jsonb) from public,anon;
grant execute on function private.publish_professional_session_v2(uuid,uuid,date,text,text,uuid,jsonb),
 private.update_professional_session_v2(uuid,date,text,text,jsonb) to authenticated;
create function public.publish_professional_session_v2(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid,p_prescription jsonb
) returns uuid language sql security invoker set search_path=''
as $$ select private.publish_professional_session_v2(p_org,p_client,p_day,p_title,p_instructions,p_request,p_prescription) $$;
create function public.update_professional_session_v2(
 p_session uuid,p_day date,p_title text,p_instructions text,p_prescription jsonb
) returns boolean language sql security invoker set search_path=''
as $$ select private.update_professional_session_v2(p_session,p_day,p_title,p_instructions,p_prescription) $$;
revoke all on function public.publish_professional_session_v2(uuid,uuid,date,text,text,uuid,jsonb),
 public.update_professional_session_v2(uuid,date,text,text,jsonb) from public,anon;
grant execute on function public.publish_professional_session_v2(uuid,uuid,date,text,text,uuid,jsonb),
 public.update_professional_session_v2(uuid,date,text,text,jsonb) to authenticated;