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
    def test_native_secondary_navigation_uses_adaptive_grouped_gray(self):
        theme = read("Theme.swift")
        method = theme.split("func ogTransparentNav() -> some View {", 1)[1].split("    }", 1)[0]
        self.assertIn(".toolbarBackground(OG.bg, for: .navigationBar)", method)
        self.assertIn(".toolbarBackground(.visible, for: .navigationBar)", method)
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
        for file in ("WorkoutView.swift", "LibraryView.swift",
                     "StandaloneTimerView.swift", "QuickLogSheet.swift"):
            self.assertIn(".ogTransparentNav()", read(file), file)
        for file in ("AIAccessView.swift", "AITrainingProgramsView.swift",
                     "BusinessCenterViews.swift", "MessagesInboxView.swift"):
            self.assertIn(".ogTransparentNav()", read(file), file)
        access = read("AIAccessView.swift")
        self.assertIn('.navigationTitle("Acceso IA")', access)
        self.assertIn('.navigationTitle("Nuevo token")', access)
        self.assertGreaterEqual(access.count(".ogTransparentNav()"), 2)


if __name__ == "__main__":
    unittest.main()
