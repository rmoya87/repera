"""Regresión: actividades deportivas sin series también son favoritas reutilizables."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODEL = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/Models.swift").read_text()
STORE = (ROOT / "Apps/Repera/Sources/ReperaStore.swift").read_text()
FAVORITES = (ROOT / "Apps/Repera/Sources/FavoritesHubView.swift").read_text()
HUB = (ROOT / "Apps/Repera/Sources/StartHubSheet.swift").read_text()
ROOT_VIEW = (ROOT / "Apps/Repera/Sources/RootTabView.swift").read_text()
HISTORY = (ROOT / "Apps/Repera/Sources/HistoryView.swift").read_text()


class SportFavoriteContractTests(unittest.TestCase):
    def test_personal_icloud_state_carries_sports_and_reads_old_documents(self):
        self.assertIn("public struct FavoriteSportActivity:", MODEL)
        self.assertIn("public var favoriteSportActivities: [FavoriteSportActivity]", MODEL)
        self.assertIn(
            "favoriteSportActivities = try c.decodeIfPresent([FavoriteSportActivity].self",
            MODEL,
        )
        self.assertIn("try c.encode(favoriteSportActivities, forKey: .favoriteSportActivities)", MODEL)

    def test_sports_with_no_exercises_do_not_create_fake_strength_sets(self):
        toggle = STORE.split("func toggleWorkoutFavorite(_ id: UUID) -> Bool", 1)[1].split(
            "var activeSessionIsFavorite", 1
        )[0]
        self.assertIn("let sportID = session.liveSportID", toggle)
        self.assertIn("state.favoriteSportActivities.append(FavoriteSportActivity(", toggle)
        self.assertIn("state.favoriteSportActivities.remove(at: existingIndex)", toggle)
        self.assertIn("guard decision.allowed else {", toggle)
        self.assertIn("let originalPlan = session.routineId.flatMap", toggle)
        self.assertIn("lastFavoriteSaveError = session.liveSportID != nil", toggle)
        self.assertIn("func removeFavoriteSportActivity(_ id: UUID)", STORE)
        self.assertIn("if state.favoriteSportActivities.contains", STORE)

    def test_favorites_display_and_launch_live_activity(self):
        self.assertIn('Section("Actividades")', FAVORITES)
        self.assertIn("onOpenSport?(activity.sportID)", FAVORITES)
        self.assertIn("store.removeFavoriteSportActivity(activity.id)", FAVORITES)
        self.assertIn("onOpenSport: onOpenSport", HUB)
        self.assertIn("LiveActivityRecorder.shared.choose(sport)", ROOT_VIEW)
        self.assertIn("tab = .start", ROOT_VIEW)

    def test_history_uses_real_save_error_and_live_entitlement(self):
        self.assertIn("store.featureAccess = { [subscriptions] in subscriptions.policy }", HISTORY)
        self.assertIn("store.lastFavoriteSaveError", HISTORY)
        self.assertIn("subscriptions.refreshEntitlementsForFeatureAction()", HISTORY)


if __name__ == "__main__":
    unittest.main()
