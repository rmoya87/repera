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
        self.assertIn("var heartRateBpm: Int? { health.pulseBpm }", hub)
        self.assertIn("var heartRateIsFresh: Bool", hub)
        self.assertIn('guard (0...20).contains(now.timeIntervalSince(measuredAt)) else { return }', hub)
        zone = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        self.assertIn('?? "Esperando pulso"', zone)
        self.assertIn("WatchHeartRateZoneBar(bpm: hub.heartRateBpm", zone)

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
        self.assertNotIn("else if (freshHeartRateBpm == null)", session)
        self.assertIn("heartRateBpm = null", session)  # reset on start/end
        activity = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        ensure = activity.split("private fun ensureHealthRecording()", 1)[1].split("\n    }", 1)[0]
        self.assertNotIn("health=null", ensure)
        self.assertIn("state.heart ?: health?.first", activity)
        self.assertIn("health = null\n        sessionPaused=false", activity)
        self.assertIn("if (previous != next) {\n            // A new companion workout has no heart-rate sample yet.\n            health = null", activity)

    def test_zones_reserve_space_before_first_sensor_reading(self):
        watch = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        wear = read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        wear_plan = read("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        self.assertIn('?? "Esperando pulso"', watch)
        self.assertIn("accessibilityLabel(accessibilityDescription)", watch)
        self.assertIn('?: "Esperando pulso"', wear)
        self.assertIn("WearHeartRateZoneBar(bpm = health?.first", wear)
        self.assertIn("WearHeartRateZoneBar(bpm = state.health?.first)", wear_plan)

if __name__ == "__main__":
    unittest.main()
