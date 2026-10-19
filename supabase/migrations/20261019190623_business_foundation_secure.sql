
-- Repera: secure first deployment, no shared sports history by default.
-- A former, unapplied draft migration was intentionally superseded.
create extension if not exists pgcrypto;
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create type public.app_role as enum ('athlete','coach','gym_admin','platform_admin');
create type public.organization_kind as enum ('personal_trainer','gym','sports_center');
create type public.organization_role as enum ('owner','admin','coach','reception','athlete');
create type public.organization_membership_status as enum ('active','invited','suspended','revoked');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role public.app_role not null default 'athlete',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{2,62}$'),
  kind public.organization_kind not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.organization_role not null,
  status public.organization_membership_status not null default 'active',
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);
create index organization_memberships_user_status_idx
  on public.organization_memberships (user_id, status, organization_id);

-- Preserve the athlete MVP tables, but make their private rows owner-only.
-- Personal sports history is local-first; no mobile upload is enabled yet.
create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete cascade,
  name text not null,
  muscle_group text not null,
  equipment text,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  constraint exercise_system_owner_ck
    check ((is_system and owner_id is null) or (not is_system and owner_id is not null))
);
create table public.routines (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  weekday smallint check (weekday between 0 and 6),
  created_at timestamptz not null default now()
);
create table public.routine_exercises (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  position int not null default 0,
  target_sets int not null default 3,
  target_reps int not null default 8,
  target_weight_kg numeric
);
create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  started_at timestamptz,
  finished_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  set_index int not null default 0,
  reps int not null default 0,
  weight_kg numeric,
  created_at timestamptz not null default now()
);

create function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles(id, display_name)
  values (new.id, left(coalesce(nullif(new.raw_user_meta_data->>'display_name',''), split_part(new.email,'@',1)),120));
  return new;
end; $$;
revoke all on function private.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

create function private.has_org_role(p_organization_id uuid, p_roles public.organization_role[])
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from public.organization_memberships m
    where m.organization_id = p_organization_id
      and m.user_id = auth.uid()
      and m.status = 'active'::public.organization_membership_status
      and m.role = any(p_roles)
  );
$$;
revoke all on function private.has_org_role(uuid, public.organization_role[]) from public, anon;
grant execute on function private.has_org_role(uuid, public.organization_role[]) to authenticated;

create function private.bootstrap_organization_owner()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.organization_memberships(organization_id,user_id,role,status)
  values (new.id,new.created_by,'owner','active');
  return new;
end; $$;
revoke all on function private.bootstrap_organization_owner() from public, anon, authenticated;
create trigger on_organization_created_add_owner
after insert on public.organizations
for each row execute function private.bootstrap_organization_owner();

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.exercises enable row level security;
alter table public.routines enable row level security;
alter table public.routine_exercises enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_sets enable row level security;

-- Profiles: never let the mobile/web client set its own global role.
create policy profiles_select_self on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy organizations_select_active_members on public.organizations
  for select to authenticated using (
    (select private.has_org_role(id, array[
      'owner','admin','coach','reception','athlete'
    ]::public.organization_role[]))
  );
create policy organizations_create_self on public.organizations
  for insert to authenticated
  with check (created_by = (select auth.uid()));
create policy organizations_update_managers on public.organizations
  for update to authenticated
  using ((select private.has_org_role(id,array['owner','admin']::public.organization_role[])))
  with check ((select private.has_org_role(id,array['owner','admin']::public.organization_role[])));

create policy memberships_select_authorized on public.organization_memberships
  for select to authenticated using (
    user_id = (select auth.uid())
    or (select private.has_org_role(organization_id,array['owner','admin']::public.organization_role[]))
  );
-- Intentional: no client INSERT/UPDATE/DELETE on memberships.
-- Invitations, approval and role changes require validated transactional RPCs.

create policy exercises_select_owner_or_system on public.exercises
  for select to authenticated
  using (is_system or owner_id = (select auth.uid()));
create policy exercises_insert_owner on public.exercises
  for insert to authenticated
  with check (owner_id = (select auth.uid()) and not is_system);
create policy exercises_update_owner on public.exercises
  for update to authenticated
  using (owner_id = (select auth.uid()) and not is_system)
  with check (owner_id = (select auth.uid()) and not is_system);
create policy exercises_delete_owner on public.exercises
  for delete to authenticated
  using (owner_id = (select auth.uid()) and not is_system);

create policy routines_owner on public.routines for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy routine_exercises_owner on public.routine_exercises
  for all to authenticated
  using (exists (select 1 from public.routines r where r.id = routine_id and r.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.routines r where r.id = routine_id and r.owner_id = (select auth.uid())));
create policy workouts_owner on public.workouts for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy workout_sets_owner on public.workout_sets for all to authenticated
  using (exists (select 1 from public.workouts w where w.id = workout_id and w.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.workouts w where w.id = workout_id and w.owner_id = (select auth.uid())));

-- Supabase default privileges may be broad; use explicit minimal table grants.
revoke all on public.profiles, public.organizations, public.organization_memberships,
  public.exercises, public.routines, public.routine_exercises, public.workouts, public.workout_sets
  from anon, authenticated;
grant select on public.profiles to authenticated;
grant update(display_name) on public.profiles to authenticated;
grant select, insert on public.organizations to authenticated;
grant update(name) on public.organizations to authenticated;
grant select on public.organization_memberships to authenticated;
grant select, insert, update, delete
  on public.exercises, public.routines, public.routine_exercises,
     public.workouts, public.workout_sets to authenticated;
