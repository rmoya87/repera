"""UI Repera: vista previa sin ayuda redundante, flechas nativas y arte BBJO."""
import unittest
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


class LoginPreviewAndThumbTests(unittest.TestCase):
    def test_preview_has_no_unrequested_swipe_instruction(self):
        view = (SRC / "SessionPreviewView.swift").read_text()
        self.assertNotIn("Toca para continuar · desliza para eliminar (no se guarda)", view)
        self.assertIn("onContinue()", view)
        self.assertIn("store.endActiveSession(save: false)", view)

    def test_workout_navigation_uses_native_chevrons(self):
        source = (SRC / "WorkoutView.swift").read_text()
        toolbar = source.split('ToolbarItem(placement: .topBarTrailing)', 1)[1]
        toolbar = toolbar.split('// Edición como destino push', 1)[0]
        self.assertIn('Image(systemName: "chevron.left")', toolbar)
        self.assertIn('Image(systemName: "chevron.right")', toolbar)
        self.assertIn(".tint(OG.label)", toolbar)
        self.assertIn('Image(systemName: "checkmark")', toolbar)
        self.assertIn(".tint(OG.accent)", toolbar)

    def test_burpee_box_jump_over_has_local_thumb(self):
        art = (SRC / "ExerciseArt.swift").read_text()
        self.assertIn('"Burpee box jump over": "art_cf_burpee_box"', art)
        self.assertIn('"Burpee box jump overs": "art_cf_burpee_box"', art)
        self.assertIn('"BBJO": "art_cf_burpee_box"', art)
        self.assertIn('normalizedName.contains("burpee")', art)
        self.assertIn('normalizedName.contains("box")', art)
        thumb = SRC.parent / "Resources" / "ExerciseArt" / "thumbs" / "art_cf_burpee_box.jpg"
        self.assertTrue(thumb.is_file(), "Falta la miniatura JPG en el bundle de Repera")


if __name__ == "__main__":
    unittest.main()
