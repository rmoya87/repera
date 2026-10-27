-- Repera platform administration: scoped read, provisioning, delegation and payment ledger.
-- No Stripe charge is generated here. Transactions are inserted only by trusted server/service_role.
create table if not exists public.platform_org_controls(
 org_id uuid primary key references public.organizations(id) on delete cascade,
 status text not null default 'active' check(status in ('active','suspended')),
 reason text not null default '', updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now()
);
create table if not exists public.platform_admin_events(
 id bigint generated always as identity primary key,
 actor_id uuid not null references auth.users(id),
 org_id uuid references public.organizations(id) on delete set null,
 action text not null,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.platform_org_provisioning(
 id uuid primary key default gen_random_uuid(),
 owner_email text not null,
 business_name text not null,
 kind public.organization_kind not null,
 plan_key text references public.business_plans(plan_key),
 status text not null default 'pending' check(status in ('pending','claimed','cancelled')),
 created_by uuid not null references auth.users(id),
 claimed_org_id uuid references public.organizations(id),
 created_at timestamptz not null default now(), claimed_at timestamptz
);
create index if not exists platform_org_provisioning_email_idx on public.platform_org_provisioning(lower(owner_email)) where status='pending';
create table if not exists public.platform_admin_delegations(
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references auth.users(id),
 org_id uuid not null references public.organizations(id) on delete cascade,
 reason text not null check(length(reason) between 12 and 300),
 started_at timestamptz not null default now(),
 expires_at timestamptz not null,
 revoked_at timestamptz
);
create index if not exists platform_delegations_active_idx on public.platform_admin_delegations(actor_id,expires_at) where revoked_at is null;
create table if not exists public.platform_billing_payments(
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations(id),
 provider text not null check(provider in ('stripe','external')),
 provider_payment_id text not null,
 amount_cents bigint not null check(amount_cents>=0),
 currency text not null default 'EUR' check(currency ~ '^[A-Z]{3}$'),
 status text not null check(status in ('pending','paid','failed','refunded','partially_refunded')),
 paid_at timestamptz, created_at timestamptz not null default now(),
 unique(provider,provider_payment_id)
);
create index if not exists platform_payments_org_date_idx on public.platform_billing_payments(org_id,created_at desc);
do $$ declare r text; begin
 foreach r in array array['platform_org_controls','platform_admin_events','platform_org_provisioning','platform_admin_delegations','platform_billing_payments'] loop
  execute format('alter table public.%I enable row level security',r);
  execute format('revoke all on public.%I from public,anon,authenticated',r);
 end loop;
end $$;
-- Do not expose financial transactions, admin provisioning or temporary delegation as writable REST tables.
grant select,insert,update on public.platform_billing_payments to service_role;
grant select on public.platform_org_controls to service_role;

create or replace function private.platform_admin_directory()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 return coalesce((
  select jsonb_agg(jsonb_build_object(
   'id',o.id,'name',o.name,'kind',o.kind::text,'slug',o.slug,'created_at',o.created_at,
   'email',o.public_email,'phone',o.phone,'website',o.website,'address',o.address,
   'description',o.description,'timezone',o.timezone,'avatar_url',o.avatar_url,
   'client_count',(select count(*) from public.clients c where c.org_id=o.id),
   'active_clients',(select count(*) from public.clients c where c.org_id=o.id and c.status='active'),
   'member_count',(select count(*) from public.organization_memberships m where m.organization_id=o.id and m.status='active'),
   'sessions',(select count(*) from public.service_occurrences s where s.org_id=o.id),
   'trial_ends_at',t.trial_ends_at,'paid_plan',t.paid_plan,'paid_until',t.paid_until,
   'status',coalesce(st.status,'active'),'status_reason',coalesce(st.reason,''),
   'last_activity',(select max(x.created_at) from public.service_bookings x where x.org_id=o.id)
  ) order by o.created_at desc)
  from public.organizations o left join public.organization_trials t on t.org_id=o.id
  left join public.platform_org_controls st on st.org_id=o.id
 ),'[]'::jsonb);
end $$;
revoke all on function private.platform_admin_directory() from public,anon,authenticated;
grant execute on function private.platform_admin_directory() to authenticated;
create or replace function public.platform_admin_directory() returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_directory()$$;
revoke all on function public.platform_admin_directory() from public,anon;
grant execute on function public.platform_admin_directory() to authenticated;

create or replace function private.platform_admin_finances()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 return jsonb_build_object(
  'payments',coalesce((select jsonb_agg(jsonb_build_object(
    'id',p.id,'org_id',p.org_id,'amount_cents',p.amount_cents,'currency',p.currency,
    'status',p.status,'provider',p.provider,'created_at',p.created_at,'paid_at',p.paid_at
   ) order by p.created_at desc) from public.platform_billing_payments p),'[]'::jsonb),
  'intents',coalesce((select jsonb_agg(jsonb_build_object(
    'id',i.id,'org_id',i.org_id,'plan_key',i.plan_key,'status',i.status,'created_at',i.created_at
   ) order by i.created_at desc) from public.business_subscription_intents i),'[]'::jsonb)
 );
end $$;
revoke all on function private.platform_admin_finances() from public,anon,authenticated;
grant execute on function private.platform_admin_finances() to authenticated;
create or replace function public.platform_admin_finances() returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_finances()$$;
revoke all on function public.platform_admin_finances() from public,anon;
grant execute on function public.platform_admin_finances() to authenticated;

create or replace function private.platform_admin_history()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'org_id',e.org_id,
   'action',e.action,'details',e.details,'created_at',e.created_at) order by e.created_at desc)
   from (select * from public.platform_admin_events order by created_at desc limit 300) e),'[]'::jsonb);
