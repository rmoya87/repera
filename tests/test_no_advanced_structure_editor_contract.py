"""Advanced structure editors were removed from Create/Edit/Play/Business."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class NoAdvancedStructureEditorContract(unittest.TestCase):
    def test_ios_sources_drop_structure_editor(self):
        self.assertFalse((ROOT / "Apps/Repera/Sources/WorkoutStructureEditorView.swift").exists())
        plan = read("Apps/Repera/Sources/PlanView.swift")
        play = read("Apps/Repera/Sources/WorkoutView.swift")
        self.assertNotIn("WorkoutStructureEditorView", plan)
        self.assertNotIn("WorkoutStructureEditorView", play)
        self.assertNotIn("Estructura avanzada", plan)
        self.assertNotIn("Estructura avanzada", play)

    def test_android_drops_phase_controls(self):
        self.assertFalse(
            (ROOT / "android/mobile/src/main/java/dev/repera/mobile/AdvancedPhaseControls.kt").exists()
        )
        editor = read("android/mobile/src/main/java/dev/repera/mobile/RoutineBlocksEditor.kt")
        self.assertNotIn("AdvancedPhaseControls", editor)
        self.assertNotIn("advancedPhases", editor)
        self.assertNotIn("Fases y técnicas", editor)

    def test_business_web_drops_advanced_markup(self):
        editor = read("web/console/src/ui/workout-editor.js")
        self.assertNotIn("Estructura avanzada", editor)
        self.assertNotIn("advancedStructureMarkup", editor)
        self.assertNotIn("data-advanced-structure", editor)
        self.assertNotIn("advanced-add", editor)
        self.assertIn("readPreservedStructure", editor)

    def test_project_yml_does_not_require_removed_swift(self):
        spec = read("project.yml")
        self.assertNotIn("WorkoutStructureEditorView.swift", spec)


if __name__ == "__main__":
    unittest.main()
