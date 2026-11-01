-- Cobro externo declarado al asignar bono: método, fecha e importe.
-- No es pasarela Repera; solo registro operativo del entrenador/gimnasio.

alter table public.service_passes
  add column if not exists payment_method text,
  add column if not exists paid_at timestamptz,
  add column if not exists paid_amount_cents integer,
  add column if not exists payment_note text;

alter table public.service_passes
  drop constraint if exists service_passes_payment_method_check;
alter table public.service_passes
  add constraint service_passes_payment_method_check
  check (payment_method is null or payment_method in ('card','transfer','cash','other','complimentary'));

alter table public.service_passes
  drop constraint if exists service_passes_paid_amount_check;
alter table public.service_passes
  add constraint service_passes_paid_amount_check
  check (paid_amount_cents is null or (paid_amount_cents >= 0 and paid_amount_cents <= 10000000));

alter table public.service_passes
  drop constraint if exists service_passes_payment_note_check;
alter table public.service_passes
  add constraint service_passes_payment_note_check
  check (payment_note is null or length(payment_note) <= 400);

-- Sustituye firma antigua (4 args) por la ampliada.
drop function if exists private.business_issue_offline_pass(uuid,uuid,uuid,uuid);
drop function if exists private.business_issue_offline_pass(uuid,uuid,uuid,uuid,text,timestamptz,integer,text);
drop function if exists public.business_issue_offline_pass(uuid,uuid,uuid,uuid);
drop function if exists public.business_issue_offline_pass(uuid,uuid,uuid,uuid,text,timestamptz,integer,text);

create function private.business_issue_offline_pass(
 p_org uuid,p_client uuid,p_offer uuid,p_request uuid,
 p_payment_method text default 'other',
 p_paid_at timestamptz default null,
 p_paid_amount_cents integer default null,
 p_payment_note text default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_offer public.business_pass_offers%rowtype;
 v_id uuid;v_actor uuid:=auth.uid();v_previous public.service_passes%rowtype;
 v_kind text; v_cap integer; v_used integer;
 v_paid text; v_paid_until timestamptz; v_trial timestamptz;
 v_already boolean;
 v_method text := coalesce(nullif(btrim(p_payment_method),''),'other');
 v_paid_at timestamptz := coalesce(p_paid_at, now());
 v_amount integer;
 v_note text := nullif(btrim(coalesce(p_payment_note,'')),'');
begin
 if v_actor is null or p_request is null or
   not private.has_org_role(p_org,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';
 end if;
 if v_method not in ('card','transfer','cash','other','complimentary') then
  raise exception 'INVALID_PAYMENT_METHOD' using errcode='22023';
 end if;
 if v_note is not null and length(v_note) > 400 then
  raise exception 'INVALID_PAYMENT_NOTE' using errcode='22023';
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

 v_amount := coalesce(p_paid_amount_cents, v_offer.price_cents);
 if v_amount < 0 or v_amount > 10000000 then
  raise exception 'INVALID_PAYMENT_AMOUNT' using errcode='22023';
 end if;
 if v_method = 'complimentary' then v_amount := 0; end if;

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
  issued_by,issuance_type,offer_id,issuance_request_id,
  payment_method,paid_at,paid_amount_cents,payment_note
 ) values(
  p_org,p_client,v_offer.kind,v_offer.credits,v_offer.credits,now(),
  now()+make_interval(days=>v_offer.validity_days),
  v_actor,'manual_offline',p_offer,p_request,
  v_method,v_paid_at,v_amount,v_note
 ) returning id into v_id;
 insert into public.service_credit_ledger(org_id,pass_id,event,amount,created_by)
 values(p_org,v_id,'offline_pass_grant',v_offer.credits,v_actor);
 return v_id;
end $$;

revoke all on function private.business_issue_offline_pass(uuid,uuid,uuid,uuid,text,timestamptz,integer,text)
 from public,anon,authenticated;
grant execute on function private.business_issue_offline_pass(uuid,uuid,uuid,uuid,text,timestamptz,integer,text)
 to authenticated;

create function public.business_issue_offline_pass(
 p_org uuid,p_client uuid,p_offer uuid,p_request uuid,
 p_payment_method text default 'other',
 p_paid_at timestamptz default null,
 p_paid_amount_cents integer default null,
 p_payment_note text default null
) returns uuid language sql security invoker set search_path='' as $$
 select private.business_issue_offline_pass(
  p_org,p_client,p_offer,p_request,p_payment_method,p_paid_at,p_paid_amount_cents,p_payment_note)
$$;
revoke all on function public.business_issue_offline_pass(uuid,uuid,uuid,uuid,text,timestamptz,integer,text)
 from public,anon;
grant execute on function public.business_issue_offline_pass(uuid,uuid,uuid,uuid,text,timestamptz,integer,text)
 to authenticated;

notify pgrst, 'reload schema';
