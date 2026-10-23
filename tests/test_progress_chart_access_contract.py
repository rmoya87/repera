"""Contratos de Progreso: acceso Gratis, muestras Pro y gráficos sin datos.

Se comprueban en el código SwiftUI para evitar regresiones en el enrutado
de permisos; los tests de dominio validan por separado las métricas reales.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"


def read(name):
    return (SOURCES / name).read_text(encoding="utf-8")


class ProgressChartAccessContractTests(unittest.TestCase):
    def test_muscle_balance_is_real_and_free(self):
        stats = read("StatsView.swift")
        training = stats.split("case .training:", 1)[1].split("case .health:", 1)[0]
        self.assertIn("tilesGrid\n                                    activityCard\n                                    muscleBalanceCard", training)
        self.assertIn("freeActivityCard\n                                    muscleBalanceCard", training)
        advanced = stats.split("private var proAdvancedSections", 1)[1].split("private var healthSections", 1)[0]
        self.assertNotIn("MuscleBalanceCard(", advanced)
        self.assertEqual(stats.count("MuscleBalanceCard("), 1)

    def test_activity_free_examples_cover_all_paid_charts(self):
        stats = read("StatsView.swift")
        previews = stats.split("private var freeHealthPreview", 1)[1].split("private func schedulePrepare", 1)[0]
        for name in (
            "ProgressSessionScoreChartCard(",
            "ProgressHeartZonesCard(",
            "ProgressCardioChartCard(",
            "ProgressCaloriesChartCard(",
            "ProgressWeightChartCard(",
        ):
            self.assertIn(name, previews)
        self.assertIn("isTeaserPreview: true", previews)
        self.assertIn("teaserSample(", previews)
        self.assertIn("teaserWeightPoints()", previews)
        self.assertIn("datos reales.", previews)

    def test_real_activity_uses_empty_charts_not_sample_points(self):
        stats = read("StatsView.swift")
        health = stats.split("private var healthSections", 1)[1].split("private var freeTilesGrid", 1)[0]
        self.assertIn("ProgressCardioChartCard(prepared: snap.charts)", health)
        self.assertIn("ProgressCaloriesChartCard(prepared: snap.charts)", health)
        self.assertIn("ProgressSessionScoreChartCard(", health)
        self.assertNotIn("teaserSample(", health)
        self.assertNotIn("isTeaserPreview: true", health)

    def test_empty_state_renders_axes_for_missing_real_data(self):
        charts = read("ProgressTrendCards.swift")
        self.assertIn("struct ProgressEmptyChart: View", charts)
        self.assertIn("RuleMark(y: .value(\"Base\"", charts)
        self.assertIn(".chartYScale(domain: yRange)", charts)
        self.assertIn("Sin ritmo cardíaco de Salud", charts)
        self.assertIn("Sin kcal de Salud", charts)
        self.assertIn("Sin pesajes en", charts)
        self.assertIn("Sin zonas cardíacas registradas", charts)
        stats = read("StatsView.swift")
        self.assertIn("Todavía no hay puntuaciones basadas en tu historial.", stats)
        exercise = read("ExerciseProgressView.swift")
        self.assertIn("if points.count < 2", exercise)
        self.assertIn("ProgressEmptyChart(", exercise)

    def test_recovery_uses_real_readiness_and_paid_charts_preview(self):
        source = read("HealthRecovery.swift")
        body = source.split("var body: some View {", 1)[1].split("private var softSleepEmpty", 1)[0]
        self.assertIn("trainingRecoveryCard", body)
        self.assertIn("if isPro {", body)
        self.assertIn("recoveryTrendPreview", body)
        self.assertIn("physiologyPreview", body)
        self.assertIn("physiologyContent", body)
        self.assertIn("ProgressEmptyChart(", body)
        self.assertIn("datos ficticios", source)
        self.assertIn("private var trainingRecoveryTrendCard", source)

    def test_premium_exercise_evolution_has_placeholder_and_free_demo(self):
        exercise = read("ExerciseProgressView.swift")
        self.assertIn("freeExerciseEvolutionPreview", exercise)
        self.assertIn("FreeExerciseSummaryCard(exerciseId: exerciseId)", exercise)
        self.assertIn('Text("Ejemplo")', exercise)
        self.assertIn("ProgressEmptyChart(", exercise)


if __name__ == "__main__":
    unittest.main()
