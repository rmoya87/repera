-- Invitar socio/cliente: reutilizar ficha lead del mismo centro, permitir el mismo
-- email en otro gimnasio, y avisar si ya está vinculado a una cuenta aquí.
create or replace function public.invite_athlete_client(
  p_org uuid,
  p_name text,
  p_email text,
  p_phone text default null
)
returns jsonb
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

  -- Ya es miembro activo de ESTE centro (con su cuenta).
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
    -- Ficha ya vinculada a una cuenta Repera en este centro.
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
    -- Mismo email en otro gimnasio: permitido (índice único es por org_id + email).
    insert into public.clients(org_id, created_by, name, email, status, phone)
    values (
      p_org,
      v_actor,
      v_name,
      v_email,
      'lead',
      nullif(v_phone, '')
    )
    returning * into v_client;
  end if;

  v_invitation_id := private.issue_org_invitation(p_org, v_email, 'athlete'::public.organization_role);

  return jsonb_build_object(
    'client_id', v_client.id,
    'invitation_id', v_invitation_id,
    'reused', v_reused,
    'email', v_email,
    'name', v_client.name,
    'phone', coalesce(v_client.phone, '')
  );
end;
$$;

revoke all on function public.invite_athlete_client(uuid, text, text, text) from public, anon;
grant execute on function public.invite_athlete_client(uuid, text, text, text) to authenticated;

comment on function public.invite_athlete_client(uuid, text, text, text) is
  'Crea o reutiliza ficha lead e invita como athlete. No bloquea si el email existe en otro centro; CLIENT_ALREADY_LINKED / ALREADY_A_MEMBER si ya está en este.';
