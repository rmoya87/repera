-- Allow Amateur gym lifts beyond SBD (FitnessVolt Symmetric Strength seed).

alter table public.strength_benchmark_distributions
  drop constraint if exists strength_benchmark_distributions_lift_check;

alter table public.strength_benchmark_distributions
  add constraint strength_benchmark_distributions_lift_check
  check (lift in (
    'squat', 'benchPress', 'deadlift',
    'frontSquat', 'sumoDeadlift', 'powerClean',
    'inclineBenchPress', 'overheadPress', 'pushPress', 'snatchPress',
    'dip', 'chinUp', 'pullUp', 'pendlayRow'
  ));

alter table public.strength_benchmark_contribution_inbox
  drop constraint if exists strength_benchmark_contribution_inbox_lift_check;

alter table public.strength_benchmark_contribution_inbox
  add constraint strength_benchmark_contribution_inbox_lift_check
  check (lift in (
    'squat', 'benchPress', 'deadlift',
    'frontSquat', 'sumoDeadlift', 'powerClean',
    'inclineBenchPress', 'overheadPress', 'pushPress', 'snatchPress',
    'dip', 'chinUp', 'pullUp', 'pendlayRow'
  ));

create or replace function public.submit_strength_benchmark_contribution(
  p_lift text,
  p_sex text,
  p_age int,
  p_body_weight_kg double precision,
  p_weight_kg double precision,
  p_source_app text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
  v_age_band text;
  v_bw_band text;
  v_submits int;
  v_allowed text[] := array[
    'squat', 'benchPress', 'deadlift',
    'frontSquat', 'sumoDeadlift', 'powerClean',
    'inclineBenchPress', 'overheadPress', 'pushPress', 'snatchPress',
    'dip', 'chinUp', 'pullUp', 'pendlayRow'
  ];
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  if p_lift is null or not (p_lift = any (v_allowed)) then
    raise exception 'invalid lift';
  end if;
  if p_sex is null or p_sex not in ('female', 'male') then
    raise exception 'invalid sex';
  end if;
  if p_source_app is null or p_source_app not in ('ios', 'android') then
    raise exception 'invalid source_app';
  end if;
  if p_age is null or p_age < 14 or p_age > 100 then
    raise exception 'invalid age';
  end if;
  if p_body_weight_kg is null or p_body_weight_kg <= 0 or p_body_weight_kg >= 400 then
    raise exception 'invalid body weight';
  end if;
  if p_weight_kg is null or p_weight_kg <= 0 or p_weight_kg >= 1000 then
    raise exception 'invalid weight';
  end if;

  v_age_band := '14-100';
  v_bw_band := case
    when p_body_weight_kg < 59.0001 then '0-59.0001'
    when p_body_weight_kg < 66.0001 then '59.0001-66.0001'
    when p_body_weight_kg < 74.0001 then '66.0001-74.0001'
    when p_body_weight_kg < 83.0001 then '74.0001-83.0001'
    when p_body_weight_kg < 93.0001 then '83.0001-93.0001'
    when p_body_weight_kg < 105.0001 then '93.0001-105.0001'
    when p_body_weight_kg < 120.0001 then '105.0001-120.0001'
    else '120-400'
  end;

  insert into public.strength_benchmark_contribution_rate as r (owner_id, day, submits, updated_at)
  values (v_uid, v_today, 1, now())
  on conflict (owner_id) do update
    set day = excluded.day,
        submits = case
          when r.day = excluded.day then r.submits + 1
          else 1
        end,
        updated_at = now()
  returning submits into v_submits;

  if v_submits > 30 then
    raise exception 'rate limited';
  end if;

  insert into public.strength_benchmark_contribution_inbox (
    lift, sex, age_band, body_weight_band, weight_kg, source_app
  ) values (
    p_lift, p_sex, v_age_band, v_bw_band, round(p_weight_kg::numeric, 1), p_source_app
  );
end;
$function$;

revoke all on function public.submit_strength_benchmark_contribution(
  text, text, int, double precision, double precision, text
) from public, anon;
grant execute on function public.submit_strength_benchmark_contribution(
  text, text, int, double precision, double precision, text
) to authenticated;
