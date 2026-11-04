-- Preserve booking provenance even after the requesting athlete's auth identity is removed.
alter table public.service_bookings
  add column if not exists requested_by_deleted_user_id uuid;
alter table public.service_bookings
  alter column requested_by drop not null;
alter table public.service_bookings
  drop constraint if exists service_bookings_requested_by_fkey;
alter table public.service_bookings
  add constraint service_bookings_requested_by_fkey
    foreign key (requested_by) references auth.users(id) on delete set null;
alter table public.service_bookings
  drop constraint if exists service_bookings_requester_recorded_check;
alter table public.service_bookings
  add constraint service_bookings_requester_recorded_check
    check (requested_by is not null or requested_by_deleted_user_id is not null);
