-- Repera Business: scheduling layers (rooms, series, day programs, org settings, open_access).
-- Safe additive migration; backfills series heuristically; does not drop legacy location text.

-- ——— org_operation_settings ———
create table if not exists public.org_operation_settings (
  org_id uuid primary key references public.organizations(id) on delete cascade,
  profile text not null default 'gym_multi'
    check (profile in ('box', 'gym_multi', 'hybrid_rooms', 'pt')),
  use_rooms boolean not null default false,
  day_program_enabled boolean not null default true,
  day_program_scope text not null default 'activity_type'
    check (day_program_scope in ('global', 'activity_type', 'room')),
  open_access_enabled boolean not null default false,
  open_access_requires_booking boolean not null default true,
  cancel_credit_hours int not null default 12
    check (cancel_credit_hours between 0 and 168),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

alter table public.org_operation_settings enable row level security;

drop policy if exists org_operation_settings_select on public.org_operation_settings;
create policy org_operation_settings_select on public.org_operation_settings
  for select to authenticated
  using (
    private.has_org_role(org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[])
  );

revoke all on public.org_operation_settings from public, anon, authenticated;
grant select on public.org_operation_settings to authenticated;

-- Defaults by org kind
insert into public.org_operation_settings (org_id, profile, use_rooms, day_program_enabled, day_program_scope, open_access_enabled)
select o.id,
  case
    when o.kind = 'personal_trainer' then 'pt'
    when o.kind in ('gym', 'sports_center') then 'gym_multi'
    else 'gym_multi'
  end,
  case when o.kind in ('gym', 'sports_center') then true else false end,
  case when o.kind = 'personal_trainer' then false else true end,
  case when o.kind = 'personal_trainer' then 'global' else 'activity_type' end,
  case when o.kind in ('gym', 'sports_center') then true else false end
from public.organizations o
on conflict (org_id) do nothing;

-- ——— facility_rooms ———
create table if not exists public.facility_rooms (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  capacity int not null default 20 check (capacity between 1 and 500),
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (org_id, id),
  unique (org_id, name)
);

create index if not exists facility_rooms_org_idx on public.facility_rooms (org_id) where is_active;

alter table public.facility_rooms enable row level security;

drop policy if exists facility_rooms_select on public.facility_rooms;
create policy facility_rooms_select on public.facility_rooms
  for select to authenticated
  using (
    private.has_org_role(org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[])
  );

revoke all on public.facility_rooms from public, anon, authenticated;
grant select on public.facility_rooms to authenticated;

-- ——— activity_types ———
create table if not exists public.activity_types (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  code text not null check (length(btrim(code)) between 1 and 40),
  name text not null check (length(btrim(name)) between 1 and 80),
  color text not null default '#22834d' check (color ~ '^#[0-9a-fA-F]{6}$'),
  requires_booking boolean not null default true,
  supports_day_program boolean not null default true,
  is_open_access boolean not null default false,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (org_id, id),
  unique (org_id, code)
);

create index if not exists activity_types_org_idx on public.activity_types (org_id) where is_active;

alter table public.activity_types enable row level security;

drop policy if exists activity_types_select on public.activity_types;
create policy activity_types_select on public.activity_types
  for select to authenticated
  using (
    private.has_org_role(org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[])
  );

revoke all on public.activity_types from public, anon, authenticated;
grant select on public.activity_types to authenticated;

-- Seed default types per org (idempotent by code)
insert into public.activity_types (org_id, code, name, color, requires_booking, supports_day_program, is_open_access, sort_order)
select o.id, t.code, t.name, t.color, t.requires_booking, t.supports_day_program, t.is_open_access, t.sort_order
from public.organizations o
cross join (
  values
    ('class', 'Clase', '#22834d', true, true, false, 10),
    ('wod', 'WOD / CrossFit', '#0A84FF', true, true, false, 20),
    ('open_gym', 'Open gym', '#FF9F0A', true, false, true, 30),
    ('appointment', 'Cita 1:1', '#AF52DE', true, false, false, 40)
) as t(code, name, color, requires_booking, supports_day_program, is_open_access, sort_order)
on conflict (org_id, code) do nothing;

-- ——— service_series ———
create table if not exists public.service_series (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  activity_type_id uuid,
  room_id uuid,
  coach_user_id uuid,
  kind text not null check (kind in ('class', 'appointment', 'open_access')),
  title text not null check (length(btrim(title)) between 2 and 120),
  capacity int not null default 12 check (capacity between 1 and 200),
  color text not null default '#22834d' check (color ~ '^#[0-9a-fA-F]{6}$'),
  location_label text not null default '' check (length(location_label) <= 250),
  description text not null default '' check (length(description) <= 2000),
  repeat_rule text not null default 'weekly'
    check (repeat_rule in ('none', 'daily', 'weekly', 'weekdays')),
  interval_days int check (interval_days is null or interval_days between 1 and 14),
  duration_minutes int not null default 60 check (duration_minutes between 5 and 720),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (org_id, id),
  foreign key (org_id, activity_type_id) references public.activity_types (org_id, id),
  foreign key (org_id, room_id) references public.facility_rooms (org_id, id),
  check (kind <> 'appointment' or capacity = 1)
);

create index if not exists service_series_org_idx on public.service_series (org_id) where is_active;

alter table public.service_series enable row level security;

drop policy if exists service_series_select on public.service_series;
create policy service_series_select on public.service_series
  for select to authenticated
  using (
    private.has_org_role(org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[])
  );

revoke all on public.service_series from public, anon, authenticated;
grant select on public.service_series to authenticated;

-- ——— day_programs ———
create table if not exists public.day_programs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  program_date date not null,
  scope text not null default 'global'
    check (scope in ('global', 'activity_type', 'room')),
  activity_type_id uuid,
  room_id uuid,
  title text not null default '' check (length(title) <= 120),
  instructions text not null default '' check (length(instructions) <= 4000),
  prescription jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, id),
  foreign key (org_id, activity_type_id) references public.activity_types (org_id, id),
  foreign key (org_id, room_id) references public.facility_rooms (org_id, id),
  check (
    (scope = 'global' and activity_type_id is null and room_id is null)
    or (scope = 'activity_type' and activity_type_id is not null and room_id is null)
    or (scope = 'room' and room_id is not null and activity_type_id is null)
  )
);

