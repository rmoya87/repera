
-- El deportista activa o revoca el acceso para CADA gimnasio o entrenador vinculado.
create function private.set_athlete_history_consent(p_org uuid,p_client uuid,p_allow boolean)
 returns boolean language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or p_allow is null or not exists(
  select 1 from public.clients c where c.org_id=p_org and c.id=p_client
     and c.user_id=auth.uid() and c.status='active') then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 insert into public.athlete_business_history_consents
  (org_id,client_id,athlete_user_id,granted_at,revoked_at)
 values(p_org,p_client,auth.uid(),now(),case when p_allow then null else now() end)
 on conflict(org_id,client_id) do update
 set granted_at=case when p_allow then now() else athlete_business_history_consents.granted_at end,
     revoked_at=case when p_allow then null else now() end
 where athlete_business_history_consents.athlete_user_id=auth.uid();
 return true;
end; $$;
revoke all on function private.set_athlete_history_consent(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function private.set_athlete_history_consent(uuid,uuid,boolean) to authenticated;
create function public.set_athlete_history_consent(p_org uuid,p_client uuid,p_allow boolean)
 returns boolean language sql security invoker set search_path=''
 as $$ select private.set_athlete_history_consent(p_org,p_client,p_allow) $$;
revoke all on function public.set_athlete_history_consent(uuid,uuid,boolean) from public,anon;
grant execute on function public.set_athlete_history_consent(uuid,uuid,boolean) to authenticated;
-- Don't let a client bypass the audited mutation RPC.
revoke insert,update on public.athlete_business_history_consents from authenticated;
