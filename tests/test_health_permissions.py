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
        request = source.split("func requestAccess(includeSleep: Bool? = nil, includeAllOptional: Bool = false) async {", 1)[1]
        request = request.split("func refreshAuthorizationStatus()", 1)[0]
        self.assertIn("HKObjectType.categoryType(forIdentifier: .sleepAnalysis)", request)
        self.assertIn("HKObjectType.quantityType(forIdentifier: .heartRate)", request)
        self.assertIn("HKObjectType.workoutType()", request)
        self.assertIn("store.requestAuthorization(toShare: share, read: read)", request)
        self.assertIn("acceptSleepFromHealthAuthorization()", request)
        self.assertIn("if includeAllOptional {", request)
        self.assertIn("HKObjectType.categoryType(forIdentifier: .menstrualFlow)", request)
        self.assertIn("HKObjectType.categoryType(forIdentifier: .ovulationTestResult)", request)
        self.assertIn("statusForAuthorizationRequest(toShare: share, read: read)", request)
        self.assertIn("enableUnifiedHealthAnalysis()", request)

    def test_onboarding_uses_same_health_permission_action(self):
        source = self.read("Onboarding/OnboardingFlowView.swift")
        self.assertIn('subtitle: "Entrenos, sueño, ciclo y constantes"', source)
        self.assertIn("await health.requestAccess(includeAllOptional: true)", source)
        self.assertIn("private var healthPermissionsComplete: Bool", source)
        self.assertNotIn("health.isAuthorized && !recovery.needsSleepDecision", source)

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
        self.assertIn("var shouldRequestSleepWithHealth: Bool { sleepEnabled }", source)


class HealthCaloriesOriginContractTests(unittest.TestCase):
    """Contratos de origen: nunca confundir estimaciones Repera con Salud."""

    def read(self, relative_path: str) -> str:
        return (SOURCES / relative_path).read_text(encoding="utf-8")

    def test_home_metric_titles_are_inline_with_icons_above_values(self):
        home = self.read("HomeView.swift")
        tile = home.split("private func metricTile(", 1)[1].split("private func setLine(", 1)[0]
        self.assertIn("HStack(spacing: 7)", tile)
        self.assertLess(tile.index("Image(systemName: icon)"), tile.index("Text(title)"))
        self.assertLess(tile.index("Text(title)"), tile.index("Text(value)"))
        self.assertIn("minHeight: 62", tile)
        self.assertIn("VStack(alignment: .leading, spacing: 12)", tile)
        value = tile.split("Text(value)", 1)[1].split(".foregroundStyle(OG.label)", 1)[0]
        self.assertIn(".font(.system(size: 28, weight: .semibold))", value)
        self.assertIn(".minimumScaleFactor(0.7)", tile)
        for label in ("Kcal", "Tiempo", "Nota"):
            self.assertIn(f'title: "{label}"', home)

    def test_home_daily_energy_has_no_local_fallback(self):
        home = self.read("HomeView.swift")
        self.assertIn("let kcal = dayHealth.activeEnergyKcal", home)
        self.assertNotIn("durationMin * 7.5", home)
        self.assertNotIn("fromSessions + fromExternal", home)

    def test_workout_chip_needs_verified_healthkit_data(self):
        chips = self.read("RegisterSessionChrome.swift")
        repera = chips.split("static func repera(", 1)[1].split("static func health(", 1)[0]
        self.assertIn("verifiedHealthKcal", repera)
        self.assertNotIn("if let kcal = session.appleActiveEnergyKcal", repera)

    def test_no_synthetic_calories_written_to_apple_health(self):
        health = self.read("HealthKitStore.swift")
        saving = health.split("private func saveStrengthWorkout(", 1)[1].split("private func discardLocalBuilder()", 1)[0]
        self.assertNotIn("HKCumulativeQuantitySample", saving)
        self.assertNotIn("builder.addSamples", saving)
        self.assertNotIn("saveActiveEnergySample(", health)

    def test_active_energy_ignores_repera_sources(self):
        health = self.read("HealthKitStore.swift")
        self.assertIn("!isReperaSource(source)", health)
        self.assertIn('source.name.localizedCaseInsensitiveContains("repera")', health)
        self.assertIn(".separateBySource", health)
        self.assertIn("verifiedWorkoutEnergyKcal", health)

    def test_legacy_estimates_removed_from_workouts_and_progress(self):
        store = self.read("ReperaStore.swift")
        chart = self.read("ProgressChartBuilder.swift")
        self.assertIn("session.appleActiveEnergyKcal = verified", store)
        self.assertIn("saved.appleActiveEnergyKcal = nil", store)
        self.assertIn("updated.appleActiveEnergyKcal = apple.kcal > 0 ? apple.kcal : nil", store)
        self.assertNotIn("workout.appleActiveEnergyKcal", chart)


if __name__ == "__main__":
    unittest.main()
