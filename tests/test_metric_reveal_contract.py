"""Revelado numérico Inicio-like: Progreso 1.ª vez (post-gate), tiles, Comenzar."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class MetricRevealContractTests(unittest.TestCase):
    def test_ios_metric_reveal_helper_and_progress_once_gate(self):
        theme = read("Apps/Repera/Sources/Theme.swift")
        stats = read("Apps/Repera/Sources/StatsView.swift")
        self.assertIn("struct OGMetricRevealText: View", theme)
        self.assertIn("@MainActor\nenum OGMetricRevealSession", theme)
        self.assertIn("static var progressHubPlayed", theme)
        self.assertIn("ogMetricRevealPlay", theme)
        # Gate: no armar en el primer frame; tras contenido listo + delay.
        self.assertIn("wantsFirstVisitReveal", stats)
        self.assertIn("playMetricReveal = false", stats)
        self.assertIn("hubContentReady", stats)
        self.assertIn("160_000_000", stats)
        self.assertIn(".environment(\\.ogMetricRevealPlay, playMetricReveal)", stats)
        self.assertIn("OGMetricRevealSession.progressHubPlayed = true", stats)
        self.assertNotIn(
            "playMetricReveal = !OGMetricRevealSession.progressHubPlayed",
            stats,
        )

    def test_ios_chart_reveal_waits_for_metric_gate(self):
        theme = read("Apps/Repera/Sources/Theme.swift")
        self.assertIn("220_000_000", theme)
        self.assertIn("!OGMetricRevealSession.progressHubPlayed && !playMetricReveal", theme)

    def test_ios_progress_tiles_and_start_use_reveal(self):
        chips = read("Apps/Repera/Sources/ProgressCategoryChips.swift")
        tiles = read("Apps/Repera/Sources/RegisterSessionChrome.swift")
        live = read("Apps/Repera/Sources/LiveActivityView.swift")
        self.assertIn("OGMetricRevealText(value: value, reduceMotion: reduceMotion)", chips)
        self.assertIn("OGMetricRevealText(value: value, reduceMotion: reduceMotion)", tiles)
        self.assertIn("OGMetricRevealText(", live)
        self.assertIn("formattedTime(recorder.duration(at: date))", live)
        self.assertIn("animateValueChanges: canLockLiveScreen", live)
        self.assertIn("startCountdownRemaining", live)
        # Idle sin TimelineView 1 Hz; countdown sigue animando dígitos.
        self.assertIn("Idle: sin tick 1", live)
        self.assertIn("animateValueChanges: true", live)
        theme = read("Apps/Repera/Sources/Theme.swift")
        self.assertIn("var animateValueChanges: Bool = false", theme)
        self.assertIn("useDigitTransition", theme)

    def test_android_metric_reveal_parity(self):
        reveal = read("android/mobile/src/main/java/dev/repera/mobile/ReperaMetricReveal.kt")
        progress = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        chips = read("android/mobile/src/main/java/dev/repera/mobile/ProgressCategoryChips.kt")
        tiles = read("android/mobile/src/main/java/dev/repera/mobile/LiveSportHistoryScreens.kt")
        live = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        charts = read("android/mobile/src/main/java/dev/repera/mobile/ProgressCharts.kt")
        body = read("android/mobile/src/main/java/dev/repera/mobile/BodyMapView.kt")
        self.assertIn("object ReperaMetricRevealSession", reveal)
        self.assertIn("fun ReperaMetricRevealText(", reveal)
        self.assertNotIn("import androidx.compose.animation.AnimatedContent", reveal)
        self.assertNotIn("AnimatedContent(", reveal)
        self.assertIn("graphicsLayer", reveal)
        self.assertIn("sin\n * `AnimatedContent`", reveal)
        self.assertIn("ProvideMetricRevealPlay(playMetricReveal)", progress)
        self.assertIn("wantsFirstVisitReveal", progress)
        self.assertIn("hubContentReady", progress)
        self.assertIn("delay(160)", progress)
        self.assertIn("withFrameNanos", progress)
        self.assertIn("ReperaMetricRevealSession.progressHubPlayed", progress)
        self.assertIn("ReperaMetricRevealText(", chips)
        self.assertIn("ReperaMetricRevealText(", tiles)
        self.assertIn("ReperaMetricRevealText(", live)
        self.assertGreaterEqual(live.count("ReperaMetricRevealText("), 5)
        self.assertIn("animateValueChanges = state.phase != LiveActivityState.Phase.IDLE", live)
        self.assertIn("live_start_countdown", live)
        self.assertIn("animateValueChanges: Boolean = false", reveal)
        self.assertIn("delay(220)", charts)
        self.assertIn("LocalProgressChartRevealActive", charts)
        self.assertIn("!chartRevealActive", charts)
        self.assertIn("LocalProgressChartRevealActive", reveal)
        self.assertIn("withFrameNanos", body)


if __name__ == "__main__":
    unittest.main()