create unique index if not exists day_programs_unique_global
  on public.day_programs (org_id, program_date) where scope = 'global';
create unique index if not exists day_programs_unique_type
  on public.day_programs (org_id, program_date, activity_type_id) where scope = 'activity_type';
create unique index if not exists day_programs_unique_room
  on public.day_programs (org_id, program_date, room_id) where scope = 'room';

alter table public.day_programs enable row level security;

drop policy if exists day_programs_select on public.day_programs;
create policy day_programs_select on public.day_programs
  for select to authenticated
  using (
    private.has_org_role(org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[])
  );

revoke all on public.day_programs from public, anon, authenticated;
grant select on public.day_programs to authenticated;

-- ——— extend service_occurrences ———
alter table public.service_occurrences
  add column if not exists series_id uuid,
  add column if not exists room_id uuid,
  add column if not exists activity_type_id uuid;

alter table public.service_occurrences drop constraint if exists service_occurrences_kind_check;
alter table public.service_occurrences
  add constraint service_occurrences_kind_check
  check (kind in ('class', 'appointment', 'open_access'));

alter table public.service_occurrences drop constraint if exists service_occurrences_appointment_capacity;
-- re-add appointment capacity rule (open_access may use >1)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'service_occurrences_appointment_capacity'
      and conrelid = 'public.service_occurrences'::regclass
  ) then
    alter table public.service_occurrences
      add constraint service_occurrences_appointment_capacity
      check (kind <> 'appointment' or capacity = 1);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'service_occurrences_series_fk'
  ) then
    alter table public.service_occurrences
      add constraint service_occurrences_series_fk
      foreign key (org_id, series_id) references public.service_series (org_id, id);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'service_occurrences_room_fk'
  ) then
    alter table public.service_occurrences
      add constraint service_occurrences_room_fk
      foreign key (org_id, room_id) references public.facility_rooms (org_id, id);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'service_occurrences_activity_type_fk'
  ) then
    alter table public.service_occurrences
      add constraint service_occurrences_activity_type_fk
      foreign key (org_id, activity_type_id) references public.activity_types (org_id, id);
  end if;
end $$;

create index if not exists service_occurrences_series_idx
  on public.service_occurrences (series_id) where series_id is not null;
create index if not exists service_occurrences_room_period_idx
  on public.service_occurrences (org_id, room_id, starts_at)
  where status = 'active' and room_id is not null;

-- Backfill rooms from distinct location labels (inactive until staff activates use_rooms)
insert into public.facility_rooms (org_id, name, capacity, is_active, sort_order)
select distinct d.org_id, left(btrim(d.location), 80), 20, false, 100
from public.service_occurrence_details d
where length(btrim(coalesce(d.location, ''))) >= 1
on conflict (org_id, name) do nothing;

-- Heuristic series backfill: group active classes by org+title+dow+hour+minute
-- Best-effort; failures must not block the rest of the migration.
do $backfill$
begin
with candidates as (
  select
    o.org_id,
    o.kind,
    o.title,
    o.capacity,
    coalesce(d.color, '#22834d') as color,
    coalesce(d.location, '') as location_label,
    coalesce(d.description, '') as description,
    extract(isodow from o.starts_at at time zone coalesce(org.timezone, 'Europe/Madrid'))::int as dow,
    extract(hour from o.starts_at at time zone coalesce(org.timezone, 'Europe/Madrid'))::int as hr,
    extract(minute from o.starts_at at time zone coalesce(org.timezone, 'Europe/Madrid'))::int as mn,
    min(o.starts_at) as first_start,
    max(o.ends_at - o.starts_at) as dur,
    array_agg(o.id order by o.starts_at) as occ_ids,
    count(*)::int as cnt
  from public.service_occurrences o
  join public.organizations org on org.id = o.org_id
  left join public.service_occurrence_details d on d.occurrence_id = o.id
  where o.status = 'active'
    and o.series_id is null
    and o.kind in ('class', 'appointment')
  group by 1,2,3,4,5,6,7,8,9,10
  having count(*) >= 2
),
ins as (
  insert into public.service_series (
    org_id, kind, title, capacity, color, location_label, description,
    repeat_rule, duration_minutes, is_active
  )
  select
    c.org_id, c.kind, c.title, c.capacity, c.color, left(c.location_label, 250), left(c.description, 2000),
    'weekly',
    greatest(5, least(720, round(extract(epoch from c.dur) / 60.0)::int)),
    true
  from candidates c
  returning id, org_id, title, capacity, color, location_label
)
update public.service_occurrences o
set series_id = s.id
from candidates c
join lateral (
  select ss.id
  from public.service_series ss
  where ss.org_id = c.org_id
    and ss.title = c.title
    and ss.capacity = c.capacity
    and ss.color = c.color
    and ss.location_label = left(c.location_label, 250)
    and ss.is_active
  order by ss.created_at desc
  limit 1
) s on true
where o.id = any (c.occ_ids)
  and o.series_id is null;
