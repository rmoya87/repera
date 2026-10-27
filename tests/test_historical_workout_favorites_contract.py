"""Regresiones de historial -> favorito -> plantilla reutilizable.

Contratos estáticos. Se requiere además ejecución Swift/iPhone para E2E.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"
STORE = (SOURCES / "ReperaStore.swift").read_text(encoding="utf-8")
HISTORY = (SOURCES / "HistoryView.swift").read_text(encoding="utf-8")
HUB = (SOURCES / "FavoritesHubView.swift").read_text(encoding="utf-8")


class HistoricalWorkoutFavoritesContractTests(unittest.TestCase):
    def test_history_star_checks_success_and_surfaces_paywall_or_error(self):
        self.assertIn("guard store.toggleWorkoutFavorite(sessionId) else {", HISTORY)
        self.assertIn("store.lastAccessDenial", HISTORY)
        self.assertIn("subscriptions.presentPaywall(", HISTORY)
        self.assertIn("favoriteSaveError", HISTORY)
        self.assertIn("store.isWorkoutFavorite(sessionId) ? \"star.fill\" : \"star\"", HISTORY)

    def test_completed_session_builds_new_favorite_without_changing_plan(self):
        code = STORE.split("func toggleWorkoutFavorite(_ id: UUID) -> Bool", 1)[1].split(
            "var activeSessionIsFavorite", 1
        )[0]
        self.assertIn("let session = state.workouts[workoutIndex]", code)
        self.assertIn("let template = Self.favoriteTemplate(from: session)", code)
        self.assertIn("guard saveRoutine(template) else { return false }", code)
        self.assertIn("state.workouts[workoutIndex].favoriteRoutineId = template.id", code)
        self.assertIn("original.isFavorite", code)
        self.assertIn("return true", code)

    def test_recovered_sessions_require_no_current_schedule(self):
        method = STORE.split("func toggleWorkoutFavorite(_ id: UUID) -> Bool", 1)[1].split(
            "var activeSessionIsFavorite", 1
        )[0]
        self.assertIn("guard hasReusableBlocks || !session.exercises.isEmpty else { return false }", method)
        self.assertIn("Self.favoriteTemplate(from: session)", method)
        self.assertIn("func isWorkoutFavorite(_ id: UUID)", STORE)

    def test_full_snapshot_and_fallback_preserve_prescription(self):
        builder = STORE.split("private static func favoriteTemplate(from session: WorkoutSession)", 1)[1].split(
            "// MARK: - Favorite timers", 1
        )[0]
        self.assertIn("session.routineBlocks", builder)
        self.assertIn("snapshot.map { $0.duplicatingContent() }", builder)
        self.assertIn("item.plannedSets.map { $0.duplicatingContent() }", builder)
        self.assertIn("item.loggedSets.filter { $0.phase == .work }", builder)
        self.assertIn("targetWeightKg: $0.weightKg", builder)
        self.assertIn("targetDurationSeconds: $0.durationSeconds", builder)
        self.assertIn("explicitPlannedSets: sets.isEmpty ? nil : sets", builder)
        self.assertIn("restBetweenRoundsSeconds: sample.blockRestBetweenRoundsSeconds", builder)
        self.assertIn("progression: .off", builder)

    def test_create_favorites_renders_saved_templates(self):
        self.assertIn("state.routines", STORE.split("var favoriteRoutines: [Routine]", 1)[1])
        self.assertIn("store.favoriteRoutines", HUB)
        self.assertIn("store.assignRoutine(routine.id, toDate: date)", HUB)


if __name__ == "__main__":
    unittest.main()
