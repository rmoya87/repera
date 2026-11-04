-- Pending centers get a real tenant immediately, without a member or owner session.
-- Platform admins use short-lived, audited delegation; pending owner account is never impersonated.
create or replace function private.platform_admin_materialize_pending(p_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v public.platform_org_provisioning%rowtype; v_org uuid;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 select * into v from public.platform_org_provisioning where id=p_id for update;
 if not found or v.status<>'pending' then raise exception 'PENDING_CENTER_NOT_FOUND' using errcode='22023'; end if;
 if v.claimed_org_id is not null then return v.claimed_org_id; end if;
 v_org:=gen_random_uuid();
 insert into public.organizations(id,name,slug,kind,created_by,avatar_url,is_discoverable,public_email)
 values(v_org,v.business_name,'admin-'||replace(v_org::text,'-',''),v.kind,v.created_by,v.avatar_url,false,v.owner_email);
 -- The existing bootstrap trigger creates a membership for created_by.
 -- Remove it atomically: the platform administrator must not become tenant owner.
 delete from public.organization_memberships where organization_id=v_org and user_id=v.created_by;
 update public.platform_org_provisioning set claimed_org_id=v_org where id=p_id;
 insert into public.platform_admin_events(actor_id,org_id,action,details)
 values(auth.uid(),v_org,'business.workspace_ready',jsonb_build_object('provisioning_id',p_id));
 return v_org;
end $$;
revoke all on function private.platform_admin_materialize_pending(uuid) from public,anon,authenticated;
grant execute on function private.platform_admin_materialize_pending(uuid) to authenticated;

create or replace function private.platform_admin_provision(p_name text,p_kind text,p_email text,p_plan text default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;v_email text:=lower(btrim(p_email));
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 if length(btrim(p_name)) not between 2 and 120 or p_kind not in ('gym','personal_trainer')
 or length(v_email)>180 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'
 then raise exception 'INVALID_BUSINESS' using errcode='22023'; end if;
 if p_plan is not null and not exists(select 1 from public.business_plans b
   where b.plan_key=p_plan and b.audience=p_kind and b.is_active)
 then raise exception 'INVALID_PLAN' using errcode='22023'; end if;
 if exists(select 1 from public.platform_org_provisioning x
   where x.owner_email=v_email and x.status='pending' and lower(x.business_name)=lower(btrim(p_name)))
 then raise exception 'DUPLICATE_PENDING_BUSINESS' using errcode='23505'; end if;
 insert into public.platform_org_provisioning(owner_email,business_name,kind,plan_key,created_by)
 values(v_email,btrim(p_name),p_kind::public.organization_kind,p_plan,auth.uid())
 returning id into v_id;
 perform private.platform_admin_materialize_pending(v_id);
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'business.provision',jsonb_build_object('provisioning_id',v_id,'kind',p_kind));
 return v_id;
end $$;
-- Existing wrapper and grants retain their signatures.

-- Backfill all real pending records from the previous workflow, with no fake athletes/users.
do $backfill$
declare v record;v_org uuid;
begin
 for v in select * from public.platform_org_provisioning
   where status='pending' and claimed_org_id is null for update
 loop
  v_org:=gen_random_uuid();
  insert into public.organizations(id,name,slug,kind,created_by,avatar_url,is_discoverable,public_email)
  values(v_org,v.business_name,'admin-'||replace(v_org::text,'-',''),v.kind,v.created_by,v.avatar_url,false,v.owner_email);
  delete from public.organization_memberships where organization_id=v_org and user_id=v.created_by;
  update public.platform_org_provisioning set claimed_org_id=v_org where id=v.id;
  insert into public.platform_admin_events(actor_id,org_id,action,details)
  values(v.created_by,v_org,'business.workspace_ready',jsonb_build_object('provisioning_id',v.id,'backfilled',true));
 end loop;
end $backfill$;

-- A verified intended owner claims the existing workspace, with its existing data,
-- rather than causing a second organization to be created.
create or replace function private.claim_platform_provisioning()
returns integer language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid();v_email text;v_row record;v_org uuid;v_count integer:=0;
begin
 if v_user is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select lower(u.email) into v_email from auth.users u
 where u.id=v_user and u.email_confirmed_at is not null;
 if v_email is null then return 0; end if;
 for v_row in select * from public.platform_org_provisioning
 where owner_email=v_email and status='pending' order by created_at asc limit 10 for update skip locked
 loop
  v_org:=v_row.claimed_org_id;
  if v_org is null then
   -- Compatibility with historic pending records not backfilled yet.
   v_org:=gen_random_uuid();
   insert into public.organizations(id,name,slug,kind,created_by,avatar_url,is_discoverable)
   values(v_org,v_row.business_name,'admin-'||replace(v_org::text,'-',''),v_row.kind,v_user,v_row.avatar_url,false);
   update public.platform_org_provisioning set claimed_org_id=v_org where id=v_row.id;
  end if;
  insert into public.organization_memberships(organization_id,user_id,role,status)
   values(v_org,v_user,'owner','active')
   on conflict(organization_id,user_id) do update set role='owner',status='active';
  update public.organizations set is_discoverable=true where id=v_org;
  update public.organization_trials set trial_started_at=now(),trial_ends_at=now()+interval '7 days'
   where org_id=v_org and paid_plan is null;
  update public.platform_org_provisioning set status='claimed',claimed_at=now() where id=v_row.id;
  insert into public.platform_admin_events(actor_id,org_id,action,details)
  values(v_user,v_org,'business.claim',jsonb_build_object('provisioning_id',v_row.id));
  v_count:=v_count+1;
 end loop;
 return v_count;
end $$;

-- Directory reports operational status separately from owner's onboarding status.
create or replace function private.platform_admin_directory()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 return coalesce((
  select jsonb_agg(jsonb_build_object(
   'id',o.id,'name',o.name,'kind',o.kind::text,'slug',o.slug,'created_at',o.created_at,
   'email',o.public_email,'phone',o.phone,'website',o.website,'address',o.address,
   'description',o.description,'timezone',o.timezone,'avatar_url',coalesce(o.avatar_url,p.avatar_url),
   'client_count',(select count(*) from public.clients c where c.org_id=o.id),
   'active_clients',(select count(*) from public.clients c where c.org_id=o.id and c.status='active'),
   'member_count',(select count(*) from public.organization_memberships m where m.organization_id=o.id and m.status='active'),
   'sessions',(select count(*) from public.service_occurrences s where s.org_id=o.id),
   'trial_ends_at',t.trial_ends_at,'paid_plan',t.paid_plan,'paid_until',t.paid_until,
   'registration_status',coalesce(p.status,'claimed'),
   'owner_email',p.owner_email,'provisioning_id',p.id,
   'status',case when st.status='suspended' then 'suspended'
      when p.status='pending' then 'pending' else 'active' end,
   'status_reason',coalesce(st.reason,''),
   'last_activity',(select max(x.booked_at) from public.service_bookings x where x.org_id=o.id)
  ) order by o.created_at desc)
  from public.organizations o
  left join public.organization_trials t on t.org_id=o.id
  left join public.platform_org_controls st on st.org_id=o.id
  left join lateral(select pr.id,pr.status,pr.owner_email,pr.avatar_url
    from public.platform_org_provisioning pr where pr.claimed_org_id=o.id
    order by pr.created_at desc limit 1) p on true
 ),'[]'::jsonb);
end $$;

-- A logo uploaded during pre-registration is reflected on the materialized tenant.
create or replace function private.platform_admin_attach_branding(p_provision uuid,p_avatar_url text)
returns void language plpgsql security definer set search_path='' as $$
declare v_expected text;v_kind public.organization_kind;v_org uuid;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 select kind,claimed_org_id into v_kind,v_org from public.platform_org_provisioning
 where id=p_provision and status='pending' and created_by=auth.uid() for update;
 if v_kind is null then raise exception 'PENDING_BUSINESS_NOT_FOUND' using errcode='22023';end if;
 v_expected:='https://uvzgujlrqohreoucirms.supabase.co/storage/v1/object/public/business-branding/pending/'
  ||p_provision::text||'/'||(case when v_kind='personal_trainer' then 'trainer.jpg' else 'logo.jpg' end);
 if p_avatar_url is distinct from v_expected then raise exception 'INVALID_IMAGE_URL' using errcode='22023';end if;
 if not exists(select 1 from storage.objects where bucket_id='business-branding'
 and name='pending/'||p_provision::text||'/'||(case when v_kind='personal_trainer' then 'trainer.jpg' else 'logo.jpg' end))
 then raise exception 'IMAGE_NOT_UPLOADED' using errcode='22023';end if;
 update public.platform_org_provisioning set avatar_url=v_expected where id=p_provision;
 if v_org is not null then update public.organizations set avatar_url=v_expected where id=v_org;end if;
 insert into public.platform_admin_events(actor_id,org_id,action,details)
 values(auth.uid(),v_org,'business.branding',jsonb_build_object('provisioning_id',p_provision));
end $$;

notify pgrst, 'reload schema';
