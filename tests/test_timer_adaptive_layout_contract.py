"""Contrato de reloj en retrato/paisaje y acceso público a audio.

SwiftUI necesita además validación visual en un dispositivo físico: este
contrato evita regresiones sobre controles y temporización, no la sustituye.
"""
import unittest
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def read(filename):
    return (SRC / filename).read_text(encoding="utf-8")


class TimerAdaptiveLayoutTests(unittest.TestCase):
    def test_portrait_clock_is_larger_and_moves_exercise_below_it(self):
        screen = read("DigitalClockDisplay.swift")
        layout = screen.split("private func portraitLayout(", 1)[1].split(
            "private func landscapeLayout(", 1
        )[0]
        self.assertIn("availableClockWidth / widthFactor", screen)
        self.assertIn("hasRound ? 4.22 : 2.76", screen)
        self.assertIn("geometry.size.width - sideWidth - horizontalInset", screen)
        self.assertNotIn("max(55, availableClockWidth", screen)
        self.assertIn("geometry.size.height * (landscape ? 0.36 : 0.235)", screen)
        self.assertLess(layout.index("clockBlock(digitHeight: digitHeight)"),
                        layout.index("exerciseDetails"))
        self.assertIn("VStack(spacing: 38)", layout)
        self.assertIn("exerciseDetails(landscape: false)", layout)
        self.assertIn("Spacer(minLength: 16)", layout)
        self.assertNotIn("TimerSystemAudioPanel()", layout)
        self.assertIn("controls(horizontal: false)", layout)

    def test_landscape_exercise_music_left_and_clock_buttons_right(self):
        screen = read("DigitalClockDisplay.swift")
        layout = screen.split("private func landscapeLayout(", 1)[1].split(
            "private func clockBlock(", 1
        )[0]
        self.assertLess(layout.index("exerciseDetails"),
                        layout.index("clockBlock(digitHeight: digitHeight)"))
        self.assertIn("exerciseDetails(landscape: true)", layout)
        self.assertIn(".frame(maxHeight: .infinity, alignment: .center)", layout)
        self.assertNotIn("TimerSystemAudioPanel()", layout)
        self.assertIn("controls(horizontal: true)", layout)
        buttons = screen.split("private func controls(horizontal:", 1)[1]
        self.assertIn("HStack(spacing: 12)", buttons)
        self.assertIn("pauseOrResumeButton", buttons)
        self.assertIn("finishButton", buttons)

    def test_no_skip_or_ellipsis_and_user_can_pause_precounter(self):
        screen = read("DigitalClockDisplay.swift")
        free = read("StandaloneTimerView.swift")
        workout = read("WorkoutView.swift")
        clock = read("WorkoutClockCoordinator.swift")
        self.assertNotIn("onSkip", screen)
        self.assertNotIn("onSkip:", workout)
        self.assertNotIn("onSkip:", free)
        self.assertNotIn('return "…"', clock)
        self.assertNotIn('return "…"', free)
        self.assertIn('return isRunning ? "Pausar" : "Continuar"', clock)
        self.assertIn('return isRunning ? "Pausar" : "Continuar"', free)
        self.assertIn("if isPreCountdown {\n            pause()", clock)
        self.assertIn("pausedPreCountdownRemaining", clock)
        self.assertIn("startPreCountdown(seconds: max(1, Int(ceil(seconds))))", clock)
        self.assertIn("pausedPreCountdownRemaining == nil", clock)

    def test_no_false_now_playing_panel_for_unreadable_external_audio(self):
        screen = read("DigitalClockDisplay.swift")
        self.assertNotIn("Audio del iPhone", screen)
        self.assertNotIn("TimerSystemAudioPanel", screen)
        self.assertNotIn("SystemAudioRoutePicker", screen)
        self.assertNotIn("AVRoutePickerView", screen)
        self.assertNotIn("MPNowPlayingInfoCenter", screen)
        self.assertNotIn("MPRemoteCommandCenter", screen)

    def test_thumbnail_is_larger_and_timer_action_is_circular_liquid_glass(self):
        screen = read("DigitalClockDisplay.swift")
        self.assertIn("size: landscape ? 112 : 100", screen)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", screen)
        play = read("WorkoutView.swift")
        start = play.index("private func content(_ session: WorkoutSession)")
        end = play.index("private func workoutExerciseRow(", start)
        block = play[start:end]
        self.assertIn("OGToolbarGlassButton(", block)
        self.assertIn('systemName: "timer"', block)
        self.assertIn("hitSize: 44", block)
        self.assertIn("appliesGlass: true", block)
        self.assertNotIn(".background(OG.surface2, in: RoundedRectangle(cornerRadius: 12", block)


if __name__ == "__main__":
    unittest.main()
