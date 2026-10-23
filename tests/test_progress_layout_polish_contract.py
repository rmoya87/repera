"""Regresión de presentación iOS: márgenes, tarjetas y barras de progreso.

Estas comprobaciones inspeccionan los puntos de composición SwiftUI; requieren
compilación visual en Xcode para validar el resultado renderizado.
"""
from pathlib import Path
import unittest

SOURCES = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def read(name: str) -> str:
    return (SOURCES / name).read_text(encoding="utf-8")


class ProgressLayoutPolishContractTests(unittest.TestCase):
    def test_technique_editor_uses_sibling_list_rows_without_nested_disclosure(self):
        play = read("WorkoutView.swift")
        body = play.split("private func content(_ session: WorkoutSession)", 1)[1]
        body = body.split("private func workoutExerciseRow(", 1)[0]
        self.assertNotIn('DisclosureGroup("Técnicas de serie · dropset / rest-pause")', body)
        self.assertIn("expandedTechniquesExerciseID == current.id", body)
        self.assertIn("logForm(current)", body)
        self.assertIn("leading: 16, bottom: 12, trailing: 16", body)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .leading)", body)

    def test_create_workout_hides_obsolete_helper_footers(self):
        plan = read("PlanView.swift")
        self.assertNotIn("Entreno solo para este día. No aparece en el plan semanal", plan)
        self.assertNotIn("Configura el formato en cualquier bloque o déjalo sin formato", plan)
        self.assertIn("Button", plan)
        self.assertIn('Label("Elegir WOD"', plan)

    def test_home_progress_has_rounded_partial_fill_and_overflow(self):
        home = read("HomeView.swift")
        bar = home.split("private struct HomeGoalProgressBar: View {", 1)[1]
        bar = bar.split("/// Inicio:", 1)[0]
        self.assertIn("Capsule().fill(OG.surface3)", bar)
        self.assertIn(".fill(tint)", bar)
        self.assertIn("if covered + overflow > 0", bar)
        self.assertIn("if overflow > 0", bar)
        self.assertIn(".clipShape(Capsule())", bar)
        self.assertIn("HomeGoalProgressBar(", home)

    def test_muscle_tabs_are_inside_card_and_have_requested_names(self):
        source = read("MuscleBalanceCard.swift")
        self.assertIn('case fatigue = "Fatiga"', source)
        self.assertIn('case effort = "Esfuerzo"', source)
        body = source.split("var body: some View {", 1)[1]
        body = body.split("private func barsSection(", 1)[0]
        self.assertLess(body.index("OGCard {"), body.index('Picker("Métrica muscular"'))
        self.assertIn(".pickerStyle(.segmented)", body)
        self.assertIn("mode == .effort", source)
        self.assertNotIn('case all = "Todas"', source)

    def test_sample_dates_have_padded_domain_without_changing_real_range(self):
        charts = read("ProgressTrendCards.swift")
        helper = charts.split("static func xDomain(", 1)[1]
        helper = helper.split("static func labelFormat(", 1)[0]
        self.assertIn("isTeaserPreview: Bool = false", helper)
        self.assertIn("if isTeaserPreview, let first = points.min()", helper)
        self.assertIn("first.addingTimeInterval(-halfDay)", helper)
        self.assertIn("last.addingTimeInterval(halfDay)", helper)
        self.assertIn("let start = range.startDate(", helper)
        self.assertEqual(charts.count("isTeaserPreview: prepared.isTeaserPreview"), 2)
        self.assertIn("isTeaserPreview: isTeaserPreview", charts)
        self.assertIn("isTeaserPreview: isTeaserPreview", read("StatsView.swift"))

    def test_example_charts_clip_only_the_plot_and_keep_axes_inside_margins(self):
        for name in ("StatsView.swift", "HealthRecovery.swift", "ExerciseProgressView.swift"):
            source = read(name)
            self.assertIn(".chartXScale(domain: 0.5...7.5)", source)
            self.assertIn(".chartPlotStyle { $0.clipped() }", source)
        charts = read("ProgressTrendCards.swift")
        self.assertIn(".chartPlotStyle { $0.clipped() }", charts)
        self.assertNotIn(".frame(maxWidth: .infinity)\n                        .clipped()", charts)


if __name__ == "__main__":
    unittest.main()
