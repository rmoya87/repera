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
        self.assertIn('label: isTeaserPreview ? "Media" : latestConfidenceLabel', stats)
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
        self.assertIn("let activeWidthFactor: CGFloat = 1.5", confidence)
        self.assertIn("unit * (selected ? activeWidthFactor : 1)", confidence)
        self.assertIn("selected ? 18 : 13", confidence)
        self.assertIn("Capsule()", confidence)
        # El estado solo se imprime en el título, no dentro del segmento.
        self.assertNotIn("Text(level.title)", confidence)
        self.assertIn("showSelectedLevelInCaption = true", confidence)
        self.assertNotIn("LinearGradient", confidence)

    def test_period_comparator_colors_are_semantic_for_free_and_pro(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        # Older StatsView has free/pro delta tiles; the redesigned main branch
        # uses the same neutral four-glance grid for both tiers and does NOT
        # show a fabricated period delta. CI tests the PR's merge with main.
        if "private var freeTilesGrid: some View" in ios:
            self.assertIn("private var tilesGrid: some View", ios)
            self.assertIn(
                "delta > 0 ? OG.accent : delta < 0 ? OG.red : OG.label3", ios
            )
        else:
            self.assertIn("private var trainingGlanceMetricsGrid: some View", ios)
            self.assertIn("ProgressMetricGlanceCard(", ios)
            self.assertIn('title: "Entrenos"', ios)
        self.assertNotIn("delta < 0 ? OG.yellow", ios)
        # Android routes both tiers through ProgressMetricsTilesGrid.
        self.assertIn("ProgressMetricsTilesGrid(snapshot, pro)", android)
        self.assertIn("null -> MaterialTheme.colorScheme.onSurfaceVariant", android)
        self.assertIn("0 -> MaterialTheme.colorScheme.onSurfaceVariant", android)
        self.assertIn("else -> if (delta > 0) brandGreen else MaterialTheme.colorScheme.error", android)
        self.assertNotIn("else Color(0xFFFFD60A)", android)

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
        self.assertIn("weight(if (selected) 1.5f else 1f)", confidence)
        self.assertIn("height(if (selected) 18.dp else 13.dp)", confidence)
        self.assertIn(".clip(androidx.compose.foundation.shape.CircleShape)", confidence)
        self.assertNotIn("tier.title,\n", confidence)
        self.assertIn("showSelectedLevelInCaption: Boolean = true", confidence)
        for title in ("Aprendiendo", "Baja", "Media", "Alta"):
            self.assertIn(title, confidence)
        self.assertNotIn("Brush.horizontalGradient", confidence)


if __name__ == "__main__":
    unittest.main()
