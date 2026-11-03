"""Static regression contracts for measured heart-rate zones in Comenzar.

These tests deliberately do not simulate live HealthKit/Health Connect samples.
That requires physical devices, sensor permissions, and native builds.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class LiveHeartRateZoneContractTests(unittest.TestCase):
    def test_ios_discrete_bar_no_gradient_and_active_labels(self):
        code = read("Apps/Repera/Sources/HeartRateZoneBar.swift")
        self.assertNotIn("LinearGradient", code)
        self.assertIn("ForEach(1...5", code)
        self.assertIn("Text(\"Zona \\(level)\")", code)
        self.assertIn("Text(\"\\(bpm) lpm\")", code)
        self.assertIn("active ? 42 : 12", code)
        self.assertNotIn("Sin lectura de FC", code)
        self.assertIn("if let bpm, let zone", code)
        for limit in ("0.60", "0.70", "0.80", "0.90"):
            self.assertIn(limit, code)

    def test_ios_gps_map_and_metrics_use_same_measured_bpm(self):
        live = read("Apps/Repera/Sources/LiveActivityView.swift")
        self.assertGreaterEqual(live.count("HeartRateZoneBar(bpm: bpm)"), 3)
        self.assertIn("if mapDetailsExpanded {", live)
        self.assertIn(".onTapGesture { mapDetailsExpanded.toggle() }", live)
        self.assertIn("if let bpm = displayedHeartRateBpm", live)
        self.assertIn(".accessibilityHint(\"Muestra u oculta desnivel y frecuencia cardíaca\")", live)
        self.assertNotIn("guard !recorder.sport.usesGPS", live)
        self.assertIn("Date().addingTimeInterval(-60)", live)
        self.assertIn("receiveCompanionHeartRate(sessionId:", live)
        self.assertIn("latestCompanionHeartRateBpm", live)
        self.assertIn("heart.id == sessionID", live)
        self.assertIn("age <= 20", live)

    def test_apple_watch_sends_real_session_scoped_samples(self):
        watch = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        client = read("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        phone = read("Apps/Repera/Sources/PhoneConnectivity.swift")
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("health.pulseBpm", watch)
        self.assertIn("publishCompanionHeartRateIfNeeded", watch)
        self.assertIn("connectivity.sendLiveHeartRate(", watch)
        self.assertIn("health.pulseCapturedAt", watch)
        self.assertIn("watchConnectivityDidBecomeReachable", watch)
        self.assertIn("collectedTypes.contains(heart)",
            read("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift"))
        self.assertIn("sendLiveHeartRate(", client)
        self.assertIn("WCSession.default.isReachable", client)
        self.assertIn('"action": "liveHeartRate"', client)
        self.assertIn('case "liveHeartRate":', phone)
        self.assertIn("phoneConnectivityDidReceiveLiveHeartRate", store)

    def test_android_segmented_bar_and_every_live_surface(self):
        bar = read("android/mobile/src/main/java/dev/repera/mobile/LiveHeartRateZoneBar.kt")
        screen = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        self.assertNotIn("Brush.horizontalGradient", bar)
        self.assertNotIn("Brush.linearGradient", bar)
        self.assertIn("LiveHeartRateZones.zone(bpm)", bar)
        self.assertIn("if (active) 3f else 1f", bar)
        self.assertIn("Zona $level", bar)
        self.assertIn("$bpm lpm", bar)
        self.assertNotIn("Sin lectura de FC", bar)
        self.assertIn("LiveHeartRateZones.zone(bpm) ?: return", bar)
        self.assertIn("expanded = mapDetailsExpanded", screen)
        self.assertIn("mapDetailsExpanded = !mapDetailsExpanded", screen)
        self.assertIn("if (expanded && bpm != null && bpm in 25..250)", screen)
        self.assertGreaterEqual(screen.count("LiveHeartRateZoneBar("), 3)
        self.assertIn("state.sport.usesGPS", screen)
        self.assertIn("HealthConnectReader(context)", screen)
        self.assertIn("runtime.currentWearHeartRateBpm(nowTick)", screen)

    def test_android_sources_are_real_and_stale_data_expires(self):
        reader = read("android/mobile/src/main/java/dev/repera/mobile/HealthConnectReader.kt")
        runtime = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityRuntime.kt")
        wear = read("android/wear/src/main/java/dev/repera/wear/WearHealthService.kt")
        mobile = read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        listener = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        self.assertIn("getGrantedPermissions()", reader)
        self.assertIn("HeartRateRecord::class", reader)
        self.assertIn("atEpochMs - 20_000L", reader)
        self.assertIn("state.gpsSessionID != sessionID", runtime)
        self.assertIn("now - wearHeartCapturedAt", runtime)
        self.assertIn("20_000L", runtime)
        self.assertIn("sensors.freshHeartRateBpm", wear)
        self.assertIn("lastHeartSampleAtElapsed",
            read("android/wear/src/main/java/dev/repera/wear/WearHealthSession.kt"))
        self.assertIn('"/repera/live-heart-rate"', wear)
        self.assertIn('"/repera/live-heart-rate"', mobile)
        self.assertIn('"/repera/live-heart-rate"', listener)
        self.assertIn("SessionStore(this).load()?.uniqueId", listener)

    def test_map_is_compact_by_default_and_metrics_view_keeps_hr_when_real(self):
        ios = read("Apps/Repera/Sources/LiveActivityView.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        self.assertIn("@State private var mapDetailsExpanded = false", ios)
        self.assertIn("mapDetailsExpanded.toggle()", ios)
        self.assertIn("if mapDetailsExpanded {", ios)
        self.assertIn("if recorder.sport.tracksElevation && recorder.hasElevationSamples", ios)
        self.assertIn("remember(accountId, state.gpsSessionID)", android)
        self.assertIn("mutableStateOf(false)", android)
        self.assertIn("if (expanded && state.sport.tracksElevation", android)
        self.assertIn("if (state.phase == LiveActivityState.Phase.IDLE) Modifier", android)
        self.assertNotIn("Sin lectura de FC",
            read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt"))

    def test_live_healthkit_and_health_connect_never_relabel_old_samples(self):
        ios = read("Apps/Repera/Sources/HealthKitStore.swift")
        android = read("android/mobile/src/main/java/dev/repera/mobile/HealthConnectReader.kt")
        self.assertIn("end.timeIntervalSince(sample.endDate)", ios)
        self.assertIn("atEpochMs - 20_000L", android)
        self.assertIn("pulseCapturedAt = Date()",
            read("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift"))
        self.assertIn("freshHeartRateBpm",
            read("android/wear/src/main/java/dev/repera/wear/WearHealthService.kt"))

    def test_watch_and_android_use_same_zone_cutoffs(self):
        ios = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        android = read("android/domain/src/main/java/dev/repera/domain/LiveHeartRateZones.kt")
        wear = read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        for value in ("0.60", "0.70", "0.80", "0.90"):
            self.assertIn(value, ios)
            self.assertIn(value, android)
        self.assertIn("LiveHeartRateZones.zone(bpm, estimatedMaxBpm)", wear)


if __name__ == "__main__":
    unittest.main()
