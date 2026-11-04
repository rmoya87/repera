"""Offline guards for Supabase migration-history reconciliation.

These checks cannot establish a live production match. They catch filename
regressions, duplicate versions and missing forward-only production repairs.
The live reconciliation is documented in docs/SUPABASE_MIGRATION_RECONCILIATION_2026-11-04.md.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "supabase" / "migrations"
AUDIT = ROOT / "docs" / "SUPABASE_MIGRATION_RECONCILIATION_2026-11-04.md"


class SupabaseReconciledMigrationContracts(unittest.TestCase):
    def test_unique_version_prefixes(self):
        migrations = sorted(MIGRATIONS.glob("*.sql"))
        versions = [m.name.split("_", 1)[0] for m in migrations]
        self.assertEqual(len(versions), len(set(versions)))
        for version in versions:
            self.assertRegex(version, r"^\d{14}$")

    def test_all_46_renamed_versions_are_preserved(self):
        pairs = re.findall(r"^\| `(\d{14})` \| `(\d{14}_[^\s|]+\.sql)` \|$", AUDIT.read_text(), re.M)
        self.assertEqual(len(pairs), 46)
        for applied_version, obsolete_name in pairs:
            self.assertEqual(len(list(MIGRATIONS.glob(applied_version + "_*.sql"))), 1, applied_version)
            self.assertFalse((MIGRATIONS / obsolete_name).exists(), obsolete_name)

    def test_forward_only_deployed_migrations_present(self):
        required = (
            "20261103220000_native_catalog_ai_metadata_parity.sql",
            "20261103221000_native_equipment_metadata_parity.sql",
            "20261103233000_board_scan_ddb_stepup_rkbs.sql",
            "20261104073557_business_push_outbox_reconciled.sql",
            "20261104074250_repera_missing_business_rpc_recovery.sql",
            "20261104074721_repera_catalog_invoker_and_business_rpc_security.sql",
        )
        for path in required:
            self.assertTrue((MIGRATIONS / path).is_file(), path)

    def test_recovery_preserves_legacy_booking_implementations(self):
        recovery = (MIGRATIONS / "20261104074250_repera_missing_business_rpc_recovery.sql").read_text()
        for name in (
            "public.business_mark_class_attendance", "public.decline_org_invitation",
            "public.coach_ack_occurrence", "public.coach_reschedule_occurrence",
            "public.coach_cancel_occurrence", "public.athlete_send_org_message",
            "public.update_organization_branding",
        ):
            self.assertIn(name, recovery)
        self.assertNotIn("create or replace function private.book_service_occurrence", recovery.lower())
        self.assertNotIn("create or replace function private.cancel_service_booking", recovery.lower())

    def test_security_migration_keeps_catalog_rls_and_forbids_anonymous_rpc(self):
        sql = (MIGRATIONS / "20261104074721_repera_catalog_invoker_and_business_rpc_security.sql").read_text().lower()
        self.assertIn("security_invoker = true", sql)
        for fn in ("class_occurrence_roster(uuid)", "delete_managed_occurrence(uuid)", "update_org_booking_window(uuid,integer)"):
            self.assertIn("revoke all on function public." + fn + " from public, anon", sql)


if __name__ == "__main__":
    unittest.main()
