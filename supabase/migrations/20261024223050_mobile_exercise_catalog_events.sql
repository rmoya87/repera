-- Catálogo remoto incremental para Repera iOS (y futuros clientes).
-- La tabla profesional sigue siendo la única fuente editorial; las filas son un feed de cambios.
-- El CHECK anterior forzaba catalog_key = 'catalog:' || name.
-- Quitar esa dependencia permite renombrar conservando identidad y estadísticas.
alter table public.business_exercise_catalog drop constraint if exists catalog_key_valid;
alter table public.business_exercise_catalog
  add constraint mobile_catalog_key_format check (
    catalog_key like 'catalog:%' and length(catalog_key) > 8
    and length(name) between 2 and 150
  );

create or replace function public.repera_catalog_prevent_key_change()
returns trigger language plpgsql set search_path = ''
as $function$
begin
  if new.catalog_key is distinct from old.catalog_key then
    raise exception 'catalog_key is immutable; update the name instead';
  end if;
  return new;
end
$function$;

revoke all on function public.repera_catalog_prevent_key_change() from public, anon, authenticated;
drop trigger if exists repera_catalog_immutable_key on public.business_exercise_catalog;
create trigger repera_catalog_immutable_key
before update on public.business_exercise_catalog
for each row execute function public.repera_catalog_prevent_key_change();

alter table public.business_exercise_catalog
  add column if not exists mobile_description text,
  add column if not exists mobile_instructions text[],
  add column if not exists mobile_body_part text,
  add column if not exists mobile_muscle_group text,
  add column if not exists mobile_sport_tag text,
  add column if not exists is_active boolean not null default true;

create table if not exists public.mobile_exercise_catalog_events (
  id bigint generated always as identity primary key,
  catalog_key text not null,
  operation text not null check (operation in ('upsert', 'delete')),
  payload jsonb,
  occurred_at timestamptz not null default now(),
  constraint catalog_events_payload_check check (
    (operation = 'delete' and payload is null)
    or (operation = 'upsert' and jsonb_typeof(payload) = 'object')
  )
);
create index if not exists mobile_catalog_events_key_idx
  on public.mobile_exercise_catalog_events (catalog_key, id desc);

alter table public.mobile_exercise_catalog_events enable row level security;
revoke all on table public.mobile_exercise_catalog_events from public, anon, authenticated;
grant select on table public.mobile_exercise_catalog_events to authenticated;
-- Las escrituras editoriales pueden realizarse mediante un backend con service_role.
grant insert on table public.mobile_exercise_catalog_events to service_role;
grant usage, select on sequence public.mobile_exercise_catalog_events_id_seq to service_role;
drop policy if exists mobile_catalog_events_authenticated_read on public.mobile_exercise_catalog_events;
create policy mobile_catalog_events_authenticated_read
  on public.mobile_exercise_catalog_events for select to authenticated using (true);

-- Ejecutada exclusivamente por triggers sobre las tablas editoriales. No es una API de escritura.
create or replace function public.repera_emit_mobile_catalog_event(p_catalog_key text)
returns void language plpgsql security invoker set search_path = ''
as $function$
declare
  v_payload jsonb;
begin
  select jsonb_build_object(
    'name', b.name,
    'category', b.category,
    'display_name_en', b.display_name_en,
    'aliases', coalesce(m.aliases, '{}'::text[]),
    'primary_muscles', coalesce(m.primary_muscles, '{}'::text[]),
    'secondary_muscles', coalesce(m.secondary_muscles, '{}'::text[]),
    'equipment', coalesce(m.equipment, '{}'::text[]),
    'native_catalog_id', m.native_catalog_id,
    'description', b.mobile_description,
    'instructions', coalesce(b.mobile_instructions, '{}'::text[]),
    'body_part', b.mobile_body_part,
    'muscle_group', b.mobile_muscle_group,
    'sport_tag', b.mobile_sport_tag,
    'is_active', b.is_active
  ) into v_payload
  from public.business_exercise_catalog b
  left join public.training_exercise_metadata m on m.catalog_key = b.catalog_key
  where b.catalog_key = p_catalog_key;

  if v_payload is null or v_payload->>'is_active' = 'false' then
    insert into public.mobile_exercise_catalog_events (catalog_key, operation, payload)
    values (p_catalog_key, 'delete', null);
  else
    insert into public.mobile_exercise_catalog_events (catalog_key, operation, payload)
    values (p_catalog_key, 'upsert', v_payload);
  end if;
end
$function$;

create or replace function public.repera_mobile_catalog_change_trigger()
returns trigger language plpgsql security invoker set search_path = ''
as $function$
begin
  if tg_op = 'DELETE' then
    perform public.repera_emit_mobile_catalog_event(old.catalog_key);
  else
    perform public.repera_emit_mobile_catalog_event(new.catalog_key);
    if tg_op = 'UPDATE' and new.catalog_key is distinct from old.catalog_key then
      perform public.repera_emit_mobile_catalog_event(old.catalog_key);
    end if;
  end if;
  return null;
end
$function$;

revoke all on function public.repera_emit_mobile_catalog_event(text) from public, anon, authenticated;
revoke all on function public.repera_mobile_catalog_change_trigger() from public, anon, authenticated;
grant execute on function public.repera_emit_mobile_catalog_event(text) to service_role;
grant execute on function public.repera_mobile_catalog_change_trigger() to service_role;

drop trigger if exists repera_mobile_catalog_business_changed on public.business_exercise_catalog;
create trigger repera_mobile_catalog_business_changed
after insert or update or delete on public.business_exercise_catalog
for each row execute function public.repera_mobile_catalog_change_trigger();

drop trigger if exists repera_mobile_catalog_metadata_changed on public.training_exercise_metadata;
create trigger repera_mobile_catalog_metadata_changed
after insert or update or delete on public.training_exercise_metadata
for each row execute function public.repera_mobile_catalog_change_trigger();

-- Snapshot inicial: el cliente que arranca en cursor 0 recibe el catálogo completo.
insert into public.mobile_exercise_catalog_events (catalog_key, operation, payload)
select b.catalog_key, 'upsert', jsonb_build_object(
  'name', b.name,
  'category', b.category,
  'display_name_en', b.display_name_en,
  'aliases', coalesce(m.aliases, '{}'::text[]),
  'primary_muscles', coalesce(m.primary_muscles, '{}'::text[]),
  'secondary_muscles', coalesce(m.secondary_muscles, '{}'::text[]),
  'equipment', coalesce(m.equipment, '{}'::text[]),
  'native_catalog_id', m.native_catalog_id,
  'description', b.mobile_description,
  'instructions', coalesce(b.mobile_instructions, '{}'::text[]),
  'body_part', b.mobile_body_part,
  'muscle_group', b.mobile_muscle_group,
  'sport_tag', b.mobile_sport_tag,
  'is_active', b.is_active
)
from public.business_exercise_catalog b
left join public.training_exercise_metadata m on m.catalog_key = b.catalog_key
where not exists (select 1 from public.mobile_exercise_catalog_events limit 1)
order by b.catalog_key;
