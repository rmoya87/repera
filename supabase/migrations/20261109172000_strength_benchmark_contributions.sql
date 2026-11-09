-- Opt-in anonymous Amateur contributions from Repera tested 1RMs.
-- Inbox never stores user/device ids. Rate limit ledger is private per auth.uid().
-- Aggregation rebuilds SymmetricStrength rows when a cohort has ≥100 samples.

create table if not exists public.strength_benchmark_contribution_rate (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  day date not null,
  submits int not null default 0 check (submits >= 0),
  updated_at timestamptz not null default now()
);

alter table public.strength_benchmark_contribution_rate enable row level security;
revoke all on table public.strength_benchmark_contribution_rate
  from public, anon, authenticated;
grant select, insert, update, delete on table public.strength_benchmark_contribution_rate
  to service_role;

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
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  if p_lift is null or p_lift not in ('squat', 'benchPress', 'deadlift') then
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

comment on function public.submit_strength_benchmark_contribution(
  text, text, int, double precision, double precision, text
) is
  'Authenticated opt-in Amateur contribution; stores only lift/sex/bands/kg. No PII in inbox.';

-- Rebuild Amateur (SymmetricStrength) quantiles from inbox when a cohort is large enough.
create or replace function public.strength_benchmark_aggregate_contributions(
  p_min_samples int default 100
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_role text := coalesce(auth.role(), '');
  v_revision text := 'repera-optin-' || to_char(timezone('utc', now()), 'YYYY-MM-DD');
  v_updated int := 0;
  r record;
  v_id bigint;
  v_payload jsonb;
  v_quantiles jsonb;
  v_min double precision;
  v_max double precision;
  parts text[];
begin
  -- service_role only (clients must not rebuild published aggregates).
  if v_role is distinct from 'service_role' then
    raise exception 'forbidden';
  end if;
  if p_min_samples is null or p_min_samples < 100 then
    p_min_samples := 100;
  end if;

  for r in
    select
      i.lift,
      i.sex,
      i.body_weight_band,
      count(*)::int as n,
      percentile_cont(0.10) within group (order by i.weight_kg) as p10,
      percentile_cont(0.25) within group (order by i.weight_kg) as p25,
      percentile_cont(0.50) within group (order by i.weight_kg) as p50,
      percentile_cont(0.75) within group (order by i.weight_kg) as p75,
      percentile_cont(0.90) within group (order by i.weight_kg) as p90,
      percentile_cont(0.95) within group (order by i.weight_kg) as p95,
      percentile_cont(0.99) within group (order by i.weight_kg) as p99
    from public.strength_benchmark_contribution_inbox i
    where i.age_band = '14-100'
    group by i.lift, i.sex, i.body_weight_band
    having count(*) >= p_min_samples
  loop
    parts := string_to_array(r.body_weight_band, '-');
    if array_length(parts, 1) <> 2 then
      continue;
    end if;
    v_min := parts[1]::double precision;
    v_max := parts[2]::double precision;
    v_quantiles := jsonb_build_array(
      jsonb_build_object('percentile', 10, 'weightKg', round(r.p10::numeric, 3)),
      jsonb_build_object('percentile', 25, 'weightKg', round(r.p25::numeric, 3)),
      jsonb_build_object('percentile', 50, 'weightKg', round(r.p50::numeric, 3)),
      jsonb_build_object('percentile', 75, 'weightKg', round(r.p75::numeric, 3)),
      jsonb_build_object('percentile', 90, 'weightKg', round(r.p90::numeric, 3)),
      jsonb_build_object('percentile', 95, 'weightKg', round(r.p95::numeric, 3)),
      jsonb_build_object('percentile', 99, 'weightKg', round(r.p99::numeric, 3))
    );
    -- Require strictly increasing kg.
    if not (
      (v_quantiles->0->>'weightKg')::double precision < (v_quantiles->1->>'weightKg')::double precision
      and (v_quantiles->1->>'weightKg')::double precision < (v_quantiles->2->>'weightKg')::double precision
      and (v_quantiles->2->>'weightKg')::double precision < (v_quantiles->3->>'weightKg')::double precision
      and (v_quantiles->3->>'weightKg')::double precision < (v_quantiles->4->>'weightKg')::double precision
      and (v_quantiles->4->>'weightKg')::double precision < (v_quantiles->5->>'weightKg')::double precision
      and (v_quantiles->5->>'weightKg')::double precision < (v_quantiles->6->>'weightKg')::double precision
    ) then
      continue;
    end if;

    insert into public.strength_benchmark_distributions (
      lift, sex, equipment, age_min, age_max,
      body_weight_min_kg, body_weight_max_kg,
      source, source_revision, sample_count, quantiles, is_active, updated_at
    ) values (
      r.lift, r.sex, 'raw', 14, 100,
      v_min, v_max,
      'SymmetricStrength', v_revision, r.n, v_quantiles, true, now()
    )
    on conflict (lift, sex, equipment, age_min, age_max,
                 body_weight_min_kg, body_weight_max_kg, source, source_revision)
    do update set
      sample_count = excluded.sample_count,
      quantiles = excluded.quantiles,
      is_active = true,
      updated_at = now()
    returning id into v_id;

    v_payload := public.strength_benchmark_row_payload(
      (select d from public.strength_benchmark_distributions d where d.id = v_id)
    );
    insert into public.strength_benchmark_events (distribution_id, operation, payload)
    values (v_id, 'upsert', v_payload);
    v_updated := v_updated + 1;
  end loop;

  return jsonb_build_object('updated', v_updated, 'revision', v_revision);
end;
$function$;

revoke all on function public.strength_benchmark_aggregate_contributions(int) from public, anon, authenticated;
grant execute on function public.strength_benchmark_aggregate_contributions(int) to service_role;

comment on function public.strength_benchmark_aggregate_contributions(int) is
  'service_role: rebuild SymmetricStrength Amateur rows from opt-in inbox (≥100 samples/cohort).';