exception when others then
  raise notice 'series backfill skipped: %', sqlerrm;
end;
$backfill$;

-- ——— room overlap trigger ———
create or replace function private.check_service_room_schedule()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_room_cap int;
begin
  if new.room_id is null or new.status is distinct from 'active' then
    return new;
  end if;
  if not exists (
    select 1 from public.facility_rooms r
    where r.id = new.room_id and r.org_id = new.org_id and r.is_active
  ) then
    raise exception 'ROOM_NOT_ACTIVE' using errcode = '22023';
  end if;
  select r.capacity into v_room_cap
  from public.facility_rooms r
  where r.id = new.room_id and r.org_id = new.org_id;
  if new.capacity > v_room_cap then
    raise exception 'CAPACITY_EXCEEDED' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('room:' || new.room_id::text, 0));
  if exists (
    select 1 from public.service_occurrences o
    where o.org_id = new.org_id
      and o.room_id = new.room_id
      and o.status = 'active'
      and o.id is distinct from new.id
      and o.starts_at < new.ends_at
      and o.ends_at > new.starts_at
  ) then
    raise exception 'ROOM_OVERLAP' using errcode = '23P01';
  end if;
  return new;
end;
$$;

drop trigger if exists service_room_schedule on public.service_occurrences;
create trigger service_room_schedule
  before insert or update of room_id, starts_at, ends_at, capacity, status
  on public.service_occurrences
  for each row execute function private.check_service_room_schedule();

-- ——— settings RPCs ———
create or replace function private.upsert_org_operation_settings(
  p_org uuid,
  p_profile text,
  p_use_rooms boolean,
  p_day_program_enabled boolean,
  p_day_program_scope text,
  p_open_access_enabled boolean,
  p_open_access_requires_booking boolean,
  p_cancel_credit_hours int
) returns public.org_operation_settings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.org_operation_settings;
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if p_profile not in ('box', 'gym_multi', 'hybrid_rooms', 'pt')
     or p_day_program_scope not in ('global', 'activity_type', 'room')
     or p_cancel_credit_hours not between 0 and 168 then
    raise exception 'INVALID_SETTINGS' using errcode = '22023';
  end if;
  insert into public.org_operation_settings as s (
    org_id, profile, use_rooms, day_program_enabled, day_program_scope,
    open_access_enabled, open_access_requires_booking, cancel_credit_hours,
    updated_at, updated_by
  ) values (
    p_org, p_profile, coalesce(p_use_rooms, false), coalesce(p_day_program_enabled, true),
    p_day_program_scope, coalesce(p_open_access_enabled, false),
    coalesce(p_open_access_requires_booking, true), coalesce(p_cancel_credit_hours, 12),
    now(), auth.uid()
  )
  on conflict (org_id) do update set
    profile = excluded.profile,
    use_rooms = excluded.use_rooms,
    day_program_enabled = excluded.day_program_enabled,
    day_program_scope = excluded.day_program_scope,
    open_access_enabled = excluded.open_access_enabled,
    open_access_requires_booking = excluded.open_access_requires_booking,
    cancel_credit_hours = excluded.cancel_credit_hours,
    updated_at = now(),
    updated_by = auth.uid()
  returning * into v;
  return v;
end;
$$;

revoke all on function private.upsert_org_operation_settings(uuid, text, boolean, boolean, text, boolean, boolean, int)
  from public, anon, authenticated;
grant execute on function private.upsert_org_operation_settings(uuid, text, boolean, boolean, text, boolean, boolean, int)
  to authenticated;

create or replace function public.upsert_org_operation_settings(
  p_org uuid,
  p_profile text,
  p_use_rooms boolean,
  p_day_program_enabled boolean,
  p_day_program_scope text,
  p_open_access_enabled boolean,
  p_open_access_requires_booking boolean,
  p_cancel_credit_hours int
) returns public.org_operation_settings
language sql
security invoker
set search_path = public
as $$
  select private.upsert_org_operation_settings(
    p_org, p_profile, p_use_rooms, p_day_program_enabled, p_day_program_scope,
    p_open_access_enabled, p_open_access_requires_booking, p_cancel_credit_hours
  );
$$;

revoke all on function public.upsert_org_operation_settings(uuid, text, boolean, boolean, text, boolean, boolean, int)
  from public, anon;
grant execute on function public.upsert_org_operation_settings(uuid, text, boolean, boolean, text, boolean, boolean, int)
  to authenticated;

create or replace function public.get_org_operation_settings(p_org uuid)
returns public.org_operation_settings
language plpgsql
security invoker
set search_path = public
as $$
declare
  v public.org_operation_settings;
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin','coach','reception','athlete']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select * into v from public.org_operation_settings where org_id = p_org;
  if not found then
    insert into public.org_operation_settings (org_id) values (p_org)
    on conflict (org_id) do nothing;
    select * into v from public.org_operation_settings where org_id = p_org;
  end if;
  return v;
end;
$$;

revoke all on function public.get_org_operation_settings(uuid) from public, anon;
grant execute on function public.get_org_operation_settings(uuid) to authenticated;

