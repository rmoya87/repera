-- Cupos por clientes comercialmente activos + entitlements Pro (sin Stripe).
-- Pro patrocinado: cálculo servidor; cumplimiento App Store/Play sigue pendiente de gate.

-- Cliente comercialmente activo: vinculado + bono activo con saldo o vigencia.
create or replace function private.count_commercially_active_clients(p_org uuid)
returns integer language sql stable security definer set search_path='' as $$
  select count(*)::int from (
    select distinct c.id
    from public.clients c
    join public.service_passes p on p.org_id=c.org_id and p.client_id=c.id
    where c.org_id=p_org
      and c.user_id is not null
      and c.status in ('active','trial','paused')
      and c.account_deleted_at is null
      and p.status='active'
      and p.valid_from <= now()
      and p.valid_until >= now()
      and p.remaining_credits > 0
  ) x;
$$;

create or replace function private.enforce_trainer_client_limit()
 returns trigger language plpgsql security definer set search_path='' as $$
declare v_kind text; v_cap integer; v_used integer;
  v_paid text; v_paid_until timestamptz; v_trial timestamptz;
begin
 if new.user_id is null or new.status not in('active','paused','trial') then return new; end if;
 if tg_op='UPDATE' and old.user_id is not distinct from new.user_id
   and old.status in('active','paused','trial') and old.org_id=new.org_id then return new; end if;
 select kind into v_kind from public.organizations where id=new.org_id;
 if v_kind<>'personal_trainer' then return new; end if;
 perform pg_advisory_xact_lock(hashtextextended('trainer_seats:'||new.org_id::text,0));
 select t.paid_plan, t.paid_until, t.trial_ends_at
   into v_paid, v_paid_until, v_trial
 from public.organization_trials t where t.org_id=new.org_id;
 if v_paid is not null and v_paid_until > now() then
   select bp.max_clients into v_cap from public.business_plans bp
    where bp.plan_key=v_paid and bp.audience='personal_trainer';
 else
   v_cap := case when v_trial > now() then 5 else 0 end;
 end if;
 if v_cap is null then v_cap := 0; end if;
 -- Cupo: vinculados con bono elegible; leads/pending sin bono no cuentan.
 v_used := private.count_commercially_active_clients(new.org_id);
 -- Si este UPDATE/INSERT aún no tiene bono, no consume plaza de pago
 -- (linked_without_plan). Solo bloquea cuando el cliente YA es comercialmente
 -- activo o cuando se intenta superar tras activar.
 if v_used >= v_cap and exists (
   select 1 from public.service_passes p
   where p.org_id=new.org_id and p.client_id=new.id and p.status='active'
     and p.valid_until>=now() and p.remaining_credits>0
 ) then
   raise exception 'TRAINER_CLIENT_LIMIT' using errcode='P0001';
 end if;
 return new;
end $$;

