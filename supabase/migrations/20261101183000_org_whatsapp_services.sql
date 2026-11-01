-- WhatsApp del centro/entrenador: número E.164 (solo dígitos) para invitaciones por wa.me.
alter table public.organizations
  add column if not exists whatsapp_e164 text,
  add column if not exists whatsapp_connected_at timestamptz;

alter table public.organizations
  drop constraint if exists organizations_whatsapp_e164_check;
alter table public.organizations
  add constraint organizations_whatsapp_e164_check
  check (whatsapp_e164 is null or whatsapp_e164 ~ '^[1-9][0-9]{7,14}$');

comment on column public.organizations.whatsapp_e164 is
  'Business WhatsApp in E.164 digits only (no +). Used to enable invite-via-WhatsApp in console.';
comment on column public.organizations.whatsapp_connected_at is
  'When the org linked a WhatsApp number for invite sharing.';

grant update(whatsapp_e164, whatsapp_connected_at) on public.organizations to authenticated;

create or replace function public.connect_org_whatsapp(p_org uuid, p_e164 text)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_digits text := regexp_replace(coalesce(p_e164, ''), '\D', '', 'g');
  v_row public.organizations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
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

create or replace function public.disconnect_org_whatsapp(p_org uuid)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.organizations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  update public.organizations
  set whatsapp_e164 = null,
      whatsapp_connected_at = null,
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
revoke all on function public.disconnect_org_whatsapp(uuid) from public, anon;
grant execute on function public.connect_org_whatsapp(uuid, text) to authenticated;
grant execute on function public.disconnect_org_whatsapp(uuid) to authenticated;
