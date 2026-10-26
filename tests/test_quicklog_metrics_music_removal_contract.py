"""Contratos fuente: quitar música, ubicar Comenzar y modernizar Apuntar ejercicio.

Son pruebas de código: la compilación Xcode y la interacción en dispositivo
requieren validación separada.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"


def swift(name):
    return (SRC / name).read_text(encoding="utf-8")


class QuickLogMetricsMusicRemovalTests(unittest.TestCase):
    def test_music_is_gone_from_all_views_and_project_settings(self):
        for name in ("DigitalClockDisplay.swift", "LiveActivityView.swift",
                     "ReperaNowPlayingBar.swift"):
            source = swift(name)
            self.assertNotIn("struct ReperaNowPlayingBar:", source)
            self.assertNotIn("ReperaNowPlayingBar(", source)
            self.assertNotIn("MPMusicPlayerController", source)
            self.assertNotIn("import MediaPlayer", source)
        plist = (ROOT / "Apps/Repera/Resources/Info.plist").read_text()
        yml = (ROOT / "project.yml").read_text()
        self.assertNotIn("NSAppleMusicUsageDescription", plist)
        self.assertNotIn("NSAppleMusicUsageDescription", yml)

    def test_metrics_start_is_left_aligned_at_top_and_map_keeps_bottom(self):
        live = swift("LiveActivityView.swift")
        metrics = live.split("private var metricsView:", 1)[1].split(
            "private var selectionCircleBackground:", 1
        )[0]
        self.assertIn("if recorder.phase == .idle", metrics)
        self.assertIn("bottomControls", metrics)
        self.assertIn(".frame(maxWidth: 360, alignment: .leading)", metrics)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .leading)", metrics)
        self.assertLess(metrics.index("bottomControls"), metrics.index("Text(formattedTime("))
        map_part = live.split("private var mapView:", 1)[1].split(
            "private func sessionMapButton(", 1
        )[0]
        self.assertIn("bottomControls", map_part)

    def test_quicklog_uses_numeric_cells_and_swipe_not_steppers(self):
        quicklog = swift("QuickLogSheet.swift")
        self.assertIn("List {", quicklog)
        self.assertIn(".swipeActions(edge: .trailing, allowsFullSwipe: true)", quicklog)
        self.assertIn("OGSwipeDeleteButton(", quicklog)
        self.assertIn("OGNumericTextField(", quicklog)
        self.assertNotIn("OGRepeatStepper(", quicklog)
        self.assertNotIn('Image(systemName: "trash")', quicklog)
        self.assertNotIn("Registra las repeticiones de cada serie.", quicklog)
        self.assertIn('Text("Serie")', quicklog)
        self.assertIn('Text("\\(index)")', quicklog)
        self.assertIn("if style == .loadAndReps", quicklog)
        self.assertIn("if style == .repsAndTime || style == .machineWork", quicklog)
        self.assertIn("if !isHold", quicklog)
        self.assertIn('Text("Cal").tag(ExerciseQuantityUnit.calories)', quicklog)
        self.assertIn('Text("Metros").tag(ExerciseQuantityUnit.meters)', quicklog)
        self.assertIn("onUpdate(updated)", quicklog)


if __name__ == "__main__":
    unittest.main()
