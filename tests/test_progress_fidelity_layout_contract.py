"""Contratos de presentación: Inicio, Programado y previews Pro de Progreso.

Verificaciones estáticas, no sustituyen la compilación ni las capturas en iOS.
"""
from pathlib import Path
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def swift(name):
    return (SOURCE / name).read_text(encoding="utf-8")


class ProgressFidelityLayoutTests(unittest.TestCase):
    def test_home_grouped_background_reaches_bottom(self):
        home = swift("HomeView.swift")
        self.assertIn(".background(OG.bg.ignoresSafeArea(edges: .bottom))", home)
        self.assertIn(".background(OG.surface)", home)
        self.assertIn('activityTodayCard', home)

    def test_diary_does_not_show_one_off_workouts_created_elsewhere(self):
        diary = swift("PlanView.swift")
        section = diary.split("private var scheduleContent", 1)[1].split("private func scheduleChips", 1)[0]
        self.assertNotIn("ForEach(datedPlans)", section)
        self.assertNotIn("scheduledDate != nil", section)
        self.assertNotIn('Text("Entrenamientos con fecha")', section)
        self.assertIn("ForEach(1...7, id:", section)
        self.assertIn('Text("Tu programación")', section)
        self.assertIn("store.routine(forWeekday: day)", section)
        self.assertIn("businessData.trainingSessions", section)
        self.assertIn("onOpenRoutine(routine)", section)

    def test_score_chart_is_smoothed_and_same_card_width_as_real(self):
        stats = swift("StatsView.swift")
        score = stats.split("private struct ProgressSessionScoreChartCard", 1)[1]
        self.assertIn(".interpolationMethod(.catmullRom)", score)
        self.assertNotIn(".interpolationMethod(.linear)", score)
        self.assertIn("OGCard(padding: 10)", score)
        self.assertIn("Ejemplo ·", score)
        self.assertIn("isTeaserPreview: isTeaserPreview", score)

    def test_heart_zones_are_inside_cardio_with_in_bar_percentages(self):
        stats = swift("StatsView.swift")
        self.assertNotIn("ProgressHeartZonesCard(", stats)
        charts = swift("ProgressTrendCards.swift")
        zone = charts.split("struct ProgressHeartZonesCard:", 1)[1].split("struct ProgressCardioChartCard:", 1)[0]
        cardio = charts.split("struct ProgressCardioChartCard:", 1)[1].split("struct ProgressCaloriesChartCard:", 1)[0]
        self.assertIn("ProgressHeartZonesCard(", cardio)
        self.assertIn("workouts: workouts", cardio)
        self.assertIn("isTeaserPreview: prepared.isTeaserPreview", cardio)
        self.assertIn("if let stats = periodStats", cardio)
        self.assertLess(cardio.index("cardioStatPill(title: \"Máx\""), cardio.index("ProgressHeartZonesCard("))
        self.assertNotIn("OGCard(", zone)
        self.assertNotIn("Zonas cardíacas · último entreno", charts)
        self.assertIn('Text("\\(Int((100 * fraction).rounded()))%")', zone)
        self.assertIn('Text("Intensidad cardiovascular")', zone)
        self.assertIn(".trim(from: 0, to:", zone)
        self.assertIn("HealthKitStore.shared.heartZones(for: latest)", zone)
        self.assertIn("if isTeaserPreview", zone)
        self.assertIn("slice.seconds / total", zone)

    def test_heart_rate_sample_has_the_same_three_tiles(self):
        charts = swift("ProgressTrendCards.swift")
        cardio = charts.split("struct ProgressCardioChartCard:", 1)[1].split("struct ProgressCaloriesChartCard:", 1)[0]
        self.assertIn("if let stats = periodStats", cardio)
        self.assertNotIn("if !prepared.isTeaserPreview, let stats", cardio)
        for name in ("Mín", "Media", "Máx"):
            self.assertIn(f'cardioStatPill(title: "{name}"', cardio)
        self.assertIn("OGCard(padding: 10)", cardio)

    def test_other_previews_display_the_same_summary_values_as_pro(self):
        stats = swift("StatsView.swift")
        free = stats.split("private var freeHealthPreview", 1)[1].split("private func schedulePrepare", 1)[0]
        self.assertIn("goalKg: 74.0", free)
        charts = swift("ProgressTrendCards.swift")
        calories = charts.split("struct ProgressCaloriesChartCard:", 1)[1].split("struct ProgressWeightChartCard:", 1)[0]
        self.assertIn("Ejemplo ·", calories)
        weight = charts.split("struct ProgressWeightChartCard:", 1)[1].split("enum ProgressChartAxis", 1)[0]
        self.assertIn("Ejemplo ·", weight)
        self.assertIn("if let latest, let goal = goalKg, let delta", weight)
        physiology = swift("HealthRecovery.swift")
        self.assertIn('unit: "lpm"', physiology)
        self.assertIn('unit: "rpm"', physiology)
        self.assertIn('Text("\\(Int(values.last ?? 0)) \\(unit)")', physiology)

    def test_chart_cards_are_wider_without_changing_global_card_padding(self):
        theme = swift("Theme.swift")
        self.assertIn("var padding: CGFloat = OG.pad", theme)
        for name in ("StatsView.swift", "ProgressTrendCards.swift", "HealthRecovery.swift", "ExerciseProgressView.swift"):
            self.assertIn("OGCard(padding: 10)", swift(name))


if __name__ == "__main__":
    unittest.main()
