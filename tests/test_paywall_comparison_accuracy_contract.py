"""El paywall no debe sobrevender gates que Gratis ya tiene (p. ej. comparativas WOD)."""

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class PaywallComparisonAccuracyTests(unittest.TestCase):
    def test_ios_paywall_rows_match_real_gates(self):
        paywall = read("Apps/Repera/Sources/Monetization/PaywallView.swift")
        self.assertIn('("Navegación mapa", "2D", "2D + 3D")', paywall)
        self.assertIn('("Progreso", "Últimos 7 días", "Completo")', paywall)
        self.assertIn('("Progresión de carga", "Sugerida en ficha", "Automática")', paywall)
        self.assertNotIn("Comparativas WOD", paywall)
        self.assertNotIn("Historial WOD", paywall)
        self.assertNotIn("Mes + a largo plazo", paywall)
        self.assertNotIn("GRATIS VS PRO", paywall)
        self.assertNotIn("DESBLOQUEA MÁS", paywall)
        self.assertNotIn('("Mapa GPS"', paywall)
        self.assertIn("Introduce el código aquí.", paywall)

    def test_android_paywall_rows_match_ios(self):
        paywall = read(
            "android/mobile/src/main/java/dev/repera/mobile/monetization/PaywallScreen.kt"
        )
        self.assertIn('Triple("Navegación mapa", "2D", "2D + 3D")', paywall)
        self.assertIn('Triple("Progreso", "Últimos 7 días", "Completo")', paywall)
        self.assertIn('Triple("Progresión de carga", "Sugerida en ficha", "Automática")', paywall)
        self.assertNotIn("Comparativas WOD", paywall)
        self.assertNotIn("Historial WOD", paywall)
        self.assertNotIn("Mes + a largo plazo", paywall)
        self.assertNotIn("GRATIS VS PRO", paywall)
        self.assertNotIn("DESBLOQUEA MÁS", paywall)
        self.assertIn("Introduce el código aquí.", paywall)

    def test_debug_offerings_do_not_invent_free_trial(self):
        debug = read("Apps/Repera/Sources/Monetization/DebugEntitlementProvider.swift")
        offerings = debug.split("func offerings()", 1)[1]
        self.assertNotIn("14 días gratis", offerings)
        self.assertIn("hasFreeTrial: false", offerings)

    def test_local_storekit_has_no_introductory_offer(self):
        local = json.loads(
            read("Apps/Repera/Resources/StoreKit/ReperaProducts.storekit")
        )
        for group in local["subscriptionGroups"]:
            for item in group["subscriptions"]:
                self.assertNotIn(
                    "introductoryOffer",
                    item,
                    msg=f"{item['productID']} no debe inventar intro local",
                )

    def test_this_session_card_compares_without_pro_gate(self):
        card = read("Apps/Repera/Sources/ExerciseThisSessionCard.swift")
        self.assertIn("Intento anterior", card)
        self.assertNotIn("subscriptions.isPro", card)
        self.assertNotIn("presentPaywall", card)

    def test_store_driven_offer_field_exists_on_both_platforms(self):
        """Descuentos/trial se muestran solo si la tienda los devuelve."""
        ios = read("Apps/Repera/Sources/Monetization/StoreKitEntitlementProvider.swift")
        android = read(
            "android/mobile/src/main/java/dev/repera/mobile/monetization/"
            "PlayBillingEntitlementProvider.kt"
        )
        paywall_ios = read("Apps/Repera/Sources/Monetization/PaywallView.swift")
        paywall_android = read(
            "android/mobile/src/main/java/dev/repera/mobile/monetization/PaywallScreen.kt"
        )
        self.assertIn("introductoryOffer", ios)
        self.assertIn("introductoryOfferSummary: introSummary", ios)
        self.assertIn("SubscriptionOfferCopy.summarize", android)
        self.assertIn("introductoryOfferSummary = intro.text", android)
        self.assertIn("package.introductoryOfferSummary", paywall_ios)
        self.assertIn("pkg.introductoryOfferSummary", paywall_android)


if __name__ == "__main__":
    unittest.main()
