"""Rendimiento Play / Crear-Editar v2: debounce, UITextField + pad lazy, navSig."""
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

    def test_ios_editor_mounted_numeric_cells_and_isolation(self):
        cell = IOS_THEME.split("private struct OGSetNumericCell", 1)[1].split(
            "struct OGFormatNumberField", 1
        )[0]
        # Lazy con isArmed (no solo FocusState): Text hasta el tap; UITextField
        # permanece armado; ambas ramas .frame(height: 44).
        self.assertIn("@State private var isArmed = false", cell)
        self.assertIn("pendingAutoFocus", cell)
        self.assertIn("if isArmed && enabled", cell)
        self.assertIn("OGNumericTextField(", cell)
        self.assertIn("Button {", cell)
        self.assertIn(".frame(height: 44)", cell)
        format_field = IOS_THEME.split("struct OGFormatNumberField", 1)[1].split(
            "private func commit()", 1
        )[0]
        self.assertIn("@State private var isArmed = false", format_field)
        self.assertIn("OGNumericTextField(", format_field)
        self.assertIn("Button {", format_field)
        # Pad 4×4 lazy: no crear OGReperaNumericKeypad en makeUIView (mata el scroll).
        numeric = IOS_THEME.split("struct OGNumericTextField: UIViewRepresentable", 1)[1].split(
            "fileprivate final class OGReperaNumericKeypad", 1
        )[0]
        self.assertIn("func ensureKeypadInstalled()", numeric)
        self.assertIn("func textFieldShouldBeginEditing", numeric)
        self.assertIn("field.inputView = nil", numeric)
        make = numeric.split("func makeUIView", 1)[1].split("func updateUIView", 1)[0]
        self.assertNotIn("OGReperaNumericKeypad(", make)
        self.assertIn("if autoFocus {", make)
        self.assertIn("StrengthExerciseSetsIsolator", IOS_PLAN)
        self.assertIn("StrengthExerciseSetsIdentity: Hashable", IOS_PLAN)
        self.assertIn(".id(setsIdentity)", IOS_PLAN)
        self.assertNotIn(": View, Equatable", IOS_PLAN)
        self.assertIn("refreshExercisesByIdIfNeeded", IOS_PLAN)
        self.assertIn("previousSetTexts(for:", IOS_PLAN)
        # Identidad estructural: sin RoutineExercise completo ni valores de serie en `.id`
        # (si plannedSets/peso/reps van en la identidad, cada tecla remonta y pierde el foco).
        identity = IOS_PLAN.split(
            "private struct StrengthExerciseSetsIdentity: Hashable", 1
        )[1].split("private struct StrengthExerciseSetsIsolator", 1)[0]
        self.assertIn("let itemID: UUID", identity)
        self.assertNotIn("let plannedSetIDs: [UUID]", identity)
        self.assertNotIn("let previousTexts: [String?]", identity)
        self.assertNotIn("let item: RoutineExercise", identity)
        self.assertIn("item: item,", IOS_PLAN)
        self.assertIn("previousTexts: previousTexts,", IOS_PLAN)
        # Bloques de fuerza siempre con strengthBlock (Añadir serie), no solo Rx completada.
        self.assertIn("strengthBlock(index: index)", IOS_PLAN)
        strength_branch = IOS_PLAN.split("if block.kind == .strength", 1)[1].split("} else {", 1)[0]
        self.assertNotIn("completedStrengthPrescription", strength_branch)
        self.assertIn("if focus != nil { return }", IOS_WORKOUT)
        self.assertIn("onChange(of: focus)", IOS_WORKOUT)
        # Primer frame sin salto de altura: catálogo/series listos antes de onAppear.
        self.assertIn("resolvedExerciseCatalog", IOS_PLAN)
        self.assertIn("withStrengthPlannedSets", IOS_PLAN)
        self.assertIn("Self.makeRows(from:", IOS_WORKOUT)
        self.assertIn("hydratePreviousSummariesIfNeeded", IOS_WORKOUT)
        self.assertIn("compactIntrinsicHeight: 44", IOS_THEME)
        self.assertIn("initialDraftSets(movement:", IOS_PLAN)
        # Una sola entrada expandida (paridad Android): evita freeze al abrir Editar.
        self.assertIn("@State private var expandedEntryID: UUID?", IOS_PLAN)
        self.assertIn("firstExpandableEntryID", IOS_PLAN)
        self.assertIn("expandedEntryID == item.id", IOS_PLAN)
        self.assertIn("plannedSets.compactSummary", IOS_PLAN)

    def test_android_play_nav_sig_and_nested_block(self):
        self.assertIn('"${it.blockId}:${it.index}:${it.name}"', ANDROID_PLAY)
        self.assertNotIn('"${it.blockId}:${it.index}:${it.name}:${it.completed}"', ANDROID_PLAY)
        # Ejercicios + logging dentro del mismo BlockEditorCard (paridad iOS).
        self.assertIn("includeEntries = true", ANDROID_PLAY)
        self.assertIn("playCompactEntries = true", ANDROID_PLAY)
        self.assertIn("trailingContent = if (isCurrent)", ANDROID_PLAY)
        self.assertIn("selectedEntryIndex == index", ANDROID_EDITOR)
        self.assertIn("PlayCompactEntryRow(", ANDROID_EDITOR)
        self.assertIn("play_entry_menu", ANDROID_EDITOR)
        # Nombres en negro (paridad iOS); no verde al seleccionar.
        compact = ANDROID_EDITOR.split("internal fun PlayCompactEntryRow(", 1)[1].split(
            "@Composable\ninternal fun CompactEntrySummaryRow(", 1
        )[0]
        self.assertIn("color = MaterialTheme.colorScheme.onSurface", compact)
        self.assertNotIn("brandGreen", compact)
        # Cabecera Play: título + timer + ⋯ más altos/grandes.
        header = ANDROID_EDITOR.split("val playHeader = onTimer != null", 1)[1].split(
            "ConfirmDeleteMultiExerciseBlockDialog(", 1
        )[0]
        self.assertIn("defaultMinSize(minHeight = 52.dp)", header)
        self.assertIn("44.dp", header)
        self.assertIn("22.dp", header)
        self.assertIn("play_block_header", header)
        self.assertIn("size = headerIconSize", header)

    def test_android_editor_single_expanded_entry(self):
        self.assertIn("var expandedEntryId by rememberSaveable", ANDROID_EDITOR)
        self.assertIn("var setsExpanded by mutableStateOf(false)", ANDROID_EDITOR)
        self.assertNotIn("// Series siempre visibles", ANDROID_EDITOR)
        self.assertIn("CompactEntrySummaryRow(", ANDROID_EDITOR)
        self.assertIn("includeEntries = true", ANDROID_EDITOR)
        self.assertIn("BlockEntryEditorSlot(", ANDROID_EDITOR)
        # Primer ejercicio expandido al abrir (Crear y Editar iguales).
        self.assertIn("firstKey", ANDROID_EDITOR)
        self.assertIn("stableKey(index)", ANDROID_EDITOR)
        self.assertIn("ExerciseListThumb(", ANDROID_EDITOR)
        self.assertIn("plan_entry_compact_menu", ANDROID_EDITOR)


if __name__ == "__main__":
    unittest.main()
