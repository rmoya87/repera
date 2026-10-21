"""Pruebas de contrato del flujo unificado de permisos de Apple Salud."""
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps/Repera/Sources"


class UnifiedHealthPermissionsTests(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (SOURCES / relative_path).read_text(encoding="utf-8")

    def test_health_request_includes_sleep_and_other_metrics(self):
        source = self.read("HealthKitStore.swift")
        request = source.split("func requestAccess(includeSleep: Bool? = nil) async {", 1)[1]
        request = request.split("func refreshAuthorizationStatus()", 1)[0]
        self.assertIn("HKObjectType.categoryType(forIdentifier: .sleepAnalysis)", request)
        self.assertIn("HKObjectType.quantityType(forIdentifier: .heartRate)", request)
        self.assertIn("HKObjectType.workoutType()", request)
        self.assertIn("store.requestAuthorization(toShare: share, read: read)", request)
        self.assertIn("acceptSleepFromHealthAuthorization()", request)

    def test_onboarding_uses_same_health_permission_action(self):
        source = self.read("Onboarding/OnboardingFlowView.swift")
        self.assertIn('subtitle: "Entrenos, calorías, pulso y sueño"', source)
        self.assertIn("await health.requestAccess()", source)
        self.assertIn("health.isAuthorized && !recovery.needsSleepDecision", source)

    def test_progress_does_not_show_independent_sleep_alert(self):
        source = self.read("StatsView.swift")
        self.assertNotIn('alert("Analizar descanso"', source)
        self.assertNotIn("showSleepPermissionAlert", source)

    def test_reenabling_sleep_reuses_unified_healthkit_request(self):
        source = self.read("HealthRecovery.swift")
        setter = source.split("func setSleep(_ enabled: Bool) async {", 1)[1]
        setter = setter.split("func acceptSleepFromHealthAuthorization()", 1)[0]
        self.assertIn("HealthKitStore.shared.requestAccess(includeSleep: true)", setter)
        self.assertNotIn("healthStore.requestAuthorization", setter)
        self.assertIn("!sleepDecisionMade || sleepEnabled", source)


if __name__ == "__main__":
    unittest.main()
