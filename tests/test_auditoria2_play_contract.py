"""Contrato auditoría 2 (Ramón 12/11/2026): Play sin checks, terminar al final, contadores vivos."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Auditoria2PlayContract(unittest.TestCase):
    def test_ios_play_finish_and_save(self):
        workout = (ROOT / "Apps/Repera/Sources/WorkoutView.swift").read_text(encoding="utf-8")
        stats = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/StatsEngine.swift").read_text(encoding="utf-8")
        self.assertIn("func liveWorkSetCount", stats)
        self.assertIn("func liveVolumeKg", stats)
        self.assertNotIn("series sin marcar", workout)
        self.assertIn("presentPlayFinishSummary", workout)
        self.assertIn("Terminar entreno", workout)
        self.assertNotIn("accessibilityLabel(\"Ejercicio siguiente\")", workout)

    def test_android_play_parity(self):
        play = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/ActiveWorkoutScreen.kt").read_text(
            encoding="utf-8"
        )
        live = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveSetRows.kt").read_text(encoding="utf-8")
        self.assertIn("sessionLiveSetCount", play)
        self.assertIn("play_finish_button", play)
        self.assertNotIn("series sin marcar", play)
        self.assertNotIn("Marcar serie", live)
        self.assertIn("DropdownMenu", play)
        self.assertNotIn("showEditStructureMenu", play)

    def test_set_summary_without_weight(self):
        line = (ROOT / "android/domain/src/main/java/dev/repera/domain/SetSummaryLine.kt").read_text(
            encoding="utf-8"
        )
        self.assertIn('"$reps reps"', line)
        models = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/Models.swift").read_text(encoding="utf-8")
        self.assertIn("reps) reps", models)

    def test_keypad_chain_android(self):
        live = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveSetRows.kt").read_text(encoding="utf-8")
        pad = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaNumericKeypad.kt").read_text(encoding="utf-8")
        self.assertIn("keepKeypadOpenOnAdvance", live)
        self.assertIn("dismissKeepsPadOpen", pad)


if __name__ == "__main__":
    unittest.main()
