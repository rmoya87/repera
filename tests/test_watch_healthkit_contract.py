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
        self.assertIn("await delegate.phoneConnectivityLatestWorkoutForToday()", phone)
        self.assertIn('if let action = userInfo["action"] as? String', phone)
        self.assertIn('"todayWorkout": data', phone)
        self.assertIn('"todayDayStart": Calendar.current.startOfDay(for: Date()).timeIntervalSince1970', phone)
        self.assertNotIn('return latestPayloadLock.withLock { latestPayload } ?? ["ok": true]', phone)

        # A reachable Watch gets a direct reply; unavailable devices keep context.
        self.assertIn("replyHandler: { [weak self] payload in", client)
        self.assertIn("self?.applyContext(payload)", client)
        self.assertIn("func refreshToday()", client)
        self.assertIn("lastInboundTodayDay", client)
        self.assertIn("func refreshToday()", hub)
        self.assertIn("hub.refreshToday()", app)
        self.assertIn("hub.refreshToday()", view)

    def test_watch_prefills_exact_prescribed_series_and_requests_fresh_today(self):
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        phone = source("Apps/Repera/Sources/PhoneConnectivity.swift")
        store = source("Apps/Repera/Sources/ReperaStore.swift")
        client = source("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")

        # Preset is a draft, not a completed set; actual LoggedSet is only
        # written by the explicit confirm action.
        self.assertIn("public var nextWorkSetPrescription: PlannedSet?", domain)
        self.assertIn("loggedSets.filter { $0.phase == .work }.count", domain)
        self.assertIn("let planned = ex?.nextWorkSetPrescription", hub)
        self.assertIn("workingReps = max(0, planned?.targetReps ?? 0)", hub)
        self.assertIn("planned?.targetWeightKg : nil", hub)
        self.assertIn("rir: ex?.exercise.loggingStyle.usesRIR == true ? planned?.targetRir : nil", hub)
        self.assertIn("durationSeconds: plannedDuration", hub)
        self.assertIn("ex?.blockWorkSeconds ?? ex?.blockIntervalSeconds", hub)
        self.assertIn("setDraft.unit", hub)
        self.assertIn("repCounter.ingest(magnitude: magnitude)", hub)
        self.assertIn("if current?.plannedSets.isEmpty != false", hub)
        self.assertIn("ctrl.logSet(", hub)
        self.assertIn("resetSetDraft()", hub)

        # Empty page keeps only title and a functional sync button.
        self.assertIn("Sin plan descargado", view)
        self.assertIn('Label("Sincronizar", systemImage:', view)
        self.assertNotIn("Si ya programaste un entrenamiento", view)
        self.assertNotIn("Abre Repera en el iPhone emparejado", view)
        self.assertIn("hub.refreshToday()", view)
        self.assertIn('"action": "requestToday"', client)
        self.assertIn("requestToday(deferIfOffline: true)", client)
        self.assertIn("wc.transferUserInfo(request)", client)
        self.assertIn("pendingManualRefresh = true", client)
        self.assertNotIn("applyContext(wc.receivedApplicationContext)\n        requestToday()", client)
        self.assertIn('Label("Sincronizar", systemImage:', view)
        self.assertIn('Image("MascotWatch")', view)
        self.assertIn("GeometryReader { available in", view)
        empty_screen = view.partition("private var emptyView: some View")[2].partition(
            "private func todayView("
        )[0]
        self.assertNotIn("figure.strengthtraining.traditional", empty_screen)
        ios_mascot = ROOT / "Apps/Repera/Resources/Assets.xcassets/MascotWatch.imageset/mascot-watch.png"
        watch_mascot = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/MascotWatch.imageset/mascot-watch.png"
        self.assertTrue(watch_mascot.is_file())
        self.assertEqual(ios_mascot.read_bytes(), watch_mascot.read_bytes())
        self.assertNotIn("Sincronizar con iPhone", view)

        # iPhone fetches the current scheduled routine before replying.
        self.assertIn("private func currentWatchWorkoutForToday()", store)
        self.assertIn("phoneConnectivityLatestWorkoutForToday() async -> WorkoutSession?", store)
        self.assertIn("self.currentWatchWorkoutForToday()", store)
        self.assertIn("await delegate.phoneConnectivityLatestWorkoutForToday()", phone)
        self.assertIn('"todayWorkout": data', phone)
        self.assertIn("delegate.phoneConnectivityDidRequestToday()", phone)

    def test_watch_does_not_show_music_controls(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertNotIn("showNowPlaying", view)
        self.assertNotIn("NowPlayingView()", view)
        self.assertNotIn('Image(systemName: "playpause.fill")', view)
        self.assertNotIn("Controlar música o podcast", view)
        self.assertIn('Label("Sincronizar", systemImage:', view)

    def test_healthkit_state_transitions_never_repeat_running_resume(self):
        """A startActivity session is already running; resume only from paused."""
        health = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("workout.state == .paused", health)
        self.assertIn("workout.state == .running", health)
        self.assertIn("pendingStateTransition != .running", health)
        self.assertIn("pendingStateTransition != .paused", health)
        self.assertIn("self.pendingStateTransition = nil", health)
        self.assertNotIn("func resume() { workout?.resume() }", health)
        self.assertNotIn("func pause() { workout?.pause() }", health)
        self.assertIn("hub.confirmAndAdvance()", view)
        self.assertEqual(view.count("hub.confirmAndAdvance()"), 1)
        self.assertNotIn('Text("Desliza ← → para revisar otras series")', view)
        self.assertNotIn('Label(hub.isFinalSet ? "Terminar" : "Siguiente"', view)
        self.assertIn("var canConfirmCurrentEntry: Bool", hub)

    def test_watch_workout_native_play_and_one_tap_save(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/SessionController.swift")

        self.assertIn("WatchExerciseThumb(exercise: exercise.exercise", view)
        self.assertIn("WatchExerciseThumb(exercise: exercise, size: 53)", view)
        self.assertIn('Text("Resumen")', view)
        self.assertIn("hub.selectBlock(startingAt: index)", view)
        self.assertIn("hub.swipeSet(horizontal < 0 ? 1 : -1)", view)
        self.assertIn("hub.confirmAndAdvance()", view)
        self.assertIn('Image(systemName: hub.nextActionIsFinish ? "checkmark" : "arrow.right")', view)
        self.assertIn("hub.canConfirmCurrentEntry", view)
        self.assertIn("hub.confirmAndAdvance()", view)
        self.assertNotIn('Text("Desliza ← → para revisar otras series")', view)
        self.assertIn('Button("Resumen") { showOutline = true }', view)
        self.assertNotIn("Confirmar serie", view)
        self.assertNotIn("Saltar al siguiente", view)
        self.assertNotIn("Volver al entrenamiento", view)
        self.assertNotIn("Registrado en Apple Salud", view)
        self.assertNotIn("Guardado en Watch · pendiente de sincronizar", view)
        self.assertNotIn('¿Finalizar el entrenamiento?', view)
        self.assertNotIn('Guardar entrenamiento', view)
        self.assertNotIn('Finalizar antes', view)
        self.assertIn('hub.finishFromSummary()', view)
        self.assertIn('func finishFromSummary()', hub)
        self.assertIn('lastFinished?.id != finished.id', hub)

        self.assertIn("func confirmAndAdvance()", hub)
        self.assertIn("func selectBlock(startingAt index: Int)", hub)
        self.assertIn("func swipeSet(_ direction: Int)", hub)
        self.assertIn("replaceLoggedSet(at:", hub)
        self.assertIn("public mutating func reviseLoggedSet(", domain)

    def test_watch_compact_titles_cards_and_play_controls(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")

        self.assertIn(".navigationTitle(pageTitle)", view)
        self.assertIn('return hub.todaysWorkout?.title ?? "Repera"', view)
        self.assertIn("return hub.current?.displayBlockHeader ?? active.title", view)
        self.assertNotIn('Text("HOY")', view)
        self.assertNotIn('Text(session.progressLabel)', view)
        self.assertIn("private func exerciseRow(", view)
        self.assertIn("private func blockExerciseRows(", view)
        self.assertIn("Divider().overlay(.gray.opacity(0.3))", view)
        self.assertNotIn("exerciseCard(", view)

        # No duplicate scroll heading, progress bar or permanent paused banner.
        self.assertIn("private var clockControls", view)
        self.assertIn('hub.isPaused ? "play.fill" : "pause.fill"', view)
        self.assertNotIn("ProgressView(value: Double(min(hub.blockElapsed", view)
        self.assertNotIn('Label("En pausa"', view)
        self.assertNotIn('Button("Finalizar antes")', view)

        # Shortcuts are exposed on Play without saving skipped/unconfirmed sets.
        self.assertIn('Button("Resumen")', view)
        self.assertIn('Image(systemName: hub.nextActionIsFinish ? "checkmark" : "arrow.right")', view)
        self.assertIn("hub.confirmAndAdvance()", view)
        self.assertNotIn("hub.nextExercise()", view)
        self.assertIn(".buttonStyle(.borderedProminent)", view)
        self.assertIn('func finishFromSummary()', hub)
        self.assertIn("if currentIsWOD {\n                reviewBlock()", hub)
        self.assertNotIn("confirmationDialog(", view)
        self.assertNotIn('Button("Guardar entrenamiento")', view)

        # Keep RIR and advanced fields editable without showing them on Play.
        play = view.partition("private var exerciseFields: some View")[2].partition(
            "private var rirControls: some View"
        )[0]
        self.assertNotIn("rirControls", play)
        self.assertNotIn("Más datos", play)
        self.assertIn("showSetDetails = true", view)
        details = view.partition("private var setDetailsView: some View")[2]
        self.assertIn("rirControls", details)

    def test_watch_next_arrow_accepts_zero_without_fake_logged_set(self):
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("var canConfirmCurrentEntry: Bool", hub)
        eligibility = hub.partition("var canConfirmCurrentEntry: Bool")[2].partition(
            "var nextActionIsFinish: Bool")[0]
        self.assertNotIn("effectiveReps > 0", eligibility)
        self.assertNotIn("restRemaining == 0", eligibility)
        self.assertIn("guard canConfirmCurrentEntry else { return }", hub)
        self.assertIn("if restRemaining > 0 {", hub)
        self.assertIn("skipRest()", hub)
        self.assertIn("if effectiveReps == 0 {", hub)
        self.assertIn("if hasNextExercise { nextExercise() } else { finishWorkout() }", hub)
        self.assertIn("if effectiveReps > 0 {", hub)
        self.assertIn("confirmIntervalSet()", hub)
        self.assertIn("if hasNextExercise { nextExercise() } else { reviewBlock() }", hub)
        self.assertIn(".disabled(!hub.canConfirmCurrentEntry)", view)
        self.assertIn("hub.confirmAndAdvance()", view)
        self.assertIn('return "Finalizado"', hub)
        self.assertNotIn("Intervalos finalizados", hub)

    def test_watch_large_controls_share_green_black_design(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        accent = "Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)"
        self.assertIn(accent, view)
        self.assertIn("private func valueStepButton(", view)
        self.assertIn('valueStepButton(symbol: "minus", label: "Restar repetición")', view)
        self.assertIn('valueStepButton(symbol: "plus", label: "Sumar repetición")', view)
        self.assertIn("private func metricStepper(", view)
        self.assertIn('metricStepper(label: "Peso kg"', view)
        self.assertIn('metricStepper(label: "Déficit (cm)"', view)
        self.assertIn('metricStepper(label: "Tiempo serie"', view)
        self.assertIn("valueStepButton(symbol: \"minus\", label: \"Reducir", view)
        self.assertIn("valueStepButton(symbol: \"plus\", label: \"Aumentar", view)
        self.assertIn(".background(accent, in: RoundedRectangle(cornerRadius: 18", view)
        self.assertIn(".frame(width: 70, height: 70)", view)
        self.assertIn(".background(accent, in: Circle())", view)
        self.assertNotIn(".tint(.red)", view)
        self.assertNotIn("role: .destructive", view)
        self.assertNotIn(".buttonStyle(.bordered)", view)
        self.assertNotIn(".buttonStyle(.borderless)", view)
        for section in view.split(".buttonStyle(.borderedProminent)")[1:]:
            self.assertIn(".tint(accent)", section[:180])
            self.assertIn(".foregroundStyle(.black)", section[:180])

    def test_watch_timers_and_primary_buttons_match_ios(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        iphone = source("Apps/Repera/Sources/WorkoutView.swift")
        theme = source("Apps/Repera/Sources/Theme.swift")

        # One brand hue: iOS OG.accent is #30D158, black for filled controls.
        self.assertIn("static let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)", theme)
        self.assertIn("private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)", view)
        self.assertIn(".background(accent, in: Circle())", view)
        self.assertIn(".frame(width: 70, height: 70)", view)
        self.assertIn('Image(systemName: hub.isPaused ? "play.fill" : "pause.fill")', view)
        self.assertIn(".foregroundStyle(.black)", view)

        # A real swipe to review a series remains; only its explanatory text goes.
        self.assertIn("DragGesture(minimumDistance: 35)", view)
        self.assertIn("hub.swipeSet(horizontal < 0 ? 1 : -1)", view)
        self.assertIn("func swipeSet(_ direction: Int)", hub)
        self.assertNotIn("Desliza ← → para revisar otras series", view)

        # The interval is the ONLY large clock and its label sits beside it
        # in the same VStack, not a separate timer underneath.
        self.assertIn("Text(timeLabel(hub.primaryClockSeconds))", view)
        self.assertIn("font(.system(size: 43, weight: .bold, design: .rounded))", view)
        self.assertIn("if let descriptor = hub.clockDescriptor", view)
        clock = view.partition("private var clockControls: some View")[2].partition(
            "private var wodContent: some View"
        )[0]
        self.assertNotIn("timeLabel(hub.intervalRemaining)", clock)
        self.assertNotIn("hub.timeRemaining ?? hub.blockElapsed", clock)
        self.assertNotIn("Text(timeLabel(remaining))", clock)
        self.assertIn("intervalRemaining ?? timeRemaining ?? blockElapsed", hub)

        # Interval formats follow the iPhone clock, including circuit rests.
        for format in (".emom", ".tabata", ".circuit", ".deathBy"):
            self.assertIn(format, hub)
        self.assertIn("private var circuitPhases", hub)
        self.assertIn("private var circuitPhase", hub)
        self.assertIn("roundRest > 0", hub)
        self.assertIn("rounds * (work + rest)", hub)
        self.assertIn("var intervalsFinished: Bool", hub)
        self.assertIn('return "Finalizado"', hub)
        self.assertNotIn('Intervalos finalizados', hub)
        self.assertIn("if wodUsesSeries && isIntervalClock", hub)
        self.assertIn("if previous < timeCapSeconds", hub)
        self.assertIn("restRemaining = 0", hub)
        self.assertIn("if wodUsesSeries {", hub)
        self.assertIn("case .emom, .deathBy:", hub)
        self.assertIn("case .emom:", iphone)
        self.assertIn("case .tabata:", iphone)

        # For Time and its equivalents count up; TC is informational.
        self.assertIn("var clockCountsUp: Bool", hub)
        self.assertIn("case .forTime, .chipper, .afap, .ladder, .buyInCashOut:", hub)
        self.assertIn("return 0", hub)
        self.assertIn("timeCapSeconds: clockCountsUp ? 0 : timeCapSeconds", hub)
        self.assertIn('return "TC superado"', hub)
        self.assertIn("countingUp: true", iphone)

        # Green prominence uses a black icon or text.
        for section in view.split(".buttonStyle(.borderedProminent)")[1:]:
            self.assertIn(".foregroundStyle(.black)", section.split(".accessibility", 1)[0][:180])

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
            "if let draft = snapshot.setDraft",
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
