-- Re-send registration instructions without forging the intended owner's acceptance.
create table if not exists public.platform_owner_email_attempts(
 id uuid primary key default gen_random_uuid(),
 provisioning_id uuid not null references public.platform_org_provisioning(id) on delete cascade,
 actor_id uuid not null references auth.users(id),
 attempted_at timestamptz not null default now()
);
create index if not exists platform_owner_email_attempts_window
 on public.platform_owner_email_attempts(provisioning_id,attempted_at desc);
alter table public.platform_owner_email_attempts enable row level security;
revoke all on public.platform_owner_email_attempts from public,anon,authenticated;

create or replace function private.platform_admin_owner_email_payload(p_provision uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v public.platform_org_provisioning%rowtype;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 select * into v from public.platform_org_provisioning where id=p_provision and status='pending' for update;
 if not found then raise exception 'PENDING_OWNER_NOT_FOUND' using errcode='22023';end if;
 if (select count(*) from public.platform_owner_email_attempts where provisioning_id=v.id
 and attempted_at>now()-interval '1 hour')>=3
 then raise exception 'EMAIL_RATE_LIMITED' using errcode='42900';end if;
 insert into public.platform_owner_email_attempts(provisioning_id,actor_id) values(v.id,auth.uid());
 return jsonb_build_object('recipient',v.owner_email,'org_name',v.business_name,
  'org_type',v.kind,'provisioning_id',v.id,'mode','owner');
end $$;
revoke all on function private.platform_admin_owner_email_payload(uuid) from public,anon,authenticated;
grant execute on function private.platform_admin_owner_email_payload(uuid) to authenticated;
create or replace function public.platform_admin_owner_email_payload(p_provision uuid)
returns jsonb language sql security invoker set search_path='' as $$
 select private.platform_admin_owner_email_payload(p_provision)
$$;
revoke all on function public.platform_admin_owner_email_payload(uuid) from public,anon;
grant execute on function public.platform_admin_owner_email_payload(uuid) to authenticated;
notify pgrst,'reload schema';
