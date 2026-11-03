"""Progreso > Entrenamiento: confidence display contracts for SwiftUI and Compose.

Static layout checks supplement, but cannot replace, device-sized UI tests.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(relative):
    return (ROOT / relative).read_text(encoding="utf-8")


class ProgressConfidenceContractTests(unittest.TestCase):
    def test_ios_shows_selected_confidence_name_not_last_session(self):
        stats = read("Apps/Repera/Sources/StatsView.swift")
        self.assertIn("label: latestConfidenceLabel", stats)
        self.assertIn("compactInProgress: true", stats)
        self.assertIn("showSelectedLevelInCaption: true", stats)
        self.assertNotIn("Confianza · última sesión", stats)
        confidence = read("Apps/Repera/Sources/SessionReviewViews.swift")
        self.assertIn('\\(caption) · \\(currentLevel.title)', confidence)
        for title in ("Aprendiendo", "Baja", "Media", "Alta"):
            self.assertIn(title, confidence)

    def test_free_preview_keeps_same_confidence_layout_as_pro(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        start = ios.index("private var scoreSummary: some View")
        end = ios.index("private func scoreMetric(", start)
        summary = ios[start:end]
        self.assertIn('label: isTeaserPreview ? "Media" : latestConfidenceLabel', summary)
        self.assertNotIn("if !isTeaserPreview {", summary)
        android = read(
            "android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt"
        )
        self.assertIn('label = if (preview) "Media" else confidenceLabel', android)
        self.assertIn("compactInProgress = true", android)
        self.assertIn('Text("Ejemplo"', android)

    def test_ios_highlight_and_maximum_half_card_width(self):
        confidence = read("Apps/Repera/Sources/SessionReviewViews.swift")
        self.assertIn("geometry.size.width * (compactInProgress ? 0.5 : 1)", confidence)
        self.assertIn("unit * (selected ? 3 : 1)", confidence)
        self.assertIn("selected ? 36 : 13", confidence)
        self.assertIn("if selected {", confidence)
        self.assertNotIn("LinearGradient", confidence)

    def test_android_shows_selected_level_and_limits_width(self):
        progress = read(
            "android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt"
        )
        confidence = read(
            "android/mobile/src/main/java/dev/repera/mobile/SessionReviewCard.kt"
        )
        self.assertIn("compactInProgress = true", progress)
        self.assertIn("showSelectedLevelInCaption = true", progress)
        self.assertNotIn("Confianza · última sesión", progress)
        self.assertIn('"$caption · ${current.title}"', confidence)
        self.assertIn(
            "maxWidth * (if (compactInProgress) 0.5f else 1f)", confidence
        )
        self.assertIn("weight(if (selected) 3f else 1f)", confidence)
        self.assertIn("height(if (selected) 36.dp else 13.dp)", confidence)
        for title in ("Aprendiendo", "Baja", "Media", "Alta"):
            self.assertIn(title, confidence)
        self.assertNotIn("Brush.horizontalGradient", confidence)


if __name__ == "__main__":
    unittest.main()
