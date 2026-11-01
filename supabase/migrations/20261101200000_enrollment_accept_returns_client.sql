-- Aceptar solicitud: devolver client_id, nombres/emails robustos, cupo PT sin
-- bloquear si falta fila de trial. La consola navega a Clientes con ese id.

create or replace function private.enforce_trainer_client_limit()
 returns trigger language plpgsql security definer set search_path='' as $$
declare v_kind text;v_cap integer;v_used integer;v_has_trial boolean;
begin
 if new.user_id is null or new.status not in('active','paused','trial') then return new;end if;
 if tg_op='UPDATE' and old.user_id is not distinct from new.user_id
   and old.status in('active','paused','trial') and old.org_id=new.org_id then return new;end if;
 select kind into v_kind from public.organizations where id=new.org_id;
 if v_kind<>'personal_trainer' then return new;end if;
 perform pg_advisory_xact_lock(hashtextextended('trainer_seats:'||new.org_id::text,0));
 select exists(select 1 from public.organization_trials t where t.org_id=new.org_id)
  into v_has_trial;
 if not v_has_trial then
  -- Alta sin ficha de trial: cupo de arranque (igual que prueba).
  v_cap:=5;
 else
  select case when t.paid_plan is not null and t.paid_until>now()
    then (select bp.max_clients from public.business_plans bp
      where bp.plan_key=t.paid_plan and bp.audience='personal_trainer')
    when t.trial_ends_at>now() then 5
    else 0 end into v_cap
   from public.organization_trials t where t.org_id=new.org_id;
  v_cap:=coalesce(v_cap,0);
 end if;
 select count(*) into v_used from public.clients c
  where c.org_id=new.org_id and c.user_id is not null
    and c.status in('active','paused','trial') and c.id is distinct from new.id;
 if v_cap=0 or v_used>=v_cap then
  raise exception 'TRAINER_CLIENT_LIMIT_REACHED: % of %',v_used,v_cap
   using errcode='23514';
 end if;
 return new;
end $$;

-- Cambio de uuid → jsonb: hace falta DROP (CREATE OR REPLACE no cambia el tipo de retorno).
drop function if exists public.business_decide_enrollment(uuid,boolean);
drop function if exists private.business_decide_enrollment(uuid,boolean);

create function private.business_decide_enrollment(p_request uuid,p_accept boolean)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
 v public.organization_athlete_requests%rowtype;
 v_user auth.users%rowtype;
 v_name text;
 v_email text;
 v_client uuid;
begin
 select * into v from public.organization_athlete_requests where id=p_request for update;
 if not found then raise exception 'REQUEST_NOT_FOUND' using errcode='22023'; end if;
 if auth.uid() is null or not private.has_org_role(v.org_id,array['owner','admin']::public.organization_role[])
 then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if v.status<>'pending' then raise exception 'REQUEST_ALREADY_HANDLED' using errcode='22023'; end if;
 if p_accept is null then raise exception 'DECISION_REQUIRED' using errcode='22023'; end if;

 if p_accept then
  select * into v_user from auth.users where id=v.athlete_id;
  if not found or v_user.email_confirmed_at is null then
   raise exception 'ATHLETE_NOT_VERIFIED' using errcode='42501'; end if;
  v_email:=lower(btrim(coalesce(v_user.email,'')));
  if v_email is null or length(v_email)<5 or position('@' in v_email)<2 then
   raise exception 'ATHLETE_EMAIL_REQUIRED' using errcode='22023'; end if;
  select left(coalesce(
    nullif(btrim(p.display_name),''),
    nullif(btrim(v_user.raw_user_meta_data->>'name'),''),
    nullif(btrim(v_user.raw_user_meta_data->>'full_name'),''),
    split_part(v_email,'@',1),
    'Atleta'),120)
   into v_name from public.profiles p where p.id=v.athlete_id;
  v_name:=left(coalesce(nullif(btrim(v_name),''),'Atleta'),120);
  if length(v_name)<2 then v_name:='Atleta'; end if;

  select id into v_client from public.clients where org_id=v.org_id and
   (user_id=v.athlete_id or lower(email)=v_email)
   order by (user_id=v.athlete_id) desc nulls last limit 1 for update;

  if v_client is not null then
   if exists(select 1 from public.clients where id=v_client and
    user_id is not null and user_id<>v.athlete_id)
   then raise exception 'CLIENT_ALREADY_LINKED' using errcode='23505'; end if;
   update public.clients set
    user_id=v.athlete_id,
    name=case when length(btrim(name))<2 then v_name else name end,
    email=v_email,
    status='active',
    updated_at=now(),
    notes=left(coalesce(nullif(btrim(notes),'')||E'\n','')
      ||'Solicitud aceptada · '||v.pass_kind
      ||case when length(btrim(v.note))>0 then ' · '||btrim(v.note) else '' end,2000)
   where id=v_client;
  else
   insert into public.clients(org_id,created_by,user_id,name,email,status,notes)
   values(
    v.org_id,auth.uid(),v.athlete_id,v_name,v_email,'active',
    left('Solicitud aceptada · '||v.pass_kind
     ||case when length(btrim(v.note))>0 then ' · '||btrim(v.note) else '' end,2000))
   returning id into v_client;
  end if;

  insert into public.organization_memberships(organization_id,user_id,role,status)
   values(v.org_id,v.athlete_id,'athlete','active')
   on conflict(organization_id,user_id) do update set role='athlete',status='active';
 end if;

 update public.organization_athlete_requests set
  status=case when p_accept then 'accepted' else 'rejected' end,
  decided_by=auth.uid(),decided_at=now() where id=v.id;

 return jsonb_build_object(
  'org_id',v.org_id,
  'client_id',v_client,
  'accepted',p_accept,
  'request_id',v.id);
end $$;

revoke all on function private.business_decide_enrollment(uuid,boolean) from public,anon,authenticated;
grant execute on function private.business_decide_enrollment(uuid,boolean) to authenticated;

create function public.business_decide_enrollment(p_request uuid,p_accept boolean)
returns jsonb language sql security invoker set search_path='' as $$
 select private.business_decide_enrollment(p_request,p_accept)
$$;
revoke all on function public.business_decide_enrollment(uuid,boolean) from public,anon;
grant execute on function public.business_decide_enrollment(uuid,boolean) to authenticated;

notify pgrst,'reload schema';
