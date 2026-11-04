-- Entrega push real: reintentos acotados con backoff, cierre con lease, tokens inválidos
-- y registro validado por plataforma. Idempotente; no modifica filas existentes.

alter table public.notification_outbox
  add column if not exists attempt_count int not null default 0,
  add column if not exists next_attempt_at timestamptz,
  add column if not exists last_error_code text;

alter table public.device_push_tokens
  add column if not exists invalidated_reason text;

create index if not exists notification_outbox_user_idx
  on public.notification_outbox(user_id);
create index if not exists notification_outbox_open_booking_idx
  on public.notification_outbox(booking_id) where status in ('pending','claimed');
create index if not exists notification_attempts_outbox_idx
  on public.notification_attempts(outbox_id);
create index if not exists notification_attempts_device_idx
  on public.notification_attempts(device_token_id) where device_token_id is not null;
create index if not exists device_push_tokens_active_token_idx
  on public.device_push_tokens(platform, token) where revoked_at is null;

-- Escritura solo vía register/revoke_push_device (validan formato y reasignación).
revoke insert, update, delete on public.device_push_tokens from authenticated;

create or replace function public.register_push_device(
  p_platform text, p_token text, p_environment text default 'production'
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_actor uuid := auth.uid();
  v_token text := btrim(coalesce(p_token, ''));
  v_env text := coalesce(p_environment, 'production');
  v_id uuid;
begin
  if v_actor is null then
    raise exception 'NOT_AUTHORIZED' using errcode='42501';
  end if;
  -- iOS sin Firebase registra el token APNs en hex; FCM (Android o iOS vía FCM) usa base64url con ':'.
  if p_platform not in ('ios','android')
     or v_env not in ('production','sandbox')
     or not ((p_platform = 'ios' and v_token ~ '^[0-9A-Fa-f]{64,200}$')
             or v_token ~ '^[A-Za-z0-9_:-]{100,4096}$') then
    raise exception 'INVALID_TOKEN' using errcode='22023';
  end if;

  -- Un dispositivo que cambia de cuenta deja de recibir avisos de la cuenta anterior.
  update public.device_push_tokens
     set revoked_at = now(), invalidated_reason = 'REASSIGNED', updated_at = now()
   where platform = p_platform and token = v_token and user_id <> v_actor and revoked_at is null;

  insert into public.device_push_tokens(user_id, platform, token, environment, revoked_at, invalidated_reason, updated_at)
  values (v_actor, p_platform, v_token, v_env, null, null, now())
  on conflict (user_id, platform, token) do update
    set revoked_at = null, invalidated_reason = null, environment = excluded.environment, updated_at = now()
  returning id into v_id;

  update public.device_push_tokens
     set revoked_at = now(), invalidated_reason = 'DEVICE_LIMIT', updated_at = now()
   where id in (
     select t.id from public.device_push_tokens t
      where t.user_id = v_actor and t.revoked_at is null
      order by t.updated_at desc
      offset 10
   );
  return v_id;
end $$;
revoke all on function public.register_push_device(text,text,text) from public, anon;
grant execute on function public.register_push_device(text,text,text) to authenticated;

create or replace function private.claim_due_reminders(p_limit int default 50, p_lease_seconds int default 60)
returns setof public.notification_outbox
language plpgsql security definer set search_path='' as $$
declare v_lease text := gen_random_uuid()::text;
begin
  return query
  with due as (
    select id from public.notification_outbox
    where (status = 'pending' and scheduled_at_utc <= now()
           and (next_attempt_at is null or next_attempt_at <= now()))
       or (status = 'claimed' and lease_until < now())
    order by scheduled_at_utc
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
    for update skip locked
  )
  update public.notification_outbox o
  set status = 'claimed', lease_owner = v_lease,
      lease_until = now() + make_interval(secs => least(greatest(coalesce(p_lease_seconds, 60), 10), 300)),
      updated_at = now()
  from due where o.id = due.id
  returning o.*;
end $$;
revoke all on function private.claim_due_reminders(int,int) from public, anon, authenticated;
grant execute on function private.claim_due_reminders(int,int) to service_role;

create or replace function private.finish_reminder_delivery(
  p_outbox uuid, p_lease text, p_outcome text, p_code text default null, p_max_attempts int default 5
) returns text language plpgsql security definer set search_path='' as $$
declare
  v_row public.notification_outbox%rowtype;
  v_attempts int;
  v_status text;
begin
  if p_outcome not in ('sent','retry','failed','skipped','cancelled','expired') then
    raise exception 'INVALID_OUTCOME' using errcode='22023';
  end if;
  select * into v_row from public.notification_outbox where id = p_outbox for update;
  if not found or v_row.status <> 'claimed' or v_row.lease_owner is distinct from p_lease then
    return 'LEASE_LOST';
  end if;
  v_attempts := v_row.attempt_count + case when p_outcome in ('sent','retry','failed') then 1 else 0 end;
  v_status := case
    when p_outcome = 'retry' and v_attempts >= least(greatest(coalesce(p_max_attempts, 5), 1), 10) then 'failed'
    when p_outcome in ('retry','skipped') then 'pending'
    else p_outcome
  end;
  update public.notification_outbox
     set status = v_status,
         attempt_count = v_attempts,
         next_attempt_at = case
           when v_status <> 'pending' then null
           when p_outcome = 'skipped' then now() + interval '10 minutes'
           else now() + make_interval(secs => least(30 * power(2, greatest(v_attempts - 1, 0)), 900))
         end,
         last_error_code = left(p_code, 64),
         lease_owner = null,
         lease_until = null,
         updated_at = now()
   where id = p_outbox;
  return v_status;
end $$;
revoke all on function private.finish_reminder_delivery(uuid,text,text,text,int) from public, anon, authenticated;
grant execute on function private.finish_reminder_delivery(uuid,text,text,text,int) to service_role;

create or replace function public.finish_reminder_delivery(
  p_outbox uuid, p_lease text, p_outcome text, p_code text default null, p_max_attempts int default 5
) returns text language sql security definer set search_path='' as $$
  select private.finish_reminder_delivery(p_outbox, p_lease, p_outcome, p_code, p_max_attempts)
$$;
revoke all on function public.finish_reminder_delivery(uuid,text,text,text,int) from public, anon, authenticated;
grant execute on function public.finish_reminder_delivery(uuid,text,text,text,int) to service_role;

create or replace function public.invalidate_push_device(p_device uuid, p_reason text)
returns void language sql security definer set search_path='' as $$
  update public.device_push_tokens
     set revoked_at = now(), invalidated_reason = left(coalesce(p_reason, 'INVALID'), 64), updated_at = now()
   where id = p_device and revoked_at is null
$$;
revoke all on function public.invalidate_push_device(uuid,text) from public, anon, authenticated;
grant execute on function public.invalidate_push_device(uuid,text) to service_role;
