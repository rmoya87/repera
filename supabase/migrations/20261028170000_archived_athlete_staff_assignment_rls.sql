-- A coach may read historical snapshots only for clients assigned to that coach.
-- Owners/admins retain their center's contractual records.
drop policy if exists business_athlete_snapshot_staff_read
  on public.business_athlete_workout_snapshots;
create policy business_athlete_snapshot_staff_read
on public.business_athlete_workout_snapshots for select
to authenticated
using (
  exists (
    select 1
    from public.organization_memberships membership
    where membership.organization_id = business_athlete_workout_snapshots.org_id
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
      and (
        membership.role in ('owner','admin')
        or (
          membership.role = 'coach'
          and exists (
            select 1 from public.staff_client_assignments assignment
            where assignment.org_id = business_athlete_workout_snapshots.org_id
              and assignment.coach_id = (select auth.uid())
              and assignment.client_id = business_athlete_workout_snapshots.client_id
          )
        )
      )
  )
);
