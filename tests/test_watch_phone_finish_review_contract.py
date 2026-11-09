"""Regression wiring for Watch-owned sessions finished from the iPhone.

Source contracts complement (not replace) paired-device HealthKit/WCSession tests.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def src(path):
    return (ROOT / path).read_text(encoding="utf-8")


class WatchPhoneFinishReviewContractTests(unittest.TestCase):
    def test_finish_command_is_durable_and_scoped_to_same_uuid(self):
        phone = src("Apps/Repera/Sources/PhoneConnectivity.swift")
        store = src("Apps/Repera/Sources/ReperaStore.swift")
        block = store.split("func controlWatchOwnedLive(_ command: String) -> Bool", 1)[1].split(
            "private(set) var watchTimerMirror", 1
        )[0]
        self.assertIn("sessionId: live.id, command: command", block)
        self.assertIn('if queued, command == "finish"', block)
        self.assertIn("UserDefaults.standard.set(live.id.uuidString, forKey: key)", block)
        self.assertIn("scope == watchOwnedLiveOwnerScope", block)
        self.assertIn("closedWatchOwnedLiveIDs.contains(live.id)", block)
        self.assertIn("WCSession.default.transferUserInfo(payload)", phone)

    def test_only_confirmed_disk_save_opens_home(self):
        store = src("Apps/Repera/Sources/ReperaStore.swift")
        root = src("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn('AccountScopedDefaults.key("repera.watch.phoneRequestedFinish.v1")', store)
        self.assertIn("revealPhoneRequestedWatchFinishIfPersisted(session.id)", store)
        self.assertIn("guard LocalStore.shared.lastPersistenceError == nil else { return }", store)
        self.assertLess(
            store.index("await LocalStore.shared.persistAndFlush(snapshot)"),
            store.index("self.revealPhoneRequestedWatchFinishIfPersisted(session.id)"),
        )
        helper = store.split("private func revealPhoneRequestedWatchFinishIfPersisted(", 1)[1].split(
            "func restorePhoneRequestedWatchFinishIfSaved()", 1
        )[0]
        self.assertIn("isPhoneRequestedWatchFinish(id)", helper)
        self.assertIn("$0.phase == .finished && $0.finishedAt != nil", helper)
        self.assertIn('name: Notification.Name("repera.phoneRequestedWatchFinishSaved")', helper)
        self.assertIn("UserDefaults.standard.removeObject(forKey: key)", helper)
        self.assertIn('for: Notification.Name("repera.phoneRequestedWatchFinishSaved")', root)
        self.assertIn("homeFocusDay = day", root)
        self.assertIn("tab = .home", root)
        self.assertIn("store.restorePhoneRequestedWatchFinishIfSaved()", root)

    def test_watch_only_completion_keeps_existing_review_actions(self):
        watch = src("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        home = src("Apps/Repera/Sources/HomeView.swift")
        store = src("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("pending.awaitingResultEntry = true", watch)
        self.assertIn("connectivity.sendFinished(pending)", watch)
        self.assertIn("connectivity.sendFinished(result)", watch)
        self.assertIn("return session.awaitingResultEntry", home)
        self.assertIn('Text("Descartar")', home)
        self.assertIn('Text("Revisar")', home)
        self.assertIn("if session.phase == .finished,", store)
        self.assertIn("isPhoneRequestedWatchFinish(session.id)", store)
        self.assertIn("session.awaitingResultEntry = true", store)

    def test_watch_remains_health_writer_and_late_packets_do_not_duplicate(self):
        phone = src("Apps/Repera/Sources/LiveActivityView.swift")
        store = src("Apps/Repera/Sources/ReperaStore.swift")
        transport = src("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        self.assertIn("if isWatchOwnedMirror {", phone)
        self.assertIn('Self.watchOwnedCommandHandler?("finish")', phone)
        self.assertIn("healthOwnedByWatch = true", phone)
        self.assertIn("queued.removeAll {", transport)
        self.assertIn("owners[session.id.uuidString] == currentOwnerScope", transport)
        self.assertIn("var saved = state.workouts[index]", store)
        self.assertIn("if changed { upsertWorkout(saved) }", store)
        self.assertIn("closedWatchOwnedLiveIDs.insert(session.id)", store)


if __name__ == "__main__":
    unittest.main()
