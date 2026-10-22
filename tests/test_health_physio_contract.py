"""Static cross-component contracts for optional local HealthKit physiology.

Swift behavior and UI are also covered by RecoveryEngineTests on Xcode CI.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class LocalHealthPhysiologyContract(unittest.TestCase):
    def test_permissions_are_optional_and_unified(self):
        health = source("Apps/Repera/Sources/HealthKitStore.swift")
        screen = source("Apps/Repera/Sources/HealthRecovery.swift")
        for scope in (
            ".heartRateVariabilitySDNN", ".restingHeartRate",
            ".respiratoryRate", ".heartRateRecoveryOneMinute",
            ".oxygenSaturation", ".appleSleepingWristTemperature",
        ):
            self.assertIn(scope, health)
        self.assertIn("Ampliar permisos para métricas deportivas", screen)
        self.assertIn("await health.requestAccess(includeSleep: recovery.sleepEnabled)", screen)
        self.assertIn("No se envían a Supabase", screen)

    def test_missing_values_are_not_scores(self):
        recovery = source("Packages/ReperaDomain/Sources/ReperaDomain/RecoveryEngine.swift")
        self.assertIn("guard Set(values.map { $0.0 }).count >= 7", recovery)
        self.assertIn("calibratedSignals: 0", recovery)
        self.assertIn("penalty: min(1.8, penalty)", recovery)
        self.assertIn("vitalHistory: [DailyVitals] = []", recovery)
        score = source("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        self.assertIn("VerifiedSessionReviewEngine.review(session: session, history: history, now: now)", score)

    def test_zones_are_from_saved_healthkit_workout(self):
        health = source("Apps/Repera/Sources/HealthKitStore.swift")
        cards = source("Apps/Repera/Sources/ProgressTrendCards.swift")
        self.assertIn("workout.zoneGroup(for: heartType)", health)
        self.assertIn("coveredFraction >= 0.60", health)
        self.assertIn("intensity, no rendimiento", cards)
        self.assertIn("Carga cardiovascular", cards)

    def test_health_signals_remain_off_cloud(self):
        mirror = source("Apps/Repera/Sources/BusinessWorkoutSyncStore.swift")
        vitals = source("Apps/Repera/Sources/HealthRecovery.swift")
        self.assertIn("privateMirrorPayload", mirror)
        self.assertNotIn("HealthPhysiologyStore", mirror)
        self.assertNotIn("Supabase.from", vitals)


if __name__ == "__main__":
    unittest.main()
