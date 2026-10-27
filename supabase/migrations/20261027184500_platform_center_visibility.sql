-- Admin decides operational visibility without forging pending owner's consent.
create or replace function private.platform_admin_set_visibility(p_org uuid,p_visible boolean)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 if not exists(select 1 from public.organizations where id=p_org) then raise exception 'CENTER_NOT_FOUND' using errcode='22023';end if;
 if p_visible is null then raise exception 'INVALID_VISIBILITY' using errcode='22023';end if;
 if p_visible and exists(select 1 from public.platform_org_controls c where c.org_id=p_org and c.status='suspended')
 then raise exception 'SUSPENDED_CENTER_NOT_DISCOVERABLE' using errcode='22023';end if;
 update public.organizations set is_discoverable=p_visible,updated_at=now() where id=p_org;
 insert into public.platform_admin_events(actor_id,org_id,action,details)
 values(auth.uid(),p_org,'business.visibility',jsonb_build_object('visible',p_visible));
end $$;
revoke all on function private.platform_admin_set_visibility(uuid,boolean) from public,anon,authenticated;
grant execute on function private.platform_admin_set_visibility(uuid,boolean) to authenticated;
create or replace function public.platform_admin_set_visibility(p_org uuid,p_visible boolean)
returns void language sql security invoker set search_path='' as $$
 select private.platform_admin_set_visibility(p_org,p_visible)
$$;
revoke all on function public.platform_admin_set_visibility(uuid,boolean) from public,anon;
grant execute on function public.platform_admin_set_visibility(uuid,boolean) to authenticated;
notify pgrst,'reload schema';
