"""Regression contracts for editing the results of already finished Repera workouts.

A completed WOD keeps its score or real logged sets, never fabricated planned
sets. Swift domain tests cover the resulting model state on Xcode 27.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


class CompletedWorkoutEditContractTests(unittest.TestCase):
    def test_every_global_wod_format_has_an_editable_result(self):
        editor = source("Apps/Repera/Sources/PlanView.swift")
        model = source("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        self.assertIn("completedScoreEditor(for: block)", editor)
        self.assertIn("format.resultCapture != .perMovementSets", editor)
        self.assertIn("private func addCompletedResult(for block: RoutineBlock)", editor)
        self.assertIn('Label("Añadir resultado", systemImage: "plus.circle")', editor)
        self.assertIn("completedDetails?.wodResults.append(WODBlockResult(", editor)
        self.assertIn("case .totalReps:", editor)
        self.assertIn("case .elapsedTime:", editor)
        for fmt in ("forTime", "chipper", "afap", "ladder", "buyInCashOut"):
            self.assertIn("."+fmt, model.split("public var resultCapture:", 1)[1].split("public enum WODResultCapture", 1)[0])
        self.assertIn("case .amrap, .deathBy, .maxEffort:", model)

    def test_completed_layout_uses_session_identity_not_late_state(self):
        editor = source("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("private var isEditingCompletedWorkout: Bool", editor)
        self.assertIn("onApplyCompleted != nil && completedSession != nil", editor)
        self.assertIn("private var completedWorkoutDraft: WorkoutSession?", editor)
        self.assertIn("completedDetails ?? completedSession", editor)
        score = editor.split("private func completedScoreEditor(", 1)[1].split("private func addCompletedResult(", 1)[0]
        self.assertIn("if isEditingCompletedWorkout,", score)
        self.assertNotIn("completedDetails != nil", score)
        wod = editor.split("private func wodBlock(index: Int)", 1)[1].split("private func resolvedExercise(", 1)[0]
        self.assertIn("if !move.isRest, isEditingCompletedWorkout,", wod)
        self.assertIn("format.resultCapture != .perMovementSets", wod)
        self.assertIn("completedWODScalingFields(movementID: move.id", wod)
        self.assertNotIn('DisclosureGroup("Adaptación del movimiento (opcional)")', wod)
        self.assertNotIn("} else if completedDetails != nil,", wod)

    def test_scoring_follows_format_not_block_kind(self):
        editor = source("Apps/Repera/Sources/PlanView.swift")
        bridge = source("Packages/ReperaDomain/Sources/ReperaDomain/CompletedWorkoutEditing.swift")
        self.assertIn("completedStrengthPrescription(index: index)", editor)
        self.assertIn("if isEditingCompletedWorkout,", editor)
        self.assertIn("format.resultCapture != .perMovementSets", editor)
        self.assertIn('let block = routine.blocks.first(where: { $0.id == saved.id })', bridge)
        self.assertNotIn('$0.id == result.id && $0.kind == .wod', bridge)

    def test_amrap_and_death_by_cannot_be_confused_with_elapsed_time(self):
        editor = source("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("if format == .amrap || format == .deathBy", editor)
        self.assertIn('title: "Rondas completas"', editor)
        self.assertIn('title: "Reps adicionales"', editor)
        self.assertIn('title: "Repeticiones máximas"', editor)
        self.assertIn("Solo las repeticiones de la ronda incompleta", editor)
        self.assertIn('title: "Minutos"', editor)
        self.assertIn('title: "Segundos"', editor)
        self.assertIn("Tiempo real empleado (no el time cap).", editor)

    def test_per_movement_result_is_not_confused_with_prescription(self):
        editor = source("Apps/Repera/Sources/PlanView.swift")
        self.assertIn("private func completedPrescribedValue(", editor)
        self.assertIn("reps == Int(prescribed) ? nil : reps", editor)
        self.assertIn('Text(logged ? "Series registradas" : "Sin series registradas · prescripción")', editor)
        self.assertIn("InlineWODMovementSets(", editor)
        self.assertIn("format.resultCapture != .perMovementSets", editor)

    def test_previous_wod_scores_are_preserved_when_format_changes(self):
        editor = source("Apps/Repera/Sources/PlanView.swift")
        history = source("Apps/Repera/Sources/HistoryView.swift")
        bridge = source("Packages/ReperaDomain/Sources/ReperaDomain/CompletedWorkoutEditing.swift")
        self.assertIn("updated.wodResults.removeAll {", bridge)
        self.assertIn("$0.id == block.id && ($0.format == nil || $0.format == format)", bridge)
        self.assertIn("return result", bridge)
        self.assertIn("historicalResults: historical", history)
        self.assertIn("Resultado de formato anterior", history)
        self.assertIn("Se conserva el resultado anterior", editor)

    def test_store_saves_edited_session_instead_of_creating_a_new_one(self):
        history = source("Apps/Repera/Sources/HistoryView.swift")
        editor = source("Apps/Repera/Sources/PlanView.swift")
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/CompletedWorkoutEditing.swift")
        self.assertIn("CompletedWorkoutEditing.applying(", history)
        self.assertIn("store.saveWorkout(updated)", history)
        self.assertIn("onApplyCompleted(edited, completedDetails)", editor)
        self.assertIn("updated.wodResults = updated.wodResults.compactMap", domain)
        self.assertIn("if let recordedFormat = result.format, recordedFormat != currentFormat", domain)
        self.assertIn("entry.blockRestBetweenRoundsSeconds = block.restBetweenRoundsSeconds", domain)
        self.assertIn("var updated = original", domain)
        self.assertIn("updated.exercises = output", domain)


if __name__ == "__main__":
    unittest.main()
