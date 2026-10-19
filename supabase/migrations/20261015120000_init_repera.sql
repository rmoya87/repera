-- Repera foundation schema (multi-role ready; athlete MVP)
-- Roles live in profiles.role (DB), not in editable user_metadata.

create extension if not exists "pgcrypto";

create type public.app_role as enum (
  'athlete',
  'coach',
  'gym_admin',
  'platform_admin'
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  role public.app_role not null default 'athlete',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles (id) on delete cascade,
  name text not null,
  muscle_group text not null,
  equipment text,
  is_system boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.routines (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  weekday smallint check (weekday between 0 and 6),
  created_at timestamptz not null default now()
);

create table public.routine_exercises (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete restrict,
  position int not null default 0,
  target_sets int not null default 3,
  target_reps int not null default 8,
  target_weight_kg numeric
);

create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  started_at timestamptz,
  finished_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete restrict,
  set_index int not null default 0,
  reps int not null default 0,
  weight_kg numeric,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)), 'athlete');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.current_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

alter table public.profiles enable row level security;
alter table public.exercises enable row level security;
alter table public.routines enable row level security;
alter table public.routine_exercises enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_sets enable row level security;

-- Profiles
create policy "profiles_select_own_or_staff"
  on public.profiles for select
  using (
    id = auth.uid()
    or public.current_role() in ('coach', 'gym_admin', 'platform_admin')
  );

create policy "profiles_update_own"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()));

-- Exercises: system readable by all authenticated; user owns custom
create policy "exercises_select_authenticated"
  on public.exercises for select
  to authenticated
  using (is_system or owner_id = auth.uid() or public.current_role() in ('platform_admin'));

create policy "exercises_insert_own"
  on public.exercises for insert
  to authenticated
  with check (owner_id = auth.uid() and is_system = false);

create policy "exercises_update_own"
  on public.exercises for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "exercises_delete_own"
  on public.exercises for delete
  to authenticated
  using (owner_id = auth.uid());

-- Routines
create policy "routines_owner_all"
  on public.routines for all
  to authenticated
  using (owner_id = auth.uid() or public.current_role() = 'platform_admin')
  with check (owner_id = auth.uid() or public.current_role() = 'platform_admin');

create policy "routine_exercises_via_routine"
  on public.routine_exercises for all
  to authenticated
  using (
    exists (
      select 1 from public.routines r
      where r.id = routine_id and (r.owner_id = auth.uid() or public.current_role() = 'platform_admin')
    )
  )
  with check (
    exists (
      select 1 from public.routines r
      where r.id = routine_id and (r.owner_id = auth.uid() or public.current_role() = 'platform_admin')
    )
  );

-- Workouts
create policy "workouts_owner_all"
  on public.workouts for all
  to authenticated
  using (owner_id = auth.uid() or public.current_role() in ('coach', 'gym_admin', 'platform_admin'))
  with check (owner_id = auth.uid() or public.current_role() = 'platform_admin');

create policy "workout_sets_via_workout"
  on public.workout_sets for all
  to authenticated
  using (
    exists (
      select 1 from public.workouts w
      where w.id = workout_id
        and (w.owner_id = auth.uid() or public.current_role() in ('coach', 'gym_admin', 'platform_admin'))
    )
  )
  with check (
    exists (
      select 1 from public.workouts w
      where w.id = workout_id and w.owner_id = auth.uid()
    )
  );
