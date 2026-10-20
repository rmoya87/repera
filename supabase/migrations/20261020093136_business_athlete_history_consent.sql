
-- Historial deportivo privado: solo disponible tras aceptación explícita del atleta,
-- para la organización a la que esté vinculado y sus entrenadores asignados.
create table public.athlete_business_history_consents(
 org_id uuid not null,
 client_id uuid not null,
 athlete_user_id uuid not null references auth.users(id),
 granted_at timestamptz not null default now(),
 revoked_at timestamptz,
 primary key(org_id,client_id),
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade
);
alter table public.athlete_business_history_consents enable row level security;
create policy history_consent_self_read on public.athlete_business_history_consents
 for select to authenticated using(athlete_user_id=auth.uid() or
 (revoked_at is null and (private.has_org_role(org_id,array['owner','admin']::public.organization_role[])
 or private.is_assigned_coach(org_id,client_id))));
create policy history_consent_self_insert on public.athlete_business_history_consents
 for insert to authenticated with check(athlete_user_id=auth.uid() and exists(
 select 1 from public.clients c where c.id=client_id and c.org_id=org_id and c.user_id=auth.uid()));
create policy history_consent_self_update on public.athlete_business_history_consents
 for update to authenticated using(athlete_user_id=auth.uid())
 with check(athlete_user_id=auth.uid() and exists(
 select 1 from public.clients c where c.id=client_id and c.org_id=org_id and c.user_id=auth.uid()));
revoke all on public.athlete_business_history_consents from public,anon,authenticated;
grant select on public.athlete_business_history_consents to authenticated;
grant insert(org_id,client_id,athlete_user_id) on public.athlete_business_history_consents to authenticated;
grant update(revoked_at,granted_at) on public.athlete_business_history_consents to authenticated;

create function private.get_shared_client_history(p_org uuid,p_client uuid)
 returns table(id uuid,title text,started_at timestamptz,finished_at timestamptz)
 language plpgsql stable security definer set search_path=''
as $$
declare athlete uuid;
begin
 if auth.uid() is null or not (
 private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
 or private.is_assigned_coach(p_org,p_client)) then
  raise exception 'NOT_AUTHORIZED' using errcode='42501';end if;
 select user_id into athlete from public.clients where org_id=p_org and id=p_client and status='active';
 if athlete is null then return;end if;
 if not exists(select 1 from public.athlete_business_history_consents c
  where c.org_id=p_org and c.client_id=p_client and c.athlete_user_id=athlete
    and c.revoked_at is null) then return;end if;
 return query select w.id,w.title,w.started_at,w.finished_at
  from public.athlete_workout_mirror w
  where w.owner_id=athlete and w.deleted_at is null and w.started_at is not null
  order by w.started_at desc limit 200;
end; $$;
revoke all on function private.get_shared_client_history(uuid,uuid) from public,anon,authenticated;
grant execute on function private.get_shared_client_history(uuid,uuid) to authenticated;
create function public.get_shared_client_history(p_org uuid,p_client uuid)
 returns table(id uuid,title text,started_at timestamptz,finished_at timestamptz)
 language sql security invoker set search_path=''
 as $$select * from private.get_shared_client_history(p_org,p_client)$$;
revoke all on function public.get_shared_client_history(uuid,uuid) from public,anon;
grant execute on function public.get_shared_client_history(uuid,uuid) to authenticated;
