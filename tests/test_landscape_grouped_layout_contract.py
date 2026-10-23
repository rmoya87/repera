"""Contratos estáticos de cajas agrupadas en retrato y apaisado (iOS 27).

No sustituyen capturas ni pruebas visuales en iPhone horizontal.
"""
import unittest
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def read(name: str) -> str:
    return (SRC / name).read_text(encoding="utf-8")


class LandscapeGroupedLayoutTests(unittest.TestCase):
    def test_shared_list_matches_progress_margins_in_both_orientations(self):
        theme = read("Theme.swift")
        modifier = theme.split("private struct OGListChromeModifier:", 1)[1].split(
            "extension View {", 1
        )[0]
        self.assertIn(".listStyle(.insetGrouped)", modifier)
        self.assertIn(".contentMargins(.horizontal, OG.pad, for: .scrollContent)", modifier)
        self.assertIn(".listSectionSpacing(12)", modifier)
        self.assertIn("OG.bg.ignoresSafeArea()", modifier)
        self.assertNotIn("verticalSizeClass == .compact", modifier)
        self.assertNotIn("OG.pad + 12", modifier)
        self.assertNotIn(".contentMargins(.all", modifier)
        self.assertNotIn(".padding(.horizontal", modifier)
        self.assertNotIn(".clipShape(", modifier)

    def test_editor_and_play_share_native_grouped_sections(self):
        editor = read("PlanView.swift")
        self.assertIn("struct DayEditorView", editor)
        self.assertIn(".listStyle(.insetGrouped)\n        .ogListChrome()", editor)
        self.assertGreaterEqual(editor.count(".ogListChrome()"), 5)
        play = read("WorkoutView.swift")
        section = play.split("private func content(_ session: WorkoutSession)", 1)[1]
        section = section.split("private func workoutExerciseRow(", 1)[0]
        self.assertIn("List {", section)
        self.assertIn(".listStyle(.insetGrouped)\n        .ogListChrome()", section)
        self.assertNotIn(".environment(\\.horizontalSizeClass, .regular)", section)

    def test_diary_and_exercise_lists_use_same_host_level_margins(self):
        diary = read("PlanView.swift").split("struct PlanView:", 1)[1].split(
            "struct DayEditorView:", 1
        )[0]
        self.assertIn(".listStyle(.insetGrouped)\n            .ogListChrome()", diary)
        exercise = read("LibraryView.swift")
        root = exercise.split("var body: some View {", 1)[1].split(
            ".scrollDismissesKeyboard(.interactively)", 1
        )[0]
        # Aplicar chrome al Group NO garantiza que el margen llegue a
        # ambas List hijas cuando la búsqueda cambia Ejercicios <-> WODs.
        self.assertNotIn(".ogListChrome()", root)
        wod = exercise.split("private var wodsList: some View", 1)[1].split(
            "private var filteredWODTemplates", 1
        )[0]
        catalog = exercise.split("private struct LibraryExerciseList:", 1)[1]
        catalog = catalog.split("@ViewBuilder", 1)[0]
        for list_view in (wod, catalog):
            self.assertIn(".listStyle(.insetGrouped)", list_view)
            self.assertIn(".ogListChrome()", list_view)

    def test_other_list_pages_reuse_chrome_not_duplicate_padding(self):
        for filename in (
            "HistoryView.swift", "SettingsView.swift",
            "FavoritesHubView.swift", "ExerciseCatalogSearchList.swift",
        ):
            self.assertIn(".ogListChrome()", read(filename), filename)
        theme = read("Theme.swift")
        self.assertIn("func ogListChrome() -> some View {\n        modifier(OGListChromeModifier())", theme)

    def test_home_calendar_is_centered_and_all_seven_days_fit_vertically(self):
        home = read("HomeView.swift")
        calendar = home.split("private var weekSelectorCard: some View {", 1)[1].split(
            "private func calendarDayColumn(", 1
        )[0]
        self.assertIn("let side = min(", calendar)
        self.assertIn("weekCarouselHeight - 8", calendar)
        self.assertIn("(geo.size.width - spacing * 6) / 7", calendar)
        self.assertIn(".frame(maxWidth: calendarVisibleWidth)", calendar)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", calendar)
        self.assertIn(".padding(.horizontal, OG.pad)", calendar)
        self.assertIn("7 * max(1, weekCarouselHeight - 8) + 6 * 4", home)
        self.assertIn("frame(height: weekCarouselHeight)", calendar)
        # El fondo inferior gris no permite que asome el fondo blanco
        # en los laterales seguros del iPhone colocado en horizontal.
        self.assertIn(".background(OG.bg.ignoresSafeArea(edges: .horizontal))", home)
        self.assertIn(".background(OG.bg.ignoresSafeArea(edges: .bottom))", home)

    def test_home_and_exercise_hero_keep_intentional_edge_to_edge(self):
        home = read("HomeView.swift")
        self.assertIn(".background(OG.surface)", home)
        detail = read("ExerciseDetailView.swift")
        self.assertIn("Imagen edge-to-edge", detail)
        self.assertIn(".padding(.horizontal, OG.pad)", detail)
        self.assertNotIn("ogListChrome()", detail)


if __name__ == "__main__":
    unittest.main()
