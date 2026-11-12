"""Contratos estáticos de la reconciliación Salud tras editar horarios.

No reemplazan tests de HealthKit en hardware. Verifican que los puntos de
entrada implicados conservan el enlace original y relanzan las lecturas.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class EditedWorkoutHealthReconciliationTests(unittest.TestCase):
    def test_editing_start_alone_marks_health_interval_as_changed(self):
        plan = read(IOS / "PlanView.swift")
        segment = plan.split("private func completedDateBinding", 1)[1].split(
            "private var completedDurationMinutes", 1
        )[0]
        self.assertIn("completedDetails?.startedAt = date", segment)
        self.assertIn("completedDetails?.userEditedDuration = true", segment)
        history = read(IOS / "HistoryView.swift")
        self.assertIn("draft?.userEditedDuration = true", history)

    def test_original_sensor_window_is_kept_before_editing(self):
        model = read(DOMAIN / "Models.swift")
        self.assertIn("recordedStartBeforeEditing", model)
        self.assertIn("recordedEndBeforeEditing", model)
        store = read(IOS / "ReperaStore.swift")
        self.assertIn("changedRecordedWindow", store)
        self.assertIn("previous.recordedStartBeforeEditing", store)
        self.assertIn("previous.recordedEndBeforeEditing", store)

    def test_recovers_watch_workout_without_reassigning_other_sessions(self):
        health = read(IOS / "HealthKitStore.swift")
        self.assertIn("verifiedWatchWorkout(forReperaSession: session.id)", health)
        self.assertIn("session.recordedStartBeforeEditing ?? start", health)
        self.assertIn("expectedSessionID: session.id", health)
        self.assertIn("external.caseInsensitiveCompare(expectedSessionID.uuidString)", health)

    def test_save_and_late_watch_uuid_trigger_reconciliation(self):
        store = read(IOS / "ReperaStore.swift")
        self.assertIn("Task { await refineSessionReviewWithHealth(sessionId: id) }", store)
        self.assertIn("linked.healthKitWorkoutUUID = uuid", store)
        self.assertIn("if !saved.userEditedDuration,", store)

    def test_measured_energy_not_replaced_with_estimation(self):
        health = read(IOS / "HealthKitStore.swift")
        self.assertIn("revisedWorkoutQuantity(", health)
        self.assertIn("let baseEnergy = await externalWorkoutEnergyKcal(uuid: workoutUUID)", health)
        self.assertIn("editedWindowQuantity(", health)
        self.assertIn("if groups.count == 1", health)

    def test_watch_energy_uses_total_energy_burned_fallback(self):
        health = read(IOS / "HealthKitStore.swift")
        segment = health.split("nonisolated private static func workoutEnergyKcal", 1)[1].split(
            "private static func samplesFromLinkedSensor", 1
        )[0]
        self.assertIn("totalEnergyBurned", segment)
        self.assertIn("statisticsKcal", segment)
        store = read(IOS / "ReperaStore.swift")
        refine = store.split("func refineSessionReviewWithHealth", 1)[1].split(
            "func saveWorkout(", 1
        )[0]
        self.assertIn("if let verifiedKcal, linked.appleActiveEnergyKcal != verifiedKcal", refine)
        self.assertNotIn(
            "(verifiedKcal != nil || linked.userEditedDuration)",
            refine,
        )
        watch = read(
            ROOT / "Apps" / "ReperaWatch" / "Sources" / "WatchHealthKitSession.swift"
        )
        self.assertIn("totalEnergyBurned", watch)

    def test_minute_precision_edits_keep_the_measured_watch_total(self):
        health = read(IOS / "HealthKitStore.swift")
        segment = health.split("private func revisedWorkoutQuantity(", 1)[1].split(
            "private func revisedMovementMetrics", 1
        )[0]
        self.assertIn("Calendar.current.isDate(newStart", segment)
        self.assertIn("Calendar.current.isDate(newEnd", segment)
        self.assertIn("return original", segment)
        self.assertIn("return await editedWindowQuantity(", segment)

    def test_missing_watch_kcal_are_rechecked_on_foreground_and_not_estimated(self):
        store = read(IOS / "ReperaStore.swift")
        segment = store.split("func reconcileWatchHealthMetrics() async", 1)[1].split(
            "func repairPastHealthKitExports()", 1
        )[0]
        self.assertIn("($0.appleActiveEnergyKcal ?? 0) <= 0", segment)
        self.assertIn("sessionHealthExtras(for: original, energyOnly: true)", segment)
        health = read(IOS / "HealthKitStore.swift")
        self.assertIn("if !energyOnly { await ensureWorkoutRouteAccess() }", health)
        self.assertIn("if energyOnly {", health)
        self.assertIn("let measured = await energyKcalForWorkout(workout)", health)
        self.assertIn("if !energyOnly, let shellUUID, shellUUID != uuid", health)
        self.assertIn("if !energyOnly, let shellUUID, shellUUID != verified.uuid", health)
        self.assertIn("extras.energySourceIsVerified", segment)
        self.assertIn("current.appleActiveEnergyKcal = kcal", segment)
        self.assertNotIn("estimateSessionKcal", segment)
        app = read(IOS / "ReperaApp.swift")
        foreground = app.split("private func refreshHealthOnForeground(", 1)[1].split(
            "private struct LaunchSplashView", 1
        )[0]
        self.assertIn("await store.reconcileWatchHealthMetrics()", foreground)

    def test_legacy_ios_workout_without_health_uuid_is_eligible_for_verified_kcal(self):
        store = read(IOS / "ReperaStore.swift")
        segment = store.split("let missingEnergy = state.workouts.filter", 1)[1].split(
            "for original in missingEnergy.prefix(20)", 1
        )[0]
        self.assertIn("session.healthKitWorkoutUUID != nil", segment)
        self.assertIn("end >= Date().addingTimeInterval(-30 * 24 * 60 * 60)", segment)
        self.assertIn("session.recordedStartBeforeEditing != nil", segment)
        self.assertIn("session.recordedEndBeforeEditing != nil", segment)
        self.assertIn("end.timeIntervalSince(start) >= 10 * 60", segment)
        self.assertIn("sessionHealthExtras(for: original, energyOnly: true)",
                      store)

    def test_legacy_phone_shell_prefers_unambiguous_external_workout(self):
        health = read(IOS / "HealthKitStore.swift")
        segment = health.split("func sessionHealthExtras(", 1)[1].split(
            "let shouldReadEditedWindow", 1
        )[0]
        self.assertIn("if (workout == nil || linkedToPhonePlaceholder)", segment)
        self.assertIn("hasRecordedAnchor", segment)
        self.assertIn("watchOnly: fromWatch", segment)
        self.assertIn("expectedSessionID: session.id", segment)
        self.assertIn("Self.isWatchRecordedSource(matchedExternal.sourceRevision.source)", segment)
        self.assertLess(segment.index("matchedExternal = await overlappingWorkout("),
                        segment.index("let own = await existingReperaWorkout("))
        self.assertNotIn("activeEnergy(from:", segment)
        self.assertNotIn("deleteExternalWorkout(id: matchedExternal.uuid)", segment)

    def test_phone_shell_zero_kcal_yields_to_watch_workout(self):
        health = read(IOS / "HealthKitStore.swift")
        self.assertIn("phoneShell", health)
        self.assertIn("linkedPhoneShell", health)
        self.assertIn("watchOnly: true, expectedSessionID: sessionId", health)
        self.assertIn("Antes de escribir una cáscara 0 kcal del iPhone", health)
        self.assertIn("deleteExternalWorkout(id: owned.uuid)", health)
        self.assertIn("deleteOrphanPhoneShells", health)


if __name__ == "__main__":
    unittest.main()
