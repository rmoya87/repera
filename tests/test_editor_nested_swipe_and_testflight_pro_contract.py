"""Guard editor swipe independence and verified TestFlight subscriptions.

These source contracts complement Xcode/iPhone simulator and physical-device UI
checks; they do not claim to execute UIKit gestures on a device.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
EDITOR = (IOS / "PlanView.swift").read_text(encoding="utf-8")
SETTINGS = (IOS / "SettingsView.swift").read_text(encoding="utf-8")
MANAGER = (IOS / "Monetization" / "SubscriptionManager.swift").read_text(encoding="utf-8")


class EditorSwipeAndTestFlightProContracts(unittest.TestCase):
    def test_each_block_header_has_one_delete_action(self):
        block = EDITOR.split("ForEach(Array(routine.blocks.enumerated())", 1)[1].split(
            'Text(block.title)', 1
        )[0]
        self.assertIn('OGSwipeDeleteButton(accessibilityLabel: "Eliminar bloque")', block)
        self.assertIn("routine.blocks.removeAll { $0.id == block.id }", block)
        self.assertIn(".swipeActions(edge: .trailing, allowsFullSwipe: false)", block)

    def test_exercise_and_strength_set_have_separate_swipe_actions(self):
        block = EDITOR.split("private func strengthBlock(index: Int)", 1)[1].split(
            "private func plannedSetBinding", 1
        )[0]
        self.assertEqual(block.count('accessibilityLabel: "Quitar ejercicio"'), 1)
        self.assertEqual(block.count('accessibilityLabel: "Eliminar serie"'), 1)
        self.assertIn("deleteStrengthSet(blockIndex: index, exerciseIndex: exIndex, setIndex: setIndex)", block)
        self.assertIn(".swipeActions(edge: .trailing, allowsFullSwipe: false)", block)
        self.assertIn("routine.blocks[index].exercises.removeAll { $0.id == item.id }", block)

    def test_series_swipe_is_attached_at_form_row_not_inside_reusable_row(self):
        reusable = EDITOR.split("private struct PlannedSetConfigRow: View", 1)[1].split(
            "struct ExercisePickerView:", 1
        )[0]
        self.assertNotIn(".swipeActions(", reusable)
        strengthEditor = EDITOR.split("struct RoutineExerciseEditor: View", 1)[1].split(
            "private struct PlannedSetConfigRow:", 1
        )[0]
        self.assertIn("OGSwipeDeleteButton(accessibilityLabel: \"Eliminar serie\")", strengthEditor)
        self.assertIn("if item.plannedSets.count > 1", strengthEditor)

    def test_wod_inline_sets_reveal_a_single_clamped_trash_button(self):
        impl = EDITOR.split("private struct InlineSetSwipeDeleteRow<", 1)[1].split(
            "// MARK: - Inline WOD sets", 1
        )[0]
        self.assertIn("private var isRevealed: Bool { openedSetID == setID }", impl)
        self.assertIn("openedSetID = projected < -revealWidth * 0.4 ? setID : nil", impl)
        self.assertIn('Image(systemName: "trash.fill")', impl)
        self.assertIn("max(-revealWidth, min(0,", impl)
        self.assertNotIn(".swipeActions(", impl)
        inline = EDITOR.split("private struct InlineWODMovementSets: View", 1)[1].split(
            "private struct WODMovementEditor:", 1
        )[0]
        self.assertIn("openedSetID: $openedSetID", inline)
        self.assertIn("setID: currentSet.id", inline)
        self.assertIn("onDelete: { removeSet(at: index) }", inline)

    def test_paid_catalog_fallback_does_not_revoke_verified_pro(self):
        self.assertIn("if !snapshot.grantsProAccess {", MANAGER)
        self.assertIn("if !offerings.packages.isEmpty, !snapshot.grantsProAccess {", MANAGER)
        self.assertIn("guard !policy.isPro else { return }", MANAGER)
        self.assertIn("verifiedAppleAccessIfNeeded(next)", MANAGER)

    def test_physical_iphone_can_recheck_testflight_access_in_settings(self):
        self.assertIn('isVerifyingSubscription', SETTINGS)
        self.assertIn('Comprobar acceso Pro', SETTINGS)
        self.assertIn("await subscriptions.refreshEntitlementsForFeatureAction()", SETTINGS)
        self.assertIn('Acceso Pro verificado en este dispositivo.', SETTINGS)
        self.assertIn('Restaurar compras', SETTINGS)


if __name__ == "__main__":
    unittest.main()
