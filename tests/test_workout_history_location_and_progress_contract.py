"""Prevent stale location and confusing training/sleep progress regressions."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class HistoryLocationProgressTests(unittest.TestCase):
    def test_historical_location_never_samples_current_phone(self):
        places = read("Apps/Repera/Sources/Location/PlaceSearchSheet.swift")
        lookup = places.split("static func suggestForSession(", 1)[1]
        self.assertNotIn("WorkoutLocationTracker.shared.capturePin()", lookup)
        self.assertIn("return nil", lookup)
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        fn = store.split("private func suggestPlaceForRecentWatchWorkout(", 1)[1].split(
            "func applyWatchSession(", 1
        )[0]
        self.assertIn("guard sourcePin != nil || !points.isEmpty else { return }", fn)
        self.assertNotIn("capturePin()", fn)

    def test_live_review_cannot_erase_captured_start_pin(self):
        live = read("Apps/Repera/Sources/LiveActivityView.swift")
        self.assertIn("recorder.startedAt == activityStart,\n               let pin", live)

    def test_real_latest_workout_is_separate_from_comparable_scores(self):
        stats = read("Apps/Repera/Sources/StatsView.swift")
        self.assertIn("private var latestCompletedWorkout", stats)
        self.assertIn('Text("Última actividad registrada")', stats)
        self.assertIn("latest.sessionReview?.scoreBasis != .personalHistory", stats)
        self.assertIn('scoreMetric("Última nota comparable"', stats)
        self.assertIn("sameDay.count", stats)
        self.assertIn("historicalWorkouts: store.state.workouts", stats)
        self.assertIn("private func liveSportHistoricalContext", stats)
        self.assertIn("guard previous.count >= 2 else { return nil }", stats)
        android = read("android/mobile/src/main/java/dev/repera/mobile/SessionScoreProgressCard.kt")
        self.assertIn('Text(\n                            "Última actividad registrada"', android)
        self.assertIn("latestWorkoutTitle: String? = null", android)

    def test_daily_strength_never_fabricates_kilograms_from_sports_only(self):
        ios = read("Apps/Repera/Sources/StatsView.swift")
        self.assertIn("private var completedWorkoutsToday", ios)
        self.assertIn("StatsEngine.confirmedVolumeKg(in: $1)", ios)
        self.assertIn('title: "Carga y marcas hoy"', ios)
        self.assertIn("sin kilos de fuerza registrados", ios)
        android = read("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        self.assertIn('title = "Carga y marcas hoy"', android)
        self.assertIn("todayKg = snapshot.hubDailyVolumeKg.lastOrNull()", android)
        self.assertIn("todaySessions > 0", android)

    def test_sleep_charts_fill_width_and_have_dotted_hour_guides(self):
        ios = read("Apps/Repera/Sources/HealthRecovery.swift")
        section = ios.split("private func sleepNightCard(", 1)[1].split(
            "private func phaseDistributionBar(", 1
        )[0]
        self.assertIn('RuleMark(y: .value("Hora guía"', section)
        self.assertIn("dash: [2, 4]", section)
        self.assertIn(".padding(.vertical, 10)", section)
        self.assertNotIn(".padding(10)\n                .background(NightSky.ink", section)
        android = read("android/mobile/src/main/java/dev/repera/mobile/RecoverySleepChart.kt")
        self.assertIn("Offset(0f, guideY)", android)
        self.assertIn("Offset(size.width, guideY)", android)
        self.assertIn('"${hour} h"', android)

if __name__ == "__main__":
    unittest.main()
