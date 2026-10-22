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
        self.assertIn('Label("Apple Salud", systemImage: "heart.text.square")', screen)
        self.assertIn("await health.requestAccess(includeAllOptional: true)", screen)
        self.assertIn("Tus datos de salud solo en tu móvil", screen)
        self.assertNotIn("Ampliar permisos para métricas deportivas", screen)
        self.assertNotIn("Sin sincronización de salud con Supabase", screen)

    def test_health_settings_are_consolidated_and_uncluttered(self):
        screen = source("Apps/Repera/Sources/HealthRecovery.swift")
        view = screen.split("struct ConnectedHealthSettingsView: View {", 1)[1].split(
            "/// Compat: redirige al detalle unificado.", 1
        )[0]
        self.assertIn('Label("Apple Salud", systemImage: "heart.text.square")', view)
        self.assertNotIn('Toggle("Analizar descanso"', view)
        self.assertNotIn('Toggle("Seguimiento del ciclo"', view)
        self.assertNotIn("Toggle(", view)
        self.assertIn("await health.requestAccess(includeAllOptional: true)", view)
        self.assertIn("enableUnifiedHealthAnalysis()", source("Apps/Repera/Sources/HealthKitStore.swift"))
        self.assertIn("sleepEnabled = true", screen)
        self.assertIn("cycleEnabled = true", screen)
        self.assertNotIn('Text("Recuperación")', view)
        self.assertNotIn('Text("Permisos independientes', view)
        self.assertNotIn("Sueño, ciclo y constantes fisiológicas", view)
        self.assertNotIn("El sueño es orientativo. Las fases menstruales", view)
        self.assertIn('Section("Privacidad")', view)
        self.assertIn('Label("Tus datos de salud solo en tu móvil"', view)
        self.assertIn("permissionManagementRequiresSettings", view)
        self.assertIn("Acceso de datos y dispositivos", view)
        self.assertNotIn('Button("Actualizar desde Apple Salud")', view)
        self.assertIn("await health.refreshToday()", view)
        self.assertIn("await recovery.refresh()", view)
        self.assertIn("await HealthPhysiologyStore.shared.refresh()", view)
        self.assertIn(".onChange(of: scenePhase)", view)

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
