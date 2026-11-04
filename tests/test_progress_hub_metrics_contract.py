"""Contratos del hub Progreso: chips, estímulo, corazón, deportes y Pro patrocinado."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
ANDROID = ROOT / "android" / "mobile" / "src" / "main" / "java" / "dev" / "repera" / "mobile"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class ProgressHubMetricsContractTests(unittest.TestCase):
    def test_recovery_and_sports_chips_are_not_hardcoded_dot(self):
        stats = read(IOS / "StatsView.swift")
        glance = stats.split("private func chipGlanceValue(for category: ProgressCategory)", 1)[1]
        glance = glance.split("private var sportsActivityCount", 1)[0]
        self.assertNotIn('case .recovery:\n            return "·"', glance)
        self.assertNotIn('case .sports:\n            return "·"', glance)
        self.assertIn("recoveryGlanceScore", glance)
        self.assertIn("sportsActivityCount", glance)

        tab = read(ANDROID / "ProgressTab.kt")
        self.assertNotIn('ProgressCategory.RECOVERY -> "·"', tab)
        self.assertNotIn('ProgressCategory.SPORTS -> "·"', tab)

    def test_fitness_formats_hours_and_minutes(self):
        stats = read(IOS / "StatsView.swift")
        self.assertIn("activeDurationHero", stats)
        self.assertIn("activeDurationNarrative", stats)
        self.assertIn("compactActiveDuration", stats)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("activeDurationHero", tab)
        self.assertIn("activeDurationNarrative", tab)

    def test_heart_bars_never_use_placeholder_ranges(self):
        stats = read(IOS / "StatsView.swift")
        heart = stats.split("private var heartSparkSamples", 1)[1].split(
            "private func heartExtremeText", 1
        )[0]
        self.assertNotIn("0.25...0.55", heart)
        self.assertIn("guard !points.isEmpty else { return [] }", heart)

    def test_strength_bars_use_weekly_volume_not_fake_e1rm(self):
        stats = read(IOS / "StatsView.swift")
        spark = stats.split("private var strengthSparkSamples", 1)[1].split(
            "private var strengthInsightCopy", 1
        )[0]
        self.assertIn("weeklyVolumeSeries", spark)
        self.assertNotIn("estimatedOneRM / 200", spark)

    def test_sports_hub_has_more_than_empty_catalog_link(self):
        stats = read(IOS / "StatsView.swift")
        sports = stats.split("private var sportsCategoryContent", 1)[1].split(
            "private var longTermTrainingTeaser", 1
        )[0]
        self.assertIn("Actividad deportiva", sports)
        self.assertIn("improvedExerciseCount", sports)
        self.assertIn("plannedWorkoutCount", sports)
        self.assertIn("Ejercicios al alza", sports)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("Actividad deportiva", tab)
        self.assertIn("sportsHubNarrative", tab)

    def test_business_sponsored_pro_rewires_after_entitlements(self):
        app = read(IOS / "ReperaApp.swift")
        self.assertIn(
            "businessData.entitlements?.businessSponsoredPro",
            app,
        )
        manager = read(IOS / "Monetization" / "SubscriptionManager.swift")
        self.assertIn("verifiedProCacheKey", manager)
        self.assertIn("loadPersistedVerifiedPro", manager)

        store = read(ANDROID / "BusinessCenterStore.kt")
        self.assertIn("get_my_effective_entitlements", store)
        self.assertIn("businessSponsoredPro", store)
        main = read(ANDROID / "MainActivity.kt")
        self.assertIn(
            "setBusinessSponsoredAccess(result.snapshot.grantsFullAppAccess)",
            main,
        )


if __name__ == "__main__":
    unittest.main()
