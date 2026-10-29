"""Regresiones de miniaturas: selector, Reordenar y recursos de ejercicios.

Contratos de código y archivos. No sustituyen la inspección visual en iPhone.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"
ART = (SRC / "ExerciseArt.swift").read_text(encoding="utf-8")
PLAN = (SRC / "PlanView.swift").read_text(encoding="utf-8")
PLAY = (SRC / "WorkoutView.swift").read_text(encoding="utf-8")
PICKER = (SRC / "ExerciseCatalogSearchList.swift").read_text(encoding="utf-8")
RESOURCES = ROOT / "Apps" / "Repera" / "Resources" / "ExerciseArt"


class ExerciseThumbnailContracts(unittest.TestCase):
    def test_reorder_shows_real_thumbnail_and_drag_preview(self):
        for filename, source, marker in (
            ("PlanView", PLAN, "reorderExerciseThumb"),
            ("WorkoutView", PLAY, "playReorderThumb"),
        ):
            with self.subTest(screen=filename):
                section = source.split(f"private func {marker}(", 1)[1].split(
                    "private func ", 1
                )[0]
                self.assertIn("ExerciseThumb(exercise: exercise, size: 32)", section)
                self.assertIn("ExerciseThumb(name: movement.name, size: 32)", section)
                self.assertIn("if movement.isRest", section)
                self.assertIn("store.state.exercises.first", section)
                self.assertIn("pause.circle", section)
                # Drag preview and regular row use the same resolver.
                row = source.split(
                    "private func reorderExerciseRow(" if filename == "PlanView"
                    else "private func playReorderRow(", 1
                )[1].split("private func ", 1)[0]
                self.assertGreaterEqual(row.count(f"{marker}(blockID: blockID, itemID: itemID"), 2)
                self.assertIn("OGReorderDragPreview", row)

    def test_picker_and_reorder_use_shared_image_component(self):
        self.assertIn("ExerciseThumb(exercise: exercise)", PICKER)
        self.assertIn("init(exercise: Exercise, size: CGFloat = 48)", ART)
        self.assertIn("init(name: String, size: CGFloat = 48)", ART)
        self.assertIn("heroImageName(for: exercise)", ART)
        self.assertIn("imageName(forFreeMovement:", ART)

    def test_remote_aliases_resolve_only_verified_art(self):
        self.assertIn("exercise.searchAliases", ART)
        self.assertIn("acceptedHero(nameMap[candidate])", ART)
        self.assertIn("if exercise.isMobility {", ART)
        self.assertIn('"Hang Squat Snatch": "art_hl_hang_sq_snatch"', ART)
        self.assertTrue((RESOURCES / "art_hl_hang_sq_snatch.jpg").is_file())

    def test_visible_list_thumbnails_are_not_cancelled_with_prefetch(self):
        fn = ART.split("static func cancelThumbPrefetch()", 1)[1].split(
            "static func warmArtManifest()", 1
        )[0]
        self.assertIn("prefetchTask?.cancel()", fn)
        self.assertNotIn("cancelAllInFlight", fn.split("{", 1)[1].split("}", 1)[0])
        self.assertIn("fetchedName == name ? fetched : nil", ART)
        self.assertIn("if Task.isCancelled { return }", ART)

    def test_every_explicit_exercise_hero_has_an_image_file(self):
        mapping = ART.split("private static let nameMap:", 1)[1].split(
            "\n    ]", 1
        )[0]
        pairs = re.findall(r'^\s*"([^"]+)":\s*"([^"]+)"', mapping, re.M)
        self.assertGreater(len(pairs), 250)
        missing = sorted({
            stem for _, stem in pairs if not (RESOURCES / f"{stem}.jpg").is_file()
        })
        self.assertFalse(missing, f"Nombre de imagen inexistente: {missing}")


if __name__ == "__main__":
    unittest.main()
