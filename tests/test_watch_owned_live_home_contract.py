"""Regression contracts for Watch-owned live activity and Home persistence.

These tests validate the end-to-end wiring in source. Device-level ActivityKit
and HealthKit behaviour also requires paired iPhone + Apple Watch testing.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


WATCH_HUB = "Apps/ReperaWatch/Sources/WatchSessionHub.swift"
WATCH_TRANSPORT = "Apps/ReperaWatch/Sources/WatchConnectivityClient.swift"
PHONE_TRANSPORT = "Apps/Repera/Sources/PhoneConnectivity.swift"
PHONE_STORE = "Apps/Repera/Sources/ReperaStore.swift"
COORDINATOR = "Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift"
HOME = "Apps/Repera/Sources/HomeView.swift"
FREE = "Apps/Repera/Sources/LiveActivityView.swift"
WIDGET = "Apps/ReperaRestWidget/TrainingLiveActivityWidget.swift"


class WatchOwnedActivityHomeRegressionTests(unittest.TestCase):
    def test_watch_live_start_and_phase_are_transported(self):
        hub = source(WATCH_HUB)
        transport = source(WATCH_TRANSPORT)
        self.assertIn("func sendWatchOwnedLive(", transport)
        self.assertIn('"ownerScope": owner', transport)
        self.assertIn('"watchOwnedLiveActivity": data', transport)
        self.assertIn("wc.transferUserInfo(payload)", transport)
        self.assertIn("wc.sendMessage(payload", transport)
        self.assertIn("publishWatchOwnedLiveToPhone(force: true)", hub)
        self.assertIn("publishWatchOwnedLiveToPhone(phase: .review, force: true)", hub)
        self.assertIn("publishWatchOwnedLiveToPhone()", hub)
        self.assertIn("watchConnectivityDidChangeOwnerScope(hasOwner: Bool)", hub)

    def test_phone_rejects_unscoped_or_stale_watch_events(self):
        phone = source(PHONE_TRANSPORT)
        coordinator = source(COORDINATOR)
        policy = source(
            "Packages/ReperaDomain/Sources/ReperaDomain/WatchOwnedLiveDeliveryPolicy.swift"
        )
        self.assertIn('|| payload["watchOwnedLiveActivity"] != nil', phone)
        self.assertIn('payload["ownerScope"] as? String == expected', phone)
        self.assertIn("WatchOwnedLiveDeliveryPolicy.accepts(snapshot)", phone)
        self.assertIn("WatchOwnedLiveDeliveryPolicy.isNewer(", coordinator)
        self.assertIn('let id = "watch:" + snapshot.id.uuidString', coordinator)
        self.assertIn("closedSessionIDs.insert(id)", coordinator)
        self.assertIn("return age <= 90", policy)
        self.assertIn("return age <= 3600", policy)

    def test_no_second_phone_healthkit_session_or_incorrect_widget_controls(self):
        coordinator = source(COORDINATOR)
        store = source(PHONE_STORE)
        widget = source(WIDGET)
        self.assertIn("func updateWatchOwned(", coordinator)
        self.assertIn("func finishWatchOwned(sessionID: UUID, saved: Bool)", coordinator)
        self.assertIn("phoneConnectivityDidReceiveWatchOwnedLive(", store)
        self.assertIn("state.activeSession == nil", store)
        self.assertIn("updateWatchOwned(snapshot)", store)
        self.assertIn('sessionID.hasPrefix("watch:")', widget)
        self.assertIn('"Control desde Apple Watch"', widget)
        self.assertIn('"repera://today"', widget)
        self.assertIn("pushType: nil", coordinator)

    def test_watch_finish_is_sent_before_healthkit_async_result(self):
        hub = source(WATCH_HUB)
        end = hub.split("func finishWatchLive()", 1)[1].split(
            "func publishTimerMirror(", 1
        )[0]
        self.assertIn("connectivity.sendFinished(pending)", end)
        self.assertLess(
            end.index("connectivity.sendFinished(pending)"),
            end.index("health.finish {")
        )
        self.assertIn('pending.appleHealthProvenance = "watchHealthKitPending"', end)
        self.assertIn("self.connectivity.sendFinished(session)", end)
        self.assertNotIn("if !health.isRecording {", end)

    def test_phone_archives_watch_owned_sport_not_planned_session(self):
        store = source(PHONE_STORE)
        self.assertIn("private func completeImportedWatchActivity(", store)
        self.assertIn("if session.liveSportID != nil", store)
        self.assertIn("finishWatchOwned(", store)
        self.assertIn("applyWatchSession(_ session: WorkoutSession)", store)
        self.assertIn("persistWorkouts()", store)
        self.assertIn("announceFreshWatchWorkout(", store)

    def test_home_immediately_rebuilds_and_selects_saved_day(self):
        home = source(HOME)
        free = source(FREE)
        self.assertIn(".onChange(of: store.workoutsEpoch, initial: true)", home)
        self.assertIn("rebuildDayBuckets()", home)
        self.assertIn('Notification.Name("repera.watchWorkoutSaved")', home)
        self.assertIn("selectedDay = calendar.startOfDay(for: date)", home)
        self.assertIn("store.saveWorkout(session)", free)
        self.assertIn("onSaved(day)", free)
        self.assertIn("session.phase = .finished", free)
        self.assertNotIn("session.phase = .ready\n                session.awaitingResultEntry", free)


if __name__ == "__main__":
    unittest.main()
