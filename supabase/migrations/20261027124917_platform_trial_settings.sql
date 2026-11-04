-- Editable commercial trial length, backed by actual onboarding trigger.
alter table public.platform_settings
 add column if not exists trial_days integer not null default 7
 check(trial_days between 1 and 60);

create or replace function private.platform_admin_save_trial_days(p_days integer)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 if p_days is null or p_days not between 1 and 60 then
  raise exception 'INVALID_TRIAL_LENGTH' using errcode='22023';end if;
 insert into public.platform_settings(id,trial_days,updated_by,updated_at)
 values(1,p_days,auth.uid(),now())
 on conflict(id) do update set trial_days=excluded.trial_days,updated_by=auth.uid(),updated_at=now();
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'platform.trial_settings',jsonb_build_object('trial_days',p_days));
end $$;
revoke all on function private.platform_admin_save_trial_days(integer) from public,anon,authenticated;
grant execute on function private.platform_admin_save_trial_days(integer) to authenticated;
create or replace function public.platform_admin_save_trial_days(p_days integer)
returns void language sql security invoker set search_path='' as $$
 select private.platform_admin_save_trial_days(p_days)
$$;
revoke all on function public.platform_admin_save_trial_days(integer) from public,anon;
grant execute on function public.platform_admin_save_trial_days(integer) to authenticated;

create or replace function private.initialize_business_trial()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_days integer;
begin
 select coalesce((select trial_days from public.platform_settings where id=1),7) into v_days;
 insert into public.organization_trials(org_id,trial_started_at,trial_ends_at)
 values(new.id,new.created_at,new.created_at+make_interval(days=>v_days))
 on conflict do nothing;
 return new;
end $$;

create or replace function private.claim_platform_provisioning()
returns integer language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid();v_email text;v_row record;v_org uuid;v_count integer:=0;v_days integer;
begin
 if v_user is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
 select lower(u.email) into v_email from auth.users u
 where u.id=v_user and u.email_confirmed_at is not null;
 if v_email is null then return 0;end if;
 select coalesce((select trial_days from public.platform_settings where id=1),7) into v_days;
 for v_row in select * from public.platform_org_provisioning
 where owner_email=v_email and status='pending' order by created_at asc limit 10 for update skip locked
 loop
  v_org:=v_row.claimed_org_id;
  if v_org is null then
   v_org:=gen_random_uuid();
   insert into public.organizations(id,name,slug,kind,created_by,avatar_url,is_discoverable)
   values(v_org,v_row.business_name,'admin-'||replace(v_org::text,'-',''),v_row.kind,v_user,v_row.avatar_url,false);
   update public.platform_org_provisioning set claimed_org_id=v_org where id=v_row.id;
  end if;
  insert into public.organization_memberships(organization_id,user_id,role,status)
  values(v_org,v_user,'owner','active')
  on conflict(organization_id,user_id) do update set role='owner',status='active';
  update public.organizations set is_discoverable=true where id=v_org;
  update public.organization_trials set trial_started_at=now(),
   trial_ends_at=now()+make_interval(days=>v_days) where org_id=v_org and paid_plan is null;
  update public.platform_org_provisioning set status='claimed',claimed_at=now() where id=v_row.id;
  insert into public.platform_admin_events(actor_id,org_id,action,details)
  values(v_user,v_org,'business.claim',jsonb_build_object('provisioning_id',v_row.id));
  v_count:=v_count+1;
 end loop;
 return v_count;
end $$;
notify pgrst,'reload schema';
