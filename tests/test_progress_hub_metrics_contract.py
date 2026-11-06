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
        # Chip Físico = media diaria 7d (no total del mes / periodo).
        fitness_chip = glance.split("case .fitness:", 1)[1].split("case .heart:", 1)[0]
        self.assertIn("dailyAverageMinutes", fitness_chip)
        self.assertNotIn("snap.summary.totalMinutes", fitness_chip)

        tab = read(ANDROID / "ProgressTab.kt")
        self.assertNotIn('ProgressCategory.RECOVERY -> "·"', tab)
        self.assertNotIn('ProgressCategory.SPORTS -> "·"', tab)
        fitness_glance = tab.split("ProgressCategory.FITNESS ->", 1)[1].split(
            "ProgressCategory.HEART ->", 1
        )[0]
        self.assertIn("dailyAverageMinutes", fitness_glance)

    def test_fitness_formats_hours_and_minutes(self):
        stats = read(IOS / "StatsView.swift")
        self.assertIn("activeDurationHero", stats)
        self.assertIn("activeDurationNarrative", stats)
        self.assertIn("compactActiveDuration", stats)
        self.assertIn("dailyAverageMinutes", stats)
        self.assertIn("weeklyAverageMinutes", stats)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("activeDurationHero", tab)
        self.assertIn("activeDurationNarrative", tab)
        self.assertIn("dailyAverageMinutes", tab)
        self.assertIn("weeklyAverageMinutes", tab)

    def test_fitness_stimulus_shows_daily_average_and_mini_bars(self):
        stats = read(IOS / "StatsView.swift")
        fitness = stats.split("private var fitnessCategoryContent", 1)[1].split(
            "private var heartCategoryContent", 1
        )[0]
        self.assertIn("media diaria", fitness)
        self.assertIn("ProgressInsightElevatedCard", fitness)
        self.assertIn("ProgressMiniFillBars", fitness)
        self.assertNotIn("Repera + Salud", fitness)
        self.assertNotIn("figure.walk", fitness)
        strength = stats.split("private var strengthCategoryContent", 1)[1].split(
            "private var strengthGlanceSessions", 1
        )[0]
        self.assertIn("ProgressInsightElevatedCard", strength)
        self.assertIn("ProgressMiniAreaSpark", strength)
        self.assertIn("chartBesideTitle: true", strength)
        self.assertIn("chartHeight: 118", strength)
        self.assertIn("chartBesideTitle: true", fitness)
        self.assertIn("chartHeight: 118", fitness)
        heart = stats.split("private var heartCategoryContent", 1)[1].split(
            "private var heartInsightCopy", 1
        )[0]
        self.assertIn("ProgressMiniRangeBars", heart)
        self.assertIn("heartSparkSamples", heart)
        self.assertNotIn("chartBelow: true", heart)
        tab = read(ANDROID / "ProgressTab.kt")
        fitness_a = tab.split("ProgressCategory.FITNESS -> {", 1)[1].split(
            "ProgressCategory.HEART -> {", 1
        )[0]
        self.assertIn("media diaria", fitness_a)
        self.assertIn("fitnessDailyBarFractions", fitness_a)
        self.assertIn("elevateChart = true", fitness_a)
        self.assertIn("chartBesideTitle = true", fitness_a)
        self.assertNotIn("Repera + Salud", fitness_a)
        strength_a = tab.split("ProgressCategory.STRENGTH -> {", 1)[1].split(
            "ProgressCategory.FITNESS -> {", 1
        )[0]
        self.assertIn("chartBesideTitle = true", strength_a)

    def test_fitness_month_shows_weekly_average_and_chart(self):
        stats = read(IOS / "StatsView.swift")
        month = stats.split("private var fitnessMonthSummaryCard", 1)[1].split(
            "private var heartMonthSummaryCard", 1
        )[0]
        self.assertIn("media semana", month)
        self.assertNotIn("sesiones", month)
        self.assertIn("ProgressMiniFillBars", month)
        self.assertIn("ProgressInsightElevatedCard", month)
        self.assertNotIn("Repera + Salud", month)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("media semana", tab)
        self.assertIn("weeklyAverageMinutes", tab)

    def test_heart_month_shows_weekly_average_and_progression(self):
        stats = read(IOS / "StatsView.swift")
        heart_month = stats.split("private var heartMonthSummaryCard", 1)[1].split(
            "private var recoveryMonthSummaryCard", 1
        )[0]
        self.assertIn("Cardio del mes", heart_month)
        self.assertIn("media/semana", heart_month)
        self.assertIn("ProgressInsightElevatedCard", heart_month)
        self.assertNotIn("Media semanal de", heart_month)
        self.assertIn("heartMonthSparkSamples", heart_month)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("Cardio del mes", tab)
        self.assertIn("heartWeeklyAverageBpm", tab)
        self.assertIn("heartMonthBarFractions", tab)

    def test_calories_week_axis_fills_seven_days(self):
        trend = read(IOS / "ProgressTrendCards.swift")
        self.assertIn("calendarDays", trend)
        self.assertIn("prefersSparseMarks", trend)
        plot = read(ANDROID / "ProgressCaloriesPlot.kt")
        self.assertIn("huecos honestos", plot)
        self.assertIn("ProgressTimeRange.WEEK", plot)

    def test_weight_points_limited_to_last_year(self):
        snap = read(IOS / "ProgressSnapshot.swift")
        weight = snap.split("static func buildWeightPoints", 1)[1]
        self.assertIn("-365", weight)
        android_snap = read(ANDROID / "ProgressSnapshot.kt")
        self.assertIn("minusDays(365)", android_snap)

    def test_heart_bars_never_use_placeholder_ranges(self):
        stats = read(IOS / "StatsView.swift")
        heart = stats.split("private static func heartRangeSamples", 1)[1].split(
            "private func heartExtremeText", 1
        )[0]
        self.assertNotIn("0.25...0.55", heart)
        # Dominio holgado: el mín lpm no mapea al eje X (lowerBound ≥ 0.04).
        self.assertIn("domainLo", heart)
        self.assertIn("0.04", heart)
        self.assertIn("Canvas", read(IOS / "ProgressCategoryChips.swift"))

        tab = read(ANDROID / "ProgressTab.kt")
        self.assertNotIn('ProgressCategory.HEART -> "—"', tab)
        self.assertIn("recentHeartBpm", tab)
        self.assertIn("heartDailyBarFractions", tab)
        self.assertIn("chartsByRange", tab)
        heart_fn = tab.split("private fun heartDailyBarRanges", 1)[1].split(
            "private fun smoothFractions", 1
        )[0]
        self.assertIn("domainLo", heart_fn)
        self.assertIn("0.04f", heart_fn)
        self.assertIn("drawRoundRect", tab)

    def test_strength_bars_use_weekly_volume_not_fake_e1rm(self):
        stats = read(IOS / "StatsView.swift")
        spark = stats.split("private var strengthSparkSamples", 1)[1].split(
            "private var strengthInsightCopy", 1
        )[0]
        self.assertIn("strengthDailyVolumeLast7", spark)
        self.assertIn("log1p(vol) / logPeak", spark)
        self.assertNotIn("weeklyVolumeSeries", spark)
        self.assertNotIn("estimatedOneRM / 200", spark)
        insight = stats.split("private var strengthInsightCopy", 1)[1].split(
            "@ViewBuilder", 1
        )[0]
        self.assertNotIn("Las barras muestran", insight)
        strength = stats.split("private var strengthCategoryContent", 1)[1].split(
            "private var strengthSparkSamples", 1
        )[0]
        self.assertIn("strengthGlanceSessions", strength)
        self.assertIn("strengthGlanceExercises", strength)
        self.assertNotIn("snap.summary.sessionCount", strength)
        self.assertNotIn("snap.chartExercises.count", strength)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("strengthDailyBarFractions", tab)
        self.assertIn("ln(1.0 + vol) / logPeak", tab)
        self.assertIn("hubDailyVolumeKg", tab)
        self.assertNotIn("Las barras muestran", tab)
        self.assertIn("strengthSessionCount", tab)
        self.assertIn("strengthExerciseCount", tab)

    def test_sports_hub_has_more_than_empty_catalog_link(self):
        stats = read(IOS / "StatsView.swift")
        sports = stats.split("private var sportsCategoryContent", 1)[1].split(
            "private var longTermTrainingTeaser", 1
        )[0]
        self.assertIn("Actividad\\ndeportiva", sports)
        self.assertIn("Progresión en\\nejercicios", sports)
        self.assertIn("sportsEvolutionSparkSamples", sports)
        self.assertNotIn("exerciseProgressSparkSamples", sports)
        self.assertIn("monthActivityHighlights", sports)
        self.assertIn("Resumen por\\nactividad", sports)
        self.assertIn("Ejercicios al alza", sports)
        self.assertIn("Del plan", sports)
        self.assertNotIn("últimos 3 meses", sports)
        self.assertIn("al alza", sports)
        self.assertIn('ogFont(52, weight: .bold, design: .rounded, relativeTo: .largeTitle)', sports)
        self.assertNotIn("historial · mejores marcas", sports)
        self.assertNotIn("e1RM al alza en tu historial", sports)
        tab = read(ANDROID / "ProgressTab.kt")
        self.assertIn("Actividad\\ndeportiva", tab)
        self.assertIn("Progresión en\\nejercicios", tab)
        self.assertIn("ProgressMiniBarRow", tab)
        self.assertIn("sportsDailyBarFractions", tab)
        self.assertIn("monthActivityHighlights", tab)
        self.assertIn("Resumen por\\nactividad", tab)
        self.assertNotIn("historial · mejores marcas", tab)

    def test_fitness_stimulus_uses_finished_sessions_only(self):
        stats = read(IOS / "StatsView.swift")
        self.assertIn("fitnessExternalMinutes", stats)
        self.assertIn("fitnessReperaMinutes", stats)
        self.assertIn("fitnessReperaMinutes + fitnessExternalMinutes", stats)
        domain = read(
            ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain" / "StatsEngine.swift"
        )
        self.assertIn(
            "guard workout.finishedAt != nil || workout.phase == .finished else { return false }",
            domain,
        )
        tab = read(ANDROID / "ProgressTab.kt")
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

    def test_android_chrome_shadow_is_shared_and_soft(self):
        bar = read(ANDROID / "ReperaFloatingTabBar.kt")
        live = read(ANDROID / "LiveActivityScreen.kt")
        place = read(ANDROID / "PlaceSearchSheet.kt")
        editor = read(ANDROID / "FinishedWorkoutEditor.kt")
        self.assertIn("fun Modifier.reperaChromeShadow", bar)
        self.assertIn("ReperaChromeShadowElevation = 1.5.dp", bar)
        self.assertIn("reperaChromeShadow(", live)
        self.assertIn("reperaChromeShadow(", place)
        self.assertIn("ReperaChromeAmbientShadow", editor)
        self.assertNotIn("shadowElevation = 4.dp", bar)
        self.assertNotIn("shadowElevation = 6.dp", bar)

    def test_android_progress_chips_full_bleed_horizontal(self):
        """Carrusel de chips: viewport a borde de pantalla; inset en contenido scrolleable."""
        chips = read(ANDROID / "ProgressCategoryChips.kt")
        bar = read(ANDROID / "ReperaFloatingTabBar.kt")
        self.assertIn("fun Modifier.reperaFullBleedHorizontal", bar)
        self.assertIn("ReperaPageGutter", bar)
        self.assertIn("reperaFullBleedHorizontal()", chips)
        self.assertIn("padding(horizontal = ReperaPageGutter", chips)
        # No recortar el viewport con padding fijo pequeño antes del scroll.
        self.assertNotIn("padding(horizontal = 4.dp, vertical = 4.dp)", chips)
        ios = read(IOS / "ProgressCategoryChips.swift")
        self.assertIn(".padding(.horizontal, OG.pad)", ios)

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
        self.assertIn("0.42, green: 0.36, blue: 0.72", chips)
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
        self.assertIn("Resumen por\\nactividad", tab)
        self.assertIn("elevateChart", tab)

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
        self.assertIn("Cardio del mes", tab)
        self.assertIn("Descanso del mes", tab)
        self.assertIn("Resumen por\\nactividad", tab)
        accents = read(ANDROID / "ReperaColorScheme.kt")
        self.assertIn("0xFF4A388C", accents)
        self.assertIn("0xFF1A9B8E", accents)
        self.assertIn("DarkMode", read(ANDROID / "ProgressCategoryChips.kt"))

    def test_recovery_empty_copy_is_short(self):
        recovery = read(IOS / "HealthRecovery.swift")
        self.assertIn("Repera necesita 2 días evaluables para evaluarte.", recovery)
        self.assertIn("Repera necesita sueño o 7 días de constantes para evaluarte", recovery)
        self.assertIn("Repera necesita 1 noche de sueño para evaluarte.", recovery)
        self.assertNotIn(
            "Necesita al menos 2 días con preparación evaluable. Sin sueño: 7 días previos",
            recovery,
        )
        android_rec = read(ANDROID / "RecoveryHistoryCards.kt")
        self.assertIn("Repera necesita 2 días evaluables para evaluarte.", android_rec)
        self.assertIn("Repera necesita 1 noche de sueño para evaluarte.", android_rec)


if __name__ == "__main__":
    unittest.main()
