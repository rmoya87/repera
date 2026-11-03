"""Static security contracts for unlinking one's own client profile."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "supabase/migrations/20261103160000_allow_staff_client_self_unlink.sql"


class OwnerClientUnlinkContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sql = MIGRATION.read_text(encoding="utf-8")

    def test_authorizes_only_own_active_client_or_athlete_membership(self):
        self.assertIn("c.org_id = p_org and c.user_id = v_actor and c.status = 'active'", self.sql)
        self.assertIn("m.organization_id = p_org and m.user_id = v_actor", self.sql)
        self.assertIn("m.role = 'athlete' and m.status = 'active'", self.sql)
        self.assertIn("raise exception 'NOT_LINKED_CLIENT' using errcode = '42501'", self.sql)

    def test_does_not_revoke_owner_admin_or_coach_memberships(self):
        revoke = self.sql.split("update public.organization_memberships", 1)[1]
        self.assertIn("and role = 'athlete' and status = 'active'", revoke)
        self.assertNotIn("role in ('owner'", revoke)
        self.assertIn("update public.clients", self.sql)
        self.assertIn("set status = 'cancelled', user_id = null", self.sql)

    def test_cancels_future_reservations_and_waitlist_but_keeps_audit(self):
        self.assertIn("b.status in ('booked', 'waitlist')", self.sql)
        self.assertIn("o.id = b.occurrence_id and o.starts_at > now()", self.sql)
        self.assertIn("status = 'cancelled'", self.sql)
        self.assertNotIn("delete from public.service_bookings", self.sql.lower())
        self.assertNotIn("delete from public.professional_training_sessions", self.sql.lower())

    def test_revokes_sharing_without_removing_personal_workouts(self):
        self.assertIn("update public.athlete_workout_sharing", self.sql)
        self.assertIn("update public.athlete_business_history_consents", self.sql)
        self.assertNotIn("delete from public.athlete_workouts", self.sql.lower())


if __name__ == "__main__":
    unittest.main()
