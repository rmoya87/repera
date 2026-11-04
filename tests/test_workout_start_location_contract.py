"""Contracts for one-shot start-location capture on all four native platforms.

These source-level guards complement platform compilation and simulator tests.
They deliberately do not assume location permission or a satellite fix always exists.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WorkoutStartLocationContractTests(unittest.TestCase):
    def test_apple_start_point_does_not_create_route(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("captureStartLocation(sessionID: next.session.id, recordsRoute: false)", hub)
        self.assertIn("captureStartLocation(sessionID: id, recordsRoute: sport.usesGPS)", hub)
        self.assertIn("locationManager.requestLocation()", hub)
        self.assertIn("if recordsRoute { locationManager.startUpdatingLocation() }", hub)
        self.assertIn('source: "appleWatch"', hub)
        self.assertIn("horizontalAccuracyMeters: location.horizontalAccuracy", hub)
        self.assertIn("connectivity.sendFinished(finished)", hub)
        self.assertIn("checkpoint() // Sincronización actual + copia offline.", hub)

    def test_iphone_indoor_snapshot_is_recorded_at_start(self):
        phone = read("Apps/Repera/Sources/LiveActivityView.swift")
        tracker = read("Apps/Repera/Sources/Location/WorkoutLocationTracker.swift")
        self.assertIn("if !sport.usesGPS {", phone)
        self.assertIn("reviewLocationPin = pin", phone)
        self.assertIn("locationPin: reviewLocationPin", phone)
        self.assertIn("reviewLocationPin = snapshot.locationPin", phone)
        self.assertIn('source: "iPhone"', tracker)

    def test_wear_location_permission_and_durable_handoff(self):
        manifest = read("android/wear/src/main/AndroidManifest.xml")
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        capture = read("android/wear/src/main/java/dev/repera/wear/WearStartLocationCapture.kt")
        repo = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        for permission in ("ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION"):
            self.assertIn(permission, manifest)
        self.assertIn("manager.getCurrentLocation(", capture)
        self.assertIn("5_000L", capture)
        self.assertIn("captureWatchStartLocation(summary.sessionId)", wear)
        self.assertIn('"source", "wearOS"', wear)
        self.assertIn('putString("snapshot", snapshot.toString()).commit()', wear)
        self.assertIn('"/repera/session-start"', wear)
        self.assertIn('finishBody.put("locationPin", pin)', wear)
        self.assertIn('incoming.optString("source") != "wearOS"', repo)
        self.assertIn("applyWearStartPin(active, pin)", repo)
        self.assertIn("session.optJSONArray(\"routePoints\")?.length()", repo)

    def test_android_indoor_comenzar_location_is_persisted(self):
        runtime = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityRuntime.kt")
        repository = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        screen = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        pending = read("android/mobile/src/main/java/dev/repera/mobile/PendingLiveActivitySheet.kt")
        self.assertIn("if (!state.sport.usesGPS) captureIndoorStartLocation(", runtime)
        self.assertIn("WorkoutLocationTracker(app).capturePin()", runtime)
        self.assertIn("startPinFile.writeText(", runtime)
        self.assertIn("locationPin = runtime.startLocationPin", screen)
        self.assertIn("locationPin = runtime.startLocationPin", pending)
        self.assertIn("if (snapshot.points.size < 2 && locationPin != null)", repository)

    def test_old_sessions_and_manual_places_remain_valid(self):
        swift = read("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        android = read("android/domain/src/main/java/dev/repera/domain/WorkoutLocation.kt")
        repository = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        self.assertIn("public var horizontalAccuracyMeters: Double?", swift)
        self.assertIn("public var source: String?", swift)
        self.assertIn("val horizontalAccuracyMeters: Double? = null", android)
        self.assertIn("val source: String? = null", android)
        self.assertIn("El lugar escogido en la plantilla es válido", repository)
        self.assertIn('incoming.optString("mapItemIdentifier").isBlank()', repository)


if __name__ == "__main__":
    unittest.main()
