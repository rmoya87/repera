-- Catálogo móvil: campos canónicos en el feed + claves de arte remoto.
-- La app transforma arrays (músculos/equipo/alternatives/art_keys) a UI.
-- Aplicada en remoto uvzgujlrqohreoucirms (2026-11-04) tras confirmación humana.

alter table public.business_exercise_catalog
  add column if not exists mobile_art_keys text[] not null default '{}';

alter table public.business_exercise_catalog
  drop constraint if exists business_exercise_catalog_mobile_art_keys_len;
alter table public.business_exercise_catalog
  add constraint business_exercise_catalog_mobile_art_keys_len
  check (cardinality(mobile_art_keys) <= 12);

comment on column public.business_exercise_catalog.mobile_art_keys is
  'Stems JPG canónicos (hero primero, luego frames). Vacío = solo arte del binario vía nameMap.';

create or replace function public.repera_emit_mobile_catalog_event(p_catalog_key text)
returns void language plpgsql security invoker set search_path = ''
as $function$
declare
  v_payload jsonb;
begin
  perform pg_catalog.pg_advisory_xact_lock(14542876, 270501);
  select jsonb_build_object(
    'name', b.name,
    'category', b.category,
    'display_name_en', b.display_name_en,
    'aliases', coalesce(m.aliases, '{}'::text[]),
    'primary_muscles', coalesce(m.primary_muscles, '{}'::text[]),
    'secondary_muscles', coalesce(m.secondary_muscles, '{}'::text[]),
    'equipment', coalesce(m.equipment, '{}'::text[]),
    'equipment_override', b.mobile_equipment,
    'native_catalog_id', m.native_catalog_id,
    'description', b.mobile_description,
    'instructions', coalesce(b.mobile_instructions, '{}'::text[]),
    'body_part', b.mobile_body_part,
    'muscle_group', b.mobile_muscle_group,
    'sport_tag', b.mobile_sport_tag,
    'skill_level', m.skill_level,
    'movement_pattern', m.movement_pattern,
    'alternatives', coalesce(m.alternatives, '{}'::text[]),
    'art_keys', coalesce(b.mobile_art_keys, '{}'::text[]),
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

revoke all on function public.repera_emit_mobile_catalog_event(text) from public, anon, authenticated;
grant execute on function public.repera_emit_mobile_catalog_event(text) to service_role;

-- Bucket público de lectura para JPG de ejercicios (escritura solo service_role / dashboard).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'exercise-art',
  'exercise-art',
  true,
  5242880,
  array['image/jpeg']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists repera_exercise_art_public_read on storage.objects;
create policy repera_exercise_art_public_read
  on storage.objects for select
  to public
  using (bucket_id = 'exercise-art');

-- Reemitir fichas activas para que clientes con cursor avanzado reciban los campos nuevos.
do $reemit$
declare
  r record;
begin
  for r in
    select catalog_key
    from public.business_exercise_catalog
    where is_active = true
    order by catalog_key
  loop
    perform public.repera_emit_mobile_catalog_event(r.catalog_key);
  end loop;
end
$reemit$;
