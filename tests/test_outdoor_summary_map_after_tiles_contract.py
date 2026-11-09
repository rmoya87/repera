"""Outdoor summary/detail: GPS map immediately after summary tiles (iOS + Android)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def _slice_between(src: str, start: str, end: str) -> str:
    head, _, rest = src.partition(start)
    assert _, f"missing start marker: {start}"
    body, _, _ = rest.partition(end)
    assert body or rest, f"missing end marker after {start}: {end}"
    return body


class OutdoorSummaryMapAfterTilesTests(unittest.TestCase):
    def test_ios_live_review_map_follows_tiles(self):
        src = read("Apps/Repera/Sources/LiveActivityView.swift")
        review = _slice_between(src, "private var review: some View {", "private func reviewMapSections(")
        tiles_at = review.find("SessionSummaryTilesRow(")
        map_at = review.find("if isGPS {\n                    reviewMapSections(")
        metrics_at = review.find("CardioSplitsView(")
        self.assertGreaterEqual(tiles_at, 0)
        self.assertGreaterEqual(map_at, 0)
        self.assertGreater(map_at, tiles_at)
        self.assertGreater(metrics_at, map_at)
        # Indoor / no-GPS pin stays after details.
        details_at = review.find('Section("Detalles de la actividad")')
        indoor_map_at = review.find("if !isGPS {\n                    reviewMapSections(")
        self.assertGreater(indoor_map_at, details_at)

    def test_ios_history_detail_map_follows_tiles(self):
        src = read("Apps/Repera/Sources/HistoryView.swift")
        detail = _slice_between(src, "private var detailList: some View {", ".ogListChrome()")
        tiles_at = detail.find("SessionSummaryTilesRow(")
        map_at = detail.find("if !isEditing, sessionIsGPSSport(session) {\n                    detailMapSections(session)")
        metrics_at = detail.find("CardioSplitsView(")
        self.assertGreaterEqual(tiles_at, 0)
        self.assertGreaterEqual(map_at, 0)
        self.assertGreater(map_at, tiles_at)
        self.assertGreater(metrics_at, map_at)

    def test_android_live_review_map_follows_tiles(self):
        src = read(
            "android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt"
        )
        review = _slice_between(
            src,
            "private fun LiveActivityReviewContent(",
            "/** FAB circular opaco del mapa",
        )
        tiles_at = review.find("SessionSummaryTilesBuilder.tiles(")
        map_at = review.find('testTag("live_review_map_card")')
        unavailable_at = review.find("LiveReviewMapUnavailableCard(")
        splits_at = review.find("LiveKilometerSplitsSection(")
        self.assertGreaterEqual(tiles_at, 0)
        self.assertGreaterEqual(map_at, 0)
        self.assertGreater(map_at, tiles_at)
        self.assertGreater(unavailable_at, tiles_at)
        self.assertGreater(splits_at, map_at)
        # Map must not appear before the date/tiles block.
        header_at = review.find("ReperaPageHeader(")
        self.assertGreater(map_at, header_at)

    def test_android_history_detail_map_follows_tiles(self):
        src = read(
            "android/mobile/src/main/java/dev/repera/mobile/CompleteHistoryScreen.kt"
        )
        tiles_at = src.find("SessionSummaryTilesBuilder.tiles(")
        map_marker = "GPS outdoor: mapa justo tras los tiles"
        map_comment_at = src.find(map_marker)
        cardio_at = src.find("CardioRouteSection(", map_comment_at)
        metrics_marker = "Métricas después del mapa"
        metrics_at = src.find(metrics_marker)
        self.assertGreaterEqual(tiles_at, 0)
        self.assertGreaterEqual(map_comment_at, 0)
        self.assertGreater(map_comment_at, tiles_at)
        self.assertGreater(cardio_at, map_comment_at)
        self.assertGreater(metrics_at, cardio_at)


if __name__ == "__main__":
    unittest.main()
