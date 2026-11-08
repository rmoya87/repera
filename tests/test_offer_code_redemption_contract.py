"""Canje de códigos de oferta: hoja StoreKit en iOS; Play redeem en Android."""

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class OfferCodeRedemptionContractTests(unittest.TestCase):
    def test_ios_paywall_presents_offer_code_redemption(self):
        paywall = read("Apps/Repera/Sources/Monetization/PaywallView.swift")
        self.assertIn("import StoreKit", paywall)
        self.assertIn("offerCodeBox", paywall)
        self.assertIn("¿TIENES UN CÓDIGO?", paywall)
        self.assertIn("Canjear código", paywall)
        self.assertIn("Introduce el código aquí.", paywall)
        self.assertIn(".offerCodeRedemption(isPresented: $showOfferCodeRedemption)", paywall)
        self.assertIn('accessibilityIdentifier("pro-redeem-offer-code")', paywall)
        self.assertIn("handleOfferCodeRedemptionFinished", paywall)
        self.assertIn("refreshEntitlementsForFeatureAction", paywall)

    def test_ios_settings_can_redeem_offer_code(self):
        settings = read("Apps/Repera/Sources/SettingsView.swift")
        self.assertIn("import StoreKit", settings)
        self.assertIn("Canjear código de oferta", settings)
        self.assertIn(".offerCodeRedemption(isPresented: $showOfferCodeRedemption)", settings)
        self.assertIn('accessibilityIdentifier("settings-redeem-offer-code")', settings)

    def test_android_paywall_opens_play_redeem(self):
        paywall = read(
            "android/mobile/src/main/java/dev/repera/mobile/monetization/PaywallScreen.kt"
        )
        config = read(
            "android/mobile/src/main/java/dev/repera/mobile/monetization/EntitlementProvider.kt"
        )
        self.assertIn("PaywallOfferCodeBox", paywall)
        self.assertIn("¿TIENES UN CÓDIGO?", paywall)
        self.assertIn("Canjear código", paywall)
        self.assertIn("CommercialConfig.REDEEM_CODE_URL", paywall)
        self.assertIn('REDEEM_CODE_URL = "https://play.google.com/redeem"', config)


if __name__ == "__main__":
    unittest.main()
