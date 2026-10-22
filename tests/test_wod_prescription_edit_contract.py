"""Finished WOD prescription is editable and distinct from performed scaling.

Swift domain tests validate round-tripping original Rx, real sets and block score.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class CompletedWODPrescriptionTests(unittest.TestCase):
    def test_finished_wod_displays_original_and_performed_separately(self):
        view = read("Apps/Repera/Sources/PlanView.swift")
        self.assertIn('Text("Prescrito (editable)")', view)
        self.assertIn('Text("Realizado (opcional)")', view)
        self.assertIn('label: "KG PRESCRITOS"', view)
        self.assertIn('label: "REPS PRESCRITAS"', view)
        self.assertIn('TextField("Sin adaptar", text: completedWODScaledValue', view)
        self.assertIn("completedWODRxFields(blockIndex: index, movementIndex: mIndex", view)
        self.assertIn("completedStrengthRxFields(blockIndex: index, exerciseIndex: itemIndex", view)
        self.assertIn("completedWODScalingFields(movementID: move.id", view)
        self.assertIn("completedScoreEditor(for: block)", view)

    def test_rx_input_persists_both_source_movement_and_planned_sets(self):
        view = read("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("private func completedWODRxValue(", view)
        self.assertIn("private func completedStrengthRxValue(", view)
        self.assertIn("scaledInputDrafts[key] = input", view)
        self.assertIn("movements[movementIndex].weightMaleKg = value", view)
        self.assertIn("movements[movementIndex].reps = reps", view)
        self.assertIn("explicit[i].targetWeightKg = value", view)
        self.assertIn("explicit[i].targetReps = reps", view)
        self.assertIn("plannedSets[i].targetWeightKg = value", view)
        self.assertIn("plannedSets[i].targetReps = reps", view)
        self.assertIn("if hasScheme", view)
        self.assertIn("if exercise.loggingStyle == .loadAndReps", view)

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
        self.assertIn("sessionReviewFormulaVersion = 10", store)


if __name__ == "__main__":
    unittest.main()