-- ——— rooms CRUD ———
create or replace function public.upsert_facility_room(
  p_org uuid, p_id uuid, p_name text, p_capacity int, p_is_active boolean, p_sort_order int
) returns public.facility_rooms
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.facility_rooms;
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if length(btrim(coalesce(p_name, ''))) not between 1 and 80
     or p_capacity not between 1 and 500 then
    raise exception 'INVALID_ROOM' using errcode = '22023';
  end if;
  if p_id is null then
    insert into public.facility_rooms (org_id, name, capacity, is_active, sort_order)
    values (p_org, btrim(p_name), p_capacity, coalesce(p_is_active, true), coalesce(p_sort_order, 0))
    returning * into v;
  else
    update public.facility_rooms
    set name = btrim(p_name),
        capacity = p_capacity,
        is_active = coalesce(p_is_active, is_active),
        sort_order = coalesce(p_sort_order, sort_order)
    where id = p_id and org_id = p_org
    returning * into v;
    if not found then raise exception 'ROOM_NOT_FOUND' using errcode = '22023'; end if;
  end if;
  return v;
end;
$$;

revoke all on function public.upsert_facility_room(uuid, uuid, text, int, boolean, int) from public, anon;
grant execute on function public.upsert_facility_room(uuid, uuid, text, int, boolean, int) to authenticated;

-- ——— activity type upsert ———
create or replace function public.upsert_activity_type(
  p_org uuid, p_id uuid, p_code text, p_name text, p_color text,
  p_requires_booking boolean, p_supports_day_program boolean, p_is_open_access boolean,
  p_is_active boolean, p_sort_order int
) returns public.activity_types
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.activity_types;
  v_color text := coalesce(nullif(btrim(p_color), ''), '#22834d');
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if length(btrim(coalesce(p_code, ''))) not between 1 and 40
     or length(btrim(coalesce(p_name, ''))) not between 1 and 80
     or v_color !~ '^#[0-9a-fA-F]{6}$' then
    raise exception 'INVALID_ACTIVITY_TYPE' using errcode = '22023';
  end if;
  if p_id is null then
    insert into public.activity_types (
      org_id, code, name, color, requires_booking, supports_day_program, is_open_access, is_active, sort_order
    ) values (
      p_org, lower(btrim(p_code)), btrim(p_name), v_color,
      coalesce(p_requires_booking, true), coalesce(p_supports_day_program, true),
      coalesce(p_is_open_access, false), coalesce(p_is_active, true), coalesce(p_sort_order, 0)
    ) returning * into v;
  else
    update public.activity_types
    set code = lower(btrim(p_code)),
        name = btrim(p_name),
        color = v_color,
        requires_booking = coalesce(p_requires_booking, requires_booking),
        supports_day_program = coalesce(p_supports_day_program, supports_day_program),
        is_open_access = coalesce(p_is_open_access, is_open_access),
        is_active = coalesce(p_is_active, is_active),
        sort_order = coalesce(p_sort_order, sort_order)
    where id = p_id and org_id = p_org
    returning * into v;
    if not found then raise exception 'ACTIVITY_TYPE_NOT_FOUND' using errcode = '22023'; end if;
  end if;
  return v;
end;
$$;

revoke all on function public.upsert_activity_type(uuid, uuid, text, text, text, boolean, boolean, boolean, boolean, int)
  from public, anon;
grant execute on function public.upsert_activity_type(uuid, uuid, text, text, text, boolean, boolean, boolean, boolean, int)
  to authenticated;

-- ——— day program upsert ———
create or replace function public.upsert_day_program(
  p_org uuid,
  p_date date,
  p_scope text,
  p_activity_type_id uuid,
  p_room_id uuid,
  p_title text,
  p_instructions text,
  p_prescription jsonb
) returns public.day_programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.day_programs;
  v_scope text := coalesce(p_scope, 'global');
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_scope not in ('global', 'activity_type', 'room') or p_date is null then
    raise exception 'INVALID_DAY_PROGRAM' using errcode = '22023';
  end if;
  if v_scope = 'global' then
    p_activity_type_id := null; p_room_id := null;
  elsif v_scope = 'activity_type' then
    if p_activity_type_id is null then raise exception 'INVALID_DAY_PROGRAM' using errcode = '22023'; end if;
    p_room_id := null;
  else
    if p_room_id is null then raise exception 'INVALID_DAY_PROGRAM' using errcode = '22023'; end if;
    p_activity_type_id := null;
  end if;

  insert into public.day_programs as d (
    org_id, program_date, scope, activity_type_id, room_id, title, instructions, prescription, updated_at
  ) values (
    p_org, p_date, v_scope, p_activity_type_id, p_room_id,
    left(coalesce(p_title, ''), 120), left(coalesce(p_instructions, ''), 4000),
    p_prescription, now()
  )
  on conflict (org_id, program_date) where scope = 'global'
  do update set
    title = excluded.title,
    instructions = excluded.instructions,
    prescription = excluded.prescription,
    updated_at = now()
  returning * into v;

  -- Unique partial indexes need separate upsert paths for type/room
  if v_scope = 'activity_type' then
    insert into public.day_programs (
      org_id, program_date, scope, activity_type_id, room_id, title, instructions, prescription, updated_at
    ) values (
      p_org, p_date, 'activity_type', p_activity_type_id, null,
      left(coalesce(p_title, ''), 120), left(coalesce(p_instructions, ''), 4000),
      p_prescription, now()
    )
    on conflict (org_id, program_date, activity_type_id) where scope = 'activity_type'
    do update set
      title = excluded.title,
      instructions = excluded.instructions,
      prescription = excluded.prescription,
      updated_at = now()
    returning * into v;
  elsif v_scope = 'room' then
    insert into public.day_programs (
      org_id, program_date, scope, activity_type_id, room_id, title, instructions, prescription, updated_at
    ) values (
      p_org, p_date, 'room', null, p_room_id,
      left(coalesce(p_title, ''), 120), left(coalesce(p_instructions, ''), 4000),
      p_prescription, now()
    )
    on conflict (org_id, program_date, room_id) where scope = 'room'
    do update set
      title = excluded.title,
      instructions = excluded.instructions,
      prescription = excluded.prescription,
      updated_at = now()
    returning * into v;
  end if;

  return v;
