"""Source-contract safety checks for offline watchOS HealthKit integration.

These checks do not substitute compiling/running with the watchOS SDK.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


class WatchHealthKitContractTests(unittest.TestCase):
    def test_watch_healthkit_capabilities(self):
        project = source("project.yml")
        plist = source("Apps/ReperaWatch/Resources/Info.plist")
        entitlements = source("Apps/ReperaWatch/Resources/ReperaWatch.entitlements")
        self.assertIn("CODE_SIGN_ENTITLEMENTS: Apps/ReperaWatch/Resources/ReperaWatch.entitlements", project)
        self.assertIn("com.apple.developer.healthkit: true", project)
        self.assertIn("com.apple.developer.healthkit", entitlements)
        self.assertIn("workout-processing", plist)
        self.assertNotIn("<string>audio</string>", plist)
        self.assertIn("NSHealthShareUsageDescription", plist)
        self.assertIn("NSHealthUpdateUsageDescription", plist)

    def test_native_watch_session_and_recovery(self):
        watch = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        for symbol in (
            "HKWorkoutSession(", "associatedWorkoutBuilder()",
            "HKLiveWorkoutDataSource(", "startActivity(with:", "beginCollection(at:",
            "stopActivity(with:", "endCollection(at:",
            "finishWorkout()", "recoverActiveWorkoutSession",
            "HKMetadataKeyExternalUUID", "startMirroringToCompanionDevice()",
            "beginNewActivity(", "onPauseResumeRequest", "pauseOrResumeRequest"
        ):
            self.assertIn(symbol, watch)
        self.assertNotIn("beginCollection(withStart:", watch)
        self.assertNotIn("endCollection(withEnd:", watch)
        self.assertNotIn("startMirroringToCompanionDevice {", watch)
        self.assertIn("try await liveBuilder.addMetadata(", watch)
        self.assertIn("try await builder.finishWorkout()", watch)

    def test_health_truth_sync_and_redaction(self):
        watch = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        phone = source("Apps/Repera/Sources/ReperaStore.swift")
        health = source("Apps/Repera/Sources/HealthKitStore.swift")
        mirror = source("Apps/Repera/Sources/BusinessWorkoutSyncStore.swift")
        self.assertIn("health.finish", watch)
        self.assertIn("health.pause()", watch)
        self.assertIn("health.resume()", watch)
        self.assertIn("appleHealthProvenance", watch)
        self.assertIn("reconcileWatchHealthMetrics()", phone)
        self.assertIn("workoutSessionMirroringStartHandler", health)
        self.assertIn("isWatchWorkoutMirrored", health)
        self.assertIn("professionalWorkoutForWatchToday()", phone)
        self.assertIn("persistAndFlush(snapshot)", phone)
        self.assertIn("completedAckHealthKitUUID:", phone)
        self.assertIn("verifiedWatchWorkout(forReperaSession", health)
        self.assertIn("isWatchRecordedSource", health)
        for scrubbed in (
            "value.healthKitWorkoutUUID = nil",
            "value.appleActiveEnergyKcal = nil",
            "value.appleDurationSeconds = nil",
            "value.appleAverageHeartRateBpm = nil",
            "value.appleHealthProvenance = nil",
        ):
            self.assertIn(scrubbed, mirror)

    def test_offline_background_transport_and_complication(self):
        watch = source("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        widget = source("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        for symbol in ("transferUserInfo", "pendingKey", "acknowledge", "todayDayStart", "healthKitUUID"):
            self.assertIn(symbol, watch)
        self.assertIn('Image("ReperaIcon")', widget)
        self.assertIn(".widgetURL(", widget)

    def test_watch_complication_uses_widget_configuration_inside_widget(self):
        """WidgetBundleBuilder accepts Widget, not StaticConfiguration."""
        widget = source("Apps/ReperaWatchWidget/ReperaWatchWidget.swift")
        self.assertIn("struct ReperaWatchWidget: Widget {", widget)
        self.assertIn("var body: some WidgetConfiguration {", widget)
        self.assertIn("StaticConfiguration(", widget)
        self.assertIn("struct ReperaWatchWidgetBundle: WidgetBundle {", widget)
        self.assertIn("var body: some Widget {\n        ReperaWatchWidget()\n    }", widget)
        self.assertEqual(widget.count("@main"), 1)
        for family in (".accessoryCircular", ".accessoryRectangular", ".accessoryInline"):
            self.assertIn(family, widget)


if __name__ == "__main__":
    unittest.main()
