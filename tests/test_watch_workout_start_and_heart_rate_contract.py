"""Contract regression tests: wrist workout start and heart-rate presentation."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

class WatchWorkoutStartAndHeartRateTests(unittest.TestCase):
    def test_apple_watch_location_delegate_implements_fail(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("locationManager.requestLocation()", hub)
        self.assertIn(
            "func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)",
            hub,
        )
        self.assertIn("CLError)?.code == .locationUnknown", hub)

    def test_apple_watch_plan_tap_chooses_live_or_record_dialog(self):
        view = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        home = read("Apps/ReperaWatch/Sources/WatchHomeHubView.swift")
        # Overlay a nivel de sesión (no dentro del hub): evita crash al desmontar.
        self.assertIn("pendingPlanStart", view)
        self.assertIn("commitPendingPlanStart", view)
        self.assertIn("onRequestPlanMode:", view)
        self.assertIn("await Task.yield()", view)
        self.assertIn("WatchPlanModeOverlay(", view)
        # watchOS: no contextMenu ni confirmationDialog (Liquid Glass traga toques).
        self.assertNotIn(".contextMenu", home)
        self.assertNotIn(".confirmationDialog(", home)
        self.assertIn("struct WatchPlanModeOverlay", home)
        self.assertIn("Entreno guiado", home)
        self.assertIn("Entreno libre", home)
        self.assertIn(".buttonStyle(.plain)", home)
        self.assertNotIn(".buttonStyle(.borderedProminent)", home)
        self.assertIn("guard hub.startToday(), hub.active?.phase == .ready", view)

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
        self.assertIn("pendingLiveReviewKey", notifier)
        root = read("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("openPendingWatchLiveReviewNotification()", root)

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

    def test_comenzar_review_can_save_then_add_or_edit_exercises(self):
        ios = read("Apps/Repera/Sources/LiveActivityView.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        screen = read("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")
        self.assertIn("Guardar y añadir/editar ejercicios", ios)
        self.assertIn("session.awaitingResultEntry = true", ios)
        self.assertIn("WorkoutCompletionNotifier.openEvent", ios)
        self.assertIn("Guardar y añadir/editar ejercicios", android)
        self.assertIn('testTag("live_save_and_edit")', android)
        self.assertIn('navController.navigate("historial-editar/" + Uri.encode(sessionId))', screen)

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
