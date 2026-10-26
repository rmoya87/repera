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

    def test_completed_summary_has_no_invisible_outer_rounded_section(self):
        history = swift("HistoryView.swift")
        header = history.split("private var detailList: some View {", 1)[1].split(
            "// El mapa va directamente debajo", 1
        )[0]
        self.assertIn("summaryCard(session)", header)
        self.assertIn(".ogCardListRow(top: 0, bottom: 2)", header)
        self.assertNotIn("Section {", header)
        self.assertIn("Text(subtitle)", header)

    def test_comenzar_splits_survive_private_supabase_restore(self):
        history = swift("HistoryView.swift")
        detail = history.split("private var detailList: some View {", 1)[1].split(
            "if isEditing {", 1
        )[0]
        # Hay distancia, tiempo y parciales aunque no haya puntos de ruta.
        self.assertIn("Recorrido no disponible en este dispositivo", detail)
        self.assertIn("session.liveKilometerSplitsSeconds", detail)
        self.assertIn("session.recordedDistanceMeters", detail)
        self.assertIn("session.activeDurationSeconds", detail)
        self.assertEqual(detail.count("CardioSplitsView("), 1)
        self.assertLess(detail.index("CardioSplitsView("), detail.index("if let extras = displayedMetrics(session)"))
        self.assertIn("totalActiveSeconds: session.activeDurationSeconds", detail)
        self.assertIn("totalDistanceMeters: session.recordedDistanceMeters", detail)
        splits = swift("CardioRouteComponents.swift")
        self.assertIn('averageStat("Ritmo medio"', splits)
        self.assertIn('averageStat("Velocidad media"', splits)
        self.assertIn("if let recorded = activeKilometerSeconds", splits)

    def test_finished_home_workout_uses_green_strength_icon_and_tighter_chips(self):
        home = swift("HomeView.swift")
        done = home.split("private func dayWorkoutCard(", 1)[1].split(
            "private func healthActivityCard(", 1
        )[0]
        self.assertIn('?? "figure.strengthtraining.traditional"', done)
        self.assertIn("tint: OG.accent", done)
        self.assertNotIn('?? "checkmark"', done)
        planned = home.split("private func plannedDayCard(", 1)[1].split(
            "private func dayWorkoutCard(", 1
        )[0]
        self.assertIn('systemName: "figure.strengthtraining.traditional"', planned)
        self.assertIn("tint: OG.label2", planned)
        self.assertIn(".frame(height: 27, alignment: .center)", home)
        self.assertIn(".padding(.top, 0)", home)

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
