"""Regresión: Favoritos nunca presenta otra compra a un atleta con Pro.

Son contratos estáticos; las compras y la UI deben verificarse también
en sandbox/TestFlight, con un usuario Pro y uno Gratis.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
MONETIZATION = IOS / "Monetization"


def read(path):
    return path.read_text(encoding="utf-8")


class FavoriteProEntitlementContractTests(unittest.TestCase):
    def test_paywall_coordinator_refuses_paid_accounts(self):
        manager = read(MONETIZATION / "SubscriptionManager.swift")
        gate = manager.split("func presentPaywall(", 1)[1].split("func dismissPaywall(", 1)[0]
        self.assertIn("guard !policy.isPro else { return }", gate)
        self.assertIn("policy.canAccess(feature)", gate)
        self.assertIn("paywall.present(context)", gate)

    def test_purchase_rights_refresh_on_user_action(self):
        manager = read(MONETIZATION / "SubscriptionManager.swift")
        self.assertIn("func refreshEntitlementsForFeatureAction() async", manager)
        self.assertIn('await refresh(reason: "feature-gate")', manager)
        self.assertIn("verifiedAppleAccessIfNeeded(next)", manager)
        self.assertIn("guard verified.grantsProAccess else { return snapshot }", manager)
        self.assertIn("provider = apple", manager)

    def test_restore_falls_back_to_verified_apple_transaction(self):
        manager = read(MONETIZATION / "SubscriptionManager.swift")
        restore = manager.split("func restorePurchases() async -> Bool", 1)[1].split(
            "private func refresh(reason:", 1
        )[0]
        self.assertIn("try await provider.restore()", restore)
        self.assertIn("try? await apple.restore()", restore)
        self.assertIn("await apple.refresh()", restore)
        self.assertIn("if appleSnapshot.grantsProAccess", restore)
        self.assertIn("provider = apple", restore)
        self.assertIn("verifiedRestore = true", restore)
        self.assertIn("if verifiedRestore {", restore)

    def test_active_workout_does_not_assume_all_failures_are_quotas(self):
        view = read(IOS / "WorkoutView.swift")
        code = view.split("private func saveCurrentWorkoutFavorite() async", 1)[1].split(
            "private func closeFlow()", 1
        )[0]
        self.assertIn("persistActiveLiveDraft()", code)
        self.assertIn("guard store.saveActiveSessionAsFavorite() != nil else", code)
        self.assertIn("if store.lastAccessDenial != nil", code)
        self.assertIn("await subscriptions.refreshEntitlementsForFeatureAction()", code)
        self.assertIn("!subscriptions.policy.isPro", code)
        self.assertIn("favoriteSaveError =", code)
        self.assertNotIn("?? subscriptions.canCreateLibraryRoutine", code)

    def test_preview_and_history_give_errors_not_paywall_for_pro(self):
        preview = read(IOS / "SessionPreviewView.swift")
        history = read(IOS / "HistoryView.swift")
        self.assertIn("await subscriptions.refreshEntitlementsForFeatureAction()", preview)
        self.assertIn("await subscriptions.refreshEntitlementsForFeatureAction()", history)
        self.assertIn("!subscriptions.policy.isPro", preview)
        self.assertIn("!subscriptions.policy.isPro", history)
        self.assertIn("favoriteSaveError", preview)
        self.assertIn("favoriteSaveError", history)

    def test_gps_sports_save_as_activity_favorites_even_with_restored_snapshots(self):
        store = read(IOS / "ReperaStore.swift")
        action = store.split("func toggleWorkoutFavorite(_ id: UUID) -> Bool {", 1)[1].split(
            "func removeFavoriteSportActivity(", 1
        )[0]
        sport_branch = action.index("if let sportID = session.liveSportID, !sportID.isEmpty {")
        reusable_blocks = action.index("let hasReusableBlocks =")
        self.assertLess(sport_branch, reusable_blocks)
        self.assertNotIn("if session.exercises.isEmpty,", action)
        self.assertIn("state.favoriteSportActivities.append(FavoriteSportActivity(", action)
        self.assertIn("legacyFavoriteIDs", action)

    def test_settings_explain_apple_sandbox_and_offline_cache(self):
        settings = read(IOS / "SettingsView.swift")
        self.assertIn("Las compras de prueba de TestFlight", settings)
        self.assertIn("Acceso Pro conservado desde la última verificación", settings)
        self.assertIn("subscriptions.snapshot.grantsProAccess", settings)

    def test_pro_bypasses_every_limited_creation_gate(self):
        policy = read(
            ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"
            / "Monetization" / "FeatureAccessPolicy.swift"
        )
        self.assertIn("guard isNew, !isPro else { return .allow() }", policy)
        self.assertIn("guard !isPro else { return .allow() }", policy)
        self.assertIn("func canCreateFavorite(isNew: Bool)", policy)
        self.assertIn("FreePlanLimits.maxFavoriteItems", policy)

    def test_fourth_favorite_uses_separate_count(self):
        store = read(IOS / "ReperaStore.swift")
        limits = read(
            ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"
            / "Monetization" / "ReperaFeature.swift"
        )
        self.assertIn("public static let maxFavoriteItems = 3", limits)
        self.assertIn("var favoriteCount: Int", store)
        self.assertIn("policy.favoriteCount = favoriteCount", store)
        self.assertIn("policy.canCreateFavorite(isNew: true)", store)
        self.assertIn("policy.canCreateFavorite(isNew: true)", read(IOS / "ReperaStore.swift"))

    def test_favorite_error_button_has_requested_day_night_contrast(self):
        view = read(IOS / "HistoryView.swift")
        self.assertIn("foregroundStyle(colorScheme == .dark ? Color.black : Color.white)", view)
        self.assertIn(".background(OG.accent, in: Capsule())", view)
        self.assertIn('accessibilityIdentifier("favorite-error-accept")', view)

    def test_store_clears_stale_access_denials(self):
        store = read(IOS / "ReperaStore.swift")
        for signature in (
            "func saveAsFavorite(_ routine: Routine, title: String? = nil) -> Routine? {",
            "func saveActiveSessionAsFavorite() -> Routine? {",
            "func setRoutineFavorite(_ id: UUID, isFavorite: Bool) -> Bool {",
        ):
            body = store.split(signature, 1)[1].split("\n", 3)[0:3]
            self.assertIn("lastAccessDenial = nil", "\n".join(body))


if __name__ == "__main__":
    unittest.main()
