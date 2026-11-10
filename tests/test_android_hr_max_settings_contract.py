"""Ajustes Android: FC máxima entre −/+ y sin bloquear la UI con busy."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt"
).read_text(encoding="utf-8")
MAIN = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
).read_text(encoding="utf-8")


class AndroidHrMaxSettingsContractTests(unittest.TestCase):
    def test_hr_max_value_between_minus_and_plus(self):
        block = SETTINGS.split('"FC máxima"', 1)[1].split("SettingsCardDivider()", 1)[0]
        minus = block.index('Text("−")')
        value = block.index("$hrMax lpm")
        plus = block.index('Text("+")')
        self.assertLess(minus, value)
        self.assertLess(value, plus)
        self.assertIn("hrReady && hrMax > 120", block)
        self.assertIn("hrReady && hrMax < 230", block)
        self.assertNotIn("!trainingBusy &&", block)

    def test_training_settings_persist_without_busy_gate(self):
        self.assertIn("onUpdateTrainingSettings = ::persistTrainingSettings", MAIN)
        helper = MAIN.split("private fun persistTrainingSettings", 1)[1].split(
            "private fun syncPublicProfileFromSettings", 1
        )[0]
        self.assertIn("snapshot = snapshot?.copy(trainingSettings = value)", helper)
        self.assertNotIn("busy = true", helper)
        self.assertNotIn("runWorkoutAction", helper)


if __name__ == "__main__":
    unittest.main()
