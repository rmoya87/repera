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
    def test_block_and_exercise_deletion_uses_menus_only(self):
        block = EDITOR.split("ForEach(Array(routine.blocks.enumerated())", 1)[1].split(
            'if block.kind == .strength', 1
        )[0]
        self.assertIn('Label("Eliminar bloque", systemImage: "trash")', block)
        self.assertNotIn(".swipeActions(", block)
        strength = EDITOR.split("private func strengthBlock(index: Int)", 1)[1].split(
            "private func plannedSetBinding", 1
        )[0]
        self.assertIn("exerciseOptions(blockID:", strength)
        self.assertIn("replacementButton(blockID:", strength)
        self.assertNotIn(".swipeActions(", strength)
        self.assertIn('Button("Eliminar ejercicio", systemImage: "trash", role: .destructive)', EDITOR)

    def test_only_series_support_bounded_swipe(self):
        impl = EDITOR.split("struct OGSetSwipeDeleteRow<", 1)[1].split(
            "// MARK: - Inline WOD sets", 1
        )[0]
        self.assertIn("private var isRevealed: Bool { openedSetID == setID }", impl)
        self.assertIn("openedSetID = projected < -revealWidth * 0.4 ? setID : nil", impl)
        self.assertIn('Image(systemName: "trash.fill")', impl)
        self.assertIn("max(-revealWidth, min(0,", impl)
        strength = EDITOR.split("private func strengthBlock(index: Int)", 1)[1].split(
            "private func plannedSetBinding", 1
        )[0]
        self.assertIn("OGSetSwipeDeleteRow(", strength)
        self.assertIn("deleteStrengthSet(blockIndex:", strength)
        inline = EDITOR.split("private struct InlineWODMovementSets: View", 1)[1].split(
            "struct WODMovementEditor:", 1
        )[0]
        self.assertIn("OGSetSwipeDeleteRow(", inline)
        self.assertIn("openedSetID: $openedSetID", inline)

    def test_drag_and_drop_is_removed_from_workout_editor(self):
        self.assertNotIn(".draggable(", EDITOR)
        self.assertNotIn(".dropDestination(", EDITOR)
        self.assertNotIn(".reorderable(", EDITOR)
        self.assertNotIn(".reorderContainer(", EDITOR)
        self.assertIn("moveBlock(block.id, offset:", EDITOR)
        self.assertIn("moveExercise(type:", EDITOR)

    def test_replacement_resets_item_identity_and_warns_about_results(self):
        self.assertIn('¿Sustituir ejercicio y reiniciar sus series?', EDITOR)
        self.assertIn('registered?.loggedSets.isEmpty == false', EDITOR)
        self.assertIn('routine.blocks[blockIndex].exercises[index] = RoutineExercise(', EDITOR)
        self.assertIn('routine.blocks[blockIndex].movements[index] = WODMovement(', EDITOR)

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
