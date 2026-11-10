"""Onboarding: pantalla de privacidad visual + copy de login (Rutinas / IA)."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = (
    ROOT / "Apps/Repera/Sources/Onboarding/OnboardingFlowView.swift"
).read_text(encoding="utf-8")
ANDROID = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/OnboardingScreen.kt"
).read_text(encoding="utf-8")
SETTINGS_IOS = (ROOT / "Apps/Repera/Sources/SettingsView.swift").read_text(encoding="utf-8")
SETTINGS_ANDROID = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt"
).read_text(encoding="utf-8")
AI_IOS = (ROOT / "Apps/Repera/Sources/AIAccessView.swift").read_text(encoding="utf-8")
AI_ANDROID = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt"
).read_text(encoding="utf-8")
HTACCESS = (ROOT / "web/.htaccess").read_text(encoding="utf-8")


class OnboardingPrivacyLoginContractTests(unittest.TestCase):
    def test_login_highlight_copy(self):
        self.assertIn('"Rutinas"', IOS)
        self.assertIn('"IA"', IOS)
        self.assertNotIn("Rutinas y series", IOS)
        self.assertNotIn("Entrenador e IA", IOS)
        self.assertIn('"Rutinas"', ANDROID)
        self.assertIn('"IA"', ANDROID)
        self.assertNotIn("Rutinas y series", ANDROID)
        self.assertNotIn("Entrenador e IA", ANDROID)

    def test_privacy_step_mentions_icloud_and_no_sharing(self):
        perms = IOS.split("struct OnboardingPermissionsStep", 1)[1]
        self.assertIn("Guardado en tu iCloud", perms)
        self.assertIn("Sin compartir con terceros", perms)
        self.assertIn("OnboardingPrivacyFactCard", perms)
        self.assertIn('Text("Continuar")', perms)

        android_perms = ANDROID.split("OnboardingPermissionsStep", 1)[1]
        self.assertIn("Tus datos, bajo tu control", android_perms)
        self.assertIn("Sin compartir con terceros", android_perms)
        self.assertIn("Health Connect", android_perms)
        self.assertIn("onboarding_permissions_continue", android_perms)

    def test_settings_bottom_margin_and_mcp_url_size(self):
        self.assertIn(
            ".contentMargins(.bottom, 28, for: .scrollContent)",
            SETTINGS_IOS,
        )
        self.assertIn("tabInset + 32.dp", SETTINGS_ANDROID)
        self.assertIn(".font(.body.weight(.semibold).monospaced())", AI_IOS)
        self.assertIn("typography.titleMedium", AI_ANDROID)
        self.assertIn("ProxyPass        /mcp", HTACCESS)


if __name__ == "__main__":
    unittest.main()
