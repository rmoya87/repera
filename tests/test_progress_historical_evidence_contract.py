"""Contracts: personal confidence, true latest activity, original GPS and sleep axes.

Static checks complement native builds and device tests, not a substitute for them.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class ProgressHistoricalEvidenceContract(unittest.TestCase):
    def test_verified_score_is_not_ambiguously_learning(self):
        swift = read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        kotlin = read("android/domain/src/main/java/dev/repera/domain/VerifiedSessionReviewEngine.kt")
        self.assertIn('confidence = "Media · historial personal"', swift)
        self.assertIn('else -> "Media · historial personal"', kotlin)
        self.assertIn('distinctDays.count >= 5 ? "Alta" : "Media · historial personal"', swift)
        self.assertIn('sessionReviewFormulaVersion = 14', read("Apps/Repera/Sources/ReperaStore.swift"))

    def test_ios_card_uses_latest_session_not_just_last_scored(self):
        ui = read("Apps/Repera/Sources/StatsView.swift")
        summary = ui.split('private var scoreSummary: some View', 1)[1]
        self.assertIn('private var latestActivity: RecentActivity?', ui)
        self.assertIn('externalActivities.max { $0.end < $1.end }', ui)
        self.assertIn('Text("Actividad")', summary)
        self.assertIn('scoreMetric("Rendimiento"', summary)
        self.assertIn('scoreMetric("Referencias"', summary)
        self.assertNotIn('scoreMetric("Cobertura"', summary)
        self.assertNotIn('"Última nota verificada"', summary)
        self.assertNotIn('"Mejor nota"', summary)
        self.assertNotIn('"Entrenos registrados"', summary)
        self.assertIn('relativeChangePercent', read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReview.swift"))
        self.assertIn('range.contains(finishedAt, weekStartsOnMonday: weekStartsOnMonday)', ui)
        self.assertIn('HealthMuscleMapper.uniqueExternalActivities(', ui)

    def test_android_card_includes_all_recorded_activity(self):
        tab = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        card = read("android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt")
        self.assertIn('latestActivity = latestActivityTitle', tab)
        self.assertIn('effort = if (pro) overview?.sessionScoreEffortByRange', tab)
        self.assertIn('Text("Actividad"', card)
        self.assertIn('TrendScoreMetric(\n                            "Rendimiento"', card)
        self.assertIn('TrendScoreMetric(\n                            "Referencias"', card)
        self.assertNotIn('TrendScoreMetric(\n                            "Cobertura"', card)
        self.assertNotIn('Última nota verificada', card)
        self.assertIn('dropNativeOverlaps(it, localStats)', read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"))

    def test_historical_location_cannot_be_replaced_by_current_phone(self):
        swift = read("Apps/Repera/Sources/Location/PlaceSearchSheet.swift")
        historical = swift.split('static func suggestForSession(', 1)[1]
        self.assertNotIn('capturePin()', historical)
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        recent = store.split('private func suggestPlaceForRecentWatchWorkout(', 1)[1].split('func applyWatchSession(', 1)[0]
        self.assertNotIn('capturePin()', recent)
        editor = read("android/mobile/src/main/java/dev/repera/mobile/FinishedWorkoutEditor.kt")
        self.assertIn('locationPin = workout.locationPin,', editor)

    def test_sleep_fills_plot_and_shows_hour_guides(self):
        ios = read("Apps/Repera/Sources/HealthRecovery.swift")
        sleep = ios.split('private func sleepNightCard(', 1)[1].split('private func phaseDistributionBar(', 1)[0]
        self.assertIn('startPadding: 0, endPadding: 0', sleep)
        self.assertIn('Text("\\(Int(hour)) h")', sleep)
        self.assertIn('filter { $0 > yLo + 0.01 }', sleep)
        self.assertIn('.chartYAxis(.hidden)', sleep)
        self.assertIn('annotation(position: .overlay, alignment: .leading)', sleep)
        self.assertIn('selected.hours)) h · \\(selected.date.formatted', sleep)
        self.assertNotIn('.chartXAxis(.hidden)', sleep)
        android = read("android/mobile/src/main/java/dev/repera/mobile/RecoverySleepChart.kt")
        self.assertIn('PathEffect.dashPathEffect(', android)
        self.assertIn('hour.toString() + " h"', android)
        self.assertIn('if (hour.toDouble() <= yLo + 0.01) continue', android)
        self.assertIn('Paint.Align.LEFT', android)
        self.assertIn('Offset(0f, lineY), Offset(size.width, lineY)', android)
        self.assertIn('h · ${', android)

    def test_plot_last_seven_scored_sessions_on_0_10_axis(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        plot = read("android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt")
        self.assertIn(".prefix(7).reversed()", ios)
        self.assertIn("private var recentScoredWorkouts: [RecentScoredWorkout]", ios)
        self.assertIn('y: .value("Puntuación", Double(item.verifiedScore))', ios)
        self.assertIn(".chartYScale(domain: 0.0...10.0)", ios.split("private var sevenWorkoutChart", 1)[1])
        self.assertIn(".take(7).reversed()", android)
        self.assertIn("ScoreBasis.PERSONAL_HISTORY", android)
        self.assertIn("SevenRecentWorkoutScoreChart(", plot)
        chart = plot.split("private fun SevenRecentWorkoutScoreChart(", 1)[1]
        self.assertIn("0 a 10", chart)
        self.assertNotIn("Duración · minutos", chart)
        self.assertNotIn("Sin nota comparable", chart)
        # Cada sesión ocupa una posición; no se interpolan días sin sesión.
        self.assertNotIn("ChronoUnit.DAYS", chart)

    def test_daily_training_not_confused_with_fake_weight(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        self.assertIn('private var trainingSessionsToday: Int', ios)
        self.assertIn('La carga en kg requiere series y pesos registrados', ios)
        self.assertNotIn('Hoy \\(trainingSessionsToday) ses.', ios)
        self.assertNotIn('strengthTodaySummary', ios)
        self.assertIn('activitiesToday = realWorkoutsToday', android)
        self.assertNotIn('val todaySummary =', android)
        self.assertNotIn('todayPrs', android)
        self.assertIn('" kg / 7 d"', android)
        self.assertNotIn('"Hoy " + realWorkoutsToday', android)

    def test_heart_zones_fallback_to_samples_when_zone_group_missing(self):
        store = read("Apps/Repera/Sources/HealthKitStore.swift")
        self.assertIn("estimatedHeartZonesFromSamples", store)
        self.assertIn("Estimado desde tu frecuencia cardíaca", store)
        self.assertNotIn("guard #available(iOS 27, *) else { return nil }", store.split("func heartZones(for session", 1)[1].split("func overlappingWorkoutWithZones", 1)[0])

    def test_cardio_selection_shows_min_avg_max(self):
        ios = read("Apps/Repera/Sources/ProgressTrendCards.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressCardioPlot.kt")
        cardio = ios.split("struct ProgressCardioChartCard", 1)[1].split("struct ProgressCaloriesChartCard", 1)[0]
        self.assertIn("minBpm.rounded())) · \\(Int(selectedPoint.avgBpm.rounded())) · \\(Int(selectedPoint.maxBpm.rounded())) lpm", cardio)
        # Overlay: no desplaza la gráfica; sin «Media» duplicada junto al título.
        self.assertIn("ZStack(alignment: .top)", cardio)
        self.assertNotIn('Text("Media \\(Int(stats.avg.rounded())) lpm")', cardio)
        self.assertIn("Alignment.TopCenter", android)
        self.assertNotIn('Media ${Math.round', read("android/mobile/src/main/java/dev/repera/mobile/ProgressCharts.kt"))

    def test_estimated_heart_zones_hide_source_caption(self):
        zones = read("Apps/Repera/Sources/ProgressTrendCards.swift").split(
            "struct ProgressHeartZonesCard", 1
        )[1].split("struct ProgressCardioChartCard", 1)[0]
        self.assertIn('zones.source.hasPrefix("Estimado")', zones)
        self.assertIn("? nil", zones)

    def test_score_chart_uses_full_width_domain(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        chart = ios.split("private var sevenWorkoutChart", 1)[1]
        self.assertIn(".chartXScale(domain: 1...max(1, recent.count))", chart)
        self.assertNotIn(".chartXScale(domain: 0...", chart.split(".chartYScale", 1)[0])
        android = read("android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt")
        score = android.split("private fun SevenRecentWorkoutScoreChart(", 1)[1]
        self.assertIn("size.width * index / (recent.size - 1)", score)

    def test_recovery_evolution_keeps_continuous_scored_days(self):
        ios = read("Apps/Repera/Sources/HealthRecovery.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressCharts.kt")
        prep = ios.split("private func prepareTrainingRecovery()", 1)[1].split("private var hasCycleData", 1)[0]
        self.assertIn("segment: 0", prep)
        self.assertNotIn("segment += 1", prep)
        readiness = android.split("if(readinessStyle) {", 1)[1].split("} else if(weightStyle)", 1)[0]
        self.assertIn("Solo días con nota: trazo continuo", readiness)
        self.assertNotIn("observedSegments(points)", readiness)


if __name__ == "__main__":
    unittest.main()
