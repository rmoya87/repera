-- Normalización más tolerante al conectar/actualizar WhatsApp del negocio
-- (00…, móvil ES local 6/7xxxxxxxx) y poder cambiar el número ya conectado.
create or replace function public.connect_org_whatsapp(p_org uuid, p_e164 text)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_raw text := btrim(coalesce(p_e164, ''));
  v_digits text;
  v_row public.organizations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  if left(v_raw, 2) = '00' then
    v_raw := substr(v_raw, 3);
  end if;
  v_digits := regexp_replace(v_raw, '\D', '', 'g');
  -- Móvil España local (9 dígitos 6/7…) → prefijo 34.
  if v_digits ~ '^[67][0-9]{8}$' then
    v_digits := '34' || v_digits;
  end if;
  v_digits := regexp_replace(v_digits, '^0+', '');

  if v_digits !~ '^[1-9][0-9]{7,14}$' then
    raise exception 'WHATSAPP_INVALID' using errcode = '22023';
  end if;

  update public.organizations
  set whatsapp_e164 = v_digits,
      whatsapp_connected_at = now(),
      updated_at = now()
  where id = p_org
  returning * into v_row;
  if not found then
    raise exception 'ORG_NOT_FOUND' using errcode = 'P0002';
  end if;
  return v_row;
end;
$$;

revoke all on function public.connect_org_whatsapp(uuid, text) from public, anon;
grant execute on function public.connect_org_whatsapp(uuid, text) to authenticated;
