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
        self.assertIn("UnevenRoundedRectangle(", exercise_list)
        self.assertIn("topLeadingRadius: items.first?.id == row.id", exercise_list)
        self.assertIn("topTrailingRadius: items.first?.id == row.id", exercise_list)
        self.assertIn("bottomLeadingRadius: items.last?.id == row.id", exercise_list)
        self.assertIn("bottomTrailingRadius: items.last?.id == row.id", exercise_list)
        self.assertIn(".fill(OG.accent)", exercise_list)
        label = swift.split("private struct LibraryExerciseRowLabel: View {", 1)[1]
        self.assertIn("isSelected ? OG.onAccent : OG.label", label)
        self.assertIn("isSelected ? OG.onAccent.opacity(0.74) : OG.label2", label)

    def test_metrics_controls_share_left_aligned_row_not_vertical_play_stack(self):
        swift = (SOURCE / "LiveActivityView.swift").read_text(encoding="utf-8")
        metrics = swift.split("private var metricsView: some View {", 1)[1].split(
            "private var selectionCircleBackground:", 1
        )[0]
        controls = metrics.split("if recorder.phase == .recording || recorder.phase == .paused", 1)[1].split(
            "HStack(spacing: 12) {", 1
        )[1].split(".padding(.horizontal, 18)", 1)[0]
        for snippet in ("metricsCircleButton(", "sessionMapButton(", '"play.fill"',
                        '"flag.checkered"', "Spacer(minLength: 0)"):
            self.assertIn(snippet, controls)
        self.assertNotIn("VStack(spacing: 8)", controls)
        self.assertLess(controls.index("metricsCircleButton("), controls.index('"play.fill"'))
        self.assertLess(controls.index('"play.fill"'), controls.index('"flag.checkered"'))
        self.assertIn("if recorder.phase == .idle", metrics)
        self.assertIn("bottomControls", metrics)
        map_header = swift.split("private var mapHeader: some View {", 1)[1].split(
            "private func sessionMapButton(", 1
        )[0]
        self.assertIn("VStack(spacing: 10)", map_header)
        self.assertIn('"flag.checkered"', map_header)


if __name__ == "__main__":
    unittest.main()
