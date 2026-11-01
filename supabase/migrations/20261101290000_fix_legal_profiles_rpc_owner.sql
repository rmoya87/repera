-- Repara «permission denied for table organization_legal_profiles» al guardar
-- branding/datos fiscales: la RPC SECURITY DEFINER debe ser del owner de la
-- tabla y devolver jsonb (el tipo fila exige SELECT al invocador en algunos
-- caminos PostgREST). La foto no debería depender de este permiso, pero el
-- formulario de Ajustes llama al upsert fiscal en el mismo submit.

revoke all on table public.organization_legal_profiles from public, anon;
grant select on table public.organization_legal_profiles to authenticated;
grant insert (
  org_id, entity_type, legal_name, tax_id, representative_name, contact_name,
  billing_email, billing_address, postal_code, city, province, country
) on table public.organization_legal_profiles to authenticated;
grant update (
  entity_type, legal_name, tax_id, representative_name, contact_name,
  billing_email, billing_address, postal_code, city, province, country, updated_at
) on table public.organization_legal_profiles to authenticated;

-- Owner de tabla / bypass habitual en Supabase.
grant all on table public.organization_legal_profiles to postgres, service_role;

drop policy if exists business_legal_managers_read on public.organization_legal_profiles;
drop policy if exists business_legal_managers_insert on public.organization_legal_profiles;
drop policy if exists business_legal_managers_update on public.organization_legal_profiles;

create policy business_legal_managers_read on public.organization_legal_profiles
  for select to authenticated
  using (private.has_org_role(org_id, array['owner','admin']::public.organization_role[]));

create policy business_legal_managers_insert on public.organization_legal_profiles
  for insert to authenticated
  with check (private.has_org_role(org_id, array['owner','admin']::public.organization_role[]));

create policy business_legal_managers_update on public.organization_legal_profiles
  for update to authenticated
  using (private.has_org_role(org_id, array['owner','admin']::public.organization_role[]))
  with check (private.has_org_role(org_id, array['owner','admin']::public.organization_role[]));

drop function if exists public.upsert_organization_legal_profile(
  uuid, text, text, text, text, text, text, text, text, text, text, text
);

create function public.upsert_organization_legal_profile(
  p_org uuid,
  p_entity_type text default 'self_employed',
  p_legal_name text default null,
  p_tax_id text default null,
  p_representative_name text default null,
  p_contact_name text default null,
  p_billing_email text default null,
  p_billing_address text default null,
  p_postal_code text default null,
  p_city text default null,
  p_province text default null,
  p_country text default 'ES'
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
  v_entity text := coalesce(nullif(btrim(p_entity_type), ''), 'self_employed');
  v_country text := upper(coalesce(nullif(btrim(p_country), ''), 'ES'));
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_entity not in ('self_employed', 'company') then
    raise exception 'INVALID_ENTITY' using errcode = '22023';
  end if;
  if v_country !~ '^[A-Z]{2}$' then
    raise exception 'INVALID_COUNTRY' using errcode = '22023';
  end if;

  insert into public.organization_legal_profiles as t (
    org_id, entity_type, legal_name, tax_id, representative_name, contact_name,
    billing_email, billing_address, postal_code, city, province, country, updated_at
  ) values (
    p_org, v_entity,
    nullif(btrim(p_legal_name), ''),
    nullif(btrim(p_tax_id), ''),
    nullif(btrim(p_representative_name), ''),
    nullif(btrim(p_contact_name), ''),
    nullif(btrim(p_billing_email), ''),
    nullif(btrim(p_billing_address), ''),
    nullif(btrim(p_postal_code), ''),
    nullif(btrim(p_city), ''),
    nullif(btrim(p_province), ''),
    v_country,
    now()
  )
  on conflict (org_id) do update set
    entity_type = excluded.entity_type,
    legal_name = excluded.legal_name,
    tax_id = excluded.tax_id,
    representative_name = excluded.representative_name,
    contact_name = excluded.contact_name,
    billing_email = excluded.billing_email,
    billing_address = excluded.billing_address,
    postal_code = excluded.postal_code,
    city = excluded.city,
    province = excluded.province,
    country = excluded.country,
    updated_at = now()
  returning to_jsonb(t.*) into v_row;

  return v_row;
end $$;

alter function public.upsert_organization_legal_profile(
  uuid, text, text, text, text, text, text, text, text, text, text, text
) owner to postgres;

revoke all on function public.upsert_organization_legal_profile(
  uuid, text, text, text, text, text, text, text, text, text, text, text
) from public, anon;
grant execute on function public.upsert_organization_legal_profile(
  uuid, text, text, text, text, text, text, text, text, text, text, text
) to authenticated, service_role;

create or replace function public.get_organization_legal_profile(p_org uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select to_jsonb(l.*) into v_row
  from public.organization_legal_profiles l
  where l.org_id = p_org;
  return v_row;
end $$;

alter function public.get_organization_legal_profile(uuid) owner to postgres;
revoke all on function public.get_organization_legal_profile(uuid) from public, anon;
grant execute on function public.get_organization_legal_profile(uuid) to authenticated, service_role;

notify pgrst, 'reload schema';
