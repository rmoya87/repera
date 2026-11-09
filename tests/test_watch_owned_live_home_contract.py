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
    def test_watch_delivery_order_survives_phone_process_restart(self):
        coordinator = source(COORDINATOR)
        store = source(PHONE_STORE)
        self.assertIn("private struct WatchDeliveryMark: Codable", coordinator)
        # `Self.watchMarksKey` in a stored-property init fails to compile
        # («Covariant 'Self' type cannot be referenced…»). Use the type name.
        init_block = coordinator.split(
            "private var watchMarks: [String: WatchDeliveryMark] = {", 1
        )[1].split("}()", 1)[0]
        self.assertIn(
            "WorkoutLiveActivityCoordinator.watchMarksKey", init_block)
        self.assertNotIn("Self.watchMarksKey", init_block)
        self.assertIn("func mayAcceptWatchOwned(", coordinator)
        self.assertIn("snapshot.capturedAt > mark.capture", coordinator)
        self.assertIn("!mark.closed", coordinator)
        self.assertIn("persistWatchMarks()", coordinator)
        self.assertIn("closed: true, observed: Date()", coordinator)
        receive = store.split(
            "func phoneConnectivityDidReceiveWatchOwnedLive(", 1
        )[1].split("func phoneConnectivityDidReceive(session:", 1)[0]
        self.assertLess(
            receive.index("mayAcceptWatchOwned(snapshot)"),
            receive.index("if snapshot.phase == .review"),
        )
        self.assertLess(
            receive.index("mayAcceptWatchOwned(snapshot)"),
            receive.index("self.watchOwnedLive = snapshot"),
        )

    def test_watch_live_activity_reuses_system_activity_and_watch_origin(self):
        coordinator = source(COORDINATOR)
        watch = coordinator.split("func updateWatchOwned(", 1)[1].split(
            "func finishWatchOwned(", 1
        )[0]
        self.assertIn('let id = "watch:" + snapshot.id.uuidString', watch)
        self.assertIn("await upsert(id: id, isPlanned: false, state: state)", watch)
        self.assertIn("Activity<TrainingActivityAttributes>.activities.first(where:", coordinator)
        self.assertIn("await activity.update(ActivityContent(state: state, staleDate: nil))", coordinator)
        self.assertIn("guard !LiveActivityRecorder.shared.isWatchOwnedMirror else { return }", coordinator)
        watchHub = source(WATCH_HUB)
        self.assertIn("publishWatchOwnedLiveToPhone(force: true)", watchHub)
        self.assertIn("func watchConnectivityDidBecomeReachable()", watchHub)

    def test_relaunch_requests_fresh_watch_snapshot_without_healthkit_control(self):
        phone = source(PHONE_TRANSPORT)
        store = source(PHONE_STORE)
        watch_transport = source(WATCH_TRANSPORT)
        hub = source(WATCH_HUB)
        self.assertIn("func requestWatchOwnedLiveSnapshot()", phone)
        self.assertIn('"action": "requestWatchOwnedLiveSnapshot"', phone)
        self.assertIn("connectivity.requestWatchOwnedLiveSnapshot()", store)
        # `@discardableResult` belongs on sendWatchOwnedLiveCommand (Bool), not
        # on the Void recovery request (inserted wrongly in fdb4f0641).
        request_idx = phone.index("func requestWatchOwnedLiveSnapshot()")
        command_idx = phone.index(
            "func sendWatchOwnedLiveCommand(sessionId: UUID, command: String) -> Bool")
        discard_idx = phone.rfind("@discardableResult", 0, command_idx + 1)
        self.assertGreater(discard_idx, request_idx)
        self.assertLess(discard_idx, command_idx)
        self.assertIn('payload["action"] as? String == "requestWatchOwnedLiveSnapshot"',
                      watch_transport)
        self.assertIn(
            "func watchConnectivityDidRequestWatchOwnedLiveSnapshot() {}",
            watch_transport)
        callback = hub.split(
            "nonisolated func watchConnectivityDidRequestWatchOwnedLiveSnapshot()", 1
        )[1].split("nonisolated func watchConnectivityDidBecomeReachable()", 1)[0]
        self.assertIn("publishWatchOwnedLiveToPhone(force: true)", callback)
        self.assertNotIn("health.begin", callback)
        self.assertNotIn("health.finish", callback)

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
        # Ordering is ledger-based (capture/closed), not a separate isNewer helper.
        self.assertIn("func mayAcceptWatchOwned(", coordinator)
        self.assertIn("snapshot.capturedAt > mark.capture", coordinator)
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
        self.assertIn("active.id != snapshot.id", store)
        self.assertIn("updateWatchOwned(snapshot)", store)
        self.assertIn("case .planned:", coordinator)
        self.assertIn('sessionID.hasPrefix("watch:")', widget)
        self.assertNotIn('"Control desde Apple Watch"', widget)
        self.assertNotIn('"Registrando en Apple Watch"', coordinator)
        self.assertIn('"repera://live"', widget)
        self.assertIn("liveActivityControls(", widget)
        self.assertIn("pushType: nil", coordinator)

    def test_watch_owned_planned_live_and_phone_handoff(self):
        hub = source(WATCH_HUB)
        phone = source(PHONE_TRANSPORT)
        store = source(PHONE_STORE)
        watch_app = source("Apps/ReperaWatch/Sources/ReperaWatchApp.swift")
        push = source("Apps/Repera/Sources/LiveActivityPushTokenStore.swift")
        self.assertIn("kind: .planned", hub)
        self.assertIn("func adoptPhoneHandoff(", hub)
        self.assertIn("func handleWorkoutConfiguration(", hub)
        # WKApplicationDelegate: SDK renombró handleWorkoutConfiguration → handle(_:)
        self.assertIn(
            "func handle(_ workoutConfiguration: HKWorkoutConfiguration)",
            watch_app,
        )
        self.assertNotIn("func handleWorkoutConfiguration(", watch_app)
        self.assertIn('payload["action"] as? String == "handoffStart"',
                      source(WATCH_TRANSPORT))
        self.assertIn("func sendWatchHandoffStart(", phone)
        self.assertIn("var canHandoffToWatch: Bool", phone)
        self.assertIn("func requestWatchHealthOwnership(", store)
        self.assertIn("startWatchAppIfPossible(", store)
        self.assertIn("pushToStartTokenKey", push)
        self.assertIn("pushToStartTokenUpdates", push)
        self.assertIn("RestActivityAttributes", push)

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

    def test_watch_health_enrichment_is_durable_before_ack(self):
        store = source(PHONE_STORE)
        # An in-flight HealthKit revision must never leave a successful Watch
        # transfer unacknowledged only because the archived workout changed.
        self.assertIn("if latest != snapshot.workouts.first(where:", store)
        self.assertIn("await LocalStore.shared.persistAndFlush(self.state)", store)
        self.assertIn("self.lastWatchAcknowledgedSession = session.id", store)

    def test_phone_does_not_discard_gps_before_durable_save(self):
        free = source(FREE)
        save = free.split("private func saveRecordedActivity()", 1)[1].split(
            "private var routeSheet", 1
        )[0]
        self.assertLess(
            save.index("store.saveWorkout(session)"),
            save.index("await LocalStore.shared.persistAndFlush(store.state)")
        )
        self.assertLess(
            save.index("guard LocalStore.shared.lastPersistenceError == nil"),
            save.index("recorder.discard(saved: true)")
        )
        self.assertIn("isSavingRecordedActivity = false", save)
        self.assertIn("saveError =", save)

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
