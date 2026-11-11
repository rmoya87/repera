"""Progreso: primera preparación muestra skeleton, no spinner «Cargando»."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS_STATS = (ROOT / "Apps/Repera/Sources/StatsView.swift").read_text(encoding="utf-8")
IOS_SK = (ROOT / "Apps/Repera/Sources/ProgressHubSkeleton.swift").read_text(encoding="utf-8")
ANDROID_TAB = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt"
).read_text(encoding="utf-8")
ANDROID_SK = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ProgressHubSkeleton.kt"
).read_text(encoding="utf-8")


class ProgressHubSkeletonContract(unittest.TestCase):
    def test_ios_uses_skeleton_instead_of_spinner(self):
        self.assertIn("struct ProgressHubSkeleton", IOS_SK)
        self.assertIn("ProgressHubSkeleton()", IOS_STATS)
        self.assertNotIn('ProgressView("Preparando progreso…")', IOS_STATS)
        self.assertNotIn('ProgressView("Cargando', IOS_STATS)
        self.assertIn("categoryNeedsSnapshotPrep", IOS_STATS)

    def test_android_uses_skeleton_when_snapshot_missing(self):
        self.assertIn("fun ProgressHubSkeleton", ANDROID_SK)
        self.assertIn('testTag("progress_hub_skeleton")', ANDROID_SK)
        self.assertIn("categoryNeedsSnapshot && snapshot == null", ANDROID_TAB)
        self.assertIn("ProgressHubSkeleton()", ANDROID_TAB)
        self.assertNotIn("CircularProgressIndicator", ANDROID_TAB.split("fun ProgressTab", 1)[1][:8000])


if __name__ == "__main__":
    unittest.main()
