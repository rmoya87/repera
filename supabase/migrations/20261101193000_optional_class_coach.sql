-- Clases sin entrenador obligatorio (coach_user_id nullable).
alter table public.service_occurrences
  alter column coach_user_id drop not null;

create or replace function private.check_service_coach_schedule()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  -- Sin coach: no hay solapes que validar.
  if new.coach_user_id is null then
    return new;
  end if;
  if not exists(
    select 1 from public.organization_memberships m
    where m.organization_id = new.org_id and m.user_id = new.coach_user_id
      and m.status = 'active'
      and m.role in ('owner','admin','coach')
  ) then
    raise exception 'COACH_NOT_ACTIVE' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('coach:' || new.coach_user_id::text, 0));
  if new.status = 'active' and exists (
    select 1 from public.service_occurrences o
    where o.coach_user_id = new.coach_user_id
      and o.status = 'active' and o.id <> new.id
      and o.starts_at < new.ends_at and o.ends_at > new.starts_at
  ) then
    raise exception 'COACH_TIME_OVERLAP' using errcode = '23P01';
  end if;
  return new;
end;
$$;

-- create_service_series: coach opcional
create or replace function private.create_service_series(
  p_org uuid, p_coach uuid, p_kind text, p_title text,
  p_start timestamptz, p_end timestamptz,
  p_capacity int, p_repeat text, p_count int,
  p_color text default '#22834d',
  p_interval_days int default null,
  p_location text default null,
  p_description text default null
) returns uuid[]
language plpgsql security definer set search_path='' as $$
declare
  generated uuid[] := '{}';
  next_start timestamptz; next_end timestamptz;
  idx int := 0; offset_days int := 0; new_id uuid;
  v_color text := coalesce(nullif(btrim(p_color), ''), '#22834d');
  v_loc text := left(nullif(btrim(coalesce(p_location, '')), ''), 250);
  v_desc text := left(nullif(btrim(coalesce(p_description, '')), ''), 2000);
  v_interval int := p_interval_days;
  v_repeat text := coalesce(p_repeat, 'none');
  v_coach uuid := p_coach;
begin
  if auth.uid() is null or not private.has_org_role(p_org, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
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
  if p_kind not in ('class','appointment')
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
    insert into public.service_occurrences(org_id, coach_user_id, kind, title, starts_at, ends_at, capacity)
    values (p_org, v_coach, p_kind, btrim(p_title), next_start, next_end, p_capacity)
    returning id into new_id;
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

notify pgrst, 'reload schema';