end;
$$;

revoke all on function public.upsert_day_program(uuid, date, text, uuid, uuid, text, text, jsonb)
  from public, anon;
grant execute on function public.upsert_day_program(uuid, date, text, uuid, uuid, text, text, jsonb)
  to authenticated;

-- Fix upsert_day_program: global path already inserted; avoid double-insert confusion
create or replace function public.upsert_day_program(
  p_org uuid,
  p_date date,
  p_scope text,
  p_activity_type_id uuid,
  p_room_id uuid,
  p_title text,
  p_instructions text,
  p_prescription jsonb
) returns public.day_programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.day_programs;
  v_scope text := coalesce(p_scope, 'global');
  v_title text := left(coalesce(p_title, ''), 120);
  v_instr text := left(coalesce(p_instructions, ''), 4000);
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin','coach']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_scope not in ('global', 'activity_type', 'room') or p_date is null then
    raise exception 'INVALID_DAY_PROGRAM' using errcode = '22023';
  end if;

  if v_scope = 'global' then
    insert into public.day_programs (
      org_id, program_date, scope, activity_type_id, room_id, title, instructions, prescription, updated_at
    ) values (p_org, p_date, 'global', null, null, v_title, v_instr, p_prescription, now())
    on conflict (org_id, program_date) where scope = 'global'
    do update set title = excluded.title, instructions = excluded.instructions,
                  prescription = excluded.prescription, updated_at = now()
    returning * into v;
  elsif v_scope = 'activity_type' then
    if p_activity_type_id is null then raise exception 'INVALID_DAY_PROGRAM' using errcode = '22023'; end if;
    insert into public.day_programs (
      org_id, program_date, scope, activity_type_id, room_id, title, instructions, prescription, updated_at
    ) values (p_org, p_date, 'activity_type', p_activity_type_id, null, v_title, v_instr, p_prescription, now())
    on conflict (org_id, program_date, activity_type_id) where scope = 'activity_type'
    do update set title = excluded.title, instructions = excluded.instructions,
                  prescription = excluded.prescription, updated_at = now()
    returning * into v;
  else
    if p_room_id is null then raise exception 'INVALID_DAY_PROGRAM' using errcode = '22023'; end if;
    insert into public.day_programs (
      org_id, program_date, scope, activity_type_id, room_id, title, instructions, prescription, updated_at
    ) values (p_org, p_date, 'room', null, p_room_id, v_title, v_instr, p_prescription, now())
    on conflict (org_id, program_date, room_id) where scope = 'room'
    do update set title = excluded.title, instructions = excluded.instructions,
                  prescription = excluded.prescription, updated_at = now()
    returning * into v;
  end if;
  return v;
end;
$$;

-- ——— resolve occurrence training ———
create or replace function public.resolve_occurrence_training(p_occurrence uuid)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_occ public.service_occurrences%rowtype;
  v_det public.service_occurrence_details%rowtype;
  v_settings public.org_operation_settings%rowtype;
  v_prog public.day_programs%rowtype;
  v_date date;
  v_tz text;
begin
  select * into v_occ from public.service_occurrences where id = p_occurrence;
  if not found then raise exception 'CLASS_NOT_FOUND' using errcode = '22023'; end if;
  if auth.uid() is null
     or not private.has_org_role(v_occ.org_id, array['owner','admin','coach','reception','athlete']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  select * into v_det from public.service_occurrence_details where occurrence_id = p_occurrence;
  if v_det.prescription is not null then
    return jsonb_build_object(
      'source', 'override',
      'title', nullif(v_det.training_title, ''),
      'instructions', nullif(v_det.training_instructions, ''),
      'prescription', v_det.prescription
    );
  end if;

  select * into v_settings from public.org_operation_settings where org_id = v_occ.org_id;
  if not found or not coalesce(v_settings.day_program_enabled, true) then
    return jsonb_build_object('source', 'none');
  end if;

  select coalesce(timezone, 'Europe/Madrid') into v_tz from public.organizations where id = v_occ.org_id;
  v_date := (v_occ.starts_at at time zone v_tz)::date;

  if v_settings.day_program_scope = 'room' and v_occ.room_id is not null then
    select * into v_prog from public.day_programs
     where org_id = v_occ.org_id and program_date = v_date and scope = 'room' and room_id = v_occ.room_id;
  elsif v_settings.day_program_scope = 'activity_type' and v_occ.activity_type_id is not null then
    select * into v_prog from public.day_programs
     where org_id = v_occ.org_id and program_date = v_date and scope = 'activity_type'
       and activity_type_id = v_occ.activity_type_id;
  end if;

  if not found then
    select * into v_prog from public.day_programs
     where org_id = v_occ.org_id and program_date = v_date and scope = 'global';
  end if;

  if found and (v_prog.prescription is not null or length(btrim(v_prog.title)) > 0) then
    return jsonb_build_object(
      'source', 'day_program',
      'day_program_id', v_prog.id,
      'title', nullif(v_prog.title, ''),
      'instructions', nullif(v_prog.instructions, ''),
      'prescription', v_prog.prescription
    );
  end if;

  return jsonb_build_object('source', 'none');
end;
$$;

revoke all on function public.resolve_occurrence_training(uuid) from public, anon;
grant execute on function public.resolve_occurrence_training(uuid) to authenticated;

-- ——— schedule bundle for apps ———
create or replace function public.get_org_schedule_bundle(p_org uuid)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_settings public.org_operation_settings;
begin
  if auth.uid() is null
     or not private.has_org_role(p_org, array['owner','admin','coach','reception','athlete']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  v_settings := public.get_org_operation_settings(p_org);
  return jsonb_build_object(
    'settings', to_jsonb(v_settings),
    'rooms', coalesce((
      select jsonb_agg(to_jsonb(r) order by r.sort_order, r.name)
      from public.facility_rooms r
      where r.org_id = p_org and r.is_active
    ), '[]'::jsonb),
    'activity_types', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.sort_order, t.name)
      from public.activity_types t
      where t.org_id = p_org and t.is_active
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_org_schedule_bundle(uuid) from public, anon;
grant execute on function public.get_org_schedule_bundle(uuid) to authenticated;

-- ——— create_service_series with series_id + open_access + room/type ———
drop function if exists private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text);
drop function if exists private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text,uuid,uuid);
drop function if exists public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text);
drop function if exists public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text,uuid,uuid);
drop function if exists public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int);

