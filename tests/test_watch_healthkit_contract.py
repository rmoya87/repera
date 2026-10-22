"""Source-contract safety checks for offline watchOS HealthKit integration.

These checks do not substitute compiling/running with the watchOS SDK.
"""
from pathlib import Path
import re
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

    def test_watch_app_has_an_explicit_runnable_xcode_scheme(self):
        """Watch widget scheme cannot launch the actual workout application."""
        spec = source("project.yml")
        schemes = spec.partition("\nschemes:\n")[2]
        self.assertTrue(schemes, "project.yml must declare shared schemes")
        watch_scheme = schemes.partition("\n  ReperaWatch:\n")[2].partition("\n  Repera:\n")[0]
        self.assertTrue(watch_scheme, "Missing the runnable ReperaWatch scheme")
        self.assertIn("ReperaWatch: all", watch_scheme)
        self.assertIn("executable: ReperaWatch", watch_scheme)
        self.assertIn("config: Debug", watch_scheme)
        self.assertNotIn("executable: ReperaWatchWidget", watch_scheme)

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

    def test_watch_app_and_complication_icons_match_ios(self):
        """Reuse iOS AppIcon bytes so all three icons stay visually identical."""
        ios = ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        watch = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        complication = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets/ReperaIcon.imageset/repera.png"
        self.assertEqual(watch.read_bytes(), ios.read_bytes())
        self.assertEqual(complication.read_bytes(), ios.read_bytes())

    def test_watch_today_refresh_after_late_scheduling(self):
        phone = source("Apps/Repera/Sources/PhoneConnectivity.swift")
        client = source("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        app = source("Apps/ReperaWatch/Sources/ReperaWatchApp.swift")
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")

        # Changes before WCSession activates must be retained, not dropped.
        self.assertIn("private var latestPayload: [String: Any]?", phone)
        self.assertIn("latestPayloadLock.withLock { latestPayload = payload }", phone)
        self.assertIn("publishLatestContext()", phone)
        self.assertIn("try wc.updateApplicationContext(payload)", phone)
        self.assertIn("wc.sendMessage(payload, replyHandler: nil)", phone)
        self.assertNotIn('wc.sendMessage(["ping": true]', phone)
        self.assertIn('case "requestToday":', phone)
        self.assertIn('return latestPayloadLock.withLock { latestPayload } ?? ["ok": true]', phone)

        # A reachable Watch gets a direct reply; unavailable devices keep context.
        self.assertIn("replyHandler: { [weak self] payload in", client)
        self.assertIn("self?.applyContext(payload)", client)
        self.assertIn("func refreshToday()", client)
        self.assertIn("lastInboundTodayDay", client)
        self.assertIn("func refreshToday()", hub)
        self.assertIn("hub.refreshToday()", app)
        self.assertIn("hub.refreshToday()", view)

    def test_watch_music_icon_contrasts_with_accent_button(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn('Image(systemName: "playpause.fill")', view)
        self.assertIn(".foregroundStyle(.black)", view)
        self.assertIn(".symbolRenderingMode(.monochrome)", view)
        self.assertIn("Sincronizar con iPhone", view)

    def test_watch_workout_native_play_and_one_tap_save(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/SessionController.swift")

        self.assertIn("WatchExerciseThumb(exercise: exercise.exercise", view)
        self.assertIn("WatchExerciseThumb(exercise: exercise, size: 53)", view)
        self.assertIn('Text("Plan completo")', view)
        self.assertIn("hub.selectBlock(startingAt: index)", view)
        self.assertIn("hub.swipeSet(horizontal < 0 ? 1 : -1)", view)
        self.assertIn("hub.confirmAndAdvance()", view)
        self.assertIn('Label(hub.isFinalSet ? "Terminar" : "Siguiente"', view)
        self.assertIn("if !hub.isFinalSet", view)
        self.assertNotIn("Confirmar serie", view)
        self.assertNotIn("Saltar al siguiente", view)
        self.assertNotIn("Volver al entrenamiento", view)
        self.assertNotIn("Registrado en Apple Salud", view)
        self.assertNotIn("Guardado en Watch · pendiente de sincronizar", view)
        self.assertEqual(view.count('.confirmationDialog("¿Finalizar el entrenamiento?"'), 1)

        self.assertIn("func confirmAndAdvance()", hub)
        self.assertIn("func selectBlock(startingAt index: Int)", hub)
        self.assertIn("func swipeSet(_ direction: Int)", hub)
        self.assertIn("reviseLoggedSet(at:", hub)
        self.assertIn("public mutating func reviseLoggedSet(", domain)

    def test_watch_thumbnail_view_is_in_an_existing_compiled_source(self):
        """A stale Xcode project still compiles the miniature component."""
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("struct WatchSessionView: View {", view)
        self.assertIn("struct WatchExerciseThumb: View {", view)
        self.assertIn("enum WatchExerciseArtwork {", view)
        self.assertFalse((ROOT / "Apps/ReperaWatch/Sources/WatchExerciseThumb.swift").exists())
        checker = source("scripts/check_xcode_sources.py")
        self.assertIn('watch.glob("*.swift")', checker)

    def test_watch_exercise_thumbnail_assets_are_ios_originals(self):
        artwork = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        names = set(re.findall(r'"(art_[^"]+)"', artwork))
        self.assertGreaterEqual(len(names), 180)
        for name in names:
            ios = ROOT / "Apps/Repera/Resources/ExerciseArt/thumbs" / f"{name}.jpg"
            watch = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets" / f"{name}.imageset" / f"{name}.jpg"
            self.assertTrue(ios.is_file(), f"Missing iOS thumbnail: {name}")
            self.assertTrue(watch.is_file(), f"Missing Watch thumbnail: {name}")
            self.assertEqual(ios.read_bytes(), watch.read_bytes(), name)

    def test_watch_recording_field_parity_and_summary_navigation(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/SessionController.swift")

        # The finished view hides immediately while HealthKit persists/acknowledges.
        self.assertIn("hub.presentedSummary", view)
        self.assertIn("summaryDismissed = true", hub)
        self.assertIn("var presentedSummary: WorkoutSession?", hub)
        self.assertIn("lastFinished: WorkoutSession?", hub)
        self.assertIn("summaryDismissed: Bool?", hub)
        self.assertIn("summaryDismissed = snapshot.summaryDismissed ?? false", hub)
        self.assertNotIn("guard !hasWorkoutInProgress, !awaitingHealthSave else { return }", hub)

        # One editor covers the same structured fields as iPhone LoggedSet.
        for needle in (
            "private var exerciseFields", "private var setDetailsView",
            "hub.setRIR(", "hub.adjustDuration(", "hub.adjustDeficit(",
            "hub.selectUnit(.calories)", "hub.selectUnit(.meters)",
            "hub.setPhase(", "hub.setKind(", "hub.setToFailure(",
            "hub.addDrop()", "hub.addCluster()",
        ):
            self.assertIn(needle, view)
        for needle in (
            "func preparedSet", "func resetSetDraft()", "func restoreSetDraft",
            "durationSeconds: set.durationSeconds", "deficitCm: set.deficitCm",
            "quantityUnit: set.quantityUnit", "phase: set.phase",
            "kind: set.kind", "rir: set.rir", "drops: set.drops",
            "clusters: set.clusters", "setDraft: setDraft",
            "setDraft = snapshot.setDraft ?? WatchSetDraft()",
            "ctrl.replaceLoggedSet(at:",
        ):
            self.assertIn(needle, hub)
        self.assertIn("func replaceLoggedSet(at index: Int, with set: LoggedSet)", domain)
        self.assertIn("session.exercises[session.currentIndex].loggedSets[index].id == set.id", domain)

        # Intervals require explicit end; no auto-finalize of Tabata/EMOM after a set.
        self.assertIn('Button("Terminar bloque") { hub.reviewBlock() }', view)
        self.assertIn("loggingStyle != .machineWork", hub)
        self.assertIn("loggingStyle != .repsAndTime", hub)
        self.assertNotIn("if isLastWorkoutExercise { reviewBlock() }", hub)
        self.assertIn("completedWorkingSets", hub)
        self.assertIn("let wasWorkingSet = setDraft.phase == .work", hub)
        self.assertIn("func adjustScoreSeconds(_ delta: Int)", hub)
        self.assertIn("reviewElapsedSeconds: reviewElapsedSeconds", hub)
        self.assertIn("wodTemplateId: templateID", hub)
        self.assertIn("var effectiveReps: Int", hub)
        self.assertIn("setDraft.clusters.reduce(0) { $0 + $1.reps }", hub)
        self.assertIn("hub.effectiveReps", view)
        self.assertIn("hub.adjustScoreSeconds(-1)", view)
        self.assertIn("hub.adjustScoreSeconds(1)", view)

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
