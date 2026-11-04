"""Contratos de telemetría de Repera: paridad de eventos y privacidad por defecto."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = json.loads((ROOT / "analytics/contract.json").read_text())
IOS = (ROOT / "Apps/Repera/Sources/Analytics/ReperaAnalytics.swift").read_text()
ANDROID = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/analytics/ReperaAnalytics.kt").read_text()
IOS_STORE = (ROOT / "Apps/Repera/Sources/ReperaStore.swift").read_text()
ANDROID_REPO = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt").read_text()
IOS_SETTINGS = (ROOT / "Apps/Repera/Sources/SettingsView.swift").read_text()
ANDROID_SETTINGS = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt").read_text()


class AnalyticsContractTests(unittest.TestCase):
    def test_canonical_event_registry_matches_swift_and_kotlin(self):
        expected = [event for area in CONTRACT["events_by_area"].values() for event in area]
        self.assertEqual(len(expected), len(set(expected)))
        for event in expected:
            self.assertRegex(event, r"^[a-z][a-z0-9_]{0,39}$")
        swift = re.findall(r'^\s*case\s+\w+\s*=\s*"([a-z0-9_]+)"', IOS, re.M)
        kotlin = re.findall(r'^\s*[A-Z_]+\("([a-z0-9_]+)"\)', ANDROID, re.M)
        self.assertEqual(set(expected), set(swift))
        self.assertEqual(set(expected), set(kotlin))
        self.assertEqual(len(expected), len(swift))
        self.assertEqual(len(expected), len(kotlin))

    def test_sport_ids_and_wod_formats_are_shared(self):
        swift_sports = (ROOT / "Apps/Repera/Sources/LiveActivityView.swift").read_text()
        android_sports = (ROOT / "android/domain/src/main/java/dev/repera/domain/LiveSport.kt").read_text()
        for sport in CONTRACT["sport_ids"]:
            self.assertRegex(swift_sports, r"\b" + re.escape(sport) + r"\b")
            self.assertIn('("' + sport + '"', android_sports)
        swift_wod = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/Models.swift").read_text()
        kotlin_wod = (ROOT / "android/domain/src/main/java/dev/repera/domain/WodRules.kt").read_text()
        for wod in CONTRACT["enum_values"]["wod_format"]:
            self.assertRegex(swift_wod, r"\bcase\s+" + re.escape(wod) + r"\b")
            self.assertIn('("' + wod + '")', kotlin_wod)

    def test_collection_disabled_until_firebase_configure_and_no_health_imports(self):
        plist = (ROOT / "Apps/Repera/Resources/Info.plist").read_text()
        android_manifest = (ROOT / "android/mobile/src/main/AndroidManifest.xml").read_text()
        self.assertRegex(
            plist,
            r"<key>FIREBASE_ANALYTICS_COLLECTION_ENABLED</key>\s*<false/>",
        )
        self.assertIn('android:name="firebase_analytics_collection_enabled" android:value="false"', android_manifest)
        self.assertIn("setAnalyticsCollectionEnabled(true)", IOS)
        self.assertIn("setAnalyticsCollectionEnabled(true)", ANDROID)
        self.assertIn("trackOnce", IOS)
        self.assertIn("trackOnce", ANDROID)
        self.assertNotIn("import HealthKit", IOS)
        self.assertNotIn("import androidx.health", ANDROID)
        self.assertNotIn("import CoreLocation", IOS)
        self.assertNotIn("import android.location", ANDROID)

    def test_no_in_app_analytics_consent_ui(self):
        self.assertNotIn("Permitir estadísticas de uso", IOS_SETTINGS)
        self.assertNotIn("Permitir estadísticas de uso", ANDROID_SETTINGS)
        self.assertNotIn("setConsent", IOS_SETTINGS)
        self.assertNotIn("setConsent", ANDROID_SETTINGS)
        self.assertNotIn("hasConsent", IOS)
        self.assertNotIn("fun setConsent", ANDROID)

    def test_no_tracking_sdk_linked_to_watches(self):
        project = (ROOT / "project.yml").read_text()
        watch_target = project.split("  ReperaWatch:", 1)[1].split("  ReperaWatchWidget:", 1)[0]
        self.assertNotIn("Firebase", watch_target)
        wear_build = (ROOT / "android/wear/build.gradle.kts").read_text()
        self.assertNotIn("firebase-analytics", wear_build)
        self.assertEqual(CONTRACT["schema_version"], 1)

    def test_commercial_events_are_kept_compatible(self):
        required = {"paywall_viewed", "paywall_dismissed", "premium_feature_tapped",
                    "free_limit_reached", "trial_started", "subscription_started",
                    "subscription_restored", "purchase_failed"}
        self.assertTrue(required.issubset(set(CONTRACT["events_by_area"]["subscription"])))
        for path in ("Apps/Repera/Sources/Monetization/MonetizationAnalytics.swift",
                     "android/mobile/src/main/java/dev/repera/mobile/monetization/MonetizationAnalytics.kt"):
            self.assertIn("ReperaAnalytics.track", (ROOT / path).read_text())

    def test_first_sports_and_progress_interactions_are_instrumented_consistently(self):
        swift_sports = (ROOT / "Apps/Repera/Sources/LiveActivityView.swift").read_text()
        android_sports = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt").read_text()
        swift_progress = (ROOT / "Apps/Repera/Sources/StatsView.swift").read_text()
        android_progress = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt").read_text()
        self.assertIn("ReperaAnalytics.track(.activitySelected", swift_sports)
        self.assertIn("ReperaAnalytics.Event.ACTIVITY_SELECTED", android_sports)
        self.assertIn("activity_family", swift_sports)
        self.assertIn("activity_family", android_sports)
        self.assertIn("ReperaAnalytics.track(.progressSectionViewed", swift_progress)
        self.assertIn("ReperaAnalytics.Event.PROGRESS_SECTION_VIEWED", android_progress)

    def test_workout_completion_hooks_after_persistence(self):
        self.assertIn("emitWorkoutCompletedAnalytics", IOS_STORE)
        self.assertIn("trackWorkoutCompleted", IOS)
        self.assertIn("emitWorkoutCompleted(", ANDROID_REPO)
        self.assertIn("trackWorkoutCompleted", ANDROID)
        self.assertIn("workoutDiscarded", IOS_STORE)
        self.assertIn("WORKOUT_DISCARDED", ANDROID_REPO)
        self.assertIn("workoutDeleted", IOS_STORE)
        self.assertIn("WORKOUT_DELETED", ANDROID_REPO)
        self.assertIn("workoutEdited", IOS_STORE)
        self.assertIn("WORKOUT_EDITED", ANDROID_REPO)
        self.assertIn("emitWorkoutStartedAnalytics", IOS_STORE)
        self.assertIn("emitWorkoutStarted(", ANDROID_REPO)
        self.assertIn("workoutBlockCompleted", IOS_STORE)
        self.assertIn("WORKOUT_BLOCK_COMPLETED", ANDROID_REPO)
        self.assertIn("resolveActivity", IOS)
        self.assertIn("resolveActivity", ANDROID)
        emitted_types = ("planned", "free", "live_sport", "timer", "quick_log")
        for value in emitted_types:
            self.assertIn(value, CONTRACT["enum_values"]["workout_type"])
            self.assertIn(f'return "{value}"', IOS_STORE)
            self.assertIn(f'return "{value}"', ANDROID_REPO)
        for value in CONTRACT["enum_values"]["activity_family"]:
            self.assertIn(f'return "{value}"', IOS)
            self.assertIn(f'"{value}"', ANDROID)
        self.assertIn('"crossfit"', IOS)
        self.assertIn('"strength"', IOS)
        self.assertIn('"crossfit"', ANDROID)
        self.assertIn('"strength"', ANDROID)

    def test_remaining_product_hooks_present_on_ios(self):
        sources = "\n".join(
            path.read_text()
            for path in (ROOT / "Apps/Repera/Sources").rglob("*.swift")
        )
        for needle in (
            ".timerPaused",
            ".timerResumed",
            ".exerciseSearchUsed",
            ".exerciseDetailViewed",
            ".mapRecenterRequested",
            ".routeSaved",
            ".classListViewed",
            ".classViewed",
            ".classWaitlistJoined",
            ".classAttended",
            ".aiConnectionStarted",
            ".aiConnectionVerified",
            ".syncCompleted",
            ".watchSyncConfirmed",
            ".dataExportCompleted",
            ".progressPeriodSelected",
            'watch_app_opened',
        ):
            self.assertIn(needle, sources)
        watch = (ROOT / "Apps/ReperaWatch/Sources/WatchConnectivityClient.swift").read_text()
        self.assertIn("enqueueAnalyticsEvent", watch)
        self.assertIn("analyticsEvent", (ROOT / "Apps/Repera/Sources/PhoneConnectivity.swift").read_text())
        wear_store = (ROOT / "android/wear/src/main/java/dev/repera/wear/WearPendingAnalyticsStore.kt").read_text()
        self.assertIn("watch_app_opened", wear_store)
        self.assertIn("/repera/analytics-event", (ROOT / "android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt").read_text())
        self.assertIn("/repera/analytics-event", (ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt").read_text())
        self.assertIn("component_id", CONTRACT["enum_values"])
        self.assertIn("action_name", CONTRACT["enum_values"])
        self.assertIn("product-analytics.js", (ROOT / "web/console/src/core/auth.js").read_text())
        self.assertIn(".aiProgramPaused", sources)
        self.assertIn(".workoutSaveFailed", sources)
        self.assertIn(".uiInteraction", sources)


if __name__ == "__main__":
    unittest.main()
