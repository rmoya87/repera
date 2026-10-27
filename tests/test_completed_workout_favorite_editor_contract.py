"""Regresión: la edición de un entrenamiento terminado guarda su favorito en Pro.

Estas comprobaciones de fuente no sustituyen probar TestFlight y un iPhone real.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"
EDITOR = (SRC / "PlanView.swift").read_text(encoding="utf-8")
HISTORY = (SRC / "HistoryView.swift").read_text(encoding="utf-8")
STORE = (SRC / "ReperaStore.swift").read_text(encoding="utf-8")
SUBSCRIPTIONS = (SRC / "Monetization" / "SubscriptionManager.swift").read_text(encoding="utf-8")


class CompletedFavoriteEditorContractTests(unittest.TestCase):
    def test_confirmation_is_async_and_reentrant_safe(self):
        self.assertIn("guard !isConfirmingSave else { return }", EDITOR)
        self.assertIn("await confirmWithVerifiedAccess()", EDITOR)
        self.assertIn("private func confirmWithVerifiedAccess() async", EDITOR)

    def test_completed_editor_verifies_pro_and_links_existing_favorite(self):
        completed = EDITOR.split("if let onApplyCompleted, let completedDetails", 1)[1].split(
            "if let onApplyDraft", 1
        )[0]
        self.assertIn("completedDetails.favoriteRoutineId.flatMap", completed)
        self.assertIn("id: prior?.id ?? UUID()", completed)
        self.assertIn("guard await saveRoutineWithVerifiedAccess(favorite) else { return }", completed)
        self.assertIn("detailsToSave.favoriteRoutineId = favorite.id", completed)
        self.assertIn("onApplyCompleted(edited, detailsToSave)", completed)
        self.assertIn("progression: .off", completed)

    def test_quota_denial_triggers_entitlement_refresh_and_retry(self):
        helper = EDITOR.split("private func saveRoutineWithVerifiedAccess(", 1)[1].split(
            "private func setRoutineFavoriteWithVerifiedAccess(", 1
        )[0]
        self.assertIn("if store.saveRoutine(candidate) { return true }", helper)
        self.assertIn("if store.lastAccessDenial != nil", helper)
        self.assertIn("await subscriptions.refreshEntitlementsForFeatureAction()", helper)
        self.assertIn("store.featureAccess = { [subscriptions] in subscriptions.policy }", helper)
        self.assertEqual(helper.count("store.saveRoutine(candidate)"), 2)
        self.assertIn("presentRoutineLimitPaywall()", helper)

    def test_failure_message_distinguishes_unverified_purchase_from_free_quota(self):
        modal = EDITOR.split("private func presentRoutineLimitPaywall()", 1)[1].split(
            "/// Al editar una sesión terminada", 1
        )[0]
        self.assertIn("guard let decision = store.lastAccessDenial, !decision.allowed", modal)
        self.assertIn("subscriptions.snapshot.status == .unknown", modal)
        self.assertIn("No hemos podido verificar tu suscripción", modal)
        self.assertIn("subscriptions.policy.isPro", modal)
        self.assertIn("subscriptions.presentPaywall(", modal)
        self.assertNotIn("Revisa sus datos y vuelve a intentarlo", modal)

    def test_history_saves_editor_result_preserving_identity(self):
        self.assertIn("CompletedWorkoutEditing.applying(", HISTORY)
        self.assertIn("store.saveWorkout(updated)", HISTORY)
        self.assertIn("func isWorkoutFavorite(_ id: UUID)", STORE)
        self.assertIn("session.favoriteRoutineId", STORE)
        self.assertIn("func refreshEntitlementsForFeatureAction() async", SUBSCRIPTIONS)


if __name__ == "__main__":
    unittest.main()