create function private.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int,
  p_color text default '#22834d',
  p_interval_days int default null,
  p_location text default null,
  p_description text default null,
  p_room_id uuid default null,
  p_activity_type_id uuid default null
) returns uuid[]
language plpgsql security definer set search_path='' as $$
declare
  generated uuid[] := '{}';
  next_start timestamptz; next_end timestamptz;
  idx int := 0; offset_days int := 0; new_id uuid;
  v_color text := coalesce(nullif(btrim(p_color), ''), '#22834d');
  v_loc text := left(btrim(coalesce(p_location, '')), 250);
  v_desc text := left(btrim(coalesce(p_description, '')), 2000);
  v_interval int := p_interval_days;
  v_repeat text := coalesce(p_repeat, 'none');
  v_coach uuid := p_coach;
  v_series uuid;
  v_settings public.org_operation_settings%rowtype;
  v_dur int;
begin
  if auth.uid() is null or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select * into v_settings from public.org_operation_settings where org_id = p_org;
  if p_kind = 'open_access' and coalesce(v_settings.open_access_enabled, false) is not true then
    raise exception 'OPEN_ACCESS_DISABLED' using errcode = '22023';
  end if;
  if p_room_id is not null and coalesce(v_settings.use_rooms, false) is not true then
    raise exception 'ROOMS_DISABLED' using errcode = '22023';
  end if;
  if v_coach is not null and not exists(
    select 1 from public.organization_memberships
    where organization_id = p_org and user_id = v_coach and status = 'active'
      and role in ('owner','admin','coach')
  ) then
    raise exception 'COACH_NOT_AUTHORIZED: el entrenador debe ser miembro activo (owner/admin/coach) del centro' using errcode = 'P0001';
  end if;
  if v_color !~ '^#[0-9a-fA-F]{6}$' then
    raise exception 'INVALID_COLOR' using errcode = '22023';
  end if;
  if v_interval is not null and v_interval not between 1 and 14 then
    raise exception 'INVALID_INTERVAL' using errcode = '22023';
  end if;
  if p_kind not in ('class','appointment','open_access')
     or (v_interval is null and v_repeat not in ('none','daily','weekly','weekdays'))
     or p_count not between 1 and 62
     or (v_repeat = 'none' and v_interval is null and p_count <> 1)
     or p_start <= now() or p_start > now() + interval '18 months'
     or p_end <= p_start or p_end > p_start + interval '12 hours'
     or length(btrim(coalesce(p_title, ''))) not between 2 and 120
     or p_capacity not between 1 and 200
     or (p_kind = 'appointment' and p_capacity <> 1)
  then
    raise exception 'INVALID_SERIES: revisa horario futuro, duración (máx 12h), repetición y aforo' using errcode = '22023';
  end if;

  v_dur := greatest(5, least(720, round(extract(epoch from (p_end - p_start)) / 60.0)::int));

  insert into public.service_series (
    org_id, activity_type_id, room_id, coach_user_id, kind, title, capacity, color,
    location_label, description, repeat_rule, interval_days, duration_minutes, is_active
  ) values (
    p_org, p_activity_type_id, p_room_id, v_coach, p_kind, btrim(p_title), p_capacity, v_color,
    v_loc, v_desc,
    case when v_interval is not null then 'daily' else v_repeat end,
    v_interval, v_dur, true
  ) returning id into v_series;

  while idx < p_count loop
    if v_interval is not null then
      offset_days := idx * v_interval;
    elsif v_repeat = 'none' then
      offset_days := 0;
    elsif v_repeat = 'daily' then
      offset_days := idx;
    elsif v_repeat = 'weekly' then
      offset_days := idx * 7;
    else
      if idx = 0 then offset_days := 0;
      else offset_days := offset_days + 1;
      end if;
      while extract(isodow from p_start + offset_days * interval '1 day') not between 1 and 5 loop
        offset_days := offset_days + 1;
      end loop;
    end if;
    next_start := p_start + offset_days * interval '1 day';
    next_end := p_end + offset_days * interval '1 day';
    if next_start > now() + interval '18 months' then
      raise exception 'SERIES_TOO_FAR' using errcode = '22023';
    end if;
    insert into public.service_occurrences(
      org_id, coach_user_id, kind, title, starts_at, ends_at, capacity,
      series_id, room_id, activity_type_id
    ) values (
      p_org, v_coach, p_kind, btrim(p_title), next_start, next_end, p_capacity,
      v_series, p_room_id, p_activity_type_id
    ) returning id into new_id;
    insert into public.service_occurrence_details(occurrence_id, org_id, description, location, color, repeat_rule)
    values (
      new_id, p_org, v_desc, v_loc, v_color,
      case when v_interval is not null then 'daily' else v_repeat end
    );
    generated := array_append(generated, new_id);
    idx := idx + 1;
  end loop;
  return generated;
