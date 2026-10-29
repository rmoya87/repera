"""Regresiones visuales acotadas: topbar Progreso y estrellas favoritas.

Pruebas de contratos fuente. Requieren validación visual posterior en dispositivo.
"""
from pathlib import Path
import unittest

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def swift(name: str) -> str:
    return (SRC / name).read_text(encoding="utf-8")


class ProgressTopbarAndFavoriteAmberContracts(unittest.TestCase):
    def test_progress_topbar_is_transparent_without_changing_shared_default(self):
        stats = swift("StatsView.swift")
        theme = swift("Theme.swift")
        self.assertIn(
            'OGFixedTopBar(title: "Progreso", subtitle: model.range.title, drawsBackground: false)',
            stats,
        )
        self.assertIn(".background(OG.bg)", stats)
        self.assertIn("var drawsBackground: Bool = true", theme)
        self.assertIn("if drawsBackground {", theme)

    def test_marked_and_unmarked_star_share_amber(self):
        detail = swift("ExerciseDetailView.swift")
        theme = swift("Theme.swift")
        self.assertIn(
            "static let favoriteAmber = Color(red: 1, green: 183 / 255, blue: 0 / 255)",
            theme,
        )
        self.assertIn('exercise.isFavorite ? "star.fill" : "star"', detail)
        self.assertIn(".foregroundStyle(OG.favoriteAmber)", detail)
        self.assertIn("tint: OG.favoriteAmber", detail)
        self.assertNotIn("exercise.isFavorite ? OG.yellow : OG.label", detail)

    def test_favorite_colors_are_consistent_without_recoloring_other_yellow(self):
        theme = swift("Theme.swift")
        self.assertIn(
            "static let yellow = Color(red: 1, green: 214 / 255, blue: 10 / 255)",
            theme,
        )
        self.assertIn("delta < 0 ? OG.yellow", swift("StatsView.swift"))
        for file in (
            "LibraryView.swift",
            "FavoritesHubView.swift",
            "StandaloneTimerView.swift",
            "StartHubSheet.swift",
        ):
            with self.subTest(file=file):
                source = swift(file)
                self.assertIn("OG.favoriteAmber", source)
                self.assertNotIn("OG.yellow", source)

    def test_home_header_and_background_remain_untouched(self):
        home = swift("HomeView.swift")
        self.assertIn(
            '.ogFixedTopBar("repera", subtitle: SpanishDate.long(selectedDay), drawsBackground: false)',
            home,
        )
        self.assertIn(".background(OG.surface.ignoresSafeArea())", home)


if __name__ == "__main__":
    unittest.main()
