"""Regressions for the visually integrated competitive-reference + training load."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class StrengthVisualContract(unittest.TestCase):
    def test_demographics_have_one_synced_source(self):
        swift = source("Packages/ReperaDomain/Sources/ReperaDomain/Models.swift")
        android = source("android/mobile/src/main/java/dev/repera/mobile/TrainingSettings.kt")
        for field in ("competitionSex", "birthYear"):
            self.assertIn(f"public var {field}:", swift)
            self.assertIn(f"val {field}:", android)
            self.assertIn(f'case ', swift)
            self.assertIn(f's.put("{field}"', android)
        self.assertIn("Picker(\"Año de nacimiento\"", source("Apps/Repera/Sources/SettingsView.swift"))
        self.assertIn("Género · referencia de fuerza", source(
            "android/mobile/src/main/java/dev/repera/mobile/TrainingSettingsSection.kt"))

    def test_strength_reference_is_embedded_in_evolution_not_separate_card(self):
        ios_detail = source("Apps/Repera/Sources/ExerciseDetailView.swift")
        ios_evolution = source("Apps/Repera/Sources/ExerciseProgressView.swift")
        android_detail = source("android/mobile/src/main/java/dev/repera/mobile/ExerciseDetailScreen.kt")
        self.assertNotIn("StrengthBenchmarkCard(", ios_detail)
        self.assertNotIn("StrengthBenchmarkCard(", android_detail)
        self.assertIn("StrengthBenchmarkVisual(", ios_evolution)
        self.assertIn("StrengthBenchmarkVisual(", android_detail)
        self.assertIn("summary?.estimatedOneRM ?: estimatedOneRM", android_detail)

    def test_no_redundant_demographic_inputs_or_long_warning_card(self):
        for path in (
            "Apps/Repera/Sources/StrengthBenchmarkCard.swift",
            "android/mobile/src/main/java/dev/repera/mobile/StrengthBenchmarkCard.kt",
        ):
            view = source(path)
            self.assertNotIn("TextField(\"Peso corporal", view)
            self.assertNotIn("Es una orientación: no mide tu", view)
            self.assertNotIn("Frente a ", view)
            self.assertIn("e1RM estimado", view)
            self.assertIn("gaussian", view.lower())
        self.assertIn("store.state.bodyWeights", source(
            "Apps/Repera/Sources/StrengthBenchmarkCard.swift"))
        self.assertIn("bodyWeightHistory?.firstOrNull()?.kg", source(
            "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt"))

    def test_competition_reference_not_misrepresented_as_population(self):
        swift = source("Apps/Repera/Sources/StrengthBenchmarkCard.swift")
        android = source("android/mobile/src/main/java/dev/repera/mobile/StrengthBenchmarkCard.kt")
        self.assertIn("illustration", swift)
        self.assertIn("not an empirically fitted normal distribution", android)
        self.assertIn("StrengthBenchmarkEngine.compareCompetitionOneRepMax", swift)
        self.assertIn("StrengthBenchmarkEngine.compareCompetitionOneRepMax", android)

    def test_recovery_has_daily_line_and_pro_gate(self):
        ios = source("Apps/Repera/Sources/HealthRecovery.swift")
        android = source("android/mobile/src/main/java/dev/repera/mobile/RecoveryTrainingLoadCard.kt")
        tab = source("android/mobile/src/main/java/dev/repera/mobile/ProgressTab.kt")
        self.assertIn("ForEach(days.indices", ios)
        self.assertIn("let day = days[index]", ios)
        self.assertIn('x: .value("Día", day.date)', ios)
        self.assertIn('y: .value("Minutos", day.minutes)', ios)
        self.assertNotIn("point.date", ios.split("Carga · 14 días", 1)[-1].split("trainingRecoveryCard", 1)[0])
        self.assertIn("LineMark(", ios)
        self.assertIn("(0..<14)", ios)
        self.assertIn("Canvas(", android)
        self.assertIn("(13 downTo 0)", android)
        self.assertIn("distinctBy { it.id }", android)
        self.assertIn("if (pro)", tab)
        self.assertIn("RecoveryTrainingLoadCard(overview)", tab)


if __name__ == "__main__":
    unittest.main()
