"""Cross-layer regression guards: global WOD score + optional scaled movement data.

Domain Swift tests cover real scoring, Codable round trips and finished edits.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class ScaledWODContractTests(unittest.TestCase):
    def test_scaled_movement_data_is_independent_of_logged_sets(self):
        model = read("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        fragment = model.split("public struct SessionExercise:", 1)[1].split("public enum SessionPhase", 1)[0]
        self.assertIn("public var adaptedReps: Int?", fragment)
        self.assertIn("public var adaptedWeightKg: Double?", fragment)
        self.assertIn("case adaptedReps, adaptedWeightKg", fragment)
        self.assertIn("adaptedReps = try c.decodeIfPresent(", fragment)
        self.assertIn("adaptedWeightKg = try c.decodeIfPresent(", fragment)
        self.assertIn("public var adjustedSummaryLine: String?", fragment)
        bridge = read("Packages/ReperaDomain/Sources/ReperaDomain/CompletedWorkoutEditing.swift")
        self.assertIn("var entry = old ?? SessionExercise(", bridge)
        self.assertIn("if let old, !old.loggedSets.isEmpty", bridge)

    def test_finished_editor_keeps_global_result_and_scaled_fields(self):
        view = read("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("completedScoreEditor(for: block)", view)
        self.assertIn("completedWODScalingFields(movementID: move.id", view)
        self.assertIn("completedWODScalingFields(movementID: item.id", view)
        self.assertIn("private func completedWODScaledValue(", view)
        self.assertIn('Text("Realizado (opcional)")', view)
        self.assertIn('Text("Prescrito (editable)")', view)
        self.assertIn("adaptedReps = nil", view)
        self.assertIn("adaptedWeightKg = nil", view)
        self.assertIn("scaledInputDrafts[key] = input", view)
        self.assertIn("ensureCompletedWorkoutDraft()", view)
        self.assertIn("completedWODRxFields(blockIndex: index, movementIndex: mIndex", view)
        self.assertIn("onApplyCompleted(edited, completedDetails)", view)

    def test_mcp_projects_scaled_values_without_fabricating_logged_sets(self):
        api = read("supabase/functions/repera-mcp/index.ts")
        self.assertIn("adaptedReps?: number | null", api)
        self.assertIn("adaptedWeightKg?: number | null", api)
        self.assertIn("scaled_movement: entry.adaptedReps != null", api)
        self.assertIn("actual_weight_kg: entry.adaptedWeightKg ?? null", api)
        self.assertIn("scaled_movement_semantics:", api)
        self.assertIn("sets: (entry.loggedSets ?? []).map", api)

    def test_scaled_rating_does_not_claim_rx_or_pr(self):
        pace = read("Packages/ReperaDomain/Sources/ReperaDomain/MovementPaceStandards.swift")
        review = read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        history = read("Apps/Repera/Sources/HistoryView.swift")
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("entry.adaptedReps.map(Double.init)", pace)
        self.assertIn("entry.adaptedWeightKg", pace)
        self.assertIn("line.effortMultiplier", pace)
        self.assertIn("if !isScaled, let bands = template?.scoreBands", review)
        self.assertIn("let historyNote = isScaled ? nil", review)
        self.assertIn("Versión adaptada", review)
        self.assertIn("partial / max(1, workPerRound)", review)
        self.assertIn("if !isScaled,", review)
        self.assertIn("sessionReviewFormulaVersion = 11", store)
        self.assertIn("exercise.adjustedSummaryLine", history)


if __name__ == "__main__":
    unittest.main()
