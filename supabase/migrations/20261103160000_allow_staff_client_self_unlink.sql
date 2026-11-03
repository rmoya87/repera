-- Permite dejar de ser cliente sin perder el rol de propietario/staff.
-- El actor solo puede desvincular SU ficha activa o su membresía athlete.
-- Mantiene el historial (reservas, pagos y entrenamientos realizados) para auditoría.
create or replace function private.leave_org_as_athlete(p_org uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null or p_org is null then
    raise exception 'NOT_LINKED_CLIENT' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('athlete_leave:' || p_org::text || ':' || v_actor::text, 0)
  );

  -- Un propietario o miembro de staff puede ser también cliente. Su rol
  -- administrativo, por sí solo, NO le autoriza a borrar otras fichas.
  if not exists (
    select 1 from public.clients c
    where c.org_id = p_org and c.user_id = v_actor and c.status = 'active'
  ) and not exists (
    select 1 from public.organization_memberships m
    where m.organization_id = p_org and m.user_id = v_actor
      and m.role = 'athlete' and m.status = 'active'
  ) then
    raise exception 'NOT_LINKED_CLIENT' using errcode = '42501';
  end if;

  -- Reservas y lista de espera futuras: liberar aforo sin borrar auditoría.
  update public.service_bookings b
  set status = 'cancelled',
      cancelled_at = now(),
      cancel_request_id = gen_random_uuid(),
      credited_on_cancel = false
  where b.org_id = p_org
    and b.status in ('booked', 'waitlist')
    and exists (
      select 1 from public.clients c
      where c.id = b.client_id and c.org_id = p_org and c.user_id = v_actor
    )
    and exists (
      select 1 from public.service_occurrences o
      where o.id = b.occurrence_id and o.starts_at > now()
    );

  update public.athlete_workout_sharing
  set enabled = false, updated_at = now()
  where org_id = p_org and athlete_id = v_actor;

  update public.athlete_business_history_consents
  set revoked_at = now()
  where org_id = p_org and athlete_user_id = v_actor and revoked_at is null;

  update public.professional_training_sessions s
  set status = 'cancelled', updated_at = now()
  where s.org_id = p_org and s.status = 'scheduled'
    and exists (
      select 1 from public.clients c
      where c.id = s.client_id and c.org_id = p_org and c.user_id = v_actor
    );

  update public.service_passes p
  set status = 'cancelled'
  where p.org_id = p_org and p.status in ('active', 'paused')
    and exists (
      select 1 from public.clients c
      where c.id = p.client_id and c.org_id = p_org and c.user_id = v_actor
    );

  -- Retener ficha CRM e histórico económico, pero retirar la vinculación.
  update public.clients
  set status = 'cancelled', user_id = null, updated_at = now()
  where org_id = p_org and user_id = v_actor;

  -- Únicamente se revoca la membresía athlete; owner/admin/coach/reception
  -- siguen activos y conservan intactos sus permisos de gestión.
  update public.organization_memberships
  set status = 'revoked'
  where organization_id = p_org and user_id = v_actor
    and role = 'athlete' and status = 'active';

  return true;
end
$$;

revoke all on function private.leave_org_as_athlete(uuid)
  from public, anon, authenticated;
grant execute on function private.leave_org_as_athlete(uuid) to authenticated;

-- La RPC pública existente conserva su firma, grants y semántica.
notify pgrst, 'reload schema';
