-- Repera security baseline. Apply only to a dedicated Repera project, after init_repera.
begin;
create table if not exists public.organizations (id uuid primary key default gen_random_uuid(), kind text not null check (kind in ('gym','coach_business')), name text not null, created_at timestamptz not null default now());
create table if not exists public.organization_members (organization_id uuid not null references public.organizations(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade, role text not null check (role in ('owner','manager','coach','staff')), status text not null check (status in ('active','suspended','ended')), primary key(organization_id,user_id));
create table if not exists public.client_relationships (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade, athlete_id uuid not null references public.profiles(id) on delete cascade, coach_id uuid references public.profiles(id), service text not null check (service in ('gym_membership','personal_training')), status text not null check (status in ('pending','active','suspended','ended')), share_workout_history boolean not null default false, valid_from timestamptz, valid_until timestamptz);
create index if not exists client_relationships_coach_idx on public.client_relationships(coach_id,athlete_id,status);
create index if not exists organization_members_user_idx on public.organization_members(user_id,organization_id,status);
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.client_relationships enable row level security;
create policy org_members_self_read on public.organization_members for select to authenticated using(user_id=(select auth.uid()));
create policy org_read_member on public.organizations for select to authenticated using(exists(select 1 from public.organization_members m where m.organization_id=organizations.id and m.user_id=(select auth.uid()) and m.status='active'));
create policy relation_read_own on public.client_relationships for select to authenticated using(athlete_id=(select auth.uid()) or (coach_id=(select auth.uid()) and exists(select 1 from public.organization_members m where m.organization_id=client_relationships.organization_id and m.user_id=(select auth.uid()) and m.status='active')));
revoke insert,update,delete on public.organizations, public.organization_members, public.client_relationships from authenticated;
grant select on public.organizations, public.organization_members, public.client_relationships to authenticated;
drop policy if exists profiles_select_own_or_staff on public.profiles;
drop policy if exists workouts_owner_all on public.workouts;
drop policy if exists workout_sets_via_workout on public.workout_sets;
drop policy if exists exercises_select_authenticated on public.exercises;
drop policy if exists routines_owner_all on public.routines;
drop policy if exists routine_exercises_via_routine on public.routine_exercises;
create policy exercises_catalog_or_owned on public.exercises for select to authenticated using(is_system or owner_id=(select auth.uid()));
create policy profile_read_scoped on public.profiles for select to authenticated using(id=(select auth.uid()) or exists(select 1 from public.client_relationships r where r.athlete_id=profiles.id and r.coach_id=(select auth.uid()) and r.status='active' and r.service='personal_training' and (r.valid_from is null or r.valid_from<=now()) and (r.valid_until is null or r.valid_until>now())));
create policy workouts_read_scoped on public.workouts for select to authenticated using(owner_id=(select auth.uid()) or exists(select 1 from public.client_relationships r where r.athlete_id=workouts.owner_id and r.coach_id=(select auth.uid()) and r.status='active' and r.service='personal_training' and r.share_workout_history and (r.valid_from is null or r.valid_from<=now()) and (r.valid_until is null or r.valid_until>now())));
create policy workouts_write_own on public.workouts for all to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy workout_sets_read_scoped on public.workout_sets for select to authenticated using(exists(select 1 from public.workouts w where w.id=workout_id));
create policy workout_sets_write_own on public.workout_sets for all to authenticated using(exists(select 1 from public.workouts w where w.id=workout_id and w.owner_id=(select auth.uid()))) with check(exists(select 1 from public.workouts w where w.id=workout_id and w.owner_id=(select auth.uid())));
create policy routines_owner on public.routines for all to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy routine_exercises_owner on public.routine_exercises for all to authenticated using(exists(select 1 from public.routines r where r.id=routine_id and r.owner_id=(select auth.uid()))) with check(exists(select 1 from public.routines r where r.id=routine_id and r.owner_id=(select auth.uid())));
-- Explicit grants: new Supabase projects may not auto-expose SQL-created tables.
revoke all on public.profiles, public.exercises, public.routines, public.routine_exercises, public.workouts, public.workout_sets, public.organizations, public.organization_members, public.client_relationships from anon;
grant select on public.profiles to authenticated;
revoke update on public.profiles from authenticated;
grant update (display_name) on public.profiles to authenticated;
grant select,insert,update,delete on public.exercises, public.routines, public.routine_exercises, public.workouts, public.workout_sets to authenticated;
grant select,insert,update,delete on public.organizations, public.organization_members, public.client_relationships, public.profiles, public.exercises, public.routines, public.routine_exercises, public.workouts, public.workout_sets to service_role;
-- Old helper is now unused by RLS; remove public execution of SECURITY DEFINER function.
revoke execute on function public.current_role() from public, anon, authenticated;
commit;