"""Source contracts for phone-owned Comenzar and explicit session terminal events.

These guard against regressions but do not replace watchOS / Wear hardware tests.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WatchLiveSyncContractTests(unittest.TestCase):
    def test_watch_owned_workout_survives_empty_phone_snapshot(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("self.startedOnThisWatch &&", hub)
        self.assertIn("self.lastFinished != nil", hub)
        self.assertIn("watchConnectivityDidReceiveTerminal", hub)
        self.assertIn("self.completeSession()", hub)
        phone = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("sendTerminalEvent(sessionID: session.id, saved: save)", phone)

    def test_live_sport_watch_never_recomputes_gps_or_starts_healthkit(self):
        model = read("Packages/ReperaDomain/Sources/ReperaDomain/WatchLiveActivitySnapshot.swift")
        self.assertIn("distanceMeters", model)
        self.assertIn("displayElapsed(at date: Date)", model)
        self.assertNotIn("routePoints", model)
        watch = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("liveActivityView", watch)
        self.assertIn('controlLiveActivity("finish")', watch)

    def test_wear_does_not_discard_watch_owned_work_on_empty_phone_context(self):
        reconciliation = read("android/domain/src/main/java/dev/repera/domain/WatchSessionReconciliation.kt")
        self.assertIn("if (incomingId.isNullOrBlank()) return true", reconciliation)
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        self.assertIn("receivePhoneTerminal", wear)
        self.assertIn("persistElapsedClock()", wear)

    def test_wear_controls_are_received_without_main_activity(self):
        manifest = read("android/mobile/src/main/AndroidManifest.xml")
        listener = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        self.assertIn('android:name=".WearLiveCommandListener"', manifest)
        self.assertIn('"/repera/live-command"', listener)
        self.assertIn('"/repera/log-set"', listener)
        self.assertIn('"/repera/session-finish"', listener)
        self.assertIn("repo.logWearSet(", listener)
        self.assertIn("WearUiPresence.active", listener)


if __name__ == "__main__":
    unittest.main()