-- También validar al emitir bono offline (punto real de consumo de cupo).
create or replace function private.business_issue_offline_pass(
 p_org uuid,p_client uuid,p_offer uuid,p_request uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_offer public.business_pass_offers%rowtype;
 v_id uuid;v_actor uuid:=auth.uid();v_previous public.service_passes%rowtype;
 v_kind text; v_cap integer; v_used integer;
 v_paid text; v_paid_until timestamptz; v_trial timestamptz;
 v_already boolean;
begin
 if v_actor is null or p_request is null or
   not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 perform pg_advisory_xact_lock(hashtextextended('manual_pass:'||p_request::text,0));
 select * into v_previous from public.service_passes
  where issuance_request_id=p_request;
 if found then
  if v_previous.org_id<>p_org or v_previous.client_id<>p_client
    or v_previous.offer_id is distinct from p_offer
    or v_previous.issued_by<>v_actor then
   raise exception 'REQUEST_REUSE' using errcode='23505';
  end if;
  return v_previous.id;
 end if;
 select * into v_offer from public.business_pass_offers
  where id=p_offer and org_id=p_org and is_active;
 if not found or not exists(
  select 1 from public.clients c where c.id=p_client and c.org_id=p_org
   and c.user_id is not null and c.status='active' and c.account_deleted_at is null
 ) then raise exception 'OFFER_OR_CLIENT_UNAVAILABLE' using errcode='22023';end if;

 select kind into v_kind from public.organizations where id=p_org;
 if v_kind='personal_trainer' then
  perform pg_advisory_xact_lock(hashtextextended('trainer_seats:'||p_org::text,0));
  select t.paid_plan,t.paid_until,t.trial_ends_at into v_paid,v_paid_until,v_trial
   from public.organization_trials t where t.org_id=p_org;
  if v_paid is not null and v_paid_until>now() then
   select bp.max_clients into v_cap from public.business_plans bp
    where bp.plan_key=v_paid and bp.audience='personal_trainer';
  else
   v_cap := case when v_trial>now() then 5 else 0 end;
  end if;
  if v_cap is null then v_cap:=0; end if;
  select exists(
    select 1 from public.service_passes p
    where p.org_id=p_org and p.client_id=p_client and p.status='active'
      and p.valid_until>=now() and p.remaining_credits>0
  ) into v_already;
  v_used := private.count_commercially_active_clients(p_org);
  if not v_already and v_used >= v_cap then
   raise exception 'TRAINER_CLIENT_LIMIT' using errcode='P0001';
  end if;
 end if;

 insert into public.service_passes(
  org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,
  issued_by,issuance_type,offer_id,issuance_request_id
 ) values(
  p_org,p_client,v_offer.kind,v_offer.credits,v_offer.credits,now(),
  now()+make_interval(days=>v_offer.validity_days),
  v_actor,'manual_offline',p_offer,p_request
 ) returning id into v_id;
 insert into public.service_credit_ledger(org_id,pass_id,event,amount,created_by)
 values(p_org,v_id,'offline_pass_grant',v_offer.credits,v_actor);
 return v_id;
end $$;

-- Entitlements efectivos del atleta autenticado (sin escritura cliente).
create or replace function public.get_my_effective_entitlements()
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid:=auth.uid();
  v_store boolean:=false;
  v_sponsored boolean:=false;
  v_orgs jsonb:='[]'::jsonb;
  v_row record;
begin
  if v_actor is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;

  -- Store Pro: tablas Play/Apple si existen; no inventar RevenueCat server-side aquí.
  begin
    select exists(
      select 1 from public.play_subscription_purchases o
      where o.owner_id=v_actor and coalesce(o.superseded,false)=false
        and coalesce(o.subscription_state,'') in ('active','in_grace','on_hold','SUBSCRIPTION_STATE_ACTIVE')
        and (o.expires_at is null or o.expires_at > now())
    ) into v_store;
  exception when undefined_table or undefined_column then
    v_store := false;
  end;

  for v_row in
    select o.id as org_id, o.name as org_name, o.kind,
           max(p.valid_until) as until_at
    from public.clients c
    join public.organizations o on o.id=c.org_id
    join public.service_passes p on p.org_id=c.org_id and p.client_id=c.id
    left join public.organization_trials t on t.org_id=o.id
    where c.user_id=v_actor and c.status='active' and c.account_deleted_at is null
      and p.status='active' and p.valid_from<=now() and p.valid_until>=now()
      and p.remaining_credits>0
      and p.issuance_type='manual_offline' -- cortesía no patrocina Pro
      and (
        (t.paid_plan is not null and t.paid_until>now())
        or (t.trial_ends_at>now())
      )
      and not exists (
        select 1 from public.platform_org_controls ctrl
        where ctrl.org_id=o.id and ctrl.status='suspended'
      )
    group by o.id, o.name, o.kind
  loop
    v_sponsored := true;
    v_orgs := v_orgs || jsonb_build_array(jsonb_build_object(
      'org_id', v_row.org_id,
      'org_name', v_row.org_name,
      'kind', v_row.kind,
      'valid_until', v_row.until_at,
      'reason', 'business_sponsored'
    ));
  end loop;

  return jsonb_build_object(
    'effective_pro', (v_store or v_sponsored),
    'store_pro', v_store,
    'business_sponsored_pro', v_sponsored,
    'sponsors', v_orgs,
    'store_gate_pending', true,
    'computed_at', now()
  );
end $$;
revoke all on function public.get_my_effective_entitlements() from public,anon;
grant execute on function public.get_my_effective_entitlements() to authenticated;
