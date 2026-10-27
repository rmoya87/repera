"""Contratos de regresión: entrenos planificados → Favoritos → reutilización.

Estos tests de fuente deben complementarse con tests iOS y sincronización.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain"
STORE = (SRC / "ReperaStore.swift").read_text(encoding="utf-8")
MODELS = (DOMAIN / "Sources" / "ReperaDomain" / "Models.swift").read_text(encoding="utf-8")
PREVIEW = (SRC / "SessionPreviewView.swift").read_text(encoding="utf-8")
EDITOR = (SRC / "PlanView.swift").read_text(encoding="utf-8")
HUB = (SRC / "FavoritesHubView.swift").read_text(encoding="utf-8")
HOME = (SRC / "HomeView.swift").read_text(encoding="utf-8")
PLAY = (SRC / "WorkoutView.swift").read_text(encoding="utf-8")


class PlannedWorkoutFavoritesContractTests(unittest.TestCase):
    def test_favorite_link_is_backward_compatible_codable(self):
        self.assertIn("public var favoriteTemplateId: UUID?", MODELS)
        self.assertIn("favoriteTemplateId: UUID? = nil", MODELS)
        self.assertIn("favoriteTemplateId = try c.decodeIfPresent(UUID.self", MODELS)
        self.assertIn("try c.encodeIfPresent(favoriteTemplateId, forKey: .favoriteTemplateId)", MODELS)
        self.assertIn("testOlderScheduledRoutinesWithoutFavoriteLinkRemainReadable", (
            DOMAIN / "Tests" / "ReperaDomainTests" / "WorkoutFavoriteCodableTests.swift"
        ).read_text(encoding="utf-8"))

    def test_scheduled_workout_is_copied_to_dated_independent_favorite(self):
        logic = STORE.split("func setRoutineFavorite(", 1)[1].split(
            "func removeFavorite(", 1
        )[0]
        self.assertIn("if source.scheduledDate != nil", logic)
        self.assertIn("source.blocks.map { $0.duplicatingContent() }", logic)
        self.assertIn("guard saveRoutine(template) else { return false }", logic)
        self.assertIn("state.routines[newIndex].favoriteTemplateId = template.id", logic)
        self.assertIn("state.routines[current].isFavorite = true", logic)
        self.assertIn("persist()", logic)

    def test_favorites_list_is_not_duplicated_by_dated_source(self):
        listing = STORE.split("var favoriteRoutines: [Routine]", 1)[1].split(
            "func routine(forWeekday", 1
        )[0]
        self.assertIn("$0.scheduledDate == nil || $0.favoriteTemplateId == nil", listing)
        self.assertIn("store.favoriteRoutines", HUB)
        self.assertIn("func saveAsFavorite(_ routine: Routine, title: String? = nil) -> Routine?", STORE)
        self.assertIn("guard saveRoutine(favorite) else { return nil }", STORE)

    def test_star_and_one_off_editor_surface_freemium_failure(self):
        self.assertIn("return store.setRoutineFavorite(", PREVIEW)
        self.assertIn("presentFavoriteLimitPaywall()", PREVIEW)
        oneoff = EDITOR.split("case .oneOff:\n            var draft = routine", 1)[1].split(
            "case .favorite:", 1
        )[0]
        self.assertIn("store.saveRoutine(draft)", oneoff)
        self.assertIn("store.setRoutineFavorite(draft.id, isFavorite: wantsFavorite)", oneoff)
        self.assertIn("presentRoutineLimitPaywall()", oneoff)

    def test_calendar_reuse_schedules_new_copy(self):
        self.assertIn("var targetDate: Date? = nil", HUB)
        self.assertIn("store.assignRoutine(routine.id, toDate: date)", HUB)
        self.assertIn("onScheduledWorkout?()", HUB)
        self.assertIn("targetDate: selectedDay", HOME)
        self.assertIn("onScheduledWorkout:", HOME)
        assign = STORE.split("func assignRoutine(_ routineId: UUID, toDate date: Date)", 1)[1].split(
            "func assignRoutine(_ routineId: UUID, toWeekday", 1
        )[0]
        self.assertIn("source.blocks.map { $0.duplicatingContent() }", assign)
        self.assertIn("isFavorite: false", assign)

    def test_removing_calendar_plan_does_not_remove_favorite(self):
        rem = STORE.split("func removeScheduledRoutine(id: UUID)", 1)[1].split(
            "func removeScheduledRoutine(on date:", 1
        )[0]
        self.assertIn("favoriteTemplateId == nil", rem)
        self.assertIn("state.routines.remove(at: index)", rem)
        self.assertIn("func clearWeeklySchedule", STORE)

    def test_play_uses_saved_reps_and_kilos_instead_of_history(self):
        # Favoritos y copias fechadas de favoritos nunca reciben objetivos
        # modificados por ProgressionEngine (ni por el default global).
        start = STORE.split("func startSession(from routine: Routine)", 1)[1].split(
            "func startSessionFromBoard(", 1
        )[0]
        self.assertIn("let base = SessionController.from(routine: routine,", start)
        self.assertIn(
            "routine.isFavorite || routine.favoriteTemplateId != nil", start
        )
        self.assertIn("routine.progression == .off", start)
        self.assertIn("if allowAdvanced && !usesExactPrescription", start)
        assign = STORE.split("func assignRoutine(_ routineId: UUID, toDate date: Date)", 1)[1].split(
            "func assignRoutine(_ routineId: UUID, toWeekday", 1
        )[0]
        self.assertIn("progression: source.isFavorite ? .off : source.progression", assign)

        # La tabla de Play se rellena con cada PlannedSet antes de consultar
        # pesos históricos; tampoco rellena celdas de peso vacío por defecto.
        view = PLAY.split("private func prefill()", 1)[1].split(
            "private func bumpWeightSuggestion", 1
        )[0]
        self.assertIn("let hasPrescription = !current.plannedSets.isEmpty", view)
        self.assertIn("current.plannedSets.first?.targetWeightKg", view)
        self.assertIn("if let suggested, !hasPrescription", view)
        board = PLAY.split("private func rebuildLiveSets(", 1)[1].split(
            "private func syncLiveQuantityUnit", 1
        )[0]
        self.assertIn("weightKg: loadField == .weightKg ? plannedSet.targetWeightKg : nil", board)
        self.assertIn("max(1, plannedSet.targetReps)", board)

        unit = (DOMAIN / "Tests" / "ReperaDomainTests" / "SessionControllerTests.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("testSavedFavoritePreservesIndividualRepsAndKilosWhenPlayingAgain", unit)
        self.assertIn("PlannedSet(targetReps: 8, targetWeightKg: 60)", unit)
        self.assertIn("PlannedSet(targetReps: 6, targetWeightKg: 65)", unit)
        self.assertIn("PlannedSet(targetReps: 4, targetWeightKg: 70)", unit)

    def test_active_session_preserves_plan_origin_and_saves_favorite_reference(self):
        method = STORE.split("func saveActiveSessionAsFavorite() -> Routine?", 1)[1].split(
            "private static func favoriteTemplate", 1
        )[0]
        self.assertIn("active.favoriteRoutineId = saved.id", method)
        self.assertNotIn("active.routineId = saved.id", method)
        self.assertIn("guard saveRoutine(template) else { return nil }", method)
        self.assertIn("store.saveActiveSessionAsFavorite() != nil", PLAY)
        self.assertIn("store.activeSessionIsFavorite", PLAY)
        self.assertIn("presentPaywall", PLAY)


if __name__ == "__main__":
    unittest.main()
