-- Serializa las escrituras del feed antes de asignar identity IDs.
-- Sin ello dos transacciones concurrentes pueden confirmar revisiones en orden distinto
-- a sus IDs y un cliente con cursor alto se saltaría la confirmación tardía.
create or replace function public.repera_emit_mobile_catalog_event(p_catalog_key text)
returns void language plpgsql security invoker set search_path = ''
as $function$
declare
  v_payload jsonb;
begin
  -- Commit-ordered append-only cursor: avoid missing a late-committing smaller ID.
  perform pg_catalog.pg_advisory_xact_lock(14542876, 270501);
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

