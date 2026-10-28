"""Regression checks for the finished standalone timer screen.

These source contracts complement (but don't replace) a TestFlight UI check.
"""
from pathlib import Path
import unittest

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"
TIMER = (SRC / "StandaloneTimerView.swift").read_text(encoding="utf-8")


class TimerCompletionLayoutTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.summary = TIMER.split("private var timerSummaryScreen: some View {", 1)[1].split(
            "private func recordTimerCompletion()", 1
        )[0]

    def test_completed_screen_uses_workout_detail_layout(self):
        self.assertIn('OGScrollablePageTitle("Temporizador finalizado")', self.summary)
        self.assertIn(".ogScrollingTitleListRow()", self.summary)
        self.assertIn("WorkoutSummaryTile(", self.summary)
        self.assertIn(".ogCardListRow(top: 0, bottom: 2)", self.summary)
        self.assertIn(".ogListChrome()", self.summary)
        self.assertIn(".listSectionSpacing(12)", self.summary)
        self.assertIn(".ogScrollingTitleNav()", self.summary)
        self.assertNotIn('Section("Resumen del temporizador")', self.summary)

    def test_done_button_is_green_circle_with_adaptive_check(self):
        self.assertIn('Image(systemName: "checkmark")', self.summary)
        self.assertIn(".background(OG.accent, in: Circle())", self.summary)
        self.assertIn("colorScheme == .dark ? Color.black : Color.white", self.summary)
        self.assertIn('accessibilityLabel("Listo")', self.summary)
        self.assertIn("showClock = false", self.summary)
        self.assertNotIn('Button("Listo")', self.summary)

    def test_place_is_editable_without_helper_copy(self):
        self.assertIn('Text("Lugar").textCase(nil)', self.summary)
        self.assertIn("WorkoutPlacePickerRow(pin: Binding(", self.summary)
        self.assertIn("summary.locationPin = updated", self.summary)
        self.assertIn("StandaloneTimerCompletionStore.save(summary)", self.summary)
        self.assertNotIn("Toca el lugar o el mapa para cambiarlo", self.summary)

    def test_summary_uses_actual_saved_completion_details(self):
        self.assertIn("summary.configuration.mode.title", self.summary)
        self.assertIn("summary.configuredSeconds", self.summary)
        self.assertIn("summary.configuration.rounds", self.summary)
        self.assertIn("summary.configuration.workTotalSeconds", self.summary)
        self.assertIn("summary.configuration.restTotalSeconds", self.summary)
        self.assertIn('Locale(identifier: "es_ES")', self.summary)
        self.assertIn("completedSummary = summary", TIMER)
        self.assertIn("StandaloneTimerCompletionStore.save(summary)", TIMER)


if __name__ == "__main__":
    unittest.main()
