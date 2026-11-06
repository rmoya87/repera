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

    def test_metrics_map_and_start_share_one_compact_control_row(self):
        swift = (SOURCE / "LiveActivityView.swift").read_text(encoding="utf-8")
        metrics = swift.split("private var metricsView: some View {", 1)[1].split(
            "private var metricsTrailingActions: some View", 1
        )[0]
        actions = swift.split("private var metricsTrailingActions: some View", 1)[1].split(
            "private var bottomControls: some View", 1
        )[0]
        toolbar = swift.split("private var bottomControls: some View", 1)[1].split(
            "private var liveSplitScreen", 1
        )[0]
        header = swift.split("private var mapHeader: some View", 1)[1].split(
            "private func toggleNavigationMapMode", 1
        )[0]

        self.assertIn("bottomControls", metrics)
        self.assertIn("metricsTrailingActions", metrics)
        self.assertIn("bottomControls", swift.split("private var mapView: some View", 1)[1])
        self.assertNotIn("sessionMapButton(", actions)
        self.assertNotIn('metricsCircleButton("map"', actions)
        self.assertNotIn('sessionMapButton(', header)
        self.assertIn('recorder.sport.symbol', toolbar)
        self.assertIn('sportPicker = true', toolbar)
        self.assertIn('showOptions = true', toolbar)
        self.assertIn('recorder.phase == .recording ? "pause.fill"', toolbar)
        self.assertIn('canLockLiveScreen ? "flag.checkered" : "gearshape.fill"', toolbar)
        self.assertNotIn('Text(store.hasActiveSession ? "CONTINUAR" : "COMENZAR")', toolbar)
        self.assertIn(".frame(maxWidth: 570)", metrics)
        self.assertNotIn("mapDetailsExpanded", swift)


if __name__ == "__main__":
    unittest.main()
