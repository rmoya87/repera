"""Contratos estáticos: errores StoreKit/TestFlight y consulta de conexiones IA.

Los contratos no sustituyen una prueba StoreKit Sandbox ni una build iOS.
"""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"


def source(path):
    return (SRC / path).read_text(encoding="utf-8")


class TestFlightStoreKitReliabilityTests(unittest.TestCase):
    def test_restore_consults_signed_entitlements_before_requesting_sync(self):
        provider = source("Monetization/StoreKitEntitlementProvider.swift")
        block = provider.split("func restore() async throws -> CommercialSnapshot", 1)[1]
        block = block.split("func offerings()", 1)[0]
        self.assertLess(
            block.index("let current = await snapshotFromCurrentEntitlements()"),
            block.index("try await AppStore.sync()"),
        )
        self.assertIn("if current.grantsProAccess { return current }", block)
        self.assertIn("let recovered = await snapshotFromCurrentEntitlements()", block)
        self.assertIn("if recovered.grantsProAccess { return recovered }", block)
        self.assertIn("EntitlementError.restoreFailed(", block)
        self.assertIn("nsError.code", block)
        self.assertNotIn("throw error", block)

    def test_products_can_retry_without_inventing_prices(self):
        provider = source("Monetization/StoreKitEntitlementProvider.swift")
        paywall = source("Monetization/PaywallView.swift")
        self.assertIn("Product.products(for: Set(productIDs))", provider)
        self.assertIn("for attempt in 1...2", provider)
        self.assertIn("if attempt == 2", provider)
        self.assertIn("logger.warning(\"Catálogo StoreKit parcial:", provider)
        self.assertIn("logger.error(\"Product.products failed:", provider)
        self.assertIn('Button("Reintentar")', paywall)
        self.assertIn('accessibilityIdentifier("pro-retry-products")', paywall)
        self.assertIn('Precios temporalmente no disponibles', paywall)
        self.assertIn('if let availabilityNotice = subscriptions.offerings.unavailableReason', paywall)
        self.assertIn("await subscriptions.loadOfferings()", paywall)
        self.assertIn("if subscriptions.isPro", paywall)
        self.assertIn("pro-active-entitlement", paywall)

    def test_product_ids_match_local_configuration(self):
        commercial = source("Monetization/CommercialConfig.swift")
        local = json.loads((ROOT / "Apps" / "Repera" / "Resources"
                            / "StoreKit" / "ReperaProducts.storekit")
                           .read_text(encoding="utf-8"))
        identifiers = {item["productID"]
                       for group in local["subscriptionGroups"]
                       for item in group["subscriptions"]}
        self.assertEqual(identifiers, {
            "com.app.repera.premium.monthly",
            "com.app.repera.premium.yearly",
        })
        for identifier in identifiers:
            self.assertIn(identifier, commercial)


class AIConnectionReliabilityTests(unittest.TestCase):
    def test_loading_failure_is_not_reported_as_empty(self):
        view = source("AIAccessView.swift")
        self.assertIn("hasLoadedConnections = true", view)
        self.assertIn("connectionsError = nil", view)
        self.assertIn("else if let connectionsError {", view)
        self.assertIn("else if hasLoadedConnections && tokens.isEmpty", view)
        self.assertIn('Button("Reintentar") { Task { await refreshTokens() } }', view)
        self.assertNotIn('"No se pudieron cargar las conexiones: \\(error.localizedDescription)"', view)

    def test_ai_actions_reflect_real_oauth_configuration(self):
        view = source("AIAccessView.swift")
        android_view = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt").read_text()
        android_launch = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIProviderLaunch.kt").read_text()
        self.assertIn("ChatGPT · pendiente de publicación", view)
        self.assertIn("Configurar Claude", view)
        self.assertIn("Grok · configuración manual", view)
        self.assertIn("guard provider.isAvailable, provider.id != \"grok\" else", view)
        self.assertIn("https://claude.ai/customize/connectors", view)
        self.assertNotIn('Text("Continuar con \\(provider.name)")', view)
        self.assertIn("AIProviderLaunch.urlFor(provider)", android_view)
        self.assertIn("ChatGPT · pendiente de publicación", android_view)
        self.assertIn("Grok · configuración manual", android_view)
        self.assertIn("https://claude.ai/customize/connectors", android_launch)
        self.assertIn('uri.host?.lowercase() == "chatgpt.com"', android_launch)
        self.assertNotIn('"grok" -> "https://grok.com/"', android_launch)

    def test_technical_ai_network_errors_are_not_displayed(self):
        view = source("AIAccessView.swift")
        mirror = source("AIChangeRequestStore.swift")
        android_store = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessStore.kt").read_text()
        self.assertIn("Reintentar catálogo", view)
        self.assertIn("Conservamos el último estado conocido", view)
        self.assertIn('category: "AIConnections"', view)
        self.assertNotIn('cambios propuestos: \\(error.localizedDescription)', mirror)
        self.assertNotIn('body.take(200)', android_store)
        self.assertNotIn('error.localizedMessage ?: ""', android_store.split("private fun runRefresh(", 1)[1].split("fun create(", 1)[0])
        self.assertIn('body.contains("42703")', android_store)

    def test_catalog_failure_preserves_last_known_oauth_provider(self):
        view = source("AIAccessView.swift")
        providers = view.split("private func refreshProviders() async", 1)[1]
        providers = providers.split("private func refreshTokens() async", 1)[0]
        self.assertNotIn("providers = providers.map", providers)

    def test_transient_mirror_failure_does_not_show_raw_network_error(self):
        mirror = source("AIChangeRequestStore.swift")
        sync = mirror.split("func syncCustomExercises(store:ReperaStore)", 1)[1]
        sync = sync.split("func decide(", 1)[0]
        self.assertNotIn("Catálogo personalizado pendiente:", sync)
        self.assertIn("return false", sync)


if __name__ == "__main__":
    unittest.main()
