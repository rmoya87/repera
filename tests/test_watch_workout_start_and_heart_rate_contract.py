"""Contract regression tests: wrist workout start and heart-rate presentation."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class WatchWorkoutStartAndHeartRateTests(unittest.TestCase):
    def test_apple_watch_plan_tap_starts_live_without_dialog(self):
        view = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        home = read("Apps/ReperaWatch/Sources/WatchHomeHubView.swift")
        self.assertIn("onPlayPlan: {\n                            startSelectedPlan(recordOnly: false)", view)
        self.assertIn("onRecordPlan: {\n                            startSelectedPlan(recordOnly: true)", view)
        self.assertIn('Button("Grabar entreno", systemImage: "record.circle")', home)
        self.assertIn("hub.startToday()\n        guard hub.active?.phase == .ready", view)

    def test_apple_watch_last_value_not_ttl_hidden(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("func heartRateBpm(at date: Date = .now) -> Int?", hub)
        self.assertIn('(0..<60).contains(date.timeIntervalSince(captured))', hub)
        self.assertIn("var heartRateIsFresh: Bool", hub)
        self.assertIn('guard (0...20).contains(now.timeIntervalSince(measuredAt)) else { return }', hub)
        zone = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        self.assertIn('?? "Esperando pulso"', zone)
        self.assertIn("WatchHeartRateZoneBar(bpm: bpm, prominent: prominent)", zone)

    def test_wear_plan_tap_starts_counting_and_clock(self):
        activity = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        start = activity.split("private fun startTodayPlan(", 1)[1].split(
            "private fun captureWatchStartLocation(", 1
        )[0]
        self.assertIn("WatchPlanExecution.play(ready)", start)
        self.assertIn("startElapsedClock()", start)
        self.assertIn('controlLocalWodTimer("start")', start)
        self.assertNotIn("sessionPaused = true", start)
        self.assertNotIn("pauseSensorsIntent = dev.repera.domain.WearStartPauseIntent", start)

    def test_wear_keeps_ui_last_sample_but_never_sends_stale_as_live(self):
        session = read("android/wear/src/main/java/dev/repera/wear/WearHealthSession.kt")
        service = read("android/wear/src/main/java/dev/repera/wear/WearHealthService.kt")
        self.assertIn("private fun snapshot()=Snapshot(owner,sensors.heartRateBpm", service)
        self.assertIn("val bpm = sensors.freshHeartRateBpm?", service)
        self.assertIn("val freshHeartRateBpm: Int?", session)
        self.assertIn("val heartSampleAtElapsed: Long", session)
        self.assertNotIn("else if (freshHeartRateBpm == null)", session)
        self.assertIn("heartRateBpm = null", session)  # reset on start/end
        activity = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        ensure = activity.split("private fun ensureHealthRecording()", 1)[1].split("\n    }", 1)[0]
        self.assertNotIn("health=null", ensure)
        self.assertIn("state.heartAtElapsed", activity)
        self.assertIn("60_001L", activity)
        self.assertIn("clearDisplayedHeart()\n        sessionPaused=false", activity)
        self.assertIn("if (previous != next) {\n            // A new companion workout has no heart-rate sample yet.\n            clearDisplayedHeart()", activity)

    def test_zones_reserve_space_before_first_sensor_reading(self):
        watch = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        wear = read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        wear_plan = read("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        self.assertIn('?? "Esperando pulso"', watch)
        self.assertIn("WatchHeartRateZoneMetric", watch)
        self.assertIn("accessibilityLabel(accessibilityDescription)", watch)
        self.assertIn('?: "Zona —/5"', wear)
        self.assertIn("WearHeartRateZoneBar(bpm = health?.first", wear)
        self.assertIn("WearHeartRateZoneBar(bpm = state.health?.first)", wear_plan)

    def test_watch_free_activity_prompts_edit_on_phone(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        notifier = read("Apps/Repera/Sources/WorkoutCompletionNotifier.swift")
        self.assertIn("pending.awaitingResultEntry = true", hub)
        self.assertIn("finished.awaitingResultEntry = true", hub)
        self.assertIn("completed.awaitingResultEntry = true", store)
        self.assertIn("WorkoutCompletionNotifier.shared.schedule(workoutID: session.id)", store)
        self.assertIn("self.state.workouts.first(where: { $0.id == session.id })?.awaitingResultEntry == true", store)
        self.assertIn("scheduleLiveReview(sessionID: UUID)", notifier)

    def test_iphone_companion_watch_finish_enters_review_not_auto_save(self):
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        command = store.split('private func handleWatchLiveCommand(', 1)[1].split(
            'nonisolated func phoneConnectivityDidReceiveStartLive(', 1
        )[0]
        self.assertIn('case "finish":', command)
        self.assertIn("recorder.finish()", command)
        self.assertIn("recorder.phase == .review", command)
        self.assertIn('repera.openComenzarFromWatch', command)
        self.assertNotIn("saveWorkout(completed)", command)
        self.assertNotIn("recorder.discard(saved: true)", command)

    def test_android_wear_finish_offers_review(self):
        listener = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        main = read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        notification = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveReviewNotification.kt")
        self.assertIn("WearLiveReviewNotification.show(this, owner, sessionId)", listener)
        self.assertIn('uri.host == "review-live"', main)
        self.assertIn("runtime.state.phase != dev.repera.domain.LiveActivityState.Phase.IDLE", main)
        self.assertIn("Entrenamiento listo para revisar", notification)

if __name__ == "__main__":
    unittest.main()
