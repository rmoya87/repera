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
        self.assertIn("guard let session else { return }", hub)
        self.assertIn("localSetIDs.isSubset(of: receivedSetIDs)", hub)
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

    def test_cancelar_x_modal_opaco_confirmar_primero_descartar_despues(self):
        native = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        root = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn('Image(systemName: "xmark")', native)
        self.assertIn('Image(systemName: "xmark")', root)
        self.assertIn('onCancelRequest()', native)
        self.assertIn('WatchLiveSessionView(sport: sport) {', root)
        self.assertIn('WatchActivityCancelOverlay(', root)
        self.assertIn('Color.black', root)
        self.assertIn('.ignoresSafeArea(.container, edges: .all)', root)
        self.assertNotIn('.confirmationDialog(', root)
        self.assertNotIn('.confirmationDialog(', native)
        confirm = root.index('Text("Confirmar")')
        discard = root.index('Text("Descartar")')
        self.assertLess(confirm, discard, "Confirmar debe ir encima de Descartar")
        self.assertIn("onConfirm: confirmActivityCancellation", root)
        modal = root.split("private struct WatchActivityCancelOverlay: View", 1)[1]
        self.assertIn('.background(accent, in: Capsule())', modal)
        self.assertIn('.background(Color.white.opacity(0.18), in: Capsule())', modal)
        self.assertEqual(modal.count('.contentShape(Capsule())'), 2)
        self.assertIn("onDiscard:", root)
        self.assertIn('hub.cancelWatchLive()', root)
        self.assertIn('hub.cancelCompanionLive()', root)
        self.assertIn('Image(systemName: "flag.checkered")', root)
        self.assertIn('Image(systemName: "flag.checkered")', native)

    def test_cancelacion_local_y_del_iphone_efectiva_sin_guardar(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        watch_link = read("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        phone_link = read("Apps/Repera/Sources/PhoneConnectivity.swift")
        phone = read("Apps/Repera/Sources/ReperaStore.swift")
        cancel_start = hub.index("func cancelWatchLive()")
        cancel_end = hub.index("func finishWatchLive()", cancel_start)
        native_cancel = hub[cancel_start:cancel_end]
        self.assertIn("health.discard()", native_cancel)
        self.assertIn("clearWatchLive()", native_cancel)
        self.assertIn("returnToHome()", native_cancel)
        self.assertNotIn("sendFinished(", native_cancel)
        self.assertNotIn("health.finish(", native_cancel)
        companion_cancel = hub.split("func cancelCompanionLive()", 1)[1].split(
            "func controlLiveActivity", 1
        )[0]
        self.assertIn("connectivity.enqueueLiveCancellation(sessionId: live.id)", companion_cancel)
        self.assertIn("cancelledCompanionSessionID = live.id", companion_cancel)
        self.assertIn("returnToHome()", companion_cancel)
        self.assertIn("if snapshot?.id == self.cancelledCompanionSessionID { return }", hub)
        self.assertIn("func enqueueLiveCancellation(sessionId: UUID)", watch_link)
        self.assertIn("wc.transferUserInfo(message)", watch_link)
        self.assertIn("flushPendingLiveCancellations()", watch_link)
        self.assertIn('["pause", "resume", "finish", "cancel"]', phone_link)
        cancel = phone.split('case "cancel":', 1)[1].split('case "finish":', 1)[0]
        self.assertIn("recorder.discard()", cancel)
        self.assertIn("sendWatchContextNow()", cancel)
        self.assertNotIn("saveWorkout(", cancel)

    def test_wear_does_not_discard_watch_owned_work_on_empty_phone_context(self):
        reconciliation = read("android/domain/src/main/java/dev/repera/domain/WatchSessionReconciliation.kt")
        self.assertIn("if (incomingId.isNullOrBlank()) return true", reconciliation)
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        self.assertIn("receivePhoneTerminal", wear)
        self.assertIn("persistElapsedClock()", wear)

    def test_wear_play_sport_falls_back_to_watch_owned_live(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        listener = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        repo = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        self.assertIn("private fun startWatchOwnedLive(sportId: String)", wear)
        self.assertIn("startWatchOwnedLive(sport)", wear)
        self.assertIn('"/repera/live-save"', wear)
        self.assertIn("fun saveWearOwnedLiveActivity(", repo)
        self.assertIn('"/repera/live-save"', listener)
        self.assertIn("handleLiveSave(event)", listener)
        # No bloquear el hub con «móvil desconectado» al iniciar deporte.
        start = wear.split("private fun requestLiveStart(sportId: String)", 1)[1].split(
            "private fun receiveLiveStartAck", 1
        )[0]
        self.assertNotIn("wear_live_start_disconnected", start)
        self.assertIn("startWatchOwnedLive(sport)", start)

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
