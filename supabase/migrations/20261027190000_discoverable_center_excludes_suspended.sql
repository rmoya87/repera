-- Keep public mobile search consistent with operational suspension and
-- keep the privileged query in an unexposed schema.
create or replace function private.search_discoverable_organizations(p_query text)
returns table(id uuid,name text,kind text,slug text,avatar_url text,tagline text)
language sql stable security definer set search_path='' as $$
 select o.id,o.name,o.kind::text,o.slug,o.avatar_url,o.tagline
 from public.organizations o
 where auth.uid() is not null
 and o.is_discoverable is true
 and not exists (
   select 1 from public.platform_org_controls controls
   where controls.org_id=o.id and controls.status='suspended'
 )
 and (
   coalesce(btrim(p_query),'')=''
   or o.name ilike '%'||btrim(p_query)||'%'
   or o.slug ilike '%'||btrim(p_query)||'%'
 )
 order by o.name limit 50;
$$;
revoke all on function private.search_discoverable_organizations(text) from public,anon,authenticated;
grant execute on function private.search_discoverable_organizations(text) to authenticated;

create or replace function public.search_discoverable_organizations(p_query text default '')
returns table(id uuid,name text,kind text,slug text,avatar_url text,tagline text)
language sql stable security invoker set search_path='' as $$
 select * from private.search_discoverable_organizations(p_query);
$$;
revoke all on function public.search_discoverable_organizations(text) from public,anon;
grant execute on function public.search_discoverable_organizations(text) to authenticated;
notify pgrst,'reload schema';