end;
$$;

revoke all on function private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text,uuid,uuid)
  from public, anon, authenticated;
grant execute on function private.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text,uuid,uuid)
  to authenticated;

-- Public wrappers: keep old signature + new optional room/type
create function public.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int,
  p_color text default '#22834d',
  p_interval_days int default null,
  p_location text default null,
  p_description text default null,
  p_room_id uuid default null,
  p_activity_type_id uuid default null
) returns uuid[]
language sql security invoker set search_path=public as $$
  select private.create_service_series(
    p_org, p_coach, p_kind, p_title, p_start, p_end, p_capacity, p_repeat, p_count,
    p_color, p_interval_days, p_location, p_description, p_room_id, p_activity_type_id
  );
$$;

revoke all on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text,uuid,uuid)
  from public, anon;
grant execute on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text,uuid,uuid)
  to authenticated;

-- Compatibility overload without room/type
create function public.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int,
  p_color text default '#22834d',
  p_interval_days int default null,
  p_location text default null,
  p_description text default null
) returns uuid[]
language sql security invoker set search_path=public as $$
  select public.create_service_series(
    p_org, p_coach, p_kind, p_title, p_start, p_end, p_capacity, p_repeat, p_count,
    p_color, p_interval_days, p_location, p_description, null::uuid, null::uuid
  );
$$;

revoke all on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text)
  from public, anon;
grant execute on function public.create_service_series(uuid,uuid,text,text,timestamptz,timestamptz,int,text,int,text,int,text,text)
  to authenticated;

-- ——— cancel uses org cancel_credit_hours ———
create or replace function private.cancel_service_booking(p_booking uuid, p_request uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid := auth.uid();
  v_booking public.service_bookings%rowtype;
  v_occ public.service_occurrences%rowtype;
  v_refund boolean;
  v_was_booked boolean;
  v_next public.service_bookings%rowtype;
  v_pass public.service_passes%rowtype;
  v_hours int := 12;
begin
  if v_actor is null or p_request is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('service_cancel:' || p_booking::text, 0));
  select * into v_booking from public.service_bookings where id = p_booking for update;
  if not found then raise exception 'BOOKING_NOT_FOUND' using errcode = '22023'; end if;
  if not (
    private.owns_org_client(v_booking.org_id, v_booking.client_id)
    or private.has_org_role(v_booking.org_id, array['owner','admin']::public.organization_role[])
  ) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  if v_booking.status = 'cancelled' then return v_booking.credited_on_cancel; end if;
  if v_booking.status in ('attended','no_show') then
    raise exception 'ATTENDANCE_ALREADY_RECORDED' using errcode = '22023';
  end if;
  select * into v_occ from public.service_occurrences where id = v_booking.occurrence_id;
  select coalesce(cancel_credit_hours, 12) into v_hours
  from public.org_operation_settings where org_id = v_booking.org_id;
  v_was_booked := v_booking.status = 'booked';
  v_refund := v_was_booked and v_occ.starts_at > now() + make_interval(hours => v_hours);
  update public.service_bookings
  set status = 'cancelled', cancelled_at = now(),
      cancel_request_id = p_request, credited_on_cancel = v_refund
  where id = v_booking.id;
  if v_refund then
    update public.service_passes set remaining_credits = remaining_credits + 1 where id = v_booking.pass_id;
    insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
    values (v_booking.org_id, v_booking.pass_id, v_booking.id, 'cancellation_credit', 1, v_actor);
  end if;

  if v_occ.kind in ('class', 'open_access') then
    update public.professional_training_sessions
       set status = 'cancelled', updated_at = now()
     where org_id = v_booking.org_id
       and client_id = v_booking.client_id
       and source_occurrence_id = v_booking.occurrence_id
       and status = 'scheduled';
  end if;

  if v_was_booked and v_occ.status = 'active' and v_occ.starts_at > now() then
    select * into v_next from public.service_bookings
     where occurrence_id = v_booking.occurrence_id and status = 'waitlist'
     order by booked_at nulls last
     for update skip locked
     limit 1;
    if found then
      select * into v_pass from public.service_passes where id = v_next.pass_id for update;
      if found and v_pass.status = 'active' and v_pass.remaining_credits >= 1
         and v_pass.valid_until >= v_occ.starts_at and v_pass.valid_from <= v_occ.starts_at then
        update public.service_bookings set status = 'booked' where id = v_next.id;
        update public.service_passes set remaining_credits = remaining_credits - 1 where id = v_pass.id;
        insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
        values (v_next.org_id, v_pass.id, v_next.id, 'booking_debit', -1, v_actor);
        insert into public.business_client_notifications(org_id, client_id, sender_user_id, title, body)
        values (
          v_next.org_id, v_next.client_id, v_actor,
          'Plaza confirmada',
          'Ya estás apuntado a «' || v_occ.title || '». Había una plaza libre y has salido de la lista de espera.'
        );
        perform private.ensure_class_training_for_client(v_occ.id, v_next.client_id);
      end if;
    end if;
  end if;
  return v_refund;
end;
$$;

-- Book open_access with class passes
create or replace function private.pass_kind_matches_occurrence(p_pass_kind text, p_occ_kind text)
returns boolean language sql immutable as $$
  select case
    when p_occ_kind = 'open_access' then p_pass_kind in ('class', 'open_access')
    else p_pass_kind = p_occ_kind
  end;
