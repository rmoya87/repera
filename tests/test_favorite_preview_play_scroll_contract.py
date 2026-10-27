"""Contratos: vista previa de favorito, Play, edición y cabecera desplazable.

Valida la integración de fuentes SwiftUI; compilar y probar en iPhone sigue
siendo obligatorio para comprobar la interacción real.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"

def read(name):
    return (SOURCES / name).read_text(encoding="utf-8")

class FavoritePreviewPlayAndHeaderTests(unittest.TestCase):
    def test_title_and_day_scroll_with_list_below_actions_toolbar(self):
        preview = read("SessionPreviewView.swift")
        body = preview.split("var body: some View {", 1)[1]
        self.assertIn("List {", body)
        self.assertIn('OGScrollablePageTitle(active != nil ? "Sesión" : "Entreno")', body)
        self.assertIn('Text("Entreno · \\(dayLabel)")', body)
        self.assertIn(".ogScrollingTitleListRow()", body)
        self.assertIn(".ogScrollingTitleNav()", body)
        self.assertNotIn(".safeAreaInset(edge: .top", body)
        self.assertLess(body.index("OGScrollablePageTitle("), body.index("if let active {"))
        self.assertLess(body.index("OGScrollablePageTitle("), body.index("if let routine = liveRoutine {"))
        self.assertIn("ToolbarItem(placement: .topBarLeading)", body)
        self.assertIn("ToolbarItem(placement: .topBarTrailing)", body)

    def test_play_starts_visible_favorite_and_opens_only_confirmed_session(self):
        preview = read("SessionPreviewView.swift")
        start = preview.split("private func startVisibleRoutine()", 1)[1].split(
            "private func presentFavoriteLimitPaywall", 1
        )[0]
        self.assertIn("guard let routine = liveRoutine else { return }", start)
        self.assertIn("store.startSession(from: routine)", start)
        self.assertIn("started.routineId == routine.id", start)
        self.assertIn("startFailureMessage = HealthKitStore.shared.lastError", start)
        self.assertLess(start.index("started.routineId == routine.id"), start.index("onStart()"))
        self.assertIn("Button {\n                        startVisibleRoutine()", preview)
        self.assertIn('.alert("No se ha podido iniciar el entreno"', preview)

    def test_edit_uses_live_routine_and_correct_mode(self):
        preview = read("SessionPreviewView.swift")
        root = read("RootTabView.swift")
        editor = read("PlanView.swift")
        self.assertIn("if let routine = liveRoutine {\n                                onEdit(routine)", preview)
        self.assertIn("flowPath.append(.editWorkout(routineId: routine.id))", root)
        self.assertIn("if let routine = resolvePreviewRoutine(id: routineId)", root)
        self.assertIn("routine.isOneOff", root)
        self.assertIn(".oneOff(isNew: false)", root)
        self.assertIn("routine.isFavorite ? .favorite(isNew: false) : .plan(isNew: false)", root)
        self.assertIn("case .favorite:\n            var draft = routine", editor)
        self.assertIn("draft.isFavorite = true", editor)
        self.assertIn("guard store.saveRoutine(draft)", editor)

    def test_favorites_hub_start_uses_real_session_and_explains_failure(self):
        hub = read("FavoritesHubView.swift")
        self.assertIn("store.startSession(from: routine)", hub)
        self.assertIn("store.state.activeSession?.routineId == routine.id", hub)
        self.assertIn("startFailureMessage = HealthKitStore.shared.lastError", hub)
        self.assertIn('.alert("No se ha podido iniciar el favorito"', hub)
        self.assertIn("onOpenedWorkout()", hub)

    def test_saved_prescription_is_still_authoritative(self):
        store = read("ReperaStore.swift")
        start = store.split("func startSession(from routine: Routine)", 1)[1].split(
            "func startSessionFromBoard(", 1
        )[0]
        self.assertIn("routine.isFavorite || routine.favoriteTemplateId != nil", start)
        self.assertIn("let base = SessionController.from(routine: routine,", start)
        self.assertIn("if allowAdvanced && !usesExactPrescription", start)

if __name__ == "__main__":
    unittest.main()
