"""Contratos estáticos de cajas agrupadas en retrato y apaisado (iOS 27).

No sustituyen capturas ni pruebas visuales en iPhone horizontal.
"""
import unittest
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def read(name: str) -> str:
    return (SRC / name).read_text(encoding="utf-8")


class LandscapeGroupedLayoutTests(unittest.TestCase):
    def test_shared_list_constrains_its_entire_width_not_just_scroll_rows(self):
        theme = read("Theme.swift")
        self.assertIn("static let contentColumnMaxWidth: CGFloat = 790", theme)
        modifier = theme.split("private struct OGListChromeModifier:", 1)[1].split(
            "extension View {", 1
        )[0]
        self.assertIn(".listStyle(.insetGrouped)", modifier)
        self.assertIn(".listSectionSpacing(12)", modifier)
        self.assertIn("OG.bg.ignoresSafeArea()", modifier)
        self.assertIn(".frame(maxWidth: OG.contentColumnMaxWidth)", modifier)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", modifier)
        self.assertNotIn(".contentMargins(.horizontal", modifier)
        self.assertNotIn(".safeAreaPadding(.horizontal", modifier)
        self.assertNotIn(".padding(.horizontal", modifier)
        self.assertNotIn(".clipShape(", modifier)
        # En el tamaño de la captura (~905 pt), la columna deja aprox.
        # 57,5 pt por lado ANTES del insetGroup nativo (~16-20 pt).
        viewport = 905
        max_width = 790
        self.assertAlmostEqual((viewport - max_width) / 2, 57.5)

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
        self.assertIn(".clipped()", calendar)
        self.assertLess(calendar.index(".frame(maxWidth: calendarVisibleWidth)"), calendar.index(".clipped()"))
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", calendar)
        self.assertIn(".padding(.horizontal, OG.pad)", calendar)
        self.assertIn("7 * max(1, weekCarouselHeight - 8) + 6 * 4", home)
        self.assertIn("frame(height: weekCarouselHeight)", calendar)
        # El fondo inferior gris no permite que asome el fondo blanco
        # en los laterales seguros del iPhone colocado en horizontal.
        self.assertIn(".background(OG.bg.ignoresSafeArea(edges: .horizontal))", home)
        self.assertIn(".background(OG.bg.ignoresSafeArea(edges: .bottom))", home)
        self.assertIn(".background(OG.surface.ignoresSafeArea(edges: [.top, .horizontal]))", home)
        self.assertIn("OG.bg.ignoresSafeArea()", home)
        self.assertNotIn("OG.surface.ignoresSafeArea()\n            }\n            .onAppear", home)

    def test_only_first_home_section_is_edge_to_edge(self):
        home = read("HomeView.swift")
        top = home.split("var body: some View {", 1)[1].split(
            "// Progreso/Actividad conservan", 1
        )[0]
        self.assertIn(".background(OG.surface.ignoresSafeArea(edges: [.top, .horizontal]))", top)
        self.assertNotIn(".ogReadableColumn()", top)
        bottom = home.split("// Progreso/Actividad conservan", 1)[1].split(
            ".refreshable", 1
        )[0]
        self.assertIn(".ogReadableColumn()", bottom)
        self.assertIn(".background(OG.bg.ignoresSafeArea(edges: .horizontal))", bottom)
        detail = read("ExerciseDetailView.swift")
        self.assertIn(".ogReadableColumn()", detail)
        self.assertIn(".padding(.horizontal, OG.pad)", detail)

    def test_scroll_views_share_same_center_column_as_list(self):
        theme = read("Theme.swift")
        readable = theme.split("private struct OGReadableColumnModifier:", 1)[1].split(
            "private struct OGListChromeModifier:", 1
        )[0]
        self.assertIn(".frame(maxWidth: OG.contentColumnMaxWidth)", readable)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", readable)
        for file in (
            "StatsView.swift", "ExerciseDetailView.swift",
            "ExerciseProgressView.swift", "CenterView.swift", "HomeView.swift",
        ):
            self.assertIn(".ogReadableColumn()", read(file), file)
        quick = read("QuickLogSheet.swift")
        self.assertIn(".ogReadableColumn()", quick)


if __name__ == "__main__":
    unittest.main()
