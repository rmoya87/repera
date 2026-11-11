"""Revelado de plots de Progreso: transform/GPU, sin layout ni recompose por frame."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_THEME = (ROOT / "Apps/Repera/Sources/Theme.swift").read_text(encoding="utf-8")
ANDROID = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ProgressCharts.kt"
).read_text(encoding="utf-8")


class ProgressChartRevealContractTests(unittest.TestCase):
    def test_ios_uses_scale_mask_and_compositing_group(self):
        reveal = IOS_THEME.split("private struct OGChartRevealModifier", 1)[1].split(
            "extension View {", 1
        )[0]
        self.assertIn(".compositingGroup()", reveal)
        self.assertIn("scaleEffect(", reveal)
        self.assertIn("OGMotion.chartReveal", reveal)
        self.assertNotIn("GeometryReader", reveal)
        self.assertNotIn("duration: 0.42", reveal)
        # Post-gate: yield en revisitas; sleep 220 ms tras números en 1.ª visita.
        self.assertIn("Task.yield()", reveal)
        self.assertIn("220_000_000", reveal)
        self.assertIn("ogMetricRevealPlay", reveal)
        self.assertIn(
            "static let chartReveal = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.28)",
            IOS_THEME,
        )

    def test_android_animatable_read_in_draw_not_state_recompose(self):
        fn = ANDROID.split(
            "internal fun Modifier.progressChartReveal", 1
        )[1].split("/** Margen superior", 1)[0]
        self.assertIn("Animatable", fn)
        self.assertIn("progress.value", fn)
        self.assertIn("durationMillis = 280", ANDROID)
        self.assertIn("CubicBezierEasing(0.16f, 1f, 0.3f, 1f)", ANDROID)
        self.assertIn("delay(220)", fn)
        self.assertIn("LocalMetricRevealPlay", fn)
        self.assertNotIn("mutableFloatStateOf", fn)
        self.assertNotIn("durationMillis = 420", ANDROID)


if __name__ == "__main__":
    unittest.main()
