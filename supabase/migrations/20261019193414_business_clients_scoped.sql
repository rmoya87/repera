-- Repera Business: minimal live client management, independent of athlete workout history.
-- Greenfield drafts in supabase/repera-greenfield are NOT an upgrade path; this is incremental.
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  user_id uuid references auth.users(id) on delete set null,
  name text not null check (length(btrim(name)) between 2 and 120),
  email text not null check (length(email) between 5 and 254 and position('@' in email) > 1),
  status text not null default 'lead' check (status in ('lead','trial','active','paused','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(org_id,id)
);
create unique index clients_org_email_uq on public.clients(org_id,lower(email));
create index clients_org_status_idx on public.clients(org_id,status,created_at);

-- Coach assignment is only manageable through a future audited owner/admin RPC.
create table public.staff_client_assignments (
  org_id uuid not null,
  coach_id uuid not null,
  client_id uuid not null,
  created_at timestamptz not null default now(),
  primary key(org_id,coach_id,client_id),
  foreign key(org_id,coach_id) references public.organization_memberships(organization_id,user_id) on delete cascade,
  foreign key(org_id,client_id) references public.clients(org_id,id) on delete cascade
);
create index staff_client_assignments_client_idx on public.staff_client_assignments(org_id,client_id);

create function private.is_assigned_coach(p_org uuid,p_client uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
 select auth.uid() is not null and exists (
  select 1 from public.staff_client_assignments a
  join public.organization_memberships m on m.organization_id=a.org_id and m.user_id=a.coach_id
  where a.org_id=p_org and a.client_id=p_client and a.coach_id=auth.uid()
   and m.status='active'::public.organization_membership_status
   and m.role='coach'::public.organization_role
 );
$$;
revoke all on function private.is_assigned_coach(uuid,uuid) from public, anon;
grant execute on function private.is_assigned_coach(uuid,uuid) to authenticated;
alter table public.clients enable row level security;
alter table public.staff_client_assignments enable row level security;
create policy clients_select_scoped on public.clients for select to authenticated
using (
 user_id=(select auth.uid())
 or (select private.has_org_role(org_id,array['owner','admin','reception']::public.organization_role[]))
 or (select private.is_assigned_coach(org_id,id))
);
create policy clients_insert_managers on public.clients for insert to authenticated
with check (
 created_by=(select auth.uid()) and user_id is null
 and (select private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
);
create policy clients_update_managers on public.clients for update to authenticated
using ((select private.has_org_role(org_id,array['owner','admin']::public.organization_role[])))
with check ((select private.has_org_role(org_id,array['owner','admin']::public.organization_role[])));
create policy staff_assignments_select_scoped on public.staff_client_assignments for select to authenticated
using (
 coach_id=(select auth.uid())
 or (select private.has_org_role(org_id,array['owner','admin']::public.organization_role[]))
);
-- No public INSERT/UPDATE/DELETE policies on staff_client_assignments.
-- Audited invitation/assignment RPCs will be added before assigning real coaches.
revoke all on public.clients,public.staff_client_assignments from anon,authenticated;
grant select on public.clients,public.staff_client_assignments to authenticated;
grant insert(org_id,created_by,name,email,status) on public.clients to authenticated;
grant update(name,email,status) on public.clients to authenticated;
