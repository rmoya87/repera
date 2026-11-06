"""Native entry-point contracts: navigation first, sensor ownership stays in app."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class NativeSystemEntryContractTests(unittest.TestCase):
    def test_ios_shortcuts_only_enqueue_navigation(self):
        swift = source("Apps/Repera/Sources/ReperaSystemShortcuts.swift")
        self.assertIn("AppShortcutsProvider", swift)
        self.assertIn("static let openAppWhenRun = true", swift)
        self.assertIn("ReperaSystemCommand.request(.today)", swift)
        self.assertNotIn("HKWorkoutSession(", swift)
        self.assertNotIn("startActivity(with:", swift)
        root = source("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("guard store.isHydrated else { return }", root)
        self.assertIn('case ("today", 0): self = .today', root)

    def test_control_center_scene_routing_cannot_start_sensors(self):
        control = source("Apps/ReperaRestWidget/ReperaControls.swift")
        self.assertIn("StaticControlConfiguration", control)
        self.assertIn("ReperaControlOpenIntent(target: .live)", control)
        self.assertNotIn("HKWorkoutSession", control)
        shared = source("Apps/Shared/ReperaControlOpenIntent.swift")
        self.assertIn("OpenIntent, TargetContentProvidingIntent", shared)
        app = source("Apps/Repera/Sources/ReperaApp.swift")
        self.assertIn('.handlesExternalEvents(matching: ["repera.control.open"])', app)
        self.assertIn(".onAppIntentExecution(ReperaControlOpenIntent.self)", app)
        widget_bundle = source("Apps/ReperaRestWidget/RestLiveActivityWidget.swift")
        self.assertIn("ReperaBeginControl()", widget_bundle)

    def test_live_activity_intents_never_confirm_sets_or_write_health(self):
        intents = source("Apps/Shared/TrainingLiveActivityIntents.swift")
        self.assertIn("LiveActivityIntent", intents)
        self.assertIn("TrainingPauseLiveActivityIntent", intents)
        self.assertIn("TrainingResumeLiveActivityIntent", intents)
        self.assertIn("TrainingOpenSessionLiveActivityIntent", intents)
        self.assertNotIn("HKWorkoutSession", intents)
        self.assertNotIn("confirmAndAdvance", intents)
        self.assertNotIn("loggedSets", intents)
        # perform() often runs off-main; enqueue must hop to MainActor before
        # NotificationCenter (SwiftUI observers mutate @Observable state).
        self.assertIn("@MainActor", intents)
        self.assertIn("await TrainingLiveActivityCommand.request(.pause)", intents)
        self.assertIn("await TrainingLiveActivityCommand.request(.resume)", intents)
        self.assertIn("await TrainingLiveActivityCommand.request(.openSession)", intents)
        widget = source("Apps/ReperaRestWidget/TrainingLiveActivityWidget.swift")
        self.assertIn("TrainingPauseLiveActivityIntent()", widget)
        self.assertIn("TrainingOpenSessionLiveActivityIntent()", widget)
        root = source("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("applyPendingLiveActivityCommand", root)
        self.assertIn("LiveActivityRecorder.shared.pause()", root)
        self.assertIn("LiveActivityRecorder.shared.resume()", root)

    def test_apple_widgets_and_watch_gesture_are_connected(self):
        bundle = source("Apps/ReperaRestWidget/RestLiveActivityWidget.swift")
        self.assertIn("ReperaHomeWidget()", bundle)
        widget = source("Apps/ReperaRestWidget/ReperaHomeWidget.swift")
        self.assertIn("repera://today", widget)
        self.assertIn("repera://live", widget)
        self.assertNotIn("HealthKit", widget)
        watch = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn(".handGestureShortcut(.primaryAction", watch)
        self.assertIn("!hub.nextActionIsFinish", watch)

    def test_android_assistant_and_appsearch_are_opt_in_public_only(self):
        shortcuts = source("android/mobile/src/main/res/xml/repera_shortcuts.xml")
        self.assertIn("actions.intent.OPEN_APP_FEATURE", shortcuts)
        self.assertIn("actions.intent.GET_THING", shortcuts)
        self.assertIn("repera://live", shortcuts)
        self.assertNotIn("HealthConnect", shortcuts)
        search = source("android/mobile/src/main/java/dev/repera/mobile/PublicExerciseAppSearch.kt")
        self.assertIn("isConsentGranted", search)
        self.assertIn('optBoolean("isCustom")', search)
        self.assertIn("clearConsent", search)
        health = source("android/mobile/src/main/java/dev/repera/mobile/ConnectedHealthScreen.kt")
        self.assertIn("AppSearchConsentRow", health)
        main = source("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        self.assertIn("PublicExerciseAppSearch.clearAll", main)

    def test_android_external_actions_are_navigation_only(self):
        route = source("android/mobile/src/main/java/dev/repera/mobile/LiveNavigationTarget.kt")
        self.assertIn('"today" -> "inicio"', route)
        self.assertIn('"timer" -> "temporizador"', route)
        tile = source("android/mobile/src/main/java/dev/repera/mobile/ReperaQuickTileService.kt")
        self.assertIn("startActivityAndCollapse(pending)", tile)
        self.assertNotIn("ExerciseClient", tile)
        self.assertNotIn("startForegroundService", tile)
        manifest = source("android/mobile/src/main/AndroidManifest.xml")
        self.assertIn("BIND_QUICK_SETTINGS_TILE", manifest)
        self.assertIn("repera_home_widget_info", manifest)
        self.assertIn("repera_shortcuts", manifest)
        self.assertIn("repera://exercises", source("android/mobile/src/main/res/xml/repera_shortcuts.xml"))

    def test_search_index_and_widget_invalidation_are_account_safe(self):
        spotlight = source("Apps/Repera/Sources/ExerciseSpotlightIndexer.swift")
        self.assertIn("!$0.isCustom && !$0.isCatalogArchived", spotlight)
        self.assertIn("lastIndexedSignature", spotlight)
        self.assertIn('domain = "com.app.repera.public-exercises"', spotlight)
        self.assertNotIn("state.workouts", spotlight)
        app = source("Apps/Repera/Sources/ReperaApp.swift")
        self.assertIn("CSSearchableItemActionType", app)
        widget = source("android/mobile/src/main/java/dev/repera/mobile/ReperaWidgetRefreshWorker.kt")
        self.assertIn("ReperaHomeWidget().updateAll(applicationContext)", widget)
        self.assertIn("ExistingWorkPolicy.KEEP", widget)
        self.assertNotIn("ExerciseClient", widget)
        storage = source("android/mobile/src/main/java/dev/repera/mobile/LocalSnapshotStore.kt")
        self.assertIn("ReperaWidgetRefresh.enqueue(appContext)", storage)
        session = source("android/mobile/src/main/java/dev/repera/mobile/SessionStore.kt")
        self.assertIn("if (identityChanged) runCatching { ReperaWidgetRefresh.enqueue(appContext) }", session)

    def test_watch_dictation_requires_manual_review_and_never_saves_on_speech(self):
        parser = source("Apps/ReperaWatch/Sources/WatchSpokenSet.swift")
        self.assertIn("struct WatchSpokenSet", parser)
        self.assertIn("repeticion(?:es)?", parser)
        watch = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("dictatedSetSheet", watch)
        self.assertIn('Button("Aplicar valores")', watch)
        self.assertIn("showSpokenSet", watch)
        self.assertNotIn("hub.confirmAndAdvance()\n                    showSpokenSet", watch)
        wear = source("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        self.assertIn("RecognizerIntent.ACTION_RECOGNIZE_SPEECH", wear)
        self.assertIn("dictationSessionId != session.sessionId", wear)
        self.assertIn("persistDraft()", wear)
        self.assertIn("onApplySpokenSet", wear)
        self.assertNotIn("queueSet(", wear.split("private fun applySpokenSetInput()", 1)[1].split("override fun onCreate(", 1)[0])

    def test_workoutkit_only_exports_goals_with_explicit_user_action(self):
        source_text = source("Apps/Repera/Sources/AppleWorkoutExportSheet.swift")
        self.assertIn("SingleGoalWorkout.supportsActivity", source_text)
        self.assertIn("SingleGoalWorkout.supportsGoal", source_text)
        # iOS: openInWorkoutApp is unavailable; use system preview + scheduler.
        self.assertNotIn("openInWorkoutApp()", source_text)
        self.assertIn(".workoutPreview(", source_text)
        self.assertIn("WorkoutScheduler.shared", source_text)
        self.assertIn("scheduler.schedule(plan, at: when)", source_text)
        self.assertIn("case .running, .walking, .hiking", source_text)
        self.assertIn("utiliza Entreno de Apple o Repera", source_text)
        self.assertNotIn("HKWorkoutSession(", source_text)
        screen = source("Apps/Repera/Sources/LiveActivityView.swift")
        self.assertIn("if recorder.phase == .idle, !recorder.isStartCountingDown", screen)
        self.assertIn("AppleWorkoutExportSheet(sport: recorder.sport)", screen)

    def test_android_gps_cannot_preempt_another_workout(self):
        gps = source("android/mobile/src/main/java/dev/repera/mobile/WorkoutLocationTracker.kt")
        self.assertIn("if (trackingSessionID == sessionID) return", gps)
        self.assertIn("if (trackingSessionID != null)", gps)
        start = gps.split("fun startRouteTracking(sessionID: String)", 1)[1].split(
            "fun stopRouteTracking()", 1
        )[0]
        self.assertNotIn("stopRouteTracking()", start)
        self.assertIn("trackingSessionID = sessionID", start)

    def test_local_booking_reminders_are_account_scoped_and_confirmed_only(self):
        scheduler = source("Apps/Repera/Sources/BusinessBookingReminderScheduler.swift")
        self.assertIn('booking.status == "booked"', scheduler)
        self.assertIn("start.addingTimeInterval(-3600)", scheduler)
        self.assertIn("BusinessDataStore.date(occurrence.startsAt)", scheduler)
        self.assertIn("generation == current", scheduler)
        center = source("Apps/Repera/Sources/BusinessDataStore.swift")
        self.assertIn("BusinessBookingReminderScheduler.clear()", center)
        self.assertIn("BusinessBookingReminderScheduler.reconcile(", center)
        android = source("android/mobile/src/main/java/dev/repera/mobile/ClassBookingReminders.kt")
        self.assertIn('it.status == "booked"', android)
        self.assertIn("fireAt = start.toEpochMilli() - 3_600_000L", android)
        self.assertIn("prefs.getString(\"owner\", null) != owner", android)
        self.assertIn("SessionStore(app).load()", android)
        self.assertNotIn("startForegroundService", android)

    def test_android_gpx_share_is_explicit_and_publicly_scoped(self):
        codec = source("android/domain/src/main/java/dev/repera/domain/RouteGPXCodec.kt")
        self.assertIn("it.isEstimated != true", codec)
        self.assertIn("point.recordedAtEpochMs - previous > 30_000L", codec)
        chooser = source("android/mobile/src/main/java/dev/repera/mobile/WorkoutRouteShare.kt")
        self.assertIn("Intent.ACTION_SEND", chooser)
        self.assertIn("Intent.FLAG_GRANT_READ_URI_PERMISSION", chooser)
        self.assertIn("ClipData.newUri", chooser)
        self.assertNotIn("startForegroundService", chooser)
        screen = source("android/mobile/src/main/java/dev/repera/mobile/CompleteHistoryScreen.kt")
        self.assertIn("Compartir recorrido GPX", screen)
        provider = source("android/mobile/src/main/res/xml/board_scan_paths.xml")
        self.assertIn('path="route_shares/"', provider)

    def test_export_is_explicit_and_uses_unmodified_gps(self):
        export = source("Apps/Repera/Sources/RouteGPXExporter.swift")
        self.assertIn("RouteGPXExporter", export)
        self.assertIn('xmlns=\\\"http://www.topografix.com/GPX/1/1', export)
        self.assertIn("(-90...90)", export)
        self.assertIn("(-180...180)", export)
        ui = source("Apps/Repera/Sources/HistoryView.swift")
        self.assertIn("ShareLink(item: exportedRoute)", ui)


if __name__ == "__main__":
    unittest.main()
