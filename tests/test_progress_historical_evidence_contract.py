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
        self.assertIn('sessionReviewFormulaVersion = 13', read("Apps/Repera/Sources/ReperaStore.swift"))

    def test_ios_card_uses_latest_session_not_just_last_scored(self):
        ui = read("Apps/Repera/Sources/StatsView.swift")
        self.assertIn('private var latestActivity: RecentActivity?', ui)
        self.assertIn('externalActivities.max { $0.end < $1.end }', ui)
        self.assertIn('"Entrenos registrados",', ui.split('private var scoreSummary: some View', 1)[1])
        self.assertIn('range.contains(finishedAt, weekStartsOnMonday: weekStartsOnMonday)', ui)
        self.assertIn('HealthMuscleMapper.uniqueExternalActivities(', ui)

    def test_android_card_includes_all_recorded_activity(self):
        tab = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        card = read("android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt")
        self.assertIn('latestActivity = latestActivityTitle', tab)
        self.assertIn('recordedSessions = overview?.dayWorkoutCounts', tab)
        self.assertIn('TrendScoreMetric("Entrenos registrados"', card)
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
        self.assertIn('RuleMark(y: .value("Referencia en horas"', sleep)
        self.assertNotIn('.padding(10)', sleep)
        android = read("android/mobile/src/main/java/dev/repera/mobile/RecoverySleepChart.kt")
        self.assertIn('PathEffect.dashPathEffect(', android)
        self.assertIn('hour.toString() + " h"', android)
        self.assertIn('Offset(0f, lineY), Offset(size.width, lineY)', android)

    def test_daily_training_not_confused_with_fake_weight(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        self.assertIn('private var trainingSessionsToday: Int', ios)
        self.assertIn('La carga en kg requiere series y pesos registrados', ios)
        self.assertIn('activitiesToday = overview?.dayWorkoutCounts', android)
        self.assertIn('sin kg confirmados', android)


if __name__ == "__main__":
    unittest.main()
