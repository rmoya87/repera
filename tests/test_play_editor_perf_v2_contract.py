"""Rendimiento Play / Crear-Editar v2: debounce, celdas perezosas, navSig, expandedEntryId."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS_WORKOUT = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
IOS_STORE = (ROOT / "Apps/Repera/Sources/ReperaStore.swift").read_text(encoding="utf-8")
IOS_THEME = (ROOT / "Apps/Repera/Sources/Theme.swift").read_text(encoding="utf-8")
IOS_PLAN = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
ANDROID_PLAY = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
).read_text(encoding="utf-8")
ANDROID_EDITOR = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/RoutineBlocksEditor.kt"
).read_text(encoding="utf-8")


class PlayEditorPerfV2Contract(unittest.TestCase):
    def test_ios_play_debounces_draft_writes(self):
        self.assertIn("private func schedulePersist(immediate: Bool)", IOS_WORKOUT)
        self.assertIn("Task.sleep(for: .milliseconds(250))", IOS_WORKOUT)
        self.assertIn("private func flushPersist(pushWatch: Bool = true)", IOS_WORKOUT)
        self.assertIn("flushPersist(pushWatch: false)", IOS_WORKOUT)
        self.assertIn("registerFlusher?({ flushPersist() })", IOS_WORKOUT)
        self.assertIn("durable: Bool = true", IOS_STORE)
        self.assertIn("pushWatch: Bool = true", IOS_STORE)
        self.assertNotIn("rebuildLiveSets", IOS_WORKOUT)
        self.assertNotIn("@State private var liveSets", IOS_WORKOUT)
        self.assertNotIn("setsBoard", IOS_WORKOUT)

    def test_ios_editor_lazy_numeric_cells_and_isolation(self):
        cell = IOS_THEME.split("private struct OGSetNumericCell", 1)[1].split(
            "struct OGFormatNumberField", 1
        )[0]
        self.assertIn("if isFocused && enabled", cell)
        self.assertIn("OGNumericTextField(", cell)
        self.assertIn("Button {", cell)
        self.assertIn("StrengthExerciseSetsIsolator", IOS_PLAN)
        self.assertIn("StrengthExerciseSetsIdentity: Hashable", IOS_PLAN)
        self.assertIn(".id(setsIdentity)", IOS_PLAN)
        self.assertNotIn(": View, Equatable", IOS_PLAN)
        self.assertIn("refreshExercisesByIdIfNeeded", IOS_PLAN)
        self.assertIn("previousSetTexts(for:", IOS_PLAN)

    def test_android_play_nav_sig_and_flat_lazy(self):
        self.assertIn('"${it.blockId}:${it.index}:${it.name}"', ANDROID_PLAY)
        self.assertNotIn('"${it.blockId}:${it.index}:${it.name}:${it.completed}"', ANDROID_PLAY)
        self.assertIn("includeEntries = false", ANDROID_PLAY)
        self.assertIn("PlayCompactEntryRow(", ANDROID_PLAY)
        self.assertIn('item(key = "play-log-${workout.index}")', ANDROID_PLAY)
        self.assertIn("BlockEditorFooterActions(", ANDROID_PLAY)

    def test_android_editor_single_expanded_entry(self):
        self.assertIn("var expandedEntryId by rememberSaveable", ANDROID_EDITOR)
        self.assertIn("var setsExpanded by mutableStateOf(false)", ANDROID_EDITOR)
        self.assertNotIn("// Series siempre visibles", ANDROID_EDITOR)
        self.assertIn("CompactEntrySummaryRow(", ANDROID_EDITOR)
        self.assertIn("includeEntries = false", ANDROID_EDITOR)
        self.assertIn("BlockEntryEditorSlot(", ANDROID_EDITOR)


if __name__ == "__main__":
    unittest.main()
