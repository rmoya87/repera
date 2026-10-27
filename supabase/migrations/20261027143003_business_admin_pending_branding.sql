-- Center brand photo prior to ownership claim; no unrestricted storage writes.
create or replace function private.can_upload_pending_business_brand(p_id text)
returns boolean language sql stable security definer set search_path='' as $$
 select private.is_repera_platform_admin()
 and p_id ~ '^[0-9a-f-]{36}$'
 and exists(select 1 from public.platform_org_provisioning p
  where p.id::text=p_id and p.created_by=auth.uid() and p.status='pending')
$$;
revoke all on function private.can_upload_pending_business_brand(text) from public,anon;
grant execute on function private.can_upload_pending_business_brand(text) to authenticated;
create policy platform_pending_branding_insert on storage.objects
 for insert to authenticated with check(
 bucket_id='business-branding'
 and (storage.foldername(name))[1]='pending'
 and (storage.foldername(name))[2] is not null
 and storage.filename(name) in ('logo.jpg','trainer.jpg')
 and private.can_upload_pending_business_brand((storage.foldername(name))[2])
);

create or replace function private.platform_admin_attach_branding(p_provision uuid,p_avatar_url text)
returns void language plpgsql security definer set search_path='' as $$
declare v_expected text;v_kind public.organization_kind;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 select kind into v_kind from public.platform_org_provisioning
  where id=p_provision and status='pending' and created_by=auth.uid() for update;
 if v_kind is null then raise exception 'PENDING_BUSINESS_NOT_FOUND' using errcode='22023';end if;
 v_expected:='https://uvzgujlrqohreoucirms.supabase.co/storage/v1/object/public/business-branding/pending/'
  ||p_provision::text||'/'||(case when v_kind='personal_trainer' then 'trainer.jpg' else 'logo.jpg' end);
 if p_avatar_url is distinct from v_expected then raise exception 'INVALID_IMAGE_URL' using errcode='22023';end if;
 if not exists(select 1 from storage.objects where bucket_id='business-branding'
 and name='pending/'||p_provision::text||'/'||(case when v_kind='personal_trainer' then 'trainer.jpg' else 'logo.jpg' end))
 then raise exception 'IMAGE_NOT_UPLOADED' using errcode='22023';end if;
 update public.platform_org_provisioning set avatar_url=v_expected where id=p_provision;
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'business.branding',jsonb_build_object('provisioning_id',p_provision));
end $$;
revoke all on function private.platform_admin_attach_branding(uuid,text) from public,anon,authenticated;
grant execute on function private.platform_admin_attach_branding(uuid,text) to authenticated;
create or replace function public.platform_admin_attach_branding(p_provision uuid,p_avatar_url text)
returns void language sql security invoker set search_path='' as $$
 select private.platform_admin_attach_branding(p_provision,p_avatar_url)
$$;
revoke all on function public.platform_admin_attach_branding(uuid,text) from public,anon;
grant execute on function public.platform_admin_attach_branding(uuid,text) to authenticated;

create or replace function private.claim_platform_provisioning()
returns integer language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid();v_email text;v_row record;v_org uuid;v_count integer:=0;
begin
 if v_user is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
 select lower(u.email) into v_email from auth.users u where u.id=v_user and u.email_confirmed_at is not null;
 if v_email is null then return 0;end if;
 for v_row in select * from public.platform_org_provisioning
 where owner_email=v_email and status='pending' order by created_at asc limit 10 for update skip locked
 loop
  v_org:=gen_random_uuid();
  insert into public.organizations(id,name,slug,kind,created_by,avatar_url)
  values(v_org,v_row.business_name,'admin-'||replace(v_org::text,'-',''),v_row.kind,v_user,v_row.avatar_url);
  update public.platform_org_provisioning set status='claimed',claimed_org_id=v_org,claimed_at=now() where id=v_row.id;
  insert into public.platform_admin_events(actor_id,org_id,action,details)
  values(v_user,v_org,'business.claim',jsonb_build_object('provisioning_id',v_row.id));
  v_count:=v_count+1;
 end loop;
 return v_count;
end $$;

create or replace function private.platform_admin_pending()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object(
 'id',p.id,'name',p.business_name,'email',p.owner_email,'kind',p.kind,
 'avatar_url',p.avatar_url,'status',p.status,'created_at',p.created_at,
 'claimed_org_id',p.claimed_org_id) order by p.created_at desc)
 from public.platform_org_provisioning p),'[]'::jsonb);
end $$;
notify pgrst,'reload schema';
