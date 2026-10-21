"""Regression contracts for Repera's Apple login, permissions and chat-first IA.

CI contracts do not replace an Xcode build and device authentication test.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
def src(path):
    return (ROOT / path).read_text(encoding="utf-8")

class AppleSyncAndAIChatContracts(unittest.TestCase):
    def test_profile_backend_matches_native_avatar_contract(self):
        sql=src("supabase/migrations/20261021235500_apple_profile_avatar_storage.sql")
        native=src("Apps/Repera/Sources/BusinessAuthStore.swift")
        self.assertIn("ADD COLUMN IF NOT EXISTS avatar_url",sql)
        self.assertIn("GRANT UPDATE(display_name,avatar_url)",sql)
        self.assertIn("profile-avatars",sql)
        self.assertIn("auth.uid()",sql)
        self.assertIn("try values.encodeNil(forKey: .avatarURL)",native)
        self.assertIn("jpeg.count <= 2_097_152",native)

    def test_manual_sync_waits_for_existing_sync_and_explains_failure(self):
        settings=src("Apps/Repera/Sources/SettingsView.swift")
        self.assertIn("await store.refreshFromiCloud()",settings)
        self.assertIn("await businessAuth.restoreSession()",settings)
        self.assertIn("workoutSync.isSyncing",settings)
        self.assertIn("AITrainingInboxStore.shared.isSyncing",settings)
        self.assertIn("AITrainingContextStore.shared.isSyncing",settings)
        self.assertIn("incomplete.joined",settings)
        self.assertNotIn('?? "operación incompleta"',settings)

    def test_no_profile_form_and_no_gym_auth_error(self):
        settings=src("Apps/Repera/Sources/SettingsView.swift")
        self.assertNotIn("AITrainingProfileView()",settings)
        self.assertNotIn('Text(issue).font(.footnote).foregroundStyle(OG.red)',settings)
        self.assertFalse((ROOT / "Apps/Repera/Sources/AITrainingProfileView.swift").exists())
        self.assertNotIn("AITrainingProgramsView()", settings)
        self.assertIn("AITrainingProgramsView()", src("Apps/Repera/Sources/PlanView.swift"))

    def test_no_unsolicited_health_sleep_or_pending_badges(self):
        settings=src("Apps/Repera/Sources/SettingsView.swift")
        recovery=src("Apps/Repera/Sources/HealthRecovery.swift")
        onboard=src("Apps/Repera/Sources/Onboarding/OnboardingFlowView.swift")
        self.assertNotIn('Text("Pendiente de confirmar")',recovery)
        self.assertNotIn('if !recovery.pendingHealthItems.isEmpty || !health.isAuthorized',recovery)
        self.assertNotIn('accessibilityLabel("Permisos pendientes")',settings)
        self.assertIn("var shouldRequestSleepWithHealth: Bool { sleepEnabled }",recovery)
        self.assertNotIn("health.isAuthorized && !recovery.needsSleepDecision",onboard)

    def test_mcp_observes_history_and_filters_by_real_gear(self):
        coach=src("supabase/functions/repera-mcp/coach.ts")
        migration=src("supabase/migrations/20261021235800_exercise_equipment_joint_demands.sql")
        self.assertIn("await history(90)",coach)
        self.assertIn("questions_to_ask_before_building_a_program",coach)
        self.assertIn('server.registerTool("set_training_preferences"',coach)
        self.assertIn('server.registerTool("find_equipment_alternatives"',coach)
        self.assertIn("const gear=new Set(availableEquipment.map(canonicalGear))",coach)
        self.assertIn("joint_demands",migration)
        self.assertIn("required_equipment",migration)
        self.assertNotIn("HealthKit",migration)

if __name__ == "__main__":
    unittest.main()
