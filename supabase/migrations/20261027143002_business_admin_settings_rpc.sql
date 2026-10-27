-- Platform configuration is stored centrally, never solely in localStorage.
create or replace function private.platform_admin_settings()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 return coalesce((select to_jsonb(s)-'updated_by' from public.platform_settings s where s.id=1),
 jsonb_build_object('support_email','','support_url','','billing_email','','privacy_url','','terms_url',''));
end $$;
revoke all on function private.platform_admin_settings() from public,anon,authenticated;
grant execute on function private.platform_admin_settings() to authenticated;
create or replace function public.platform_admin_settings() returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_settings()$$;
revoke all on function public.platform_admin_settings() from public,anon;
grant execute on function public.platform_admin_settings() to authenticated;

create or replace function private.platform_admin_update_settings(
p_support_email text,p_support_url text,p_billing_email text,p_privacy_url text,p_terms_url text)
returns void language plpgsql security definer set search_path='' as $$
declare v_support text:=nullif(btrim(p_support_email),'');
v_billing text:=nullif(btrim(p_billing_email),'');
v_url text:=nullif(btrim(p_support_url),'');
v_privacy text:=nullif(btrim(p_privacy_url),'');
v_terms text:=nullif(btrim(p_terms_url),'');
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501';end if;
 if (v_support is not null and (length(v_support)>180 or v_support !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'))
 or (v_billing is not null and (length(v_billing)>180 or v_billing !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'))
 or (v_url is not null and (length(v_url)>500 or v_url !~ '^https://[^[:space:]]+$'))
 or (v_privacy is not null and (length(v_privacy)>500 or v_privacy !~ '^https://[^[:space:]]+$'))
 or (v_terms is not null and (length(v_terms)>500 or v_terms !~ '^https://[^[:space:]]+$'))
 then raise exception 'INVALID_SETTINGS' using errcode='22023'; end if;
 insert into public.platform_settings(id,support_email,support_url,billing_email,privacy_url,terms_url,updated_by)
 values(1,v_support,v_url,v_billing,v_privacy,v_terms,auth.uid())
 on conflict(id) do update set support_email=excluded.support_email,support_url=excluded.support_url,
 billing_email=excluded.billing_email,privacy_url=excluded.privacy_url,terms_url=excluded.terms_url,
 updated_by=auth.uid(),updated_at=now();
 insert into public.platform_admin_events(actor_id,action,details)
 values(auth.uid(),'platform.settings',jsonb_build_object('fields','platform_contacts'));
end $$;
revoke all on function private.platform_admin_update_settings(text,text,text,text,text) from public,anon,authenticated;
grant execute on function private.platform_admin_update_settings(text,text,text,text,text) to authenticated;
create or replace function public.platform_admin_update_settings(
p_support_email text,p_support_url text,p_billing_email text,p_privacy_url text,p_terms_url text)
returns void language sql security invoker set search_path='' as $$
 select private.platform_admin_update_settings(p_support_email,p_support_url,p_billing_email,p_privacy_url,p_terms_url)
$$;
revoke all on function public.platform_admin_update_settings(text,text,text,text,text) from public,anon;
grant execute on function public.platform_admin_update_settings(text,text,text,text,text) to authenticated;
