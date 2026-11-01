-- 1) Bonos a fichas lead (antes de aceptar): al vincularse ya ven el acceso.
-- 2) invite_athlete_client con modo prueba / bono cobrado.
-- 3) Preview de invitación para la app (nombre del centro).

create or replace function private.grant_complimentary_pass(
  p_org uuid, p_client uuid, p_kind text, p_credits int, p_valid_until timestamptz
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_id uuid;
begin
  if v_actor is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if p_kind not in ('class','appointment')
     or p_credits not between 1 and 1000
     or p_valid_until <= now()
     or p_valid_until > now() + interval '2 years' then
    raise exception 'INVALID_PASS' using errcode = '22023';
  end if;
  -- Lead o activo del centro (puede no tener user_id todavía).
  if not exists (
    select 1 from public.clients c
    where c.org_id = p_org and c.id = p_client
      and c.status in ('lead','trial','active')
      and c.account_deleted_at is null
  ) then
    raise exception 'CLIENT_NOT_LINKED' using errcode = '22023';
  end if;
  insert into public.service_passes(
    org_id, client_id, kind, total_credits, remaining_credits, valid_until, issued_by, issuance_type
  ) values (
    p_org, p_client, p_kind, p_credits, p_credits, p_valid_until, v_actor, 'complimentary'
  ) returning id into v_id;
  insert into public.service_credit_ledger(org_id, pass_id, event, amount, created_by)
  values (p_org, v_id, 'complimentary_grant', p_credits, v_actor);
  return v_id;
end;
$$;

create or replace function private.business_issue_offline_pass(
  p_org uuid, p_client uuid, p_offer uuid, p_request uuid,
  p_payment_method text default 'other',
  p_paid_at timestamptz default null,
  p_paid_amount_cents integer default null,
  p_payment_note text default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_offer public.business_pass_offers%rowtype;
  v_id uuid;
  v_actor uuid := auth.uid();
  v_previous public.service_passes%rowtype;
  v_kind text;
  v_cap integer;
  v_used integer;
  v_paid text;
  v_paid_until timestamptz;
  v_trial timestamptz;
  v_already boolean;
  v_method text := coalesce(nullif(btrim(p_payment_method), ''), 'other');
  v_paid_at timestamptz := coalesce(p_paid_at, now());
  v_amount integer;
  v_note text := nullif(btrim(coalesce(p_payment_note, '')), '');
  v_pass_kind text;
begin
  if v_actor is null or p_request is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_method not in ('card','transfer','cash','other','complimentary') then
    raise exception 'INVALID_PAYMENT_METHOD' using errcode = '22023';
  end if;
  if v_note is not null and length(v_note) > 400 then
    raise exception 'INVALID_PAYMENT_NOTE' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('manual_pass:' || p_request::text, 0));
  select * into v_previous from public.service_passes where issuance_request_id = p_request;
  if found then
    if v_previous.org_id <> p_org or v_previous.client_id <> p_client
       or v_previous.offer_id is distinct from p_offer
       or v_previous.issued_by <> v_actor then
      raise exception 'REQUEST_REUSE' using errcode = '23505';
    end if;
    return v_previous.id;
  end if;

  select * into v_offer
  from public.business_pass_offers
  where id = p_offer and org_id = p_org and is_active;
  if not found or not exists (
    select 1 from public.clients c
    where c.id = p_client and c.org_id = p_org
      and c.status in ('lead','trial','active')
      and c.account_deleted_at is null
  ) then
    raise exception 'OFFER_OR_CLIENT_UNAVAILABLE' using errcode = '22023';
  end if;

  v_amount := coalesce(p_paid_amount_cents, v_offer.price_cents);
  if v_amount < 0 or v_amount > 10000000 then
    raise exception 'INVALID_PAYMENT_AMOUNT' using errcode = '22023';
  end if;
  if v_method = 'complimentary' then v_amount := 0; end if;

  v_pass_kind := case
    when coalesce(v_offer.access_scope, 'trainer_appointments') = 'gym_access' then 'class'
    else coalesce(nullif(v_offer.kind, ''), 'appointment')
  end;
  if v_pass_kind not in ('class','appointment') then v_pass_kind := 'appointment'; end if;

  select kind into v_kind from public.organizations where id = p_org;
  if v_kind = 'personal_trainer' then
    perform pg_advisory_xact_lock(hashtextextended('trainer_seats:' || p_org::text, 0));
    select t.paid_plan, t.paid_until, t.trial_ends_at
      into v_paid, v_paid_until, v_trial
    from public.organization_trials t where t.org_id = p_org;
    if v_paid is not null and v_paid_until > now() then
      select bp.max_clients into v_cap
      from public.business_plans bp
      where bp.plan_key = v_paid and bp.audience = 'personal_trainer';
    else
      v_cap := case when v_trial > now() then 5 else 0 end;
    end if;
    if v_cap is null then v_cap := 0; end if;
    select exists (
      select 1 from public.service_passes p
      where p.org_id = p_org and p.client_id = p_client and p.status = 'active'
        and p.valid_until >= now() and p.remaining_credits > 0
    ) into v_already;
    v_used := private.count_commercially_active_clients(p_org);
    if not v_already and v_used >= v_cap then
      raise exception 'TRAINER_CLIENT_LIMIT' using errcode = 'P0001';
    end if;
  end if;

  insert into public.service_passes(
    org_id, client_id, kind, total_credits, remaining_credits, valid_from, valid_until,
    issued_by, issuance_type, offer_id, issuance_request_id,
    payment_method, paid_at, paid_amount_cents, payment_note,
    billing_model, access_scope, slot_weekdays, slot_start_minute, slot_end_minute
  ) values (
    p_org, p_client, v_pass_kind, v_offer.credits, v_offer.credits, now(),
    now() + make_interval(days => v_offer.validity_days),
    v_actor, 'manual_offline', p_offer, p_request,
    v_method, v_paid_at, v_amount, v_note,
    v_offer.billing_model, v_offer.access_scope, v_offer.slot_weekdays,
    v_offer.slot_start_minute, v_offer.slot_end_minute
  ) returning id into v_id;
  insert into public.service_credit_ledger(org_id, pass_id, event, amount, created_by)
  values (p_org, v_id, 'offline_pass_grant', v_offer.credits, v_actor);
  return v_id;
end;
$$;

drop function if exists public.invite_athlete_client(uuid, text, text, text);

create function public.invite_athlete_client(
  p_org uuid,
  p_name text,
  p_email text,
  p_phone text default null,
  p_pass_mode text default 'none',
  p_trial_credits integer default null,
  p_trial_kind text default null,
  p_trial_days integer default 30,
  p_offer_id uuid default null,
  p_payment_method text default null,
  p_paid_amount_cents integer default null,
  p_payment_note text default null,
  p_pass_request uuid default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_name text := left(btrim(coalesce(p_name, '')), 120);
  v_phone text := left(btrim(coalesce(p_phone, '')), 40);
  v_client public.clients%rowtype;
  v_invitation_id uuid;
  v_reused boolean := false;
  v_mode text := lower(btrim(coalesce(p_pass_mode, 'none')));
  v_pass_id uuid;
  v_trial_days integer := greatest(1, least(coalesce(p_trial_days, 30), 365));
  v_trial_kind text := coalesce(nullif(btrim(coalesce(p_trial_kind, '')), ''), 'class');
  v_org_kind text;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if length(v_name) < 2 then
    raise exception 'INVALID_NAME' using errcode = '22023';
  end if;
  if length(v_email) not between 5 and 254
     or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then
    raise exception 'INVALID_EMAIL' using errcode = '22023';
  end if;
  if v_mode not in ('none', 'trial', 'paid') then
    raise exception 'INVALID_PASS_MODE' using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.organization_memberships m
    join auth.users u on u.id = m.user_id
    where m.organization_id = p_org
      and m.status = 'active'
      and lower(btrim(u.email)) = v_email
  ) then
    raise exception 'ALREADY_A_MEMBER' using errcode = '23505';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_org::text || ':client:' || v_email, 0));

  select * into v_client
  from public.clients
  where org_id = p_org and lower(email) = v_email
  for update;

  if found then
    if v_client.user_id is not null then
      raise exception 'CLIENT_ALREADY_LINKED' using errcode = '23505';
    end if;
    update public.clients
    set name = v_name,
        phone = case when v_phone = '' then phone else v_phone end,
        updated_at = now()
    where id = v_client.id
    returning * into v_client;
    v_reused := true;
  else
    insert into public.clients(org_id, created_by, name, email, status, phone)
    values (p_org, v_actor, v_name, v_email, 'lead', nullif(v_phone, ''))
    returning * into v_client;
  end if;

  v_invitation_id := private.issue_org_invitation(p_org, v_email, 'athlete'::public.organization_role);

  select kind into v_org_kind from public.organizations where id = p_org;
  if v_trial_kind not in ('class','appointment') then
    v_trial_kind := case when v_org_kind = 'personal_trainer' then 'appointment' else 'class' end;
  end if;

  if v_mode = 'trial' then
    if p_trial_credits is null or p_trial_credits < 1 or p_trial_credits > 100 then
      raise exception 'INVALID_TRIAL_CREDITS' using errcode = '22023';
    end if;
    v_pass_id := private.grant_complimentary_pass(
      p_org, v_client.id, v_trial_kind, p_trial_credits,
      now() + make_interval(days => v_trial_days)
    );
  elsif v_mode = 'paid' then
    if p_offer_id is null or p_pass_request is null then
      raise exception 'INVALID_PAID_PASS' using errcode = '22023';
    end if;
    v_pass_id := private.business_issue_offline_pass(
      p_org, v_client.id, p_offer_id, p_pass_request,
      coalesce(p_payment_method, 'other'),
      now(),
      p_paid_amount_cents,
      p_payment_note
    );
  end if;

  return jsonb_build_object(
    'client_id', v_client.id,
    'invitation_id', v_invitation_id,
    'reused', v_reused,
    'email', v_email,
    'name', v_client.name,
    'phone', coalesce(v_client.phone, ''),
    'pass_mode', v_mode,
    'pass_id', v_pass_id
  );
