"""Contrato de topbars iOS 27: gris agrupado salvo Inicio transparente.

Las comprobaciones previenen una regresión del background nativo al plegar
un large title, pero la apariencia final requiere una compilación en iPhone.
"""
import unittest
from pathlib import Path

SOURCES = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def read(name: str) -> str:
    return (SOURCES / name).read_text(encoding="utf-8")


class NavigationBackgroundContractTests(unittest.TestCase):
    def test_native_secondary_navigation_is_translucent_not_opaque(self):
        theme = read("Theme.swift")
        method = theme.split("func ogTransparentNav() -> some View {", 1)[1].split("    }", 1)[0]
        self.assertIn(".toolbarBackground(.thinMaterial, for: .navigationBar)", method)
        self.assertIn(".toolbarBackground(.automatic, for: .navigationBar)", method)
        self.assertNotIn(".toolbarBackground(OG.bg, for: .navigationBar)", method)
        self.assertNotIn(".toolbarBackground(.visible, for: .navigationBar)", method)
        self.assertNotIn(".toolbarBackground(.hidden", method)
        self.assertIn("static let bg = adaptive(", theme)

    def test_pinned_large_titles_share_gray_toolbar_on_scroll(self):
        theme = read("Theme.swift")
        pinned = theme.split("func ogPinnedTransparentNav(", 1)[1].split("    }", 1)[0]
        self.assertIn(".navigationBarTitleDisplayMode(.large)", pinned)
        self.assertIn(".toolbar(.visible, for: .navigationBar)", pinned)
        self.assertIn(".ogTransparentNav()", pinned)
        for file in (
            "PlanView.swift", "HistoryView.swift", "SettingsView.swift",
            "ExerciseDetailView.swift", "ExerciseProgressView.swift",
            "WODCatalogPickerView.swift", "HealthRecovery.swift",
        ):
            self.assertIn(".ogPinnedTransparentNav(", read(file), file)

    def test_custom_content_nav_stays_transparent_for_home(self):
        theme = read("Theme.swift")
        custom = theme.split("func ogContentTitleNav() -> some View {", 1)[1].split("    }", 1)[0]
        self.assertIn(".toolbarBackground(.hidden, for: .navigationBar)", custom)
        self.assertIn(".toolbar(.hidden, for: .navigationBar)", custom)
        self.assertNotIn(".ogTransparentNav()", custom)
        home = read("HomeView.swift")
        self.assertIn('.ogFixedTopBar("repera"', home)
        self.assertNotIn(".ogTransparentNav()", home)
        self.assertIn(".background(OG.surface)", home)

    def test_inline_navigation_and_manual_titles_do_not_turn_white(self):
        self.assertIn(".ogTransparentNav()", read("WorkoutView.swift"))
        for file in ("AIAccessView.swift", "AITrainingProgramsView.swift",
                     "BusinessCenterViews.swift", "MessagesInboxView.swift"):
            self.assertIn(".ogTransparentNav()", read(file), file)
        access = read("AIAccessView.swift")
        self.assertIn('.navigationTitle("Acceso IA")', access)
        self.assertIn('.navigationTitle("Nuevo token")', access)
        self.assertGreaterEqual(access.count(".ogTransparentNav()"), 2)



    def test_diary_style_transparent_bars_are_scoped_to_requested_screens(self):
        theme = read("Theme.swift")
        style = theme.split("func ogDiaryTransparentNav() -> some View {", 1)[1].split("    }", 1)[0]
        self.assertIn(".toolbarBackground(.hidden, for: .navigationBar)", style)
        for file in (
            "LibraryView.swift", "FavoritesHubView.swift", "QuickLogPickerView.swift",
            "QuickLogSheet.swift", "StandaloneTimerView.swift",
            "ExerciseDetailView.swift", "ExerciseProgressView.swift",
        ):
            self.assertIn(".ogDiaryTransparentNav()", read(file), file)
        exercise_progress = read("ExerciseProgressView.swift")
        self.assertLess(
            exercise_progress.index(".ogPinnedTransparentNav("),
            exercise_progress.index(".ogDiaryTransparentNav()")
        )
        for file in ("HistoryView.swift", "SettingsView.swift", "WorkoutView.swift"):
            self.assertNotIn(".ogDiaryTransparentNav()", read(file), file)

    def test_timer_numeric_inputs_replace_visible_plus_minus_controls(self):
        timer = read("StandaloneTimerView.swift")
        form = timer.split("private func compactIntRow(", 1)[1].split("private func persistFavorite()", 1)[0]
        self.assertIn('TimerNumericInput(label: "RONDAS"', form)
        self.assertIn('TimerNumericInput(label: "MIN"', form)
        self.assertIn('TimerNumericInput(label: "SEG"', form)
        self.assertIn("range: 0...59", form)
        self.assertNotIn("minusPlus(", form)
        self.assertNotIn("bumpTime(", form)
        self.assertNotIn('Image(systemName: "plus")', form)
        self.assertNotIn('Image(systemName: "minus")', form)
        input_view = timer.split("private struct TimerNumericInput:", 1)[1].split("struct StandaloneTimerView:", 1)[0]
        self.assertIn("OGNumericTextField(", input_view)
        self.assertIn("_draft = State(initialValue: String(value.wrappedValue))", input_view)
        self.assertIn("range.contains(parsed)", input_view)
        self.assertIn("min(range.upperBound, max(range.lowerBound, parsed))", input_view)
        self.assertIn(".background(OG.surface2, in: RoundedRectangle", input_view)

if __name__ == "__main__":
    unittest.main()
