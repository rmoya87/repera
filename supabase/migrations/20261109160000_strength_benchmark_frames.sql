-- Strength reference frames (Amateur / Élite) — schema + bootstrap/delta RPCs.
-- Bundled strength_benchmarks.json remains offline bootstrap until a human applies
-- this migration and seeds rows. Do NOT apply remotely without confirmation.
-- Contribution upload is stubbed (opt-in later); no client writes in this migration.

create table if not exists public.strength_benchmark_distributions (
  id bigint generated always as identity primary key,
  lift text not null check (lift in ('squat', 'benchPress', 'deadlift')),
  sex text not null check (sex in ('female', 'male')),
  equipment text not null check (equipment in ('raw', 'wraps', 'singlePly', 'multiPly')),
  age_min int not null check (age_min >= 14),
  age_max int not null check (age_max <= 100 and age_max >= age_min),
  body_weight_min_kg double precision not null,
  body_weight_max_kg double precision not null
    check (body_weight_max_kg > body_weight_min_kg),
  source text not null check (source in ('OpenPowerlifting', 'SymmetricStrength')),
  source_revision text not null check (length(source_revision) between 1 and 120),
  sample_count int not null check (sample_count >= 0),
  quantiles jsonb not null check (jsonb_typeof(quantiles) = 'array'),
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint strength_benchmark_unique_cohort unique (
    lift, sex, equipment, age_min, age_max,
    body_weight_min_kg, body_weight_max_kg, source, source_revision
  )
);

create index if not exists strength_benchmark_source_idx
  on public.strength_benchmark_distributions (source, is_active);

alter table public.strength_benchmark_distributions enable row level security;
revoke all on table public.strength_benchmark_distributions from public, anon, authenticated;
grant select on table public.strength_benchmark_distributions to authenticated;
grant insert, update, delete on table public.strength_benchmark_distributions to service_role;
grant usage, select on sequence public.strength_benchmark_distributions_id_seq to service_role;

drop policy if exists strength_benchmark_authenticated_read
  on public.strength_benchmark_distributions;
create policy strength_benchmark_authenticated_read
  on public.strength_benchmark_distributions
  for select to authenticated
  using (is_active);

create table if not exists public.strength_benchmark_events (
  id bigint generated always as identity primary key,
  distribution_id bigint references public.strength_benchmark_distributions(id) on delete set null,
  operation text not null check (operation in ('upsert', 'delete')),
  payload jsonb,
  occurred_at timestamptz not null default now(),
  constraint strength_benchmark_events_payload_check check (
    (operation = 'delete' and payload is null)
    or (operation = 'upsert' and jsonb_typeof(payload) = 'object')
  )
);

create index if not exists strength_benchmark_events_id_idx
  on public.strength_benchmark_events (id desc);

alter table public.strength_benchmark_events enable row level security;
revoke all on table public.strength_benchmark_events from public, anon, authenticated;
grant select on table public.strength_benchmark_events to authenticated;
grant insert on table public.strength_benchmark_events to service_role;
grant usage, select on sequence public.strength_benchmark_events_id_seq to service_role;

drop policy if exists strength_benchmark_events_authenticated_read
  on public.strength_benchmark_events;
create policy strength_benchmark_events_authenticated_read
  on public.strength_benchmark_events
  for select to authenticated
  using (true);

create or replace function public.strength_benchmark_row_payload(
  r public.strength_benchmark_distributions
) returns jsonb
language sql
stable
security invoker
set search_path = ''
as $function$
  select jsonb_build_object(
    'id', r.id,
    'cohort', jsonb_build_object(
      'lift', r.lift,
      'sex', r.sex,
      'equipment', r.equipment,
      'ageMin', r.age_min,
      'ageMax', r.age_max,
      'bodyWeightMinKg', r.body_weight_min_kg,
      'bodyWeightMaxKg', r.body_weight_max_kg
    ),
    'source', r.source,
    'sourceRevision', r.source_revision,
    'sampleCount', r.sample_count,
    'quantiles', r.quantiles,
    'isActive', r.is_active
  );
$function$;

revoke all on function public.strength_benchmark_row_payload(public.strength_benchmark_distributions)
  from public, anon;
grant execute on function public.strength_benchmark_row_payload(public.strength_benchmark_distributions)
  to authenticated, service_role;

create or replace function public.strength_benchmark_bootstrap()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $function$
  select jsonb_build_object(
    'revision', coalesce((select max(id) from public.strength_benchmark_events), 0),
    'distributions', coalesce((
      select jsonb_agg(public.strength_benchmark_row_payload(d) order by d.id)
      from public.strength_benchmark_distributions d
      where d.is_active
    ), '[]'::jsonb)
  );
$function$;

revoke all on function public.strength_benchmark_bootstrap() from public, anon;
grant execute on function public.strength_benchmark_bootstrap() to authenticated;

comment on function public.strength_benchmark_bootstrap() is
  'Instantánea de cuantiles de fuerza + revision; cold-start / catch-up. Sin PII.';

create or replace function public.strength_benchmark_delta(p_after_revision bigint)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $function$
  select jsonb_build_object(
    'revision', coalesce((select max(id) from public.strength_benchmark_events), 0),
    'events', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', e.id,
          'operation', e.operation,
          'payload', e.payload,
          'occurredAt', e.occurred_at
        )
        order by e.id
      )
      from public.strength_benchmark_events e
      where e.id > coalesce(p_after_revision, 0)
    ), '[]'::jsonb)
  );
$function$;

revoke all on function public.strength_benchmark_delta(bigint) from public, anon;
grant execute on function public.strength_benchmark_delta(bigint) to authenticated;

comment on function public.strength_benchmark_delta(bigint) is
  'Feed incremental de cambios de cuantiles tras una revision; authenticated read-only.';

-- Opt-in contribution inbox (disabled for clients). Service role only until product ships.
create table if not exists public.strength_benchmark_contribution_inbox (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  lift text not null check (lift in ('squat', 'benchPress', 'deadlift')),
  sex text not null check (sex in ('female', 'male')),
  age_band text not null,
  body_weight_band text not null,
  weight_kg double precision not null check (weight_kg > 0 and weight_kg < 1000),
  source_app text not null check (source_app in ('ios', 'android')),
  -- No user id / device id / location. Aggregates only after human review.
  notes text
);

alter table public.strength_benchmark_contribution_inbox enable row level security;
revoke all on table public.strength_benchmark_contribution_inbox
  from public, anon, authenticated;
grant select, insert, delete on table public.strength_benchmark_contribution_inbox to service_role;
grant usage, select on sequence public.strength_benchmark_contribution_inbox_id_seq to service_role;
