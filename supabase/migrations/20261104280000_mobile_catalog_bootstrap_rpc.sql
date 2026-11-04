-- Bootstrap del catálogo móvil en 1 round-trip (estado actual).
-- Evita rejugar miles de eventos en cold start / lag grande.
-- Los deltas siguen yendo por mobile_exercise_catalog_events.

create or replace function public.mobile_exercise_catalog_bootstrap()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $function$
  select jsonb_build_object(
    'revision', coalesce((select max(id) from public.mobile_exercise_catalog_events), 0),
    'entries', coalesce((
      select jsonb_object_agg(
        b.catalog_key,
        jsonb_build_object(
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
        )
      )
      from public.business_exercise_catalog b
      left join public.training_exercise_metadata m on m.catalog_key = b.catalog_key
    ), '{}'::jsonb)
  );
$function$;

revoke all on function public.mobile_exercise_catalog_bootstrap() from public, anon;
grant execute on function public.mobile_exercise_catalog_bootstrap() to authenticated;

comment on function public.mobile_exercise_catalog_bootstrap() is
  'Instantánea canónica del catálogo editorial + revision del feed; uso cold-start / catch-up.';
