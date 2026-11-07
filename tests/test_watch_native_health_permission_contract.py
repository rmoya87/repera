"""Source contracts for Watch-owned native UI and HealthKit permissions.

Hardware verification is still required on an iPhone and paired Apple Watch.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class WatchNativeHealthContracts(unittest.TestCase):
    def test_completed_cardio_session_can_be_saved_without_exercise_blocks(self):
        editor = read("Apps/Repera/Sources/PlanView.swift")
        predicate = editor.split("private var canConfirm: Bool", 1)[1].split(
            "private func confirm()", 1
        )[0]
        self.assertIn("if onApplyCompleted != nil", predicate)
        self.assertIn("completedWorkoutDraft != nil", predicate)
        self.assertLess(predicate.index("if onApplyCompleted != nil"),
                        predicate.index("routine.blocks.contains"))

    def test_confirm_button_has_explicit_repera_green_circle(self):
        theme = read("Apps/Repera/Sources/Theme.swift")
        button = theme.split("struct OGDoneCheckButton: View", 1)[1].split(
            "struct BackToolbarButton", 1
        )[0]
        self.assertIn(".background(OG.accent, in: Circle())", button)
        self.assertIn(".accessibilityLabel(accessibilityLabel)", button)
        self.assertIn(".disabled(!enabled)", button)

    def test_watch_widget_opens_native_companion_and_no_watch_only_copy(self):
        widget = read("Apps/ReperaRestWidget/TrainingLiveActivityWidget.swift")
        coord = read("Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift")
        root = read("Apps/Repera/Sources/RootTabView.swift")
        self.assertNotIn('"Control desde Apple Watch"', widget)
        self.assertNotIn('"Registrando en Apple Watch"', coord)
        self.assertIn('"repera://live"', widget)
        self.assertIn('"repera-watch://active"', widget)
        self.assertIn("WatchOwnedLiveMirrorView(", root)
        self.assertIn("sendCommand: store.controlWatchOwnedLive", root)
        self.assertNotIn("HKWorkoutSession(", root)

    def test_live_companion_is_not_another_sensor_writer(self):
        phone = read("Apps/Repera/Sources/PhoneConnectivity.swift")
        watch = read("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("func sendWatchOwnedLiveCommand(", phone)
        self.assertIn('"ownerScope": owner', phone)
        self.assertIn('payload["action"] as? String == "watchOwnedLiveCommand"', watch)
        self.assertIn("watchConnectivityDidReceiveWatchOwnedLiveCommand(", hub)
        self.assertIn("self.watchLiveSessionID == sessionId", hub)
        self.assertIn("self.active?.id == sessionId", hub)
        self.assertIn("WatchOwnedLiveDeliveryPolicy.isNewer(", store)
        self.assertIn("closedWatchOwnedLiveIDs", store)

    def test_watch_sensor_metrics_are_optional_and_backward_compatible(self):
        model = read("Packages/ReperaDomain/Sources/ReperaDomain/WatchLiveActivitySnapshot.swift")
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        root = read("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("heartRateBpm: Int? = nil", model)
        self.assertIn("activeEnergyKcal: Double? = nil", model)
        self.assertIn("decodeIfPresent(Int.self, forKey: .heartRateBpm)", model)
        self.assertIn("decodeIfPresent(Double.self, forKey: .activeEnergyKcal)", model)
        self.assertIn("heartRateBpm: health.pulseCapturedAt.map", hub)
        self.assertIn("activeEnergyKcal: health.kcal", hub)
        self.assertIn("if let bpm = snapshot.heartRateBpm", root)
        self.assertIn("if let kcal = snapshot.activeEnergyKcal", root)

    def test_distance_write_denial_does_not_abort_watch_workout(self):
        watch = read("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        distance = watch.split("private func endBuilder(at date: Date)", 1)[1].split(
            "try await builder.endCollection(at: date)", 1
        )[0]
        self.assertIn("store.authorizationStatus(for: type) == .sharingAuthorized", distance)
        self.assertIn("try await builder.addSamples([sample])", distance)
        self.assertIn("La distancia GPS se conserva en Repera", distance)
        self.assertIn("share.insert(distanceType)", watch)

    def test_iphone_route_permission_refresh_includes_numeric_distance(self):
        store = read("Apps/Repera/Sources/HealthKitStore.swift")
        permission = store.split("func ensureWorkoutRouteAccess()", 1)[1].split(
            "private func fetchRoutePoints(", 1
        )[0]
        for name in (".distanceWalkingRunning", ".distanceCycling",
                     ".distanceSwimming", ".distanceDownhillSnowSports"):
            self.assertGreaterEqual(permission.count(name), 2)


if __name__ == "__main__":
    unittest.main()