end $$;
revoke all on function private.platform_admin_history() from public,anon,authenticated;
grant execute on function private.platform_admin_history() to authenticated;
create or replace function public.platform_admin_history() returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_history()$$;
revoke all on function public.platform_admin_history() from public,anon;
grant execute on function public.platform_admin_history() to authenticated;

create or replace function private.platform_admin_provision(p_name text,p_kind text,p_email text,p_plan text default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_email text:=lower(btrim(p_email));
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 if length(btrim(p_name)) not between 2 and 120 or p_kind not in ('gym','personal_trainer')
    or length(v_email)>180 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
 then raise exception 'INVALID_BUSINESS' using errcode='22023'; end if;
 if p_plan is not null and not exists (select 1 from public.business_plans b where b.plan_key=p_plan
    and b.audience=p_kind and b.is_active) then raise exception 'INVALID_PLAN' using errcode='22023'; end if;
 if exists(select 1 from public.platform_org_provisioning x where x.owner_email=v_email and x.status='pending'
   and lower(x.business_name)=lower(btrim(p_name))) then raise exception 'DUPLICATE_PENDING_BUSINESS' using errcode='23505'; end if;
 insert into public.platform_org_provisioning(owner_email,business_name,kind,plan_key,created_by)
 values(v_email,btrim(p_name),p_kind::public.organization_kind,p_plan,auth.uid()) returning id into v_id;
 insert into public.platform_admin_events(actor_id,action,details) values(auth.uid(),'business.provision',
 jsonb_build_object('provisioning_id',v_id,'kind',p_kind));
 return v_id;
end $$;
revoke all on function private.platform_admin_provision(text,text,text,text) from public,anon,authenticated;
grant execute on function private.platform_admin_provision(text,text,text,text) to authenticated;
create or replace function public.platform_admin_provision(p_name text,p_kind text,p_email text,p_plan text default null)
returns uuid language sql security invoker set search_path='' as $$
 select private.platform_admin_provision(p_name,p_kind,p_email,p_plan)
$$;
revoke all on function public.platform_admin_provision(text,text,text,text) from public,anon;
grant execute on function public.platform_admin_provision(text,text,text,text) to authenticated;

create or replace function private.claim_platform_provisioning()
returns integer language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid();v_email text;v_row record;v_org uuid;v_count integer:=0;
begin
 if v_user is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select lower(u.email) into v_email from auth.users u where u.id=v_user and u.email_confirmed_at is not null;
 if v_email is null then return 0; end if;
 for v_row in select * from public.platform_org_provisioning
   where owner_email=v_email and status='pending' order by created_at asc limit 10 for update skip locked loop
  v_org:=gen_random_uuid();
  insert into public.organizations(id,name,slug,kind,created_by)
    values(v_org,v_row.business_name,'admin-'+replace(v_org::text,'-',''),v_row.kind,v_user);
  update public.platform_org_provisioning set status='claimed',claimed_org_id=v_org,claimed_at=now() where id=v_row.id;
  insert into public.platform_admin_events(actor_id,org_id,action,details)
    values(v_user,v_org,'business.claim',jsonb_build_object('provisioning_id',v_row.id));
  v_count:=v_count+1;
 end loop;
 return v_count;
end $$;
revoke all on function private.claim_platform_provisioning() from public,anon,authenticated;
grant execute on function private.claim_platform_provisioning() to authenticated;
create or replace function public.claim_platform_provisioning() returns integer
 language sql security invoker set search_path='' as $$select private.claim_platform_provisioning()$$;
revoke all on function public.claim_platform_provisioning() from public,anon;
grant execute on function public.claim_platform_provisioning() to authenticated;

create or replace function private.platform_admin_pending()
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.business_name,'email',p.owner_email,
   'kind',p.kind,'status',p.status,'created_at',p.created_at,'claimed_org_id',p.claimed_org_id)
   order by p.created_at desc) from public.platform_org_provisioning p),'[]'::jsonb);
