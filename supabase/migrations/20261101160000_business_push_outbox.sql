-- Recordatorios 60 min: outbox servidor + tokens. Envío vía Edge (secretos opcionales).

create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('ios','android')),
  token text not null check (length(token) between 10 and 4096),
  environment text not null default 'production' check (environment in ('production','sandbox')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (user_id, platform, token)
);
create index if not exists device_push_tokens_user_idx
  on public.device_push_tokens(user_id) where revoked_at is null;
alter table public.device_push_tokens enable row level security;
revoke all on public.device_push_tokens from public,anon,authenticated;
grant select, insert, update on public.device_push_tokens to authenticated;
create policy device_tokens_own on public.device_push_tokens
 for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  class_reminders boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.notification_preferences enable row level security;
revoke all on public.notification_preferences from public,anon,authenticated;
grant select, insert, update on public.notification_preferences to authenticated;
create policy notif_prefs_own on public.notification_preferences
 for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

create table if not exists public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid not null references public.organizations(id) on delete cascade,
  booking_id uuid not null,
  occurrence_id uuid not null,
  kind text not null default 'class_reminder_60'
    check (kind in ('class_reminder_60','appointment_reminder_60','starts_soon')),
  event_version int not null default 1,
  scheduled_at_utc timestamptz not null,
  status text not null default 'pending'
    check (status in ('pending','claimed','sent','cancelled','failed','expired')),
  idempotency_key text not null unique,
  lease_owner text,
  lease_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (org_id, booking_id) references public.service_bookings(org_id, id) on delete cascade
);
create index if not exists notification_outbox_due_idx
  on public.notification_outbox(status, scheduled_at_utc)
  where status in ('pending','claimed');
alter table public.notification_outbox enable row level security;
revoke all on public.notification_outbox from public,anon,authenticated;
-- Solo service_role / Edge con claim; el usuario no lee outbox.
grant select on public.notification_outbox to authenticated;
create policy notification_outbox_own_read on public.notification_outbox
 for select to authenticated using (user_id=auth.uid());

create table if not exists public.notification_attempts (
  id uuid primary key default gen_random_uuid(),
  outbox_id uuid not null references public.notification_outbox(id) on delete cascade,
  device_token_id uuid references public.device_push_tokens(id) on delete set null,
  attempted_at timestamptz not null default now(),
  provider text not null default 'fcm',
  provider_code text,
  success boolean not null default false
);
alter table public.notification_attempts enable row level security;
revoke all on public.notification_attempts from public,anon,authenticated;

create or replace function public.register_push_device(
  p_platform text, p_token text, p_environment text default 'production'
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid(); v_id uuid;
begin
  if v_actor is null or p_platform not in ('ios','android')
     or length(btrim(coalesce(p_token,''))) not between 10 and 4096
     or coalesce(p_environment,'production') not in ('production','sandbox') then
    raise exception 'INVALID_TOKEN' using errcode='22023';
  end if;
  insert into public.device_push_tokens(user_id,platform,token,environment,revoked_at,updated_at)
  values (v_actor,p_platform,btrim(p_token),coalesce(p_environment,'production'),null,now())
  on conflict (user_id, platform, token) do update
    set revoked_at=null, environment=excluded.environment, updated_at=now()
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.register_push_device(text,text,text) from public,anon;
grant execute on function public.register_push_device(text,text,text) to authenticated;

create or replace function public.revoke_push_device(p_token text)
returns boolean language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
  update public.device_push_tokens
  set revoked_at=now(), updated_at=now()
  where user_id=auth.uid() and token=btrim(p_token) and revoked_at is null;
  return found;
end $$;
revoke all on function public.revoke_push_device(text) from public,anon;
grant execute on function public.revoke_push_device(text) to authenticated;

-- Encolar recordatorio al confirmar reserva (solo booked con hora).
create or replace function private.enqueue_booking_reminder()
returns trigger language plpgsql security definer set search_path='' as $$
declare
  v_occ public.service_occurrences%rowtype;
  v_user uuid;
  v_pref boolean;
  v_when timestamptz;
  v_kind text;
  v_key text;
begin
  if tg_op='INSERT' and new.status='booked' then
    null;
  elsif tg_op='UPDATE' and old.status='booked' and new.status in ('cancelled','attended','no_show') then
    update public.notification_outbox
    set status='cancelled', updated_at=now(), event_version=event_version+1
    where booking_id=new.id and status in ('pending','claimed');
    return new;
  else
    return new;
  end if;

  select * into v_occ from public.service_occurrences where id=new.occurrence_id;
  if not found or v_occ.status<>'active' then return new; end if;

  select c.user_id into v_user from public.clients c where c.id=new.client_id and c.org_id=new.org_id;
  if v_user is null then return new; end if;

  select coalesce(np.class_reminders, true) into v_pref
  from public.notification_preferences np where np.user_id=v_user;
  if v_pref is false then return new; end if;

  v_when := v_occ.starts_at - interval '60 minutes';
  if v_when <= now() then
    -- Reserva con menos de 60 min: solo «starts_soon» si faltan 10–59 min.
    if v_occ.starts_at > now() + interval '10 minutes'
       and v_occ.starts_at <= now() + interval '59 minutes' then
      v_kind := 'starts_soon';
      v_when := now() + interval '15 seconds';
    else
      return new;
    end if;
  else
    v_kind := case when v_occ.kind='appointment' then 'appointment_reminder_60' else 'class_reminder_60' end;
  end if;

  v_key := new.id::text || ':' || v_kind || ':' || extract(epoch from v_occ.starts_at)::bigint::text;
  insert into public.notification_outbox(
    user_id, org_id, booking_id, occurrence_id, kind, scheduled_at_utc, idempotency_key
  ) values (v_user, new.org_id, new.id, v_occ.id, v_kind, v_when, v_key)
  on conflict (idempotency_key) do nothing;
  return new;
end $$;

drop trigger if exists booking_reminder_outbox on public.service_bookings;
create trigger booking_reminder_outbox
 after insert or update of status on public.service_bookings
 for each row execute function private.enqueue_booking_reminder();

-- Claim atómico para Edge (service_role).
create or replace function private.claim_due_reminders(p_limit int default 50, p_lease_seconds int default 60)
returns setof public.notification_outbox
language plpgsql security definer set search_path='' as $$
declare v_lease text := gen_random_uuid()::text;
begin
  return query
  with due as (
    select id from public.notification_outbox
    where status='pending' and scheduled_at_utc <= now()
       or (status='claimed' and lease_until < now())
    order by scheduled_at_utc
    limit least(greatest(coalesce(p_limit,50),1),200)
    for update skip locked
  )
  update public.notification_outbox o
  set status='claimed', lease_owner=v_lease,
      lease_until=now()+make_interval(secs=>least(greatest(coalesce(p_lease_seconds,60),10),300)),
      updated_at=now()
  from due where o.id=due.id
  returning o.*;
end $$;
revoke all on function private.claim_due_reminders(int,int) from public,anon,authenticated;
-- Solo service_role / edge con service key.
grant execute on function private.claim_due_reminders(int,int) to service_role;

create or replace function public.claim_due_reminders(p_limit int default 50, p_lease_seconds int default 60)
returns setof public.notification_outbox
language sql security definer set search_path='' as $$
  select * from private.claim_due_reminders(p_limit, p_lease_seconds)
$$;
revoke all on function public.claim_due_reminders(int,int) from public,anon,authenticated;
grant execute on function public.claim_due_reminders(int,int) to service_role;
