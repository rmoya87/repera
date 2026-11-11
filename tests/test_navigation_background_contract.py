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
        # Transparencia real: sin material ni fondo opaco (Liquid Glass iOS 26+).
        self.assertIn(".toolbarBackground(.hidden, for: .navigationBar)", method)
        self.assertNotIn(".toolbarBackground(OG.bg, for: .navigationBar)", method)
        self.assertNotIn(".toolbarBackground(.thinMaterial, for: .navigationBar)", method)
        self.assertNotIn(".toolbarBackground(.visible, for: .navigationBar)", method)
        self.assertIn("static let bg = adaptive(", theme)

    def test_pinned_large_titles_share_gray_toolbar_on_scroll(self):
        theme = read("Theme.swift")
        pinned = theme.split("func ogPinnedTransparentNav(", 1)[1].split("    }", 1)[0]
        self.assertIn(".navigationBarTitleDisplayMode(.large)", pinned)
        self.assertIn(".toolbar(.visible, for: .navigationBar)", pinned)
        self.assertIn(".ogTransparentNav()", pinned)
        # Preferido: título en contenido (ogScrollingTitleNav). pinned queda
        # para detalle de sesión/actividad con large title nativo.
        for file in (
            "PlanView.swift", "SettingsView.swift",
            "ExerciseDetailView.swift", "ExerciseProgressView.swift",
            "WODCatalogPickerView.swift", "HealthRecovery.swift",
        ):
            src = read(file)
            self.assertTrue(
                ".ogScrollingTitleNav(" in src or ".ogPinnedTransparentNav(" in src,
                file,
            )
        self.assertIn(".ogPinnedTransparentNav(", read("HistoryView.swift"))

    def test_custom_content_nav_stays_transparent_for_home(self):
        theme = read("Theme.swift")
        custom = theme.split("func ogContentTitleNav() -> some View {", 1)[1].split("    }", 1)[0]
        self.assertIn(".toolbarBackground(.hidden, for: .navigationBar)", custom)
        self.assertIn(".toolbar(.hidden, for: .navigationBar)", custom)
        self.assertNotIn(".ogTransparentNav()", custom)
        home = read("HomeView.swift")
        self.assertIn('.ogFixedTopBar("repera"', home)
        self.assertNotIn(".ogTransparentNav()", home)
        self.assertIn(".background(OG.surface.ignoresSafeArea())", home)
        self.assertNotIn(".frame(height: 360, alignment: .top)", home)

    def test_inline_navigation_and_manual_titles_do_not_turn_white(self):
        self.assertIn(".ogTransparentNav()", read("WorkoutView.swift"))
        access = read("AIAccessView.swift")
        # Instrucciones / sub-sheets: barra transparente o título scroll.
        self.assertTrue(
            ".ogTransparentNav()" in access or ".ogScrollingTitleNav()" in access
        )
        # Nuevo token: sheet fitted con X (OGPageHeader), no NavigationStack title.
        self.assertIn('OGPageHeader(title: "Nuevo token")', access)
        self.assertIn("CloseToolbarButton(action: dismissCreatedToken", access)
        self.assertIn("createdTokenSheet", access)
        self.assertIn(".ogFittedSheet()", access)



    def test_diary_style_transparent_bars_are_scoped_to_requested_screens(self):
        theme = read("Theme.swift")
        style = theme.split("func ogDiaryTransparentNav() -> some View {", 1)[1].split("    }", 1)[0]
        # Alias de ogTransparentNav (hidden); no reintroduce material.
        self.assertIn(".ogTransparentNav()", style)
        for file in (
            "LibraryView.swift", "QuickLogPickerView.swift",
            "QuickLogSheet.swift",
            "ExerciseDetailView.swift", "ExerciseProgressView.swift",
        ):
            self.assertIn(".ogDiaryTransparentNav()", read(file), file)
        # Favoritos / Timer usan ogScrollingTitleNav (+ list chrome), no el alias diary.
        for file in ("FavoritesHubView.swift", "StandaloneTimerView.swift"):
            self.assertIn(".ogScrollingTitleNav(", read(file), file)
        exercise_progress = read("ExerciseProgressView.swift")
        self.assertIn(".ogScrollingTitleNav(", exercise_progress)
        self.assertIn(".ogDiaryTransparentNav()", exercise_progress)
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
        input_view = timer.split("struct TimerNumericInput:", 1)[1].split(
            "struct StandaloneTimerView:", 1
        )[0]
        self.assertIn("OGNumericTextField(", input_view)
        self.assertIn("_draft = State(initialValue: String(value.wrappedValue))", input_view)
        self.assertIn("range.contains(parsed)", input_view)
        self.assertIn("min(range.upperBound, max(range.lowerBound, parsed))", input_view)
        self.assertIn(".background(OG.surface2, in: RoundedRectangle", input_view)

if __name__ == "__main__":
    unittest.main()
