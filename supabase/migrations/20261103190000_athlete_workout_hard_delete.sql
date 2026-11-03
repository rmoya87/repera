-- A workout removed by the athlete is physically deleted, not replaced by
-- an empty payload / deleted_at tombstone. Other users and coaches cannot DELETE.
-- Run before releasing clients that issue DELETE through the Data API.
alter table public.athlete_workout_mirror enable row level security;

drop policy if exists athlete_workout_private_delete on public.athlete_workout_mirror;
create policy athlete_workout_private_delete
    on public.athlete_workout_mirror
    for delete to authenticated
    using (
        owner_id = (select auth.uid())
        and (auth.jwt() ->> 'client_id') is null
    );

revoke delete on public.athlete_workout_mirror from public, anon;
grant delete on public.athlete_workout_mirror to authenticated;

-- Backward compatibility: old TestFlight/Play builds still issue an UPSERT
-- with deleted_at instead of DELETE. Remove that row in the SAME transaction.
-- No permanent soft-delete row or metadata remains even for older builds.
create or replace function private.remove_legacy_workout_tombstone()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    delete from public.athlete_workout_mirror
    where id = new.id and owner_id = new.owner_id;
    return null;
end;
$$;
revoke all on function private.remove_legacy_workout_tombstone() from public, anon;
drop trigger if exists athlete_workout_legacy_hard_delete
    on public.athlete_workout_mirror;
create trigger athlete_workout_legacy_hard_delete
    after insert or update of deleted_at on public.athlete_workout_mirror
    for each row when (new.deleted_at is not null)
    execute function private.remove_legacy_workout_tombstone();

-- Remove historical soft-deleted rows. Their payloads are not to be retained.
delete from public.athlete_workout_mirror
where deleted_at is not null;
