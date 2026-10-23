"""Pruebas de contrato de Play: registro de movimientos y reloj por formato.

Los tests de comportamiento del dominio viven en SessionControllerTests.swift.
La UI de Play debe mantener los campos de registro en todos los formatos WOD.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"


class PlayWODContractTests(unittest.TestCase):
    def read(self, name: str) -> str:
        return (SOURCES / name).read_text(encoding="utf-8")

    def test_set_row_argument_order_matches_the_swift_memberwise_initializer(self):
        """A stored-property memberwise initializer requires argument labels in order."""
        play = self.read("WorkoutView.swift")
        component = self.read("Theme.swift")
        call = play.split("OGSetEntryRow(", 1)[1].split("onFirstCommit:", 1)[0]
        declaration = component.split("struct OGSetEntryRow: View {", 1)[1].split(
            "    var body: some View {", 1
        )[0]
        labels = (
            "rowID", "index", "previous", "firstValue", "secondValue",
            "nextEditableRowID", "firstAllowsDecimal", "showsConfirmation",
            "completed", "rir", "showsRIR", "onRIRChange", "focus",
        )
        positions = [call.index(label + ":") for label in labels]
        self.assertEqual(positions, sorted(positions))
        component_positions = [declaration.index("var " + label + ":") if
                               "var " + label + ":" in declaration else
                               declaration.index("var " + label + " ")
                               for label in labels]
        self.assertEqual(component_positions, sorted(component_pos    def test_all_wod_formats_show_inline_movement_fields_without_score_card(self):
        source = self.read("WorkoutView.swift")
        screen = source.split("private func content(_ session: WorkoutSession)", 1)[1]
        screen = screen.split("private func workoutExerciseRow(", 1)[0]
        exercise_rows = screen.split("ForEach(block.indexes, id:", 1)[1]
        exercise_rows = exercise_rows.split("if finishedTimedBlockID", 1)[0]
        self.assertIn("if session.currentIndex == index {", exercise_rows)
        self.assertIn("setsBoard(entry)", exercise_rows)
        self.assertIn("logForm(current)", exercise_rows)
        self.assertNotIn("resultCapture", exercise_rows)
        self.assertNotIn("blockScorePanel", source)
        self.assertNotIn('Text("Resultado · \\(format.displayName)")', screen)
        self.assertIn("presentScoreEditor(for:", source)
        self.assertIn("openBlockTimer(block, session: session)", screen)

 source)

    def test_interval_timer_does_not_finish_without_logging_sets(self):
        source = self.read("WorkoutView.swift")
        handler = source.split("private func presentWODConfirmIfNeeded()", 1)[1]
        handler = handler.split("private func presentScoreEditor(", 1)[0]
        self.assertIn("finishedTimedBlockID = current.blockId ?? current.id", handler)
        self.assertNotIn("store.finishCurrentTimedBlock()", handler)
        self.assertIn('Button("Finalizar bloque")', source)

    def test_timer_can_be_minimized_during_emom_and_tabata(self):
        source = self.read("WorkoutView.swift")
        clock = self.read("WorkoutClockCoordinator.swift")
        self.assertIn("minimizedTimerDock", source)
        self.assertIn("clock.minimize()", source)
        self.assertIn("clock.showClock()", source)
        self.assertIn("func minimize()", clock)
        self.assertIn("func showClock()", clock)
        self.assertIn("while !Task.isCancelled, isRunning", clock)

    def test_tabata_phases_resume_from_wall_clock_with_variable_durations(self):
        clock = self.read("WorkoutClockCoordinator.swift")
        self.assertIn("phaseDurations = (0..<max(1, totalIntervals)).map", clock)
        self.assertIn("phaseDurations.reduce(0, +)", clock)
        self.assertIn("boundary.addingTimeInterval(TimeInterval(intervalLength))", clock)
        self.assertIn("beginWorkPhase(from: pre)", clock)
        self.assertIn("displayedRoundsTotal", clock)

    def test_circuit_has_inter_round_rest_and_deathby_early_stop(self):
        workout = self.read("WorkoutView.swift")
        models = (DOMAIN / "Models.swift").read_text(encoding="utf-8")
        self.assertIn("blockRestBetweenRoundsSeconds", workout)
        self.assertIn('phases.append("Circuito · descanso entre rondas")', workout)
        self.assertIn("allowEarlyIntervalFinish: true", workout)
        self.assertIn("blockRestBetweenRoundsSeconds = try c.decodeIfPresent", models)

    def test_amrap_and_for_time_have_different_result_fields(self):
        source = self.read("WODResultConfirmSheet.swift")
        self.assertIn('numberInput("Rondas completas"', source)
        self.assertIn('numberInput("Reps adicionales"', source)
        self.assertIn('numberInput("Tiempo · m:ss"', source)
        self.assertIn("format == .amrap || format == .deathBy", source)


if __name__ == "__main__":
    unittest.main()
