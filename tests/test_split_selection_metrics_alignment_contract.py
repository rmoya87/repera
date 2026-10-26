"""Regresiones de selección DUO y controles de sesión en vista Métricas.

Valida contratos SwiftUI en fuente. Las esquinas y el flujo en dispositivos
se comprueban además en Xcode/TestFlight.
"""
from pathlib import Path
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


class DuoSelectionAndMetricsTests(unittest.TestCase):
    def test_selected_exercise_has_green_grouped_background_and_contrast(self):
        swift = (SOURCE / "LibraryView.swift").read_text(encoding="utf-8")
        exercise_list = swift.split("private struct LibraryExerciseList: View {", 1)[1].split(
            "private struct LibrarySearchIfCompact:", 1
        )[0]
        self.assertIn("selectedExerciseID == row.id", exercise_list)
        self.assertIn("LibrarySelectedExerciseBackground(", exercise_list)
        self.assertIn("isFirst: items.first?.id == row.id", exercise_list)
        self.assertIn("isLast: items.last?.id == row.id", exercise_list)
        # El Shape se infiere fuera del ForEach/List; evita el timeout de Swift.
        background = swift.split("private struct LibrarySelectedExerciseBackground: View {", 1)[1].split(
            "private struct LibrarySearchIfCompact:", 1
        )[0]
        self.assertIn("UnevenRoundedRectangle(", background)
        self.assertIn("topLeadingRadius: isFirst ? OG.radiusCard : 0", background)
        self.assertIn("topTrailingRadius: isFirst ? OG.radiusCard : 0", background)
        self.assertIn("bottomLeadingRadius: isLast ? OG.radiusCard : 0", background)
        self.assertIn("bottomTrailingRadius: isLast ? OG.radiusCard : 0", background)
        self.assertIn(".fill(OG.accent)", background)
        label = swift.split("private struct LibraryExerciseRowLabel: View {", 1)[1]
        self.assertIn("isSelected ? OG.onAccent : OG.label", label)
        self.assertIn("isSelected ? OG.onAccent.opacity(0.74) : OG.label2", label)

    def test_diary_swipe_does_not_bind_unused_routine(self):
        plan = (SOURCE / "PlanView.swift").read_text(encoding="utf-8")
        schedule = plan.split("private var scheduleContent:", 1)[1].split(
            "private func scheduleChips(", 1
        )[0]
        self.assertIn("if routine != nil {", schedule)
        self.assertNotIn('if let routine {\n                        OGSwipeDeleteButton(', schedule)

    def test_metrics_controls_stay_right_aligned_and_expand_horizontally(self):
        swift = (SOURCE / "LiveActivityView.swift").read_text(encoding="utf-8")
        metrics = swift.split("private var metricsView: some View {", 1)[1].split(
            "private var selectionCircleBackground:", 1
        )[0]
        # El HStack contiene título a la izquierda y botones en el extremo derecho.
        heading = metrics.split("HStack(spacing: 12) {", 1)[1].split(
            ".padding(.horizontal, 18)", 1
        )[0]
        self.assertIn("Spacer(minLength: 4)", heading)
        self.assertIn("metricsTrailingActions", heading)
        self.assertLess(heading.index("Spacer(minLength: 4)"), heading.index("metricsTrailingActions"))
        self.assertNotIn("HStack(spacing: 12) {\n                        if showGuidanceToggle", metrics)

        # Play y Finalizar no forman una columna vertical.
        actions = swift.split("private var metricsTrailingActions: some View {", 1)[1].split(
            "private var selectionCircleBackground:", 1
        )[0]
        self.assertIn("HStack(spacing: 8)", actions)
        self.assertIn("metricsCircleButton(", actions)
        self.assertIn("sessionMapButton(", actions)
        self.assertNotIn("VStack", actions)
        self.assertLess(actions.index('"play.fill"'), actions.index('"flag.checkered"'))
        self.assertIn("if recorder.phase == .idle", metrics)
        self.assertIn("bottomControls", metrics)

        # Mapa conserva la columna de acciones independiente.
        map_header = swift.split("private var mapHeader: some View {", 1)[1].split(
            "private func sessionMapButton(", 1
        )[0]
        self.assertIn("VStack(spacing: 10)", map_header)
        self.assertIn('"flag.checkered"', map_header)


if __name__ == "__main__":
    unittest.main()
