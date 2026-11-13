"""Filas de ejercicio en Crear/Editar/Play: resumen bajo título, sin chevron, taps separados."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS_PLAN = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
IOS_WORKOUT = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
ANDROID_EDITOR = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/RoutineBlocksEditor.kt"
).read_text(encoding="utf-8")
ANDROID_PLAY = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
).read_text(encoding="utf-8")


class ExerciseRowTapContract(unittest.TestCase):
    def test_ios_wod_summary_under_title_without_chevron_row(self):
        wod = IOS_PLAN.split("private func wodBlock(index: Int)", 1)[1].split(
            "private func resolvedExercise(for move: WODMovement)", 1
        )[0]
        # Resumen junto al título (colapsado), no fila aparte con chevron.
        self.assertIn("if !isExpanded {", wod)
        self.assertIn("Text(move.summaryLine)", wod)
        self.assertNotIn('Image(systemName: "chevron.right")', wod)
        # Miniatura → ficha; título/resumen → expandir series o descanso.
        self.assertIn("exerciseDetailID = resolved.id", wod)
        self.assertIn("movementThumb(move: move, resolved: resolved)", wod)
        self.assertIn("expandedEntryID = move.id", wod)
        self.assertIn('Text(move.isRest ? "Descanso" : resolved.name)', wod)

    def test_ios_strength_thumb_opens_detail_title_expands(self):
        strength = IOS_PLAN.split("private func strengthBlock(index: Int)", 1)[1].split(
            "private func insertRest(after blockID: UUID)", 1
        )[0]
        self.assertIn("exerciseDetailID = ex.id", strength)
        self.assertIn("expandedEntryID = item.id", strength)
        self.assertIn("item.plannedSets.compactSummary", strength)
        self.assertNotIn('Image(systemName: "chevron.right")', strength)

    def test_ios_play_splits_thumb_and_title_taps(self):
        play_rows = IOS_WORKOUT.split("private func playBlockExerciseRows(", 1)[1].split(
            "private func playBlockTechniquesRows(", 1
        )[0]
        self.assertIn("exerciseDetailID = entry.exercise.id", play_rows)
        self.assertIn("store.selectExercise(at: index)", play_rows)
        self.assertIn('Text(isRest ? "Descanso"', play_rows)
        self.assertIn("entry.plannedSets.compactSummary", play_rows)

    def test_android_compact_rows_split_thumb_and_text(self):
        compact = ANDROID_EDITOR.split(
            "internal fun CompactEntrySummaryRow(", 1
        )[1].split("@Composable\ninternal fun BlockEntryEditorSlot(", 1)[0]
        self.assertIn("onOpenDetail: (() -> Unit)? = null", compact)
        self.assertIn('testTag("plan_entry_compact_text")', compact)
        self.assertIn("Modifier.clickable(onClick = onOpenDetail)", compact)
        self.assertIn(".clickable(onClick = onClick)", compact)
        # Sin flecha en la fila compacta de series/reps.
        self.assertNotIn("KeyboardArrowRight", compact)

        play = ANDROID_EDITOR.split("internal fun PlayCompactEntryRow(", 1)[1].split(
            "@Composable\ninternal fun CompactEntrySummaryRow(", 1
        )[0]
        self.assertIn("onOpenDetail: (() -> Unit)? = null", play)
        self.assertIn("Modifier.clickable(onClick = onOpenDetail)", play)
        self.assertIn(".clickable(onClick = onClick)", play)

    def test_android_play_wires_open_exercise(self):
        self.assertIn("onOpenExercise: (String) -> Unit = {}", ANDROID_PLAY)
        self.assertIn("onOpenExercise = onOpenExercise,", ANDROID_PLAY)

    def test_ios_exercise_menu_info_open_divider_glass_morph(self):
        # Menú de fila de ejercicio en Play (Información / Abrir / separador / morph).
        self.assertIn('Button("Información", systemImage: "info.circle")', IOS_WORKOUT)
        self.assertIn('Button("Abrir", systemImage: "checkmark.circle")', IOS_WORKOUT)
        self.assertNotIn('Button("Seleccionar ejercicio"', IOS_WORKOUT)
        plan_opts = IOS_PLAN.split("private func exerciseOptions(", 1)[1].split(
            "private func applyExerciseReplacement(", 1
        )[0]
        self.assertIn('Button("Información", systemImage: "info.circle")', plan_opts)
        self.assertIn('Button("Abrir", systemImage: "checkmark.circle")', plan_opts)
        self.assertIn("Divider()", plan_opts)
        self.assertIn('Button("Eliminar ejercicio", systemImage: "trash", role: .destructive)', plan_opts)
        # Morph nativo circular (mismo tamaño que ⋯ del bloque; no cápsula).
        self.assertIn(".ogGlassCircleMenu()", plan_opts)
        self.assertIn("OGGlassEllipsisLabel()", plan_opts)
        self.assertNotIn(".glassEffect(", plan_opts)
        play_rows = IOS_WORKOUT.split("private func playBlockExerciseRows(", 1)[1].split(
            "private func playBlockTechniquesRows(", 1
        )[0]
        self.assertIn(".ogGlassCircleMenu()", play_rows)
        self.assertIn("OGGlassEllipsisLabel()", play_rows)
        self.assertNotIn(".glassEffect(", play_rows)
        theme = (ROOT / "Apps/Repera/Sources/Theme.swift").read_text(encoding="utf-8")
        self.assertIn("struct OGGlassEllipsisLabel", theme)
        self.assertIn("func ogGlassCircleMenu()", theme)
        self.assertIn(".buttonBorderShape(.circle)", theme)

    def test_block_title_inside_card_large_no_outside_header(self):
        # iOS Crear/Editar: sin header de Section con el título; nombre grande dentro.
        blocks = IOS_PLAN.split("ForEach(Array(routine.blocks.enumerated())", 1)[1].split(
            'Section {\n                Button {\n                    routine.blocks.append',
            1,
        )[0]
        self.assertIn(".font(.system(size: 20, weight: .bold))", blocks)
        self.assertNotIn("header: {\n                    Text(block.title)", blocks)
        # iOS Play: sin «Bloque · Formato» fuera; título 20 bold dentro.
        play = IOS_WORKOUT.split("ForEach(workoutBlocks(session))", 1)[1].split(
            'Section("Notas del entreno")', 1
        )[0]
        self.assertNotIn('Text("Bloque")', play)
        title_row = IOS_WORKOUT.split("private func playBlockTitleRow(", 1)[1].split(
            "private func playBlockExerciseList(", 1
        )[0]
        self.assertIn(".font(.system(size: 20, weight: .bold))", title_row)
        # Android: sin ReperaSectionTitle duplicado fuera de la card.
        editor_list = ANDROID_EDITOR.split("blocks.forEachIndexed { index, block ->", 1)[1].split(
            'item(key = "editor-actions")', 1
        )[0]
        self.assertNotIn("ReperaSectionTitle(", editor_list)
        self.assertIn("fontSize = 20.sp", ANDROID_EDITOR)
        self.assertNotIn(
            "ReperaSectionTitle(block.title.ifBlank",
            ANDROID_PLAY,
        )

    def test_android_exercise_menu_info_open_divider(self):
        play = ANDROID_EDITOR.split("internal fun PlayCompactEntryRow(", 1)[1].split(
            "@Composable\ninternal fun CompactEntrySummaryRow(", 1
        )[0]
        self.assertIn('Text("Información")', play)
        self.assertIn('Text("Abrir")', play)
        self.assertNotIn('Text("Seleccionar ejercicio")', play)
        self.assertIn("HorizontalDivider()", play)
        self.assertIn('Text("Eliminar ejercicio"', play)
        compact = ANDROID_EDITOR.split(
            "internal fun CompactEntrySummaryRow(", 1
        )[1].split("@Composable\ninternal fun BlockEntryEditorSlot(", 1)[0]
        self.assertIn('Text("Información")', compact)
        self.assertIn('Text("Abrir")', compact)
        self.assertNotIn('Text("Editar series")', compact)
        self.assertIn("HorizontalDivider()", compact)


if __name__ == "__main__":
    unittest.main()
