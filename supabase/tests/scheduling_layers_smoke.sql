-- Smoke (manual / CI SQL): scheduling layers shape.
-- Does not mutate production; run inside a transaction with ROLLBACK.

begin;

select to_regclass('public.org_operation_settings') is not null as has_settings;
select to_regclass('public.facility_rooms') is not null as has_rooms;
select to_regclass('public.activity_types') is not null as has_types;
select to_regclass('public.service_series') is not null as has_series;
select to_regclass('public.day_programs') is not null as has_day_programs;

select count(*) > 0 as has_kind_open_access
from information_schema.check_constraints
where constraint_name = 'service_occurrences_kind_check'
  and check_clause ilike '%open_access%';

select exists(
  select 1 from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'resolve_occurrence_training'
) as has_resolve;

select exists(
  select 1 from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'get_org_schedule_bundle'
) as has_bundle;

select exists(
  select 1 from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'upsert_org_operation_settings'
) as has_upsert_settings;

rollback;
