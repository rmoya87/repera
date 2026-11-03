-- Allow managers to finish a pass without renewing (cancel remaining credits / validity).
create or replace function public.finalize_service_pass(p_pass uuid)
returns public.service_passes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_pass public.service_passes%rowtype;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  select * into v_pass
  from public.service_passes
  where id = p_pass
  for update;

  if not found then
    raise exception 'PASS_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not private.has_org_role(
    v_pass.org_id,
    array['owner','admin','reception']::public.organization_role[]
  ) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  if v_pass.status is distinct from 'active' then
    return v_pass;
  end if;

  update public.service_passes
  set
    status = 'cancelled',
    remaining_credits = 0,
    valid_until = least(coalesce(valid_until, now()), now())
  where id = v_pass.id
  returning * into v_pass;

  return v_pass;
end;
$$;

revoke all on function public.finalize_service_pass(uuid) from public, anon;
grant execute on function public.finalize_service_pass(uuid) to authenticated;

comment on function public.finalize_service_pass(uuid) is
  'Cancels an active service pass so it is not renewed; managers only.';
