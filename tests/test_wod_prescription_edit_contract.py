"""Finished WOD prescription is editable and distinct from performed scaling.

Swift domain tests validate round-tripping original Rx, real sets and block score.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class CompletedWODPrescriptionTests(unittest.TestCase):
    def test_real_fields_are_compact_and_prescription_is_kept_unchanged(self):
        view = read("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("completedStrengthPrescription(index: index)", view)
        self.assertIn("HStack(alignment: .top, spacing: 12)", view)
        self.assertIn("completedWODScalingFields(movementID: item.id", view)
        self.assertIn("completedWODScalingFields(movementID: move.id", view)
        self.assertIn('"REPS REALES"', view)
        self.assertIn('"KG REALES"', view)
        self.assertNotIn("Prescrito (editable)", view)
        self.assertNotIn("Realizado (opcional)", view)
        self.assertNotIn("En blanco = prescripción original", view)
        self.assertNotIn('DisclosureGroup("Corregir prescripción o adaptación")', view)
        self.assertNotIn('DisclosureGroup("Adaptación del movimiento (opcional)")', view)
        self.assertIn("completedScoreEditor(for: block)", view)

    def test_visual_prefill_does_not_create_false_scaled_results(self):
        view = read("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("private func completedPrescribedValue(", view)
        self.assertIn("return entry.adaptedReps.map(String.init) ?? prescribed", view)
        self.assertIn('return entry.adaptedWeightKg.map { String(format: "%g", $0) } ?? prescribed', view)
        self.assertIn("reps == Int(prescribed) ? nil : reps", view)
        self.assertIn("abs(kg - $0) < 0.05", view)
        self.assertNotIn("private func completedWODRxValue(", view)
        self.assertNotIn("private func completedStrengthRxValue(", view)

    def test_completed_bridge_does_not_replace_rx_with_logged_sets(self):
        domain = read("Packages/ReperaDomain/Sources/ReperaDomain/CompletedWorkoutEditing.swift")
        self.assertIn("preservePrescription: source.wodFormat?.resultCapture", domain)
        self.assertIn("original?.explicitPlannedSets ?? entry.plannedSets", domain)
        self.assertIn("block.wodFormat == nil || block.wodFormat?.resultCapture == .perMovementSets", domain)
        self.assertIn("entry.plannedSets = sets", domain)
        self.assertIn("var entry = old ?? SessionExercise(", domain)
        self.assertIn("updated.wodResults = updated.wodResults.compactMap", domain)
        history = read("Apps/Repera/Sources/HistoryView.swift")
        self.assertIn("store.saveWorkout(updated)", history)

    def test_actual_equal_to_rx_is_not_falsely_scaled(self):
        model = read("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        self.assertIn("public var hasRecordedWODExecution: Bool", model)
        self.assertIn("adaptedReps != plannedSets.first?.targetReps", model)
        self.assertIn("abs(adaptedWeightKg - rxKg) >= 0.05", model)
        self.assertIn('hasWODScaling ? "Adaptado · " : "Realizado · "', model)
        review = read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        self.assertIn("let isScaled = session.exercises.contains", review)
        self.assertIn("if !isScaled, let bands = template?.scoreBands", review)
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("sessionReviewFormulaVersion = 11", store)


if __name__ == "__main__":
    unittest.main()
