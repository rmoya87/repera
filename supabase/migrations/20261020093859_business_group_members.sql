
-- Cambios atómicos del grupo y sus miembros, con aislamiento por organización.
create function private.manage_business_group(
 p_group uuid,p_name text,p_description text,p_clients uuid[]
) returns boolean language plpgsql security definer set search_path=''
as $$
declare g public.business_training_groups%rowtype;
begin
 select * into g from public.business_training_groups where id=p_group for update;
 if not found then raise exception 'GROUP_NOT_FOUND' using errcode='22023';end if;
 if not private.has_org_role(g.org_id,array['owner','admin']::public.organization_role[]) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 if length(btrim(coalesce(p_name,''))) not between 2 and 100 or length(coalesce(p_description,''))>500
  or cardinality(coalesce(p_clients,'{}'::uuid[]))>500 then
  raise exception 'INVALID_GROUP' using errcode='22023';end if;
 if exists(
  select 1 from unnest(coalesce(p_clients,'{}'::uuid[])) id
  where not exists(select 1 from public.clients c where c.org_id=g.org_id and c.id=id)
 ) then raise exception 'CLIENT_NOT_IN_ORG' using errcode='42501';end if;
 update public.business_training_groups set name=btrim(p_name),description=coalesce(p_description,'') where id=g.id;
 delete from public.business_training_group_members where group_id=g.id;
 insert into public.business_training_group_members(org_id,group_id,client_id)
 select g.org_id,g.id,id from unnest(coalesce(p_clients,'{}'::uuid[])) id group by id;
 return true;
end; $$;
revoke all on function private.manage_business_group(uuid,text,text,uuid[]) from public,anon,authenticated;
grant execute on function private.manage_business_group(uuid,text,text,uuid[]) to authenticated;
create function public.manage_business_group(p_group uuid,p_name text,p_description text,p_clients uuid[])
 returns boolean language sql security invoker set search_path=''
 as $$select private.manage_business_group(p_group,p_name,p_description,p_clients)$$;
revoke all on function public.manage_business_group(uuid,text,text,uuid[]) from public,anon;
grant execute on function public.manage_business_group(uuid,text,text,uuid[]) to authenticated;
