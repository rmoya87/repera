"""Nombres/campos de formatos WOD: Escalera, For Time min+seg, escáner → editor."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS_MODELS = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/Models.swift").read_text(encoding="utf-8")
IOS_PLAN = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
IOS_HOME = (ROOT / "Apps/Repera/Sources/HomeView.swift").read_text(encoding="utf-8")
ANDROID_WOD = (ROOT / "android/domain/src/main/java/dev/repera/domain/WodRules.kt").read_text(encoding="utf-8")
ANDROID_EDITOR = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/RoutineBlocksEditor.kt").read_text(encoding="utf-8")
ANDROID_NAV = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt").read_text(encoding="utf-8")
ANDROID_CONFIRM = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/BoardClassicReviewEditor.kt").read_text(encoding="utf-8")
ANDROID_PARSER = (ROOT / "android/domain/src/main/java/dev/repera/domain/BoardScanLiteParser.kt").read_text(encoding="utf-8")
IOS_PARSER = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/BoardScanLiteParser.swift").read_text(encoding="utf-8")


class WodFormatLabelsContract(unittest.TestCase):
    def test_short_display_names(self):
        self.assertIn('case .emom: return "EMOM"', IOS_MODELS)
        self.assertIn('case .forTime: return "For Time"', IOS_MODELS)
        self.assertIn('case .ladder: return "Escalera"', IOS_MODELS)
        self.assertIn('case .partner: return "Partner"', IOS_MODELS)
        self.assertIn('case .forTime: return "For Time"', IOS_MODELS)
        self.assertNotIn('return "EMOM / Every X\'"', IOS_MODELS)
        self.assertNotIn('return "Ladder / 21-15-9"', IOS_MODELS)
        self.assertNotIn('case .ladder: return "Escalado"', IOS_MODELS)
        self.assertIn('return blockHeader?.isEmpty == false ? blockHeader! : "Escalera"', IOS_MODELS)
        self.assertIn('EMOM -> "EMOM"', ANDROID_WOD)
        self.assertIn('FOR_TIME -> "For Time"', ANDROID_WOD)
        self.assertIn('LADDER -> "Escalera"', ANDROID_WOD)
        self.assertNotIn('LADDER -> "Escalado"', ANDROID_WOD)
        self.assertIn('PARTNER -> "Partner"', ANDROID_WOD)
        wear = (
            ROOT / "android/domain/src/main/java/dev/repera/domain/WearBlockHeader.kt"
        ).read_text(encoding="utf-8")
        self.assertIn('WodFormat.LADDER -> h ?: "Escalera"', wear)
        catalog_test = (
            ROOT / "android/domain/src/test/java/dev/repera/domain/CatalogWodsTest.kt"
        ).read_text(encoding="utf-8")
        self.assertIn('assertEquals("For Time", fran.formatLabel)', catalog_test)
        self.assertNotIn('assertEquals("For Time / RFT", fran.formatLabel)', catalog_test)

    def test_for_time_fields_are_rounds_time_time(self):
        self.assertIn('case .roundRest: return "Tiempo"', IOS_PLAN)
        self.assertIn('[.rounds, .duration, .roundRest]', IOS_PLAN)
        self.assertIn('"Tiempo (s)" to "roundRest"', ANDROID_EDITOR)
        self.assertNotIn('"Rondas (s)" to "roundRest"', ANDROID_EDITOR)

    def test_scan_opens_create_editor(self):
        self.assertIn("scannedRoutine(from:", IOS_HOME)
        self.assertIn("mode: .oneOff(isNew: true)", IOS_HOME)
        self.assertIn("PendingBoardScanDraft.hold", ANDROID_NAV)
        self.assertIn("rutina-nueva?fecha=", ANDROID_NAV)
        self.assertIn('Text("Continuar")', ANDROID_CONFIRM)
        self.assertNotIn('Text("Crear rutina")', ANDROID_CONFIRM)
        render = (
            ROOT / "android/mobile/src/test/java/dev/repera/mobile/render/BoardClassicReviewRenderTest.kt"
        ).read_text(encoding="utf-8")
        self.assertIn('onNodeWithText("Continuar")', render)
        self.assertNotIn('onNodeWithText("Crear rutina")', render)

    def test_for_time_keeps_bare_scheme(self):
        self.assertIn("bareScheme", IOS_PARSER)
        self.assertIn("current?.format == .forTime", IOS_PARSER)
        self.assertIn("bareScheme", ANDROID_PARSER)
        self.assertIn("current?.format == WODFormat.FOR_TIME", ANDROID_PARSER)

    def test_editor_and_play_stay_fast_with_many_exercises(self):
        ios_plan = IOS_PLAN
        ios_workout = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
        android_play = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("exercisesById", ios_plan)
        self.assertIn("Solo el ejercicio actual monta el editor de series", ios_workout)
        self.assertIn("playBlockSectionBody(", ios_workout)
        self.assertIn("playBlockExerciseRows(", ios_workout)
        self.assertIn("PlayEditableSetsView(", ios_workout)
        self.assertIn("exerciseEntry:", ios_workout)
        self.assertLess(
            ios_workout.index("Solo el ejercicio actual monta el editor de series"),
            ios_workout.index("PlayEditableSetsView("),
        )
        self.assertIn("playCompactEntries = true", android_play)
        self.assertIn("routine_blocks_editor_list", ANDROID_EDITOR)
        self.assertIn("includeEntries = false", ANDROID_EDITOR)
        self.assertIn("expandedEntryId", ANDROID_EDITOR)
        self.assertIn("exercisesById", ANDROID_EDITOR)

    def test_format_picker_rounds_top_corners(self):
        """Título fuera de Section/card para que «Sin formato» lleve el radio superior."""
        picker = IOS_PLAN.split("struct WODFormatPickerPage", 1)[1].split(
            "// MARK: - Importar bloques", 1
        )[0]
        self.assertIn('OGScrollablePageTitle("Formato del bloque")', picker)
        self.assertIn("Section {", picker)
        self.assertLess(
            picker.index('OGScrollablePageTitle("Formato del bloque")'),
            picker.index("Section {"),
        )
        android_picker = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/BlockFormatPickerSheet.kt"
        ).read_text(encoding="utf-8")
        self.assertIn('testTag("block_format_group")', android_picker)
        self.assertIn(".clip(shape)", android_picker)


if __name__ == "__main__":
    unittest.main()