$$;

create or replace function private.book_service_occurrence(p_occurrence uuid, p_pass uuid, p_request uuid)
returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_actor uuid := auth.uid();
  v_occ public.service_occurrences%rowtype;
  v_pass public.service_passes%rowtype;
  v_client_id uuid;
  v_booking uuid;
  v_existing public.service_bookings%rowtype;
  v_reserved int;
  v_status text;
  v_open_hours int;
  v_eff_cap int;
  v_room_cap int;
  v_settings public.org_operation_settings%rowtype;
begin
  if v_actor is null or p_request is null then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('service_book:' || p_request::text, 0));
  select * into v_existing from public.service_bookings where request_id = p_request;
  if found then
    if v_existing.occurrence_id <> p_occurrence or v_existing.pass_id <> p_pass or v_existing.requested_by <> v_actor then
      raise exception 'REQUEST_ID_REUSED' using errcode = '23505';
    end if;
    return v_existing.id;
  end if;
  select * into v_occ from public.service_occurrences where id = p_occurrence for update;
  if not found or v_occ.status <> 'active' or v_occ.starts_at <= now() then
    raise exception 'OCCURRENCE_UNAVAILABLE' using errcode = '22023';
  end if;
  select * into v_settings from public.org_operation_settings where org_id = v_occ.org_id;
  if v_occ.kind = 'open_access' and coalesce(v_settings.open_access_enabled, false) is not true then
    raise exception 'OPEN_ACCESS_DISABLED' using errcode = '22023';
  end if;
  if v_occ.kind = 'open_access' and coalesce(v_settings.open_access_requires_booking, true) is not true then
    raise exception 'OPEN_ACCESS_CHECKIN_ONLY' using errcode = '22023';
  end if;
  select class_booking_open_hours into v_open_hours
    from public.organizations where id = v_occ.org_id;
  v_open_hours := coalesce(v_open_hours, 168);
  if v_occ.starts_at > now() + make_interval(hours => v_open_hours) then
    raise exception 'BOOKING_NOT_OPEN_YET' using errcode = '22023';
  end if;
  if not private.has_org_role(v_occ.org_id, array['athlete']::public.organization_role[]) then
    raise exception 'NOT_A_MEMBER' using errcode = '42501';
  end if;
  select * into v_pass from public.service_passes where id = p_pass and org_id = v_occ.org_id for update;
  if not found
     or not private.pass_kind_matches_occurrence(v_pass.kind, v_occ.kind)
     or v_pass.status <> 'active'
     or v_pass.remaining_credits < 1 or v_pass.valid_from > v_occ.starts_at
     or v_pass.valid_until < v_occ.starts_at then
    raise exception 'NO_VALID_PASS' using errcode = '22023';
  end if;
  v_client_id := v_pass.client_id;
  if not private.owns_org_client(v_occ.org_id, v_client_id) then
    raise exception 'NOT_OWN_PASS' using errcode = '42501';
  end if;
  if exists(
    select 1 from public.service_bookings b
    where b.occurrence_id = v_occ.id and b.client_id = v_client_id
      and b.status in ('booked','waitlist','attended')
  ) then
    raise exception 'ALREADY_BOOKED' using errcode = '23505';
  end if;
  v_eff_cap := v_occ.capacity;
  if v_occ.room_id is not null then
    select capacity into v_room_cap from public.facility_rooms
     where id = v_occ.room_id and org_id = v_occ.org_id;
    if found then v_eff_cap := least(v_eff_cap, v_room_cap); end if;
  end if;
  select count(*) into v_reserved from public.service_bookings b
   where b.occurrence_id = v_occ.id and b.status in ('booked','attended');
  v_status := case when v_reserved >= v_eff_cap then 'waitlist' else 'booked' end;
  insert into public.service_bookings(org_id, occurrence_id, client_id, pass_id, requested_by, request_id, status)
  values (v_occ.org_id, v_occ.id, v_client_id, v_pass.id, v_actor, p_request, v_status)
  returning id into v_booking;
  if v_status = 'booked' then
    update public.service_passes set remaining_credits = remaining_credits - 1 where id = v_pass.id;
    insert into public.service_credit_ledger(org_id, pass_id, booking_id, event, amount, created_by)
    values (v_occ.org_id, v_pass.id, v_booking, 'booking_debit', -1, v_actor);
    if v_occ.kind = 'class' then
      perform private.ensure_class_training_for_client(v_occ.id, v_client_id);
    end if;
  end if;
  return v_booking;
end;
$$;

-- Coach overlap: skip when coach is null (open gym / unassigned)
create or replace function private.check_service_coach_schedule()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if new.coach_user_id is null then
    return new;
  end if;
  if not exists(
    select 1 from public.organization_memberships m
    where m.organization_id=new.org_id and m.user_id=new.coach_user_id
      and m.status='active'
      and m.role in ('owner','admin','coach')
  ) then raise exception 'COACH_NOT_ACTIVE' using errcode='42501'; end if;

  perform pg_advisory_xact_lock(hashtextextended('coach:'||new.coach_user_id::text,0));
  if new.status='active' and exists (
    select 1 from public.service_occurrences o
    where o.coach_user_id=new.coach_user_id
      and o.status='active' and o.id<>new.id
      and o.starts_at<new.ends_at and o.ends_at>new.starts_at
  ) then raise exception 'COACH_TIME_OVERLAP' using errcode='23P01'; end if;
  return new;
end;
$$;

notify pgrst, 'reload schema';
