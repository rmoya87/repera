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
        self.assertIn("availableClockWidth / 3.05", screen)
        self.assertIn("geometry.size.height * (landscape ? 0.36 : 0.235)", screen)
        self.assertLess(layout.index("clockBlock(digitHeight: digitHeight)"),
                        layout.index("exerciseDetails"))
        self.assertIn("Spacer(minLength: 10)", layout)
        self.assertIn("TimerSystemAudioPanel()", layout)
        self.assertIn("controls(horizontal: false)", layout)

    def test_landscape_exercise_music_left_and_clock_buttons_right(self):
        screen = read("DigitalClockDisplay.swift")
        layout = screen.split("private func landscapeLayout(", 1)[1].split(
            "private func clockBlock(", 1
        )[0]
        self.assertLess(layout.index("exerciseDetails"),
                        layout.index("clockBlock(digitHeight: digitHeight)"))
        self.assertIn("TimerSystemAudioPanel()", layout)
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

    def test_native_airplay_access_does_not_claim_other_apps_now_playing(self):
        screen = read("DigitalClockDisplay.swift")
        self.assertIn("import AVKit", screen)
        self.assertIn("AVRoutePickerView", screen)
        self.assertIn("UIViewRepresentable", screen)
        self.assertIn("Centro de control", screen)
        self.assertNotIn("MPNowPlayingInfoCenter", screen.split(
            "private struct SystemAudioRoutePicker:", 1
        )[1])
        self.assertNotIn("MPRemoteCommandCenter", screen)


if __name__ == "__main__":
    unittest.main()
