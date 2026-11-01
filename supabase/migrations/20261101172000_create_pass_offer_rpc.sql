-- Crear tarifas vía RPC (evita fallos de schema cache de PostgREST en INSERT).

create or replace function public.business_create_pass_offer(
  p_org uuid,
  p_name text,
  p_kind text,
  p_credits integer,
  p_validity_days integer,
  p_price_cents integer,
  p_billing_model text default 'session_pack',
  p_access_scope text default 'trainer_appointments',
  p_slot_weekdays int[] default array[1,2,3,4,5]::int[],
  p_slot_start_minute integer default 540,
  p_slot_end_minute integer default 720
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_id uuid;
  v_billing text := coalesce(nullif(btrim(p_billing_model), ''), 'session_pack');
  v_scope text := coalesce(nullif(btrim(p_access_scope), ''), 'trainer_appointments');
  v_name text := btrim(coalesce(p_name, ''));
  v_kind text := coalesce(p_kind, 'appointment');
  v_days int[];
begin
  if v_actor is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if length(v_name) not between 2 and 120 then
    raise exception 'INVALID_NAME' using errcode = '22023';
  end if;
  if v_kind not in ('class', 'appointment') then
    raise exception 'INVALID_KIND' using errcode = '22023';
  end if;
  if v_billing not in ('session_pack', 'monthly', 'unlimited', 'time_slot') then
    raise exception 'INVALID_BILLING' using errcode = '22023';
  end if;
  if v_scope not in ('trainer_appointments', 'gym_access') then
    raise exception 'INVALID_SCOPE' using errcode = '22023';
  end if;
  if p_credits is null or p_credits < 1 or p_credits > 9999
     or p_validity_days is null or p_validity_days < 1 or p_validity_days > 730
     or p_price_cents is null or p_price_cents < 0 or p_price_cents > 10000000 then
    raise exception 'INVALID_OFFER' using errcode = '22023';
  end if;

  if v_billing = 'time_slot' then
    select coalesce(array_agg(distinct d), '{}') into v_days
    from unnest(coalesce(p_slot_weekdays, array[]::int[])) as d
    where d between 1 and 7;
    if cardinality(v_days) < 1
       or p_slot_start_minute is null or p_slot_end_minute is null
       or p_slot_start_minute < 0 or p_slot_end_minute > 1440
       or p_slot_end_minute <= p_slot_start_minute then
      raise exception 'INVALID_SLOT' using errcode = '22023';
    end if;
  else
    v_days := array[1,2,3,4,5]::int[];
  end if;

  if v_scope = 'gym_access' then v_kind := 'class'; end if;
  if v_scope = 'trainer_appointments' and v_kind not in ('class','appointment') then
    v_kind := 'appointment';
  end if;

  insert into public.business_pass_offers(
    org_id, name, kind, credits, validity_days, price_cents, currency, is_active,
    created_by, billing_model, access_scope, slot_weekdays, slot_start_minute, slot_end_minute
  ) values (
    p_org, v_name, v_kind, p_credits, p_validity_days, p_price_cents, 'EUR', true,
    v_actor, v_billing, v_scope,
    case when v_billing = 'time_slot' then v_days else array[1,2,3,4,5]::int[] end,
    case when v_billing = 'time_slot' then p_slot_start_minute else 540 end,
    case when v_billing = 'time_slot' then p_slot_end_minute else 720 end
  ) returning id into v_id;

  return v_id;
end $$;

revoke all on function public.business_create_pass_offer(
  uuid,text,text,integer,integer,integer,text,text,int[],integer,integer
) from public, anon;
grant execute on function public.business_create_pass_offer(
  uuid,text,text,integer,integer,integer,text,text,int[],integer,integer
) to authenticated;

notify pgrst, 'reload schema';
