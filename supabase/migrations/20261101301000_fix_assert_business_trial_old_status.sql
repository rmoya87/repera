-- Fix: record "old" has no field "status"
-- private.assert_business_trial se comparte entre tablas CON status
-- (service_occurrences, professional_training_sessions) y SIN status
-- (professional_workout_templates, service_bookings INSERT, groups, …).
-- Acceder a old.status con AND no es seguro en todos los caminos;
-- anidar por tg_table_name evita evaluar el campo en tablas ajenas.

create or replace function private.assert_business_trial()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  -- Tras caducar la prueba, seguir permitiendo cancelaciones.
  if tg_op = 'UPDATE' then
    if tg_table_name = 'service_occurrences' then
      if old.status = 'active' and new.status = 'cancelled' then
        return new;
      end if;
    elsif tg_table_name = 'professional_training_sessions' then
      if old.status = 'scheduled' and new.status = 'cancelled' then
        return new;
      end if;
    end if;
  end if;

  if not exists (
    select 1
    from public.organization_trials t
    where t.org_id = new.org_id
      and (
        t.trial_ends_at > now()
        or (t.paid_until > now() and t.paid_plan is not null)
      )
  ) then
    raise exception 'TRIAL_EXPIRED_PAYMENT_REQUIRED' using errcode = '42501';
  end if;

  return new;
end;
$$;
