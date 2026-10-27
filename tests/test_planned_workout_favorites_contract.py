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
        self.assertIn("guard store.setRoutineFavorite(", PREVIEW)
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
