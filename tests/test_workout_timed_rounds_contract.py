"""Contrato de cronómetro por rondas del entreno.

Verifica que el reloj de Play pide duración solo cuando no hay una
prescripción temporal, respeta EMOM/Tabata y no descarta el resultado
al terminar desde la tarjeta minimizada. La UI final requiere Xcode.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
PLAY = (IOS / "WorkoutView.swift").read_text(encoding="utf-8")
CLOCK = (IOS / "WorkoutClockCoordinator.swift").read_text(encoding="utf-8")
SCREEN = (IOS / "DigitalClockDisplay.swift").read_text(encoding="utf-8")


class WorkoutTimedRoundsTests(unittest.TestCase):
    def test_only_unconfigured_free_blocks_ask_for_round_duration(self):
        request = PLAY.split("private func requestBlockClockStart(", 1)[1].split(
            "private func manualRoundDurationSheet(", 1
        )[0]
        self.assertIn("current.wodFormat == nil || current.wodFormat == .strength", request)
        self.assertIn("current.blockTimeCapMinutes", request)
        self.assertIn("current.blockIntervalSeconds", request)
        self.assertIn("current.blockWorkSeconds", request)
        self.assertIn("guard freeFormat && !hasPrescribedDuration else", request)
        self.assertIn("startBlockClock(for: current)", request)
        self.assertIn("manualRoundSetup = ManualRoundSetup(", request)
        self.assertIn("rounds: prescribedRoundCount(for: current)", request)
        self.assertIn("current.blockRounds ?? planned", request)
        self.assertIn("map { $0.plannedSets.count }.max()", request)

    def test_setup_is_presented_before_first_timer_start(self):
        self.assertIn(".sheet(item: $manualRoundSetup)", PLAY)
        sheet = PLAY.split("private func manualRoundDurationSheet(", 1)[1].split(
            "private func startBlockClock(", 1
        )[0]
        self.assertIn('Text("Duración de cada ronda")', sheet)
        self.assertIn("Stepper(value: $manualRoundMinutes, in: 0...120)", sheet)
        self.assertIn("Stepper(value: $manualRoundSeconds, in: 0...55, step: 5)", sheet)
        self.assertIn(".disabled(manualRoundMinutes == 0 && manualRoundSeconds == 0)", sheet)
        self.assertIn("current.id == setup.exerciseID", sheet)
        self.assertIn("manualRoundMinutes * 60 + manualRoundSeconds", sheet)
        self.assertIn("startBlockClock(for: current, manualRoundSeconds: seconds, manualRounds: setup.rounds)", sheet)
        # Todas las entradas del reloj (botón por bloque, selector y automático)
        # usan el mismo gate; solo el gate dispara configure directamente.
        self.assertGreaterEqual(PLAY.count("requestBlockClockStart(for: current)"), 4)

    def test_prescribed_intervals_are_not_overridden_by_setup(self):
        configured = PLAY.split("private func startBlockClock(", 1)[1].split(
            "private func metaPill(", 1
        )[0]
        for f in (".emom", ".tabata", ".circuit", ".deathBy"):
            self.assertIn(f"case {f}:", configured)
        self.assertIn("current.blockIntervalSeconds ?? 60", configured)
        self.assertIn("current.blockWorkSeconds ?? 20", configured)
        self.assertIn("current.blockRestSeconds ?? 10", configured)
        self.assertIn("current.plannedIntervals ?? current.blockRounds", configured)
        self.assertIn("manualRoundSeconds\n                ?? current.blockIntervalSeconds ?? current.blockWorkSeconds", configured)
        self.assertIn("totalIntervals: rounds,", configured)
        self.assertIn("initialCountdown: roundDuration,", configured)
        self.assertIn("intervalMode: true,", configured)

    def test_fullscreen_round_counter_and_glass_minimize(self):
        screen = PLAY.split("private var wodFullscreenClock: some View", 1)[1].split(
            "private func presentWODConfirmIfNeeded()", 1
        )[0]
        self.assertIn("clock.isIntervalMode", screen)
        self.assertIn("clock.displayedRound", screen)
        self.assertIn("roundNumber: roundDisplay", screen)
        self.assertIn("totalRounds: clock.isIntervalMode ? clock.displayedRoundsTotal : nil", screen)
        self.assertIn('closeSymbol: "chevron.down"', screen)
        self.assertIn('closeAccessibilityLabel: "Minimizar reloj"', screen)
        self.assertIn("onClose: { clock.minimize() }", screen)
        top = SCREEN.split("private var topBar: some View", 1)[1].split(
            "private func exerciseDetails(", 1
        )[0]
        self.assertIn("systemName: closeSymbol", top)
        self.assertIn("accessibilityLabel: closeAccessibilityLabel", top)
        self.assertIn("appliesGlass: true", top)
        self.assertIn('var closeSymbol: String = "xmark"', SCREEN)

    def test_minimized_card_tap_reopens_and_pause_finish_are_adjacent(self):
        dock = PLAY.split("private var minimizedTimerDock: some View", 1)[1].split(
            "private var restDock: some View", 1
        )[0]
        self.assertIn("Button {\n                    clock.showClock()", dock)
        self.assertIn("clock.displayedRound", dock)
        self.assertIn("clock.displayedRoundsTotal", dock)
        self.assertIn("clock.handlePrimary()", dock)
        self.assertIn("clock.finishByUser()", dock)
        self.assertIn(".disabled(!clock.canFinishByUser)", dock)
        self.assertNotIn('"Ver reloj"', dock)
        self.assertNotIn("clock.stop()", dock)
        self.assertLess(dock.index("clock.showClock()"), dock.index("clock.handlePrimary()"))
        self.assertLess(dock.index("clock.handlePrimary()"), dock.index("clock.finishByUser()"))
        self.assertIn('Text("Terminar")', dock)

    def test_finish_preserves_elapsed_not_remaining_and_does_not_complete_sets(self):
        self.assertIn("hasStarted && !isPreCountdown && pausedPreCountdownRemaining == nil", CLOCK)
        finished = CLOCK.split("func finishByUser()", 1)[1].split(
            "func consumePendingEnd()", 1
        )[0]
        self.assertIn("phaseDurations.prefix(intervalIndex)", finished)
        self.assertIn("configuredCapSeconds - displaySeconds", finished)
        self.assertIn("pendingEndReason = .userFinished", finished)
        self.assertIn("stop(keepVisible: false)", finished)
        confirm = PLAY.split("private func presentWODConfirmIfNeeded()", 1)[1].split(
            "private func presentScoreEditor(", 1
        )[0]
        self.assertIn("finishedTimedBlockID = current.blockId ?? current.id", confirm)
        self.assertNotIn("store.finishCurrentTimedBlock()", confirm)


if __name__ == "__main__":
    unittest.main()