end $$;
revoke all on function private.platform_admin_pending() from public,anon,authenticated;
grant execute on function private.platform_admin_pending() to authenticated;
create or replace function public.platform_admin_pending() returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_pending()$$;
revoke all on function public.platform_admin_pending() from public,anon;
grant execute on function public.platform_admin_pending() to authenticated;

create or replace function private.platform_admin_set_status(p_org uuid,p_status text,p_reason text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 if p_status not in ('active','suspended') or length(btrim(p_reason))<8 or length(p_reason)>300 then
   raise exception 'INVALID_STATUS_REASON' using errcode='22023'; end if;
 if not exists(select 1 from public.organizations where id=p_org) then raise exception 'BUSINESS_NOT_FOUND' using errcode='22023'; end if;
 insert into public.platform_org_controls(org_id,status,reason,updated_at,updated_by)
 values(p_org,p_status,btrim(p_reason),now(),auth.uid())
 on conflict(org_id) do update set status=excluded.status,reason=excluded.reason,updated_at=now(),updated_by=auth.uid();
 insert into public.platform_admin_events(actor_id,org_id,action,details) values(auth.uid(),p_org,
 'business.status',jsonb_build_object('status',p_status,'reason',btrim(p_reason)));
end $$;
revoke all on function private.platform_admin_set_status(uuid,text,text) from public,anon,authenticated;
grant execute on function private.platform_admin_set_status(uuid,text,text) to authenticated;
create or replace function public.platform_admin_set_status(p_org uuid,p_status text,p_reason text) returns void
 language sql security invoker set search_path='' as $$select private.platform_admin_set_status(p_org,p_status,p_reason)$$;
revoke all on function public.platform_admin_set_status(uuid,text,text) from public,anon;
grant execute on function public.platform_admin_set_status(uuid,text,text) to authenticated;

create or replace function private.platform_admin_delegate(p_org uuid,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_id uuid;v_exp timestamptz:=now()+interval '30 minutes';
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 if length(btrim(p_reason)) not between 12 and 300 then raise exception 'DELEGATION_REASON_REQUIRED' using errcode='22023'; end if;
 if not exists(select 1 from public.organizations where id=p_org) then raise exception 'BUSINESS_NOT_FOUND' using errcode='22023'; end if;
 update public.platform_admin_delegations set revoked_at=now()
  where actor_id=auth.uid() and revoked_at is null;
 insert into public.platform_admin_delegations(actor_id,org_id,reason,expires_at)
  values(auth.uid(),p_org,btrim(p_reason),v_exp) returning id into v_id;
 insert into public.platform_admin_events(actor_id,org_id,action,details)
  values(auth.uid(),p_org,'delegation.start',jsonb_build_object('delegation_id',v_id,'reason',btrim(p_reason)));
 return jsonb_build_object('id',v_id,'org_id',p_org,'expires_at',v_exp);
end $$;
revoke all on function private.platform_admin_delegate(uuid,text) from public,anon,authenticated;
grant execute on function private.platform_admin_delegate(uuid,text) to authenticated;
create or replace function public.platform_admin_delegate(p_org uuid,p_reason text) returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_delegate(p_org,p_reason)$$;
revoke all on function public.platform_admin_delegate(uuid,text) from public,anon;
grant execute on function public.platform_admin_delegate(uuid,text) to authenticated;

create or replace function private.platform_admin_current_delegation()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_record record;
begin
 if not private.is_repera_platform_admin() then return null; end if;
 select d.id,d.org_id,d.expires_at,d.reason,o.name into v_record
 from public.platform_admin_delegations d join public.organizations o on o.id=d.org_id
 where d.actor_id=auth.uid() and d.revoked_at is null and d.expires_at>now()
 order by d.started_at desc limit 1;
 if v_record.id is null then return null; end if;
 return jsonb_build_object('id',v_record.id,'org_id',v_record.org_id,
   'expires_at',v_record.expires_at,'reason',v_record.reason,'name',v_record.name);
end $$;
revoke all on function private.platform_admin_current_delegation() from public,anon,authenticated;
grant execute on function private.platform_admin_current_delegation() to authenticated;
create or replace function public.platform_admin_current_delegation() returns jsonb
 language sql security invoker set search_path='' as $$select private.platform_admin_current_delegation()$$;
revoke all on function public.platform_admin_current_delegation() from public,anon;
grant execute on function public.platform_admin_current_delegation() to authenticated;

create or replace function private.platform_admin_end_delegation()
returns void language plpgsql security definer set search_path='' as $$
declare v_org uuid;
begin
 if not private.is_repera_platform_admin() then raise exception 'NOT_PLATFORM_ADMIN' using errcode='42501'; end if;
 select org_id into v_org from public.platform_admin_delegations
  where actor_id=auth.uid() and revoked_at is null and expires_at>now()
  order by started_at desc limit 1;
 update public.platform_admin_delegations set revoked_at=now()
  where actor_id=auth.uid() and revoked_at is null;
 if v_org is not null then insert into public.platform_admin_events(actor_id,org_id,action)
   values(auth.uid(),v_org,'delegation.end'); end if;
end $$;
revoke all on function private.platform_admin_end_delegation() from public,anon,authenticated;
grant execute on function private.platform_admin_end_delegation() to authenticated;
create or replace function public.platform_admin_end_delegation() returns void
 language sql security invoker set search_path='' as $$select private.platform_admin_end_delegation()$$;
revoke all on function public.platform_admin_end_delegation() from public,anon;
grant execute on function public.platform_admin_end_delegation() to authenticated;

-- Active delegation permits the business owner/admin interface under the admin's own JWT.
-- Athlete-only policies remain excluded. Suspension revokes ordinary memberships immediately.
create or replace function private.has_org_role(p_organization_id uuid,p_roles public.organization_role[])
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and
 (
   (not exists(select 1 from public.platform_org_controls s
        where s.org_id=p_organization_id and s.status='suspended')
    and exists(select 1 from public.organization_memberships m
        where m.organization_id=p_organization_id and m.user_id=auth.uid()
          and m.status='active'::public.organization_membership_status and m.role=any(p_roles)))
   or
   (private.is_repera_platform_admin() and p_roles && array['owner','admin','coach','reception']::public.organization_role[]
     and exists(select 1 from public.platform_admin_delegations d
       where d.actor_id=auth.uid() and d.org_id=p_organization_id
         and d.revoked_at is null and d.expires_at>now()))
 );
$$;
-- Direct membership browsing for delegated admins is still scoped by RLS.
create policy memberships_platform_delegated_read on public.organization_memberships
 for select to authenticated using (
 private.is_repera_platform_admin() and exists(
 select 1 from public.platform_admin_delegations d
 where d.org_id=organization_id and d.actor_id=auth.uid()
 and d.revoked_at is null and d.expires_at>now()
 ));
notify pgrst,'reload schema';
