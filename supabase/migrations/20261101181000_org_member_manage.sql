-- Owner/admin can change staff role or revoke membership (not themselves / not sole owner).
create or replace function public.manage_org_member(
  p_org uuid,
  p_user uuid,
  p_action text,
  p_role public.organization_role default null
)
returns public.organization_memberships
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.organization_memberships%rowtype;
  v_owners int;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if p_user is null or p_user = v_actor then
    raise exception 'CANNOT_MANAGE_SELF' using errcode = 'P0001';
  end if;
  if p_action not in ('set_role','revoke') then
    raise exception 'INVALID_ACTION' using errcode = '22023';
  end if;

  select * into v_row
  from public.organization_memberships
  where organization_id = p_org and user_id = p_user
  for update;

  if not found then
    raise exception 'MEMBER_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_row.role = 'owner' then
    select count(*) into v_owners
    from public.organization_memberships
    where organization_id = p_org and role = 'owner' and status = 'active';
    if v_owners <= 1 and (p_action = 'revoke' or (p_action = 'set_role' and p_role is distinct from 'owner')) then
      raise exception 'LAST_OWNER' using errcode = 'P0001';
    end if;
  end if;

  -- Admins cannot escalate to owner or touch owners.
  if not private.has_org_role(p_org, array['owner']::public.organization_role[]) then
    if v_row.role = 'owner' or p_role = 'owner' then
      raise exception 'NOT_AUTHORIZED' using errcode = '42501';
    end if;
  end if;

  if p_action = 'revoke' then
    update public.organization_memberships
    set status = 'revoked'
    where organization_id = p_org and user_id = p_user
    returning * into v_row;
    return v_row;
  end if;

  if p_role is null or p_role not in ('admin','coach','reception') then
    raise exception 'INVALID_ROLE' using errcode = '22023';
  end if;

  update public.organization_memberships
  set role = p_role, status = 'active'
  where organization_id = p_org and user_id = p_user
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.manage_org_member(uuid, uuid, text, public.organization_role) from public, anon;
grant execute on function public.manage_org_member(uuid, uuid, text, public.organization_role) to authenticated;

create or replace function public.delete_business_group(p_group uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  select org_id into v_org from public.business_training_groups where id = p_group;
  if v_org is null then
    raise exception 'GROUP_NOT_FOUND' using errcode = 'P0002';
  end if;
  if not private.has_org_role(v_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  delete from public.business_training_group_members where group_id = p_group;
  delete from public.business_training_groups where id = p_group;
end;
$$;

revoke all on function public.delete_business_group(uuid) from public, anon;
grant execute on function public.delete_business_group(uuid) to authenticated;
