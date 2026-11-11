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
        # X / flag viven en WatchSessionControlsGrid (SessionView); live solo la monta.
        self.assertIn('WatchSessionControlsGrid(', native)
        self.assertIn('onCancel: onCancelRequest', native)
        self.assertIn('systemName: "xmark"', root)
        self.assertIn('systemName: "flag.checkered"', root)
        self.assertIn('WatchLiveSessionView(sport: sport) {', root)
        self.assertIn('WatchActivityCancelOverlay(', root)
        self.assertIn('Color.black', root)
        self.assertIn('.ignoresSafeArea(.container, edges: .all)', root)
        # Cancel live usa overlay propio; el confirmationDialog del archivo es solo plan/finish.
        self.assertNotIn('.confirmationDialog("¿Cancelar actividad?"', root)
        self.assertNotIn('.confirmationDialog(', native)
        self.assertIn("onConfirm: confirmActivityCancellation", root)
        modal = root.split("private struct WatchActivityCancelOverlay: View", 1)[1]
        confirm = modal.index('Text("Confirmar")')
        discard = modal.index('Text("Descartar")')
        self.assertLess(confirm, discard, "Confirmar debe ir encima de Descartar")
        self.assertIn('.background(accent, in: Capsule())', modal)
        self.assertIn('.background(Color.white.opacity(0.18), in: Capsule())', modal)
        self.assertEqual(modal.count('.contentShape(Capsule())'), 2)
        self.assertNotIn("Se perderán los datos", modal)
        self.assertGreaterEqual(modal.count("Spacer(minLength: 0)"), 2)
        self.assertIn("onDiscard:", root)
        self.assertIn('hub.cancelWatchLive()', root)
        self.assertIn('hub.cancelCompanionLive()', root)

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

    def test_wear_play_sport_is_always_watch_owned(self):
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
        self.assertIn("startWatchOwnedLive(sportId)", start)
        self.assertNotIn('"/repera/live-start"', start)

    def test_wear_controls_are_received_without_main_activity(self):
        manifest = read("android/mobile/src/main/AndroidManifest.xml")
        listener = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        self.assertIn('android:name=".WearLiveCommandListener"', manifest)
        self.assertIn('"/repera/live-command"', listener)
        self.assertIn('"/repera/log-set"', listener)
        self.assertIn('"/repera/session-finish"', listener)
        self.assertIn("repo.logWearSet(", listener)
        self.assertIn("WearUiPresence.active", listener)

    def test_companion_review_finishes_healthkit_not_discard(self):
        """Revisión del iPhone debe cerrar el HKWorkout del Watch, no descartarlo."""
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        receive = hub.split(
            "nonisolated func watchConnectivityDidReceiveLive(_ snapshot: WatchLiveActivitySnapshot?)",
            1,
        )[1].split(
            "nonisolated func watchConnectivityDidReceiveHandoffStart(",
            1,
        )[0]
        # La fase .review de la misma sesión companion debe finalizar Salud.
        self.assertIn("finishCompanionHealthIfNeeded", receive)
        self.assertIn("snapshot.phase == .review", receive)
        self.assertIn("finishCompanionHealthIfNeeded", hub)
        finish = hub.split("func finishCompanionHealthIfNeeded", 1)[1].split(
            "func controlLiveActivity", 1
        )[0]
        self.assertIn("health.finish", finish)
        self.assertNotIn("health.discard()", finish)

    def test_phone_live_handoff_keeps_pending_for_startWatchApp(self):
        """Comenzar desde iPhone no puede perder el UUID ante startWatchApp."""
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        handoff = hub.split(
            "nonisolated func watchConnectivityDidReceiveHandoffStart(",
            1,
        )[1].split("nonisolated func watchConnectivityDidReceive(session:", 1)[0]
        self.assertIn("self.pendingPhoneHandoff = (session, sessionID, sportID)", handoff)
        self.assertIn("adoptPhoneLiveHealthOwnership", handoff)
        config = hub.split("func handleWorkoutConfiguration(", 1)[1].split(
            "private func publishWatchOwnedLiveToPhone", 1
        )[0]
        # Al despertar, consumir pending live con ownership companion (mismo UUID).
        self.assertIn("adoptPhoneLiveHealthOwnership", config)
        self.assertIn("pendingPhoneHandoff", config)

    def test_companion_sensor_mirrors_and_respects_outdoor(self):
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        receive = hub.split(
            "nonisolated func watchConnectivityDidReceiveLive(_ snapshot: WatchLiveActivitySnapshot?)",
            1,
        )[1].split(
            "nonisolated func watchConnectivityDidReceiveHandoffStart(",
            1,
        )[0]
        self.assertIn("mirrorsToPhone: true", receive)
        self.assertIn("outdoor: sport?.usesGPS", receive)
        self.assertNotIn("outdoor: false, mirrorsToPhone: false", receive)

    def test_live_commands_are_durable_without_momentary_reachability(self):
        """Pausa/finalizar/cancelar deben encolar aunque sendMessage no esté reachable."""
        watch = read("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        send = watch.split("func sendLiveCommand(", 1)[1].split(
            "func sendLiveHeartRate(", 1
        )[0]
        self.assertIn("transferUserInfo", send)
        # No exigir isReachable como único camino (el espejo sí llega por context).
        self.assertNotIn(
            "WCSession.default.isReachable,\n              let owner = currentOwnerScope else { return false }",
            send,
        )

    def test_phone_plan_handoff_keeps_pending_when_watch_woken(self):
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        ownership = store.split(
            "private func requestWatchHealthOwnership(for session: WorkoutSession)",
            1,
        )[1].split("private func currentWatchOwnerScope", 1)[0]
        # Tras despertar Watch no borrar provenance ni abrir builder iPhone.
        self.assertIn("if woke { return }", ownership)
        self.assertIn("beginHealthTracking(for: active)", ownership)


if __name__ == "__main__":
    unittest.main()
