-- Platform-wide account directory including users without memberships.
create or replace function private.platform_admin_athletes()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then
   raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';
 end if;
 return coalesce((
  select jsonb_agg(jsonb_build_object(
   'id',u.id,
   'name',coalesce(nullif(btrim(p.display_name),''),
      nullif(btrim(u.raw_user_meta_data->>'name'),''),split_part(u.email,'@',1)),
   'email',u.email,
   'avatar_url',case
      when coalesce(nullif(p.avatar_url,''),u.raw_user_meta_data->>'avatar_url','') like 'https://%'
      then coalesce(nullif(p.avatar_url,''),u.raw_user_meta_data->>'avatar_url')
      else null end,
   'created_at',u.created_at,
   'confirmed',u.email_confirmed_at is not null,
   'platform_role',coalesce(p.role::text,'user'),
   'center_count',(select count(distinct m.organization_id)
     from public.organization_memberships m where m.user_id=u.id
       and m.status='active' and m.role='athlete'),
   'client_links',(select count(*) from public.clients c where c.user_id=u.id)
   ) order by u.created_at desc)
   from auth.users u left join public.profiles p on p.id=u.id
 ),'[]'::jsonb);
end $$;
revoke all on function private.platform_admin_athletes() from public,anon,authenticated;
grant execute on function private.platform_admin_athletes() to authenticated;
create or replace function public.platform_admin_athletes()
 returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_athletes()
$$;
revoke all on function public.platform_admin_athletes() from public,anon;
grant execute on function public.platform_admin_athletes() to authenticated;
