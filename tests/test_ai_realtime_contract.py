"""Contract checks for Repera's foreground AI inbox and streamlined access view.

These tests do not replace an iOS simulator build or a two-user Realtime E2E test.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"


class AIRealtimeContractTests(unittest.TestCase):
    def test_access_view_has_single_explicit_sync_in_account_only(self):
        access = (SRC / "AIAccessView.swift").read_text(encoding="utf-8")
        settings = (SRC / "SettingsView.swift").read_text(encoding="utf-8")
        for old in (
            "Inicia sesión con Apple y conecta Repera",
            "Actualizar entrenamientos de IA",
            "} footer: {",
            "await inbox.sync(store: store)",
        ):
            self.assertNotIn(old, access)
        self.assertIn("AITrainingInboxStore.shared.sync(store: store)", settings)

    def test_realtime_is_owner_scoped_and_lifecycle_bound(self):
        inbox = (SRC / "AITrainingInboxStore.swift").read_text(encoding="utf-8")
        app = (SRC / "ReperaApp.swift").read_text(encoding="utf-8")
        self.assertIn('table: "ai_training_plans"', inbox)
        self.assertIn('filter: .eq("owner_id", value: userID.uuidString.lowercased())', inbox)
        self.assertIn("try await channel.subscribeWithError()", inbox)
        self.assertIn("await client.realtimeV2.removeChannel(channel)", inbox)
        self.assertIn("realtimeGeneration == connectionID", inbox)
        self.assertIn("await self.sync(store: store)", inbox)
        self.assertIn("aiInbox.stopRealtime()", app)
        self.assertIn("aiInbox.startRealtime(store: store)", app)
        self.assertIn("aiInbox.lastImportedTitle", app)
        self.assertIn("store.saveRoutine(plan)", inbox)

    def test_realtime_publication_does_not_include_other_private_tables(self):
        migration = (
            ROOT / "supabase/migrations/20261021171000_ai_training_plans_realtime_publication.sql"
        ).read_text(encoding="utf-8")
        self.assertIn("ALTER PUBLICATION supabase_realtime ADD TABLE public.ai_training_plans", migration)
        self.assertNotIn("ADD TABLE public.ai_access_tokens", migration)
        self.assertNotIn("ADD TABLE public.athlete_workout_mirror", migration)


if __name__ == "__main__":
    unittest.main()
