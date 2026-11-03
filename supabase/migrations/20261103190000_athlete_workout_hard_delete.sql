-- A workout removed by the athlete is physically deleted, not replaced by
-- an empty payload / deleted_at tombstone. Other users and coaches cannot DELETE.
-- Run before releasing clients that issue DELETE through the Data API.
alter table public.athlete_workout_mirror enable row level security;

drop policy if exists athlete_workout_private_delete on public.athlete_workout_mirror;
create policy athlete_workout_private_delete
    on public.athlete_workout_mirror
    for delete to authenticated
    using (owner_id = (select auth.uid()));

revoke delete on public.athlete_workout_mirror from public, anon;
grant delete on public.athlete_workout_mirror to authenticated;

-- Remove historical soft-deleted rows. Their payloads are not to be retained.
delete from public.athlete_workout_mirror
where deleted_at is not null;
