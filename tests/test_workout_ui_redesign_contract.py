"""Contrato UI gestión de entrenamientos (rediseño 2026-11)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
THEME = (ROOT / "Apps/Repera/Sources/Theme.swift").read_text(encoding="utf-8")
WORKOUT = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
HOME = (ROOT / "Apps/Repera/Sources/HomeView.swift").read_text(encoding="utf-8")
COMPONENTS = (ROOT / "Apps/Repera/Sources/WorkoutUIComponents.swift").read_text(encoding="utf-8")
PREVIEW = (ROOT / "Apps/Repera/Sources/SessionPreviewView.swift").read_text(encoding="utf-8")
PLAN = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
PICKER = (ROOT / "Apps/Repera/Sources/ExerciseCatalogSearchList.swift").read_text(encoding="utf-8")
REST = (ROOT / "Apps/Repera/Sources/RestSessionCoordinator.swift").read_text(encoding="utf-8")
ANDROID_KEYPAD = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaNumericKeypad.kt"
).read_text(encoding="utf-8")


class WorkoutUiRedesignContract(unittest.TestCase):
    def test_theme_tokens_and_keyboard_fix(self):
        self.assertIn("static let accentText", THEME)
        self.assertIn("static let keypadBg", THEME)
        self.assertIn("field.resignFirstResponder()", THEME.split("commitFromKeyboard", 1)[1][:900])
        cell = THEME.split("private struct OGSetNumericCell", 1)[1].split("struct OGFormatNumberField", 1)[0]
        self.assertIn(".strokeBorder(OG.accent, lineWidth: 2)", cell)
        pad = THEME.split("fileprivate final class OGReperaNumericKeypad", 1)[1]
        self.assertIn("keypadBg", pad)
        self.assertIn("actionTitle", pad)

    def test_shared_components_exist(self):
        for name in (
            "OGWorkoutMetaChip",
            "OGUndoToast",
            "OGWorkoutFinishSummarySheet",
            "OGPlaySessionProgressHeader",
            "RoutinePresentationStats",
        ):
            self.assertIn(name, COMPONENTS)

    def test_play_finish_summary_and_rest(self):
        self.assertIn("OGWorkoutFinishSummarySheet", WORKOUT)
        self.assertIn("showFinishSummary", WORKOUT)
        self.assertIn("Editar estructura", WORKOUT)
        self.assertIn("usesMinimizeGlyph: true", WORKOUT)
        self.assertIn("adjustRemaining(by:", WORKOUT)
        self.assertIn("func adjustRemaining(by delta: Int)", REST)
        play_sets = WORKOUT.split("private struct PlayEditableSetsView", 1)[1].split(
            "private struct WODResultInlineEditor", 1
        )[0]
        self.assertGreaterEqual(play_sets.count("showsConfirmation: true"), 2)

    def test_home_keeps_weekly_and_activity_sections(self):
        self.assertIn("weeklyProgressCard", HOME)
        self.assertIn("Actividad de hoy", HOME)
        self.assertIn("RoutinePresentationStats.counts", HOME)
        self.assertIn('Text(caption)', HOME)
        self.assertIn("play.fill", HOME)

    def test_preview_bottom_bar_and_editor_tab_bar(self):
        self.assertIn("safeAreaInset(edge: .bottom)", PREVIEW)
        self.assertIn("Empezar", PREVIEW)
        self.assertIn("OGWorkoutMetaChip", PREVIEW)
        self.assertIn(".toolbar(.hidden, for: .tabBar)", PLAN)
        self.assertIn("ogDiscardChangesConfirm", PLAN)
        self.assertIn("ogUndoToast", PLAN)
        self.assertIn("ExerciseCatalogSelectionMode", PICKER)
        self.assertIn("Añadir \\(selectedIDs.count)", PICKER)

    def test_android_keypad_has_dynamic_colors(self):
        self.assertIn("keypadBackground", ANDROID_KEYPAD)


if __name__ == "__main__":
    unittest.main()
