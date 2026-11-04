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

        tab = read(ANDROID / "ProgressTab.kt")
        self.assertNotIn('ProgressCategory.HEART -> "—"', tab)
        self.assertIn("recentHeartBpm", tab)
        self.assertIn("heartDailyBarFractions", tab)
        self.assertIn("chartsByRange", tab)
        heart_fn = tab.split("private fun heartDailyBarFractions", 1)[1].split(
            "private fun sportsDailyBarFractions", 1
        )[0]
        self.assertNotIn("0.25f", heart_fn)
        self.assertIn("if (sample.isEmpty()) return emptyList()", heart_fn)

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
        self.assertIn("sportsEvolutionSparkSamples", sports)
        self.assertIn("exerciseProgressSparkSamples", sports)
        self.assertIn("Ejercicios al alza", sports)
        self.assertIn("Tiempo En vivo", sports)
        self.assertNotIn("últimos 3 meses", sports)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("Actividad deportiva", tab)
        self.assertIn("ProgressMiniBarRow", tab)
        self.assertIn("sportsDailyBarFractions", tab)

    def test_fitness_stimulus_explains_period_and_sources(self):
        stats = read(IOS / "StatsView.swift")
        self.assertIn("Repera + Salud", stats)
        self.assertIn("fitnessExternalMinutes", stats)
        self.assertIn("fitnessReperaMinutes", stats)
        self.assertIn("let minutes = repera + external", stats)
        domain = read(
            ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain" / "StatsEngine.swift"
        )
        self.assertIn(
            "guard workout.finishedAt != nil || workout.phase == .finished else { return false }",
            domain,
        )
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("Repera + Salud", tab)
        self.assertIn("Health Connect", tab)
        android_domain = read(
            ROOT / "android" / "domain" / "src" / "main" / "java" / "dev" / "repera" / "domain" / "StatsEngine.kt"
        )
        self.assertIn("it.finished && range.contains", android_domain)

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

    def test_hub_uses_last_7_days_not_esta_semana(self):
        stats = read(IOS / "StatsView.swift")
        chips = read(IOS / "ProgressCategoryChips.swift")
        tab = read(ANDROID / "ProgressTab.kt")
        android_chips = read(ANDROID / "ProgressCategoryChips.kt")
        self.assertIn("Últimos 7 días", stats)
        self.assertNotIn("Esta semana", stats)
        self.assertIn("Últimos 7 días", tab)
        self.assertNotIn("Esta semana", tab)
        self.assertIn('case .recovery: return "moon.fill"', chips)
        self.assertIn('case .fitness: return "Físico"', chips)
        self.assertIn('FITNESS("Físico"', android_chips)
        self.assertIn("0.29, green: 0.22, blue: 0.55", chips)
        self.assertIn("0.10, green: 0.61, blue: 0.56", chips)
        # Hub fijo a 7 días; Recuperación/Corazón = Ahora; Media mes tras consistencia.
        self.assertIn('let target: ProgressTimeRange = .week', stats)
        self.assertIn('case .heart, .recovery:\n            return "Ahora"', stats)
        self.assertIn('ProgressCategory.HEART, ProgressCategory.RECOVERY -> "Ahora"', tab)
        self.assertLess(
            stats.index("thisWeekConsistencyCard"),
            stats.index("trainingGlanceMetricsGrid"),
        )
        self.assertLess(
            tab.index("ProgressWeekConsistencyCard"),
            tab.index("ProgressTrainingGlanceGrid("),
        )
        self.assertIn('title = "Media mes"', tab)
        self.assertIn("sportsEvolutionSparkSamples", stats)
        self.assertIn("historial · mejores marcas", stats)
        self.assertIn("mejores marcas", tab)

    def test_month_summaries_at_end_of_health_tabs(self):
        stats = read(IOS / "StatsView.swift")
        tab = read(ANDROID / "ProgressTab.kt")
        for name in (
            "fitnessMonthSummaryCard",
            "heartMonthSummaryCard",
            "recoveryMonthSummaryCard",
            "sportsMonthSummaryCard",
        ):
            self.assertIn(name, stats)
        self.assertIn("ProgressMonthSummaryCard", tab)
        self.assertIn("Actividad del mes", tab)
        self.assertIn("FC media del mes", tab)
        self.assertIn("Descanso del mes", tab)
        self.assertIn("Salidas del mes", tab)
        accents = read(ANDROID / "ReperaColorScheme.kt")
        self.assertIn("0xFF4A388C", accents)
        self.assertIn("0xFF1A9B8E", accents)
        self.assertIn("DarkMode", read(ANDROID / "ProgressCategoryChips.kt"))


if __name__ == "__main__":
    unittest.main()
