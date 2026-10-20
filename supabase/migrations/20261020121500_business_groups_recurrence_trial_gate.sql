
-- Repera Business 360: groups, real recurring classes, immutable 7-day trial gate.
create table public.business_training_groups(
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id) on delete cascade,
 name text not null check(length(btrim(name)) between 2 and 100),
 description text not null default '' check(length(description)<=500),
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 unique(org_id,id),
 unique(org_id,name)
);
create table public.business_training_group_members(
 group_id uuid not null,
 org_id uuid not null,
 client_id uuid not null,
 primary key(group_id,client_id),
 foreign key(org_id,group_id) references public.business_training_groups(org_id,id) on delete cascade,
 foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade
);
alter table public.business_training_groups enable row level security;
alter table public.business_training_group_members enable row level security;
create policy business_groups_select on public.business_training_groups for select to authenticated using(
 private.has_org_role(org_id,array['owner','admin','coach']::public.organization_role[]));
create policy business_groups_insert on public.business_training_groups for insert to authenticated with check(
 created_by=auth.uid() and private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_groups_update on public.business_training_groups for update to authenticated using(
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
 with check(private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_groups_delete on public.business_training_groups for delete to authenticated using(
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_group_members_select on public.business_training_group_members for select to authenticated using(
 private.has_org_role(org_id,array['owner','admin','coach']::public.organization_role[]));
create policy business_group_members_insert on public.business_training_group_members for insert to authenticated with check(
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_group_members_delete on public.business_training_group_members for delete to authenticated using(
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
revoke all on public.business_training_groups,public.business_training_group_members from public,anon,authenticated;
grant select on public.business_training_groups,public.business_training_group_members to authenticated;
grant insert(org_id,name,description,created_by),update(name,description),delete on public.business_training_groups to authenticated;
grant insert(org_id,group_id,client_id),delete on public.business_training_group_members to authenticated;

create function private.create_service_series(
 p_org uuid,p_coach uuid,p_kind text,p_title text,p_start timestamptz,p_end timestamptz,
 p_capacity int,p_repeat text,p_count int
) returns uuid[] language plpgsql security definer set search_path=''
as $$
declare generated uuid[]:='{}'; next_start timestamptz; next_end timestamptz;
  idx int:=0; offset_days int:=0; new_id uuid;
begin
 if auth.uid() is null or not private.has_org_role(p_org,array['owner','admin']::public.organization_role[])
  then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if not exists(select 1 from public.organization_memberships
  where organization_id=p_org and user_id=p_coach and status='active'
    and role in ('owner','admin','coach')) then
   raise exception 'COACH_NOT_AUTHORIZED' using errcode='42501'; end if;
 if p_kind not in ('class','appointment') or p_repeat not in ('none','daily','weekly','weekdays')
 or p_count not between 1 and 52 or (p_repeat='none' and p_count<>1)
 or p_start<=now() or p_start>now()+interval '18 months'
 or p_end<=p_start or p_end>p_start+interval '12 hours'
 or length(btrim(coalesce(p_title,''))) not between 2 and 120
 or p_capacity not between 1 and 200 or (p_kind='appointment' and p_capacity<>1)
 then raise exception 'INVALID_SERIES' using errcode='22023'; end if;
 while idx<p_count loop
  if p_repeat='none' then offset_days:=0;
  elsif p_repeat='daily' then offset_days:=idx;
  elsif p_repeat='weekly' then offset_days:=idx*7;
  else
   while extract(isodow from p_start+offset_days*interval '1 day') not between 1 and 5 loop
    offset_days:=offset_days+1;
   end loop;
  end if;
  next_start:=p_start+offset_days*interval '1 day';
  next_end:=p_end+offset_days*interval '1 day';
  if next_start>now()+interval '18 months' then raise exception 'SERIES_TOO_FAR' using errcode='22023'; end if;
  insert into public.service_occurrences(org_id,coach_user_id,kind,title,starts_at,ends_at,capacity)
   values(p_org,p_coach,p_kind,btrim(p_title),next_start,next_end,p_capacity) returning id into new_id;
  insert into public.service_occurrence_details(occurrence_id,org_id,repeat_rule)
   values(new_id,p_org,p_repeat);
  generated:=array_append(generated,new_id);
  idx:=idx+1;
  if p_repeat='weekdays' then offset_days:=offset_days+1; end if;
 end loop;
 return generated;
end; $$;
revoke all on function private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int)
 from public,anon,authenticated;
grant execute on function private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int) to authenticated;
create function public.create_service_series(
 p_org uuid,p_coach uuid,p_kind text,p_title text,p_start timestamptz,p_end timestamptz,
 p_capacity int,p_repeat text,p_count int
) returns uuid[] language sql security invoker set search_path=''
as $$select private.create_service_series(p_org,p_coach,p_kind,p_title,p_start,p_end,p_capacity,p_repeat,p_count)$$;
revoke all on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int)
 from public,anon;
grant execute on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int) to authenticated;

-- Expiry is decided by database clock, not browser input. A selected (unpaid) plan
-- never unlocks the account. Billing integration must set paid_plan/paid_until on server.
create function private.assert_business_trial() returns trigger
language plpgsql security definer set search_path=''
as $$
begin
 if not exists(select 1 from public.organization_trials t
   where t.org_id=new.org_id and
       (t.trial_ends_at>now() or (t.paid_until>now() and t.paid_plan is not null))) then
  raise exception 'TRIAL_EXPIRED_PAYMENT_REQUIRED' using errcode='42501'; end if;
 return new;
end; $$;
revoke all on function private.assert_business_trial() from public,anon,authenticated;
create trigger trial_gate_services before insert or update on public.service_occurrences
 for each row execute function private.assert_business_trial();
create trigger trial_gate_workout_templates before insert or update on public.professional_workout_templates
 for each row execute function private.assert_business_trial();
create trigger trial_gate_professional_sessions before insert or update on public.professional_training_sessions
 for each row execute function private.assert_business_trial();
create trigger trial_gate_notifications before insert on public.business_client_notifications
 for each row execute function private.assert_business_trial();
create trigger trial_gate_clients before insert on public.clients
 for each row execute function private.assert_business_trial();

-- Readable pricing intent: no simulated payment and no self-grant of paid access.
create table public.business_subscription_intents(
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id) on delete cascade,
 plan_key text not null check(plan_key in ('trainer_5','trainer_50','trainer_75','gym_basic','gym_advanced','gym_expert')),
 actor uuid not null references auth.users(id),
 status text not null default 'awaiting_payment_provider' check(status='awaiting_payment_provider'),
 created_at timestamptz not null default now()
);
alter table public.business_subscription_intents enable row level security;
create policy business_subscription_intents_read on public.business_subscription_intents for select to authenticated using(
 private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
create policy business_subscription_intents_insert on public.business_subscription_intents for insert to authenticated with check(
 actor=auth.uid() and private.has_org_role(org_id,array['owner','admin']::public.organization_role[]));
revoke all on public.business_subscription_intents from public,anon,authenticated;
grant select,insert on public.business_subscription_intents to authenticated;
