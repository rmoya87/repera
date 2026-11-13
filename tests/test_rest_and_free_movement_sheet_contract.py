#!/usr/bin/env python3
"""Descanso (no REST) + miniatura; movimiento libre como sheet en iOS/Android."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID_EDITOR = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/RoutineBlocksEditor.kt"
).read_text(encoding="utf-8")
ANDROID_COMPONENTS = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaComponents.kt"
).read_text(encoding="utf-8")
IOS_PLAN = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
IOS_WORKOUT = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
IOS_CARD = (ROOT / "Apps/Repera/Sources/OGRoutineBlockCard.swift").read_text(
    encoding="utf-8"
)
IOS_MODELS = (
    ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/Models.swift"
).read_text(encoding="utf-8")


class RestAndFreeMovementSheetContract(unittest.TestCase):
    def test_android_rest_shows_descanso_and_thumb(self):
        self.assertIn('isRest -> "Descanso"', ANDROID_EDITOR)
        self.assertIn("isRest = isRest", ANDROID_EDITOR)
        self.assertIn("RestListThumb()", ANDROID_EDITOR)
        self.assertIn("fun RestListThumb(", ANDROID_COMPONENTS)
        self.assertIn("Icons.Filled.Pause", ANDROID_COMPONENTS)
        # Filas compactas aceptan isRest para no dejar hueco vacío a la izquierda.
        self.assertIn("isRest: Boolean = false", ANDROID_EDITOR)

    def test_android_insert_actions_only_inside_block(self):
        play = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt"
        ).read_text(encoding="utf-8")
        # Dentro del card del bloque.
        self.assertIn("includeFooterActions = true", play)
        # No duplicar Ejercicio/Descanso/Libre en el pie de Play (paridad iOS).
        footer = play.split("fun PlaySessionPlanFooter(", 1)[1].split(
            "fun ActiveWorkoutToolbar(", 1
        )[0]
        self.assertNotIn("WorkoutWODInsertActions(", footer)

    def test_android_free_movement_is_bottom_sheet(self):
        self.assertIn("free_move_sheet", ANDROID_EDITOR)
        self.assertIn("ReperaModalBottomSheet(", ANDROID_EDITOR)
        self.assertIn("skipPartiallyExpanded = true", ANDROID_EDITOR)
        self.assertNotIn("AlertDialog(", ANDROID_EDITOR.split("fun FreeMovementDialog")[1].split("@Composable\nprivate fun NumberRow")[0])

    def test_ios_free_movement_is_fitted_sheet(self):
        self.assertIn(".sheet(item: $createFreeMovementForBlock)", IOS_PLAN)
        self.assertIn(".sheet(item: $createFreeMovementForBlock)", IOS_WORKOUT)
        self.assertNotIn(
            ".navigationDestination(item: $createFreeMovementForBlock)", IOS_PLAN
        )
        self.assertNotIn(
            ".navigationDestination(item: $createFreeMovementForBlock)", IOS_WORKOUT
        )
        self.assertIn("struct FreeMovementBlockTarget: Identifiable", IOS_PLAN)
        self.assertIn("FreeMovementBlockTarget?", IOS_PLAN)
        self.assertIn("FreeMovementBlockTarget?", IOS_WORKOUT)
        self.assertIn(".ogFittedSheet()", IOS_PLAN)
        self.assertIn('OGPageHeader(title: "Nuevo movimiento")', IOS_PLAN)

    def test_ios_rest_row_has_pause_thumb_and_descanso(self):
        self.assertIn('Text("Descanso")', IOS_CARD)
        self.assertIn('Image(systemName: "pause.fill")', IOS_CARD)
        self.assertIn(".frame(width: 48, height: 48)", IOS_CARD)
        self.assertIn('Text(move.isRest ? "Descanso" : resolved.name)', IOS_PLAN)

    def test_ios_rest_stays_inside_block_not_separate(self):
        # No crear RoutineBlock(title: "Descanso") aparte al pulsar Descanso.
        self.assertIn("promoteStrengthBlockToWODIfNeeded", IOS_PLAN)
        self.assertIn("movements.append(rest)", IOS_PLAN)
        self.assertNotIn(
            'RoutineBlock(title: "Descanso", kind: .wod, movements: [rest])',
            IOS_PLAN,
        )
        self.assertNotIn(
            'RoutineBlock(title: "Descanso", kind: .wod, movements: [rest])',
            IOS_WORKOUT,
        )
        # Inputs como el resto de la config (OGFormatNumberField), no Stepper.
        self.assertIn('title: "Segundos"', IOS_PLAN)
        self.assertIn('unit: "s"', IOS_PLAN)
        self.assertIn("OGFormatNumberField(", IOS_PLAN)
        rest_ui = IOS_PLAN.split("if move.isRest {")[1].split("} else if isEditingCompletedWorkout")[0]
        self.assertNotIn("Stepper(", rest_ui)
        self.assertIn('return "\\(sec) s"', IOS_MODELS)
        self.assertNotIn("' REST", IOS_MODELS)


if __name__ == "__main__":
    unittest.main()
