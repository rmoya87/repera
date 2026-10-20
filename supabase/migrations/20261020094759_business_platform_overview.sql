
-- Read-only platform oversight, no private athlete data or impersonation.
create function private.platform_business_overview()
 returns table(id uuid,name text,kind text,created_at timestamptz,trial_ends_at timestamptz,client_count bigint)
 language plpgsql stable security definer set search_path=''
as $$
begin
 if auth.uid() is null or not exists (
  select 1 from public.profiles p join auth.users u on u.id=p.id
  where p.id=auth.uid() and p.role='platform_admin' and
    lower(u.email)='rmoya87@gmail.com' and u.email_confirmed_at is not null
 ) then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 return query
 select o.id,o.name,o.kind::text,o.created_at,t.trial_ends_at,
  (select count(*) from public.clients c where c.org_id=o.id)
 from public.organizations o
 left join public.organization_trials t on t.org_id=o.id
 order by o.created_at desc limit 500;
end; $$;
revoke all on function private.platform_business_overview() from public,anon,authenticated;
grant execute on function private.platform_business_overview() to authenticated;
create function public.platform_business_overview()
 returns table(id uuid,name text,kind text,created_at timestamptz,trial_ends_at timestamptz,client_count bigint)
 language sql security invoker set search_path=''
 as $$select * from private.platform_business_overview()$$;
revoke all on function public.platform_business_overview() from public,anon;
grant execute on function public.platform_business_overview() to authenticated;
