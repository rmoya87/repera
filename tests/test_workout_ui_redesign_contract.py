"""Contrato UI gestión de entrenamientos (rediseño 2026-11)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
THEME = (ROOT / "Apps/Repera/Sources/Theme.swift").read_text(encoding="utf-8")
WORKOUT = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
HOME = (ROOT / "Apps/Repera/Sources/HomeView.swift").read_text(encoding="utf-8")
COMPONENTS = (ROOT / "Apps/Repera/Sources/Theme.swift").read_text(encoding="utf-8")
PREVIEW = (ROOT / "Apps/Repera/Sources/SessionPreviewView.swift").read_text(encoding="utf-8")
PLAN = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
PICKER = (ROOT / "Apps/Repera/Sources/ExerciseCatalogSearchList.swift").read_text(encoding="utf-8")
REST = (ROOT / "Apps/Repera/Sources/RestSessionCoordinator.swift").read_text(encoding="utf-8")
ANDROID_KEYPAD = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaNumericKeypad.kt"
).read_text(encoding="utf-8")
ANDROID_UI = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/WorkoutUiComponents.kt"
).read_text(encoding="utf-8")
ANDROID_PLAY = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
).read_text(encoding="utf-8")
ANDROID_LIVE = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveSetRows.kt"
).read_text(encoding="utf-8")
ANDROID_PICKER = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ExercisePickerSheet.kt"
).read_text(encoding="utf-8")
ANDROID_PREVIEW = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/SessionPreviewSheet.kt"
).read_text(encoding="utf-8")
ANDROID_HOME = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/HomeDayCards.kt"
).read_text(encoding="utf-8")
ANDROID_EDITOR = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/RoutineBlocksEditor.kt"
).read_text(encoding="utf-8")
ANDROID_PLAY = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
).read_text(encoding="utf-8")
WORKOUT_IOS = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
REPO = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt"
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
        self.assertIn("Reordenar", WORKOUT)
        self.assertNotIn("Formato de bloque", WORKOUT)
        self.assertNotIn("Editar estructura", WORKOUT)
        self.assertIn("usesMinimizeGlyph: true", WORKOUT)
        self.assertIn("adjustRemaining(by:", WORKOUT)
        self.assertIn("func adjustRemaining(by delta: Int)", REST)
        play_sets = WORKOUT.split("private struct PlayEditableSetsView", 1)[1].split(
            "private struct WODResultInlineEditor", 1
        )[0]
        self.assertIn("showsConfirmation: false", play_sets)
        self.assertIn("liveWorkSetCount", WORKOUT)
        self.assertIn("Terminar entreno", WORKOUT)

    def test_home_keeps_weekly_and_activity_sections(self):
        self.assertIn("weeklyProgressCard", HOME)
        self.assertIn("Actividad de hoy", HOME)
        self.assertIn("RoutinePresentationStats.counts", HOME)
        self.assertIn('Text(caption)', HOME)
        self.assertIn("play.fill", HOME)

    def test_preview_bottom_bar_and_editor_tab_bar(self):
        self.assertIn("safeAreaInset(edge: .bottom)", PREVIEW)
        self.assertIn("OGFloatingPrimaryCTA", PREVIEW)
        self.assertIn("Empezar", PREVIEW)
        # Solo Empezar abajo; Editar/Borrar en ⋯ (sin segundo botón Editar).
        preview_inset = PREVIEW.split("safeAreaInset(edge: .bottom)", 1)[1][:800]
        self.assertIn("OGFloatingPrimaryCTA", preview_inset)
        self.assertNotIn('"Editar"', preview_inset)
        self.assertIn("OGWorkoutMetaChip", PREVIEW)
        self.assertIn(".toolbar(.hidden, for: .tabBar)", PLAN)
        self.assertIn("ogDiscardChangesConfirm", PLAN)
        self.assertIn("ogUndoToast", PLAN)
        self.assertIn("hideNativeBack: true", PLAN)
        self.assertIn(".navigationBarBackButtonHidden(true)", PLAN)
        self.assertIn('accessibilityLabel("Volver")', PLAN)
        # Un solo chevron leading (no condicionado solo a dirty + nativo).
        self.assertIn("if isEditorDirty", PLAN.split("accessibilityLabel(\"Volver\")", 1)[0][-400:])
        self.assertIn("ExerciseCatalogSelectionMode", PICKER)
        self.assertIn("Añadir \\(selectedIDs.count)", PICKER)
        self.assertIn("OGFloatingPrimaryCTA", PICKER)
        self.assertNotIn("ultraThinMaterial", PICKER)
        wod_picker = (
            ROOT / "Apps/Repera/Sources/WODCatalogPickerView.swift"
        ).read_text(encoding="utf-8")
        self.assertIn('OGFloatingPrimaryCTA(title: "Usar este WOD"', wod_picker)
        self.assertIn("struct OGFloatingPrimaryCTA", THEME)

    def test_android_keypad_has_dynamic_colors(self):
        self.assertIn("keypadBackground", ANDROID_KEYPAD)
        self.assertIn("submitTitle", ANDROID_KEYPAD)
        self.assertIn("keypadStep", ANDROID_KEYPAD)

    def test_android_shared_components(self):
        for name in (
            "WorkoutMetaChip",
            "WorkoutFinishSummarySheet",
            "WorkoutPlayProgressHeader",
            "DiscardChangesDialog",
            "PlayRestFooter",
            "SessionPreviewBottomBar",
            "FloatingPrimaryCta",
        ):
            self.assertIn(name, ANDROID_UI)
        bar = ANDROID_UI.split("fun SessionPreviewBottomBar", 1)[1][:900]
        self.assertIn("FloatingPrimaryCta", bar)
        self.assertIn('title = "Empezar"', bar)
        self.assertNotIn('Text("Editar")', bar)

    def test_android_play_and_live_rows(self):
        self.assertIn("WorkoutFinishSummarySheet", ANDROID_PLAY)
        self.assertIn("KeyboardArrowDown", ANDROID_PLAY)
        self.assertIn("Reordenar", ANDROID_PLAY)
        self.assertNotIn("Editar estructura", ANDROID_PLAY)
        self.assertIn("WorkoutPlayProgressHeader", ANDROID_PLAY)
        self.assertIn("play_finish_button", ANDROID_PLAY)
        self.assertIn("showExerciseNav = false", ANDROID_PLAY)
        self.assertIn("SetRowIndexBadge", ANDROID_LIVE)
        self.assertIn("PreviousSetValueChip", ANDROID_LIVE)
        self.assertIn("border(2.dp, brandGreen", ANDROID_LIVE)
        self.assertNotIn("Marcar serie", ANDROID_LIVE)

    def test_android_picker_preview_home_editor(self):
        self.assertIn("allowsMultipleSelection", ANDROID_PICKER)
        self.assertIn("Añadir ${selected.size}", ANDROID_PICKER)
        self.assertIn("FloatingPrimaryCta", ANDROID_PICKER)
        self.assertIn("SessionPreviewBottomBar", ANDROID_PREVIEW)
        self.assertIn("SessionPreviewSummaryChips", ANDROID_PREVIEW)
        self.assertIn("home_planned_play", ANDROID_HOME)
        self.assertIn("DiscardChangesDialog", ANDROID_EDITOR)
        self.assertIn("allowsMultipleSelection = true", ANDROID_EDITOR)
        self.assertIn("aliases: Map<String, String>", ANDROID_PICKER)
        wod_lib = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/WodLibraryScreen.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("FloatingPrimaryCta", wod_lib)
        self.assertIn('title = "Empezar ahora"', wod_lib)

    def test_undo_and_block_delete_confirmations(self):
        self.assertIn("presentUndoToast", PLAN)
        self.assertIn("deleteStrengthSet", PLAN)
        self.assertIn("blockDeleteConfirmID", PLAN)
        self.assertIn("¿Eliminar este bloque?", PLAN)
        self.assertIn("Ejercicio eliminado", PLAN)
        self.assertIn("showWorkoutUndoSnackbar", ANDROID_UI)
        self.assertIn("WorkoutUndoSnackbarHost", ANDROID_EDITOR)
        self.assertIn("ConfirmDeleteMultiExerciseBlockDialog", ANDROID_UI)
        self.assertIn("nonRestExerciseCount", ANDROID_EDITOR)
        self.assertIn("cloneForUndo", ANDROID_EDITOR)
        self.assertIn("WorkoutUndoSnackbarHost", ANDROID_PLAY)
        self.assertIn("deleteSetWithUndo", ANDROID_PLAY)
        self.assertIn("restoreDeletedSet", REPO)
        self.assertIn("restorePendingSet", REPO)
        self.assertIn("ogUndoToast($undoToast)", WORKOUT_IOS)
        self.assertIn("presentPlayUndoToast", WORKOUT_IOS)
        self.assertIn("playBlockDeleteConfirmID", WORKOUT_IOS)
        self.assertIn("onUndoSetDelete", WORKOUT_IOS)
        wod_editor = PLAN.split("struct WODMovementEditor", 1)[1][:20000]
        self.assertIn("ogUndoToast($undoToast)", wod_editor)
        self.assertIn("presentUndoToast", wod_editor)
        self.assertIn("eliminada", wod_editor)


if __name__ == "__main__":
    unittest.main()
