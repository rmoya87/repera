"""Static regressions for workout location captions and Home calendar anchor.

The Swift layout still needs a device/Xcode build; these assertions guarantee
that UI spacing/scroll intent is represented in the checked-in code.
"""
from pathlib import Path
import unittest

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def swift(filename):
    return (SRC / filename).read_text(encoding="utf-8")


class WorkoutSummaryAndHomeCalendarTests(unittest.TestCase):
    def test_workout_date_keeps_same_origin_without_negative_offset(self):
        history = swift("HistoryView.swift")
        block = history.split("if !subtitle.isEmpty {", 1)[1].split(
            "summaryCard(session)", 1
        )[0]
        self.assertIn("Text(subtitle)", block)
        self.assertIn(".fixedSize(horizontal: false, vertical: true)", block)
        self.assertIn(".padding(.leading, 2)", block)
        self.assertNotIn(".offset(x: -6)", block)
        self.assertNotIn(".padding(.leading, 8)", block)

    def test_pin_label_is_not_repeated_below_map(self):
        history = swift("HistoryView.swift")
        section = history.split("SessionMapWeatherCard(", 1)[1].split(
            "// Solo métricas reales de Apple Salud", 1
        )[0]
        self.assertIn("sessionMapView(session)", section)
        self.assertIn("if sessionMapContent(session) != .pin", section)
        self.assertIn('Text("Colores = velocidad', section)
        self.assertNotIn("Text(name)", section)
        self.assertNotIn("session.locationPin?.name", section)

    def test_home_initial_scroll_shows_yesterday_first_today_second(self):
        home = swift("HomeView.swift")
        rebuild = home.split("private func rebuildWeekChrome() {", 1)[1].split(
            "private func rebuildStreakChrome()", 1
        )[0]
        self.assertIn("if calendarScrollID == nil", rebuild)
        self.assertIn("calendar.date(byAdding: .day, value: -1, to: selectedDay)", rebuild)
        self.assertIn("cachedCalendarDays.first(where:", rebuild)
        self.assertIn("calendar.isDate($0.date, inSameDayAs: firstVisibleDate)", rebuild)
        self.assertIn("?.iso", rebuild)
        self.assertNotIn("calendarScrollID = makeWeekDays(offset: 0).first?.iso\n        }", rebuild)
        self.assertIn("@State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())", home)
        self.assertIn(".scrollPosition(id: $calendarScrollID, anchor: .leading)", home)


if __name__ == "__main__":
    unittest.main()
