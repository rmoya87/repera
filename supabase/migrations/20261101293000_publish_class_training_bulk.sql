-- Asignar el mismo entreno a varias classes (occurrences) de un día / selección.

create or replace function private.publish_class_training_bulk(
  p_occurrences uuid[],
  p_title text,
  p_instructions text,
  p_prescription jsonb
) returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  ids uuid[];
  occ_id uuid;
  v public.service_occurrences%rowtype;
  org uuid;
  title text := btrim(coalesce(p_title, ''));
  instructions text := coalesce(p_instructions, '');
  occ_count int := 0;
  athlete_count int := 0;
  n int;
begin
  if p_occurrences is null or cardinality(p_occurrences) < 1 then
    raise exception 'NO_OCCURRENCES' using errcode = '22023';
  end if;
  if cardinality(p_occurrences) > 40 then
    raise exception 'TOO_MANY_OCCURRENCES' using errcode = '22023';
  end if;
  -- Deduplicar preservando orden aproximado.
  select array_agg(distinct x) into ids from unnest(p_occurrences) as t(x);
  if ids is null or cardinality(ids) < 1 then
    raise exception 'NO_OCCURRENCES' using errcode = '22023';
  end if;
  if length(title) not between 2 and 120
     or length(instructions) > 10000
     or not private.validate_professional_prescription(p_prescription) then
    raise exception 'INVALID_PRESCRIPTION' using errcode = '22023';
  end if;

  foreach occ_id in array ids loop
    select * into v from public.service_occurrences where id = occ_id;
    if not found or v.status <> 'active' or v.starts_at <= now() or v.kind <> 'class' then
      raise exception 'CLASS_NOT_EDITABLE' using errcode = '22023';
    end if;
    if org is null then
      org := v.org_id;
      if not private.has_org_role(org, array['owner','admin']::public.organization_role[]) then
        raise exception 'NOT_AUTHORIZED' using errcode = '42501';
      end if;
    elsif v.org_id <> org then
      raise exception 'MIXED_ORGS' using errcode = '22023';
    end if;
  end loop;

  foreach occ_id in array ids loop
    n := private.publish_class_training(occ_id, title, instructions, p_prescription);
    occ_count := occ_count + 1;
    athlete_count := athlete_count + coalesce(n, 0);
  end loop;

  return jsonb_build_object(
    'occurrences', occ_count,
    'athletes', athlete_count
  );
end;
$$;

revoke all on function private.publish_class_training_bulk(uuid[], text, text, jsonb)
  from public, anon, authenticated;
grant execute on function private.publish_class_training_bulk(uuid[], text, text, jsonb)
  to authenticated;

create or replace function public.publish_class_training_bulk(
  p_occurrences uuid[],
  p_title text,
  p_instructions text,
  p_prescription jsonb
) returns jsonb
language sql
security invoker
set search_path to ''
as $$
  select private.publish_class_training_bulk(p_occurrences, p_title, p_instructions, p_prescription);
$$;

revoke all on function public.publish_class_training_bulk(uuid[], text, text, jsonb)
  from public, anon;
grant execute on function public.publish_class_training_bulk(uuid[], text, text, jsonb)
  to authenticated;

notify pgrst, 'reload schema';
