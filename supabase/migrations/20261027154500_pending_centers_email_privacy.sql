-- Do not expose an unverified future owner's email as the center's public email.
update public.organizations o set public_email=null
 from public.platform_org_provisioning p
 where p.claimed_org_id=o.id and p.status='pending' and o.is_discoverable=false
   and o.public_email=p.owner_email;

create or replace function private.platform_admin_materialize_pending(p_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v public.platform_org_provisioning%rowtype;v_org uuid;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 select * into v from public.platform_org_provisioning where id=p_id for update;
 if not found or v.status<>'pending' then raise exception 'PENDING_CENTER_NOT_FOUND' using errcode='22023'; end if;
 if v.claimed_org_id is not null then return v.claimed_org_id; end if;
 v_org:=gen_random_uuid();
 insert into public.organizations(id,name,slug,kind,created_by,avatar_url,is_discoverable)
 values(v_org,v.business_name,'admin-'||replace(v_org::text,'-',''),v.kind,v.created_by,v.avatar_url,false);
 delete from public.organization_memberships where organization_id=v_org and user_id=v.created_by;
 update public.platform_org_provisioning set claimed_org_id=v_org where id=p_id;
 insert into public.platform_admin_events(actor_id,org_id,action,details)
 values(auth.uid(),v_org,'business.workspace_ready',jsonb_build_object('provisioning_id',p_id));
 return v_org;
end $$;
