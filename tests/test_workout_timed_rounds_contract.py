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

    def test_new_strength_blocks_have_no_implicit_emom_interval(self):
        models = (ROOT / "Packages" / "ReperaDomain" / "Sources"
                  / "ReperaDomain" / "Models.swift").read_text(encoding="utf-8")
        strength = models.split("public static func strength(title:", 1)[1].split(
            "/// Copia profunda", 1
        )[0]
        self.assertIn("emomIntervalSeconds: nil", strength)
        self.assertIn("emomIntervalSeconds: Int? = 60", models)

    def test_setup_is_presented_before_first_timer_start(self):
        self.assertIn(".sheet(item: $manualRoundSetup, onDismiss:", PLAY)
        self.assertIn("confirmedManualRoundStart = nil", PLAY)
        self.assertIn("startBlockClock(\n                for: current,", PLAY)
        sheet = PLAY.split("private func manualRoundDurationSheet(", 1)[1].split(
            "private func startBlockClock(", 1
        )[0]
        self.assertIn('Text("Configurar temporizador")', sheet)
        self.assertIn('title: "Trabajar por ronda"', sheet)
        self.assertIn('title: "Descansar entre rondas"', sheet)
        self.assertIn("minutes: $manualRoundMinutes", sheet)
        self.assertIn("seconds: $manualRoundSeconds", sheet)
        self.assertIn("minutes: $manualRoundRestMinutes", sheet)
        self.assertIn("seconds: $manualRoundRestSeconds", sheet)
        self.assertIn(".disabled(manualRoundMinutes == 0 && manualRoundSeconds == 0)", sheet)
        self.assertIn("current.id == setup.exerciseID", sheet)
        self.assertIn("manualRoundMinutes * 60 + manualRoundSeconds", sheet)
        self.assertIn("manualRoundTimeRow(", sheet)
        self.assertIn("TimerNumericInput(label:", sheet)
        self.assertIn("range: 0...59", sheet)
        self.assertNotIn("Stepper(", sheet)
        self.assertIn("confirmedManualRoundStart = ConfirmedManualRoundStart(", sheet)
        self.assertIn("restSeconds: manualRoundRestMinutes * 60 + manualRoundRestSeconds", sheet)
        self.assertIn("manualRoundSetup = nil", sheet)
        self.assertNotIn("startBlockClock(for: current, manualRoundSeconds: seconds", sheet)
        # Todas las entradas del reloj (botón por bloque, selector y automático)
        # usan el mismo gate; solo el gate dispara configure directamente.
        self.assertGreaterEqual(PLAY.count("requestBlockClockStart(for: current)"), 4)

    def test_setup_uses_shared_numeric_inputs_liquid_glass_and_fits_content(self):
        sheet = PLAY.split("private func manualRoundDurationSheet(", 1)[1].split(
            "private func startBlockClock(", 1
        )[0]
        self.assertIn(".ogFittedHeight()", sheet)
        self.assertIn(".ogFittedSheet()", sheet)
        self.assertNotIn(".presentationDetents([.height(", sheet)
        self.assertNotIn(".presentationBackground(OG.surface)", sheet)
        self.assertNotIn("Spacer(minLength: 0)", sheet)
        self.assertIn(".fixedSize(horizontal: false, vertical: true)", sheet)
        self.assertIn('private func manualRoundTimeRow(', sheet)
        self.assertNotIn(".buttonStyle(.borderedProminent)", sheet)
        self.assertIn(".foregroundStyle(.black)", sheet)
        self.assertIn(".background(OG.accent, in: Capsule())", sheet)
        self.assertIn('Text("Iniciar temporizador")', sheet)
        self.assertIn("TimerNumericInput(label: \"MIN\"", sheet)
        self.assertIn("TimerNumericInput(label: \"SEG\"", sheet)

        timer = (IOS / "StandaloneTimerView.swift").read_text(encoding="utf-8")
        numeric = timer.split("struct TimerNumericInput: View {", 1)[1].split(
            "struct StandaloneTimerView: View {", 1
        )[0]
        self.assertIn("OGNumericTextField(", numeric)
        self.assertIn(
            ".glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))",
            numeric,
        )
        self.assertIn(".frame(height: 48)", numeric)
        self.assertIn("compactIntrinsicHeight: 48", numeric)
        self.assertIn(".frame(height: 64, alignment: .top)", numeric)
        self.assertIn(".clipped()", numeric)
        self.assertNotIn(".frame(maxWidth: .infinity, minHeight: 48)", numeric)
        self.assertNotIn("private struct TimerNumericInput", timer)
        self.assertIn("TimerNumericInput(label:", timer)

    def test_round_fields_cannot_force_fullscreen_sheet_via_uikit_layout(self):
        play = PLAY.split("private func manualRoundTimeRow(", 1)[1].split(
            "/// Reloj a pantalla completa", 1
        )[0]
        self.assertIn(".frame(width: 84, height: 64, alignment: .top)", play)
        self.assertIn(".frame(width: 176, height: 64, alignment: .top)", play)
        self.assertIn(".frame(height: 72, alignment: .center)", play)
        self.assertGreaterEqual(play.count(".clipped()"), 3)
        self.assertNotIn(".frame(maxWidth: 184)", play)

        theme = (IOS / "Theme.swift").read_text(encoding="utf-8")
        field = theme.split("struct OGNumericTextField: UIViewRepresentable {", 1)[1].split(
            "private func configure(", 1
        )[0]
        self.assertIn("var compactIntrinsicHeight: CGFloat? = nil", field)
        self.assertIn("func sizeThatFits(", field)
        self.assertIn("guard let compactIntrinsicHeight else { return nil }", field)
        self.assertIn("height: compactIntrinsicHeight", field)
        # No altera los demás campos de series que no solicitan altura
        # intrínseca específica.
        self.assertIn("guard let compactIntrinsicHeight else { return nil }", field)

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
        self.assertIn("manualRoundSeconds\n                ?? current.blockWorkSeconds ?? explicitInterval", configured)
        self.assertIn("customPhaseDurations: phaseDurations", configured)
        self.assertIn("customPhaseSubtitles: phaseLabels", configured)
        self.assertIn("customRoundNumbers: phaseRoundNumbers", configured)
        self.assertIn("customRoundsTotal: rounds", configured)
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
        self.assertIn('clock.subtitle.contains("Descanso")', dock)
        self.assertIn("clock.handlePrimary()", dock)
        self.assertIn("clock.finishByUser()", dock)
        self.assertIn(".disabled(!clock.canFinishByUser)", dock)
        self.assertNotIn('"Ver reloj"', dock)
        self.assertNotIn("clock.stop()", dock)
        self.assertLess(dock.index("clock.showClock()"), dock.index("clock.handlePrimary()"))
        self.assertLess(dock.index("clock.finishByUser()"), dock.index("clock.handlePrimary()"))
        self.assertIn('Image(systemName: "flag.checkered")', dock)
        self.assertIn('Image(systemName: clock.isRunning ? "pause.fill" : "play.fill")', dock)
        self.assertIn("clock.isRunning ? OG.yellow : OG.accent", dock)
        self.assertIn(".background(.black, in: Circle())", dock)
        self.assertIn(".background(OG.surface2, in: Circle())", dock)
        self.assertIn(".glassEffect(.regular.tint(OG.surface2).interactive(), in: .circle)", dock)
        self.assertIn(".glassEffect(.regular, in: .rect(cornerRadius: 18))", dock)
        self.assertNotIn('.background(OG.surface, in: RoundedRectangle(', dock)

    def test_implicit_sixty_second_interval_does_not_skip_free_block_setup(self):
        request = PLAY.split("private func requestBlockClockStart(", 1)[1].split(
            "private func manualRoundDurationSheet(", 1
        )[0]
        self.assertIn("current.blockIntervalSeconds != 60 || current.wodFormat == .strength", request)
        self.assertIn("let rest = max(0, current.blockRestBetweenRoundsSeconds ?? 0)", request)
        self.assertIn("manualRoundRestMinutes = rest / 60", request)
        self.assertIn("manualRoundRestSeconds = rest % 60", request)
        configured = PLAY.split("private func startBlockClock(", 1)[1].split(
            "private func metaPill(", 1
        )[0]
        self.assertIn("current.blockIntervalSeconds == 60", configured)
        self.assertIn("&& current.wodFormat == nil", configured)

    def test_work_rest_round_phases_have_no_rest_after_last_round(self):
        configured = PLAY.split("private func startBlockClock(", 1)[1].split(
            "private func metaPill(", 1
        )[0]
        self.assertIn("for round in 1...rounds", configured)
        self.assertIn("phaseDurations.append(roundDuration)", configured)
        self.assertIn("if round < rounds && rest > 0", configured)
        self.assertIn("phaseDurations.append(rest)", configured)
        self.assertIn("phaseRoundNumbers.append(round)", configured)
        self.assertIn('phaseLabels.append("Descanso entre rondas")', configured)
        self.assertIn("customRoundNumbers: phaseRoundNumbers", configured)
        self.assertIn("customRoundsTotal: rounds", configured)

    def test_setup_sheet_dismisses_before_fullscreen_clock_is_presented(self):
        show = PLAY.split(".sheet(item: $manualRoundSetup, onDismiss:", 1)[1].split(
            ".toolbar {", 1
        )[0]
        self.assertIn("confirmedManualRoundStart", show)
        self.assertIn("current.id == selection.exerciseID", show)
        self.assertIn("manualRoundRestSeconds: selection.restSeconds", show)
        self.assertLess(show.index("confirmedManualRoundStart = nil"),
                        show.index("startBlockClock("))

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
