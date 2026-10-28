-- A deleted athlete becomes a non-interactive business history snapshot.
-- Retain company-owned invoices, bookings, prescribed sessions and client card.
alter table public.clients
  add column if not exists account_deleted_at timestamptz;

create table if not exists public.business_athlete_workout_snapshots (
  org_id uuid not null references public.organizations(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,
  workout_id uuid not null,
  title text not null,
  started_at timestamptz,
  finished_at timestamptz,
  payload jsonb not null,
  frozen_at timestamptz not null default now(),
  primary key (org_id, client_id, workout_id)
);

create index if not exists idx_business_athlete_workout_snapshots_client
  on public.business_athlete_workout_snapshots (org_id, client_id, finished_at desc);

alter table public.business_athlete_workout_snapshots enable row level security;
revoke all on public.business_athlete_workout_snapshots from public, anon, authenticated;
grant select on public.business_athlete_workout_snapshots to authenticated;

drop policy if exists business_athlete_snapshot_staff_read on public.business_athlete_workout_snapshots;
create policy business_athlete_snapshot_staff_read
on public.business_athlete_workout_snapshots for select
to authenticated
using (
  exists (
    select 1 from public.organization_memberships membership
     where membership.organization_id = org_id
       and membership.user_id = (select auth.uid())
       and membership.status = 'active'
       and membership.role in ('owner','admin','coach')
  )
);

-- Inert historical card: business operators may read, but cannot edit/delete
-- a client frozen by account erasure.
create or replace function public.repera_reject_archived_client_changes()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if old.account_deleted_at is not null and current_user not in ('postgres','service_role') then
    raise exception 'Este cliente es un registro histórico de solo lectura.'
      using errcode = '42501';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;
revoke all on function public.repera_reject_archived_client_changes() from public;
drop trigger if exists trg_repera_archived_client_read_only on public.clients;
create trigger trg_repera_archived_client_read_only
before update or delete on public.clients
for each row execute function public.repera_reject_archived_client_changes();

-- No new reservations, passes or professional prescriptions for archived users.
create or replace function public.repera_reject_archived_client_activity()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if exists (
    select 1 from public.clients c
    where c.id = new.client_id and c.account_deleted_at is not null
  ) then
    raise exception 'Este cliente ya no tiene una cuenta activa.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function public.repera_reject_archived_client_activity() from public;

drop trigger if exists trg_repera_archived_client_booking on public.service_bookings;
create trigger trg_repera_archived_client_booking
before insert on public.service_bookings
for each row execute function public.repera_reject_archived_client_activity();

drop trigger if exists trg_repera_archived_client_pass on public.service_passes;
create trigger trg_repera_archived_client_pass
before insert on public.service_passes
for each row execute function public.repera_reject_archived_client_activity();

drop trigger if exists trg_repera_archived_client_training on public.professional_training_sessions;
create trigger trg_repera_archived_client_training
before insert on public.professional_training_sessions
for each row execute function public.repera_reject_archived_client_activity();
