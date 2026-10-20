-- Discoverable centers/trainers, org avatars, athlete self-link / leave, athlete→org messages.

alter table public.organizations
  add column if not exists avatar_url text
    check (avatar_url is null or length(avatar_url) between 8 and 2000),
  add column if not exists is_discoverable boolean not null default true,
  add column if not exists tagline text
    check (tagline is null or length(btrim(tagline)) between 2 and 160);

grant update(name, avatar_url, is_discoverable, tagline) on public.organizations to authenticated;

-- Public directory for signed-in athletes (no membership required).
create or replace function public.search_discoverable_organizations(p_query text default '')
returns table (
  id uuid,
  name text,
  kind text,
  slug text,
  avatar_url text,
  tagline text
)
language sql
security definer
set search_path = ''
stable
as $$
  select o.id,
         o.name,
         o.kind::text,
         o.slug,
         o.avatar_url,
         o.tagline
  from public.organizations o
  where o.is_discoverable is true
    and (
      coalesce(btrim(p_query), '') = ''
      or o.name ilike '%' || btrim(p_query) || '%'
      or o.slug ilike '%' || btrim(p_query) || '%'
    )
  order by o.name
  limit 50;
$$;

revoke all on function public.search_discoverable_organizations(text) from public, anon;
grant execute on function public.search_discoverable_organizations(text) to authenticated;

-- Athlete requests link + preferred pass kind (class | appointment | unlimited).
create or replace function public.request_org_athlete_link(
  p_org uuid,
  p_pass_kind text default 'class',
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_email text;
  v_name text;
  v_client uuid;
  v_kind text := lower(btrim(coalesce(p_pass_kind, 'class')));
  v_note text := left(btrim(coalesce(p_note, '')), 500);
begin
  if v_actor is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.organizations o
    where o.id = p_org and o.is_discoverable is true
  ) then
    raise exception 'ORG_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_kind not in ('class', 'appointment', 'unlimited') then
    raise exception 'INVALID_PASS_KIND' using errcode = '22023';
  end if;

  select lower(btrim(email)) into v_email
  from auth.users
  where id = v_actor and email_confirmed_at is not null;
  if v_email is null then
    raise exception 'VERIFIED_EMAIL_REQUIRED' using errcode = '42501';
  end if;

  select coalesce(nullif(btrim(p.display_name), ''), split_part(v_email, '@', 1), 'Deportista')
    into v_name
  from public.profiles p
  where p.id = v_actor;
  v_name := left(coalesce(v_name, 'Deportista'), 120);
  if length(v_name) < 2 then v_name := 'Deportista'; end if;

  insert into public.organization_memberships(organization_id, user_id, role, status)
  values (p_org, v_actor, 'athlete', 'active')
  on conflict (organization_id, user_id) do update
    set role = 'athlete', status = 'active';

  select id into v_client
  from public.clients
  where org_id = p_org and (user_id = v_actor or lower(email) = v_email)
  for update;

  if v_client is not null then
    update public.clients
    set user_id = v_actor,
        status = 'active',
        notes = left(
          coalesce(nullif(btrim(notes), '') || E'\n', '')
            || 'Solicitud app: bono ' || v_kind
            || case when length(v_note) > 0 then ' · ' || v_note else '' end,
          2000
        ),
        updated_at = now()
    where id = v_client;
  else
    insert into public.clients(org_id, created_by, user_id, name, email, status, notes)
    values (
      p_org,
      v_actor,
      v_actor,
      v_name,
      v_email,
      'active',
      left('Solicitud app: bono ' || v_kind
        || case when length(v_note) > 0 then ' · ' || v_note else '' end, 2000)
    )
    returning id into v_client;
  end if;

  return v_client;
end;
$$;

revoke all on function public.request_org_athlete_link(uuid, text, text) from public, anon;
grant execute on function public.request_org_athlete_link(uuid, text, text) to authenticated;

-- Athlete unlinks from a center/trainer (keeps client row for the business history).
create or replace function public.leave_org_as_athlete(p_org uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  update public.organization_memberships
  set status = 'revoked'
  where organization_id = p_org
    and user_id = v_actor
    and role = 'athlete'
    and status = 'active';

  update public.clients
  set user_id = null,
      status = 'cancelled',
      updated_at = now()
  where org_id = p_org
    and user_id = v_actor;

  return true;
end;
$$;

revoke all on function public.leave_org_as_athlete(uuid) from public, anon;
grant execute on function public.leave_org_as_athlete(uuid) to authenticated;

-- Athlete → center/trainer message (same inbox coaches already read).
create or replace function public.athlete_send_org_message(
  p_org uuid,
  p_title text,
  p_body text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_client uuid;
  v_id uuid;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if not private.has_org_role(p_org, array['athlete']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select id into v_client
  from public.clients
  where org_id = p_org and user_id = v_actor and status = 'active'
  limit 1;
  if v_client is null
     or length(btrim(coalesce(p_title, ''))) not between 2 and 120
     or length(btrim(coalesce(p_body, ''))) not between 2 and 1000 then
    raise exception 'INVALID_MESSAGE' using errcode = '22023';
  end if;

  insert into public.business_client_notifications(org_id, client_id, sender_user_id, title, body)
  values (p_org, v_client, v_actor, btrim(p_title), btrim(p_body))
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.athlete_send_org_message(uuid, text, text) from public, anon;
grant execute on function public.athlete_send_org_message(uuid, text, text) to authenticated;

-- Managers can update branding (avatar / discoverability / tagline).
create or replace function public.update_organization_branding(
  p_org uuid,
  p_avatar_url text default null,
  p_tagline text default null,
  p_is_discoverable boolean default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner', 'admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  update public.organizations
  set avatar_url = case
        when p_avatar_url is null then avatar_url
        when btrim(p_avatar_url) = '' then null
        else left(btrim(p_avatar_url), 2000)
      end,
      tagline = case
        when p_tagline is null then tagline
        when btrim(p_tagline) = '' then null
        else left(btrim(p_tagline), 160)
      end,
      is_discoverable = coalesce(p_is_discoverable, is_discoverable),
      updated_at = now()
  where id = p_org;
  return found;
end;
$$;

revoke all on function public.update_organization_branding(uuid, text, text, boolean) from public, anon;
grant execute on function public.update_organization_branding(uuid, text, text, boolean) to authenticated;
