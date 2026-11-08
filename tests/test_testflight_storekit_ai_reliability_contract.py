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
        self.assertIn("logger.error(\"Product.products failed:", provider)
        self.assertIn('Button("Reintentar")', paywall)
        self.assertIn('accessibilityIdentifier("pro-retry-products")', paywall)
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

    def test_catalog_failure_preserves_last_known_oauth_provider(self):
        view = source("AIAccessView.swift")
        providers = view.split("private func refreshProviders() async", 1)[1]
        providers = providers.split("private func refreshTokens() async", 1)[0]
        self.assertNotIn("providers = providers.map", providers)

    def test_ai_instructions_are_per_provider_not_stacked(self):
        view = source("AIAccessView.swift")
        # Continuar abre el chat con el prompt; sin enlaces «Solo instrucciones»
        # ni pie largo en Elige tu asistente. Sheet solo en fallos / ChatGPT pendiente.
        section = view.split("private var connectionSection", 1)[1].split(
            "private func connectionVerified", 1
        )[0]
        self.assertNotIn("Solo instrucciones", section)
        self.assertNotIn("La conexión se configura dentro de cada asistente", section)
        self.assertNotIn('Button("Ver instrucciones")', view)
        self.assertIn("instructionsProvider", view)
        self.assertIn(".sheet(item: $instructionsProvider)", view)
        sheet = view.split(".sheet(item: $instructionsProvider)", 1)[1].split(
            ".confirmationDialog(", 1
        )[0]
        self.assertNotIn("ForEach(providers)", sheet)
        self.assertIn("AIProviderLaunch.instructions(for: provider)", sheet)

    def test_transient_mirror_failure_does_not_show_raw_network_error(self):
        mirror = source("AIChangeRequestStore.swift")
        sync = mirror.split("func syncCustomExercises(store:ReperaStore)", 1)[1]
        sync = sync.split("func decide(", 1)[0]
        self.assertNotIn("Catálogo personalizado pendiente:", sync)
        self.assertIn("return false", sync)


if __name__ == "__main__":
    unittest.main()
