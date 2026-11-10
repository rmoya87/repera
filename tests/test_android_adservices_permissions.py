"""Android mobile contract: no advertising identifiers or Privacy Sandbox ad permissions."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "android/mobile/src/main/AndroidManifest.xml"
ANALYTICS = ROOT / "android/mobile/src/main/java/dev/repera/mobile/analytics/ReperaAnalytics.kt"


class AndroidAdvertisingPermissionsContractTests(unittest.TestCase):
    def test_advertising_permissions_are_removed_at_manifest_merge(self):
        manifest = MANIFEST.read_text(encoding="utf-8")
        for permission in (
            "com.google.android.gms.permission.AD_ID",
            "android.permission.ACCESS_ADSERVICES_AD_ID",
            "android.permission.ACCESS_ADSERVICES_ATTRIBUTION",
            "android.permission.ACCESS_ADSERVICES_TOPICS",
        ):
            with self.subTest(permission=permission):
                self.assertIn(
                    f'<uses-permission android:name="{permission}" tools:node="remove" />',
                    manifest,
                )

    def test_firebase_advertising_collection_and_personalization_disabled(self):
        manifest = MANIFEST.read_text(encoding="utf-8")
        for name in (
            "google_analytics_adid_collection_enabled",
            "google_analytics_default_allow_ad_personalization_signals",
        ):
            with self.subTest(name=name):
                self.assertIn(
                    f'<meta-data android:name="{name}" android:value="false" />',
                    manifest,
                )
        self.assertNotIn("firebase_analytics_adid_collection_enabled", manifest)

    def test_product_analytics_activation_unchanged(self):
        self.assertIn("setAnalyticsCollectionEnabled(true)", ANALYTICS.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
