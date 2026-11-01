-- Avatar de gimnasio/entrenador no se guardaba:
-- 1) accept enrollment / link atleta hacía ON CONFLICT … role='athlete' y
--    degradaba al created_by (owner) → athlete.
-- 2) Políticas de storage.business-branding solo miraban memberships owner/admin
--    (ignoraban delegación platform_admin vía private.has_org_role).

-- Impide degradar staff a athlete (cualquier ruta futura).
create or replace function private.protect_staff_org_membership()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
     and old.role in ('owner','admin','coach','reception')
     and new.role = 'athlete' then
    new.role := old.role;
  end if;
  return new;
end $$;

drop trigger if exists protect_staff_org_membership on public.organization_memberships;
create trigger protect_staff_org_membership
  before update of role on public.organization_memberships
  for each row execute function private.protect_staff_org_membership();

-- Restaurar propietario: created_by debe ser owner activo.
insert into public.organization_memberships(organization_id, user_id, role, status)
select o.id, o.created_by, 'owner'::public.organization_role, 'active'::public.organization_membership_status
from public.organizations o
where o.created_by is not null
on conflict (organization_id, user_id) do update
set
  role = case
    when public.organization_memberships.role in ('owner','admin')
      then public.organization_memberships.role
    else 'owner'::public.organization_role
  end,
  status = 'active'::public.organization_membership_status;

-- Storage: usar has_org_role (membership real O delegación admin de plataforma).
drop policy if exists business_branding_insert on storage.objects;
drop policy if exists business_branding_update on storage.objects;

create policy business_branding_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'business-branding'
  and storage.filename(name) in ('logo.jpg', 'trainer.jpg')
  and (storage.foldername(name))[1] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and private.has_org_role(
    ((storage.foldername(name))[1])::uuid,
    array['owner','admin']::public.organization_role[]
  )
);

create policy business_branding_update on storage.objects
for update to authenticated
using (
  bucket_id = 'business-branding'
  and (storage.foldername(name))[1] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and private.has_org_role(
    ((storage.foldername(name))[1])::uuid,
    array['owner','admin']::public.organization_role[]
  )
)
with check (
  bucket_id = 'business-branding'
  and storage.filename(name) in ('logo.jpg', 'trainer.jpg')
  and (storage.foldername(name))[1] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and private.has_org_role(
    ((storage.foldername(name))[1])::uuid,
    array['owner','admin']::public.organization_role[]
  )
);

-- RPC segura para fijar avatar_url (evita PATCH silencioso vacío).
create or replace function public.update_organization_avatar(
  p_org uuid,
  p_avatar_url text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text := nullif(btrim(coalesce(p_avatar_url, '')), '');
  v_row jsonb;
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_url is not null then
    if v_url !~ '^https://' or length(v_url) < 8 or length(v_url) > 2000 then
      raise exception 'INVALID_AVATAR_URL' using errcode = '22023';
    end if;
  end if;

  update public.organizations
  set avatar_url = v_url, updated_at = now()
  where id = p_org
  returning to_jsonb(organizations.*) into v_row;

  if v_row is null then
    raise exception 'ORG_NOT_FOUND' using errcode = 'P0002';
  end if;
  return jsonb_build_object(
    'id', v_row->>'id',
    'avatar_url', v_row->>'avatar_url'
  );
end $$;

alter function public.update_organization_avatar(uuid, text) owner to postgres;
revoke all on function public.update_organization_avatar(uuid, text) from public, anon;
grant execute on function public.update_organization_avatar(uuid, text) to authenticated, service_role;

notify pgrst, 'reload schema';
