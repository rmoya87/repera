-- Quitar el entreno asociado a una clase (plantilla + fan-out a inscritos).

create or replace function private.clear_class_training(p_occurrence uuid)
returns int
language plpgsql
security definer
set search_path to ''
as $$
declare
  v public.service_occurrences%rowtype;
  cleared int := 0;
begin
  select * into v from public.service_occurrences where id = p_occurrence;
  if not found or v.kind <> 'class' or v.status <> 'active' or v.starts_at <= now() then
    raise exception 'CLASS_NOT_EDITABLE' using errcode = '22023';
  end if;
  if not private.has_org_role(v.org_id, array['owner','admin']::public.organization_role[]) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  update public.service_occurrence_details
     set training_title = null,
         training_instructions = '',
         prescription = null
   where occurrence_id = p_occurrence
     and org_id = v.org_id;

  update public.professional_training_sessions
     set status = 'cancelled',
         updated_at = now()
   where org_id = v.org_id
     and source_occurrence_id = p_occurrence
     and status = 'scheduled';

  get diagnostics cleared = row_count;
  return cleared;
end;
$$;

revoke all on function private.clear_class_training(uuid)
  from public, anon, authenticated;
grant execute on function private.clear_class_training(uuid)
  to authenticated;

create or replace function public.clear_class_training(p_occurrence uuid)
returns int
language sql
security invoker
set search_path to ''
as $$
  select private.clear_class_training(p_occurrence);
$$;

revoke all on function public.clear_class_training(uuid)
  from public, anon;
grant execute on function public.clear_class_training(uuid)
  to authenticated;

notify pgrst, 'reload schema';