end;
$$;

revoke all on function public.invite_athlete_client(
  uuid, text, text, text, text, integer, text, integer, uuid, text, integer, text, uuid
) from public, anon;
grant execute on function public.invite_athlete_client(
  uuid, text, text, text, text, integer, text, integer, uuid, text, integer, text, uuid
) to authenticated;

create or replace function public.get_my_invitation_preview(p_invitation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_email text;
  v_inv public.organization_invitations%rowtype;
  v_org public.organizations%rowtype;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  select lower(btrim(email)) into v_email
  from auth.users
  where id = v_actor and email_confirmed_at is not null;
  if v_email is null then
    raise exception 'VERIFIED_EMAIL_REQUIRED' using errcode = '42501';
  end if;

  select * into v_inv
  from public.organization_invitations
  where id = p_invitation_id;
  if not found or v_inv.email <> v_email then
    raise exception 'INVITATION_NOT_FOUND' using errcode = '42501';
  end if;
  if v_inv.accepted_at is not null or v_inv.cancelled_at is not null or v_inv.expires_at <= now() then
    raise exception 'INVITATION_INACTIVE' using errcode = '22023';
  end if;

  select * into v_org from public.organizations where id = v_inv.organization_id;
  if not found then
    raise exception 'ORG_NOT_FOUND' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'invitation_id', v_inv.id,
    'organization_id', v_org.id,
    'organization_name', v_org.name,
    'organization_kind', v_org.kind,
    'organization_avatar_url', v_org.avatar_url,
    'organization_tagline', v_org.tagline,
    'invited_role', v_inv.invited_role,
    'expires_at', v_inv.expires_at
  );
end;
$$;

revoke all on function public.get_my_invitation_preview(uuid) from public, anon;
grant execute on function public.get_my_invitation_preview(uuid) to authenticated;
