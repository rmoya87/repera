-- Ensure discoverable org directory RPC exists (fixes mobile «could not find the function»).

alter table public.organizations
  add column if not exists avatar_url text
    check (avatar_url is null or length(avatar_url) between 8 and 2000),
  add column if not exists is_discoverable boolean not null default true,
  add column if not exists tagline text
    check (tagline is null or length(btrim(tagline)) between 2 and 160);

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

-- Notify PostgREST to reload schema cache after creating the RPC.
notify pgrst, 'reload schema';
