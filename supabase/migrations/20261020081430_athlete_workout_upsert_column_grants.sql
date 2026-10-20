-- PostgREST INSERT ... ON CONFLICT DO UPDATE writes identity columns too.
-- RLS still requires owner_id=auth.uid() for both OLD and NEW records.
grant update(id,owner_id) on public.athlete_workout_mirror to authenticated;
-- Consent may only be changed by the athlete: both OLD and NEW RLS policies
-- require athlete_id=auth.uid() and an active linked client membership.
grant update(athlete_id,org_id) on public.athlete_workout_sharing to authenticated;
