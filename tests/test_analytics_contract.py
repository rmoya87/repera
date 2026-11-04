"""Contratos de telemetría de Repera: paridad de eventos y privacidad por defecto."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = json.loads((ROOT / "analytics/contract.json").read_text())
IOS = (ROOT / "Apps/Repera/Sources/Analytics/ReperaAnalytics.swift").read_text()
ANDROID = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/analytics/ReperaAnalytics.kt").read_text()


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

    def test_opt_in_and_no_health_sdk_in_analytics_adapter(self):
        plist = (ROOT / "Apps/Repera/Resources/Info.plist").read_text()
        android_manifest = (ROOT / "android/mobile/src/main/AndroidManifest.xml").read_text()
        self.assertRegex(
            plist,
            r"<key>FIREBASE_ANALYTICS_COLLECTION_ENABLED</key>\s*<false/>",
        )
        self.assertIn('android:name="firebase_analytics_collection_enabled" android:value="false"', android_manifest)
        self.assertIn("if (!consentGranted) return", ANDROID)
        self.assertIn("UserDefaults.standard.bool(forKey: consentKey)", IOS)
        self.assertNotIn("import HealthKit", IOS)
        self.assertNotIn("import androidx.health", ANDROID)
        self.assertNotIn("import CoreLocation", IOS)
        self.assertNotIn("import android.location", ANDROID)

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


if __name__ == "__main__":
    unittest.main()
