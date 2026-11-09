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
        for field in ("competitionSex", "birthYear", "strengthReferenceFrame"):
            self.assertIn(f"public var {field}:", swift)
            self.assertIn(f"val {field}:", android)
            self.assertIn(f'case ', swift)
            self.assertIn(f's.put("{field}"', android)
        settings = source("Apps/Repera/Sources/SettingsView.swift")
        android_settings = source(
            "android/mobile/src/main/java/dev/repera/mobile/TrainingSettingsSection.kt")
        self.assertIn("Picker(\"Año de nacimiento\"", settings)
        self.assertIn("Picker(\"Género\"", settings)
        self.assertIn("Picker(\"Nivel\"", settings)
        self.assertIn("Amateur", settings)
        self.assertIn("Élite", settings)
        self.assertIn("Mejorar Amateur (anónimo)", settings)
        self.assertIn("contributeAnonymousStrengthStats", swift)
        self.assertIn("contributeAnonymousStrengthStats", android)
        self.assertIn("Mejorar Amateur (anónimo)", android_settings)
        self.assertIn("contributeAnonymousStrengthStats", android_settings)
        self.assertNotIn("Género (referencia deportiva)", settings)
        self.assertIn('Text("Género"', android_settings)
        self.assertIn('Text("Nivel"', android_settings)
        self.assertIn('"Amateur"', android_settings)
        self.assertIn('"Élite"', android_settings)
        self.assertNotIn("Género · referencia de fuerza", android_settings)
        self.assertIn('"Femenino"', android_settings)
        self.assertIn('"Masculino"', android_settings)

    def test_rendimiento_filters_by_strength_reference_frame(self):
        engine = source(
            "Packages/ReperaDomain/Sources/ReperaDomain/StrengthBenchmarkEngine.swift")
        android_engine = source(
            "android/domain/src/main/java/dev/repera/domain/StrengthBenchmarkEngine.kt")
        ios_visual = source("Apps/Repera/Sources/StrengthBenchmarkCard.swift")
        android_visual = source(
            "android/mobile/src/main/java/dev/repera/mobile/StrengthBenchmarkCard.kt")
        self.assertIn("enum StrengthReferenceFrame", engine)
        self.assertIn('case amateur', engine)
        self.assertIn('case elite', engine)
        self.assertIn('["SymmetricStrength"]', engine)
        self.assertIn('["OpenPowerlifting"]', engine)
        self.assertIn("frame: StrengthReferenceFrame = .amateur", engine)
        self.assertIn("enum class StrengthReferenceFrame", android_engine)
        self.assertIn('setOf("SymmetricStrength")', android_engine)
        self.assertIn('setOf("OpenPowerlifting")', android_engine)
        self.assertIn("frame: StrengthReferenceFrame = StrengthReferenceFrame.AMATEUR",
                      android_engine)
        self.assertIn("store.state.settings.strengthReferenceFrame", ios_visual)
        self.assertIn("allowed.contains($0.source)", ios_visual)
        self.assertIn("strengthReferenceFrame", android_visual)
        self.assertIn("it.source in allowed", android_visual)
        assets_ios = (ROOT / "Apps/Repera/Resources/strength_benchmarks.json").read_text(
            encoding="utf-8")
        self.assertIn("OpenPowerlifting", assets_ios)
        self.assertIn("SymmetricStrength", assets_ios)
        self.assertIn("fitnessvolt-gym-seed-2026-11-09", assets_ios)
        migration = source(
            "supabase/migrations/20261109160000_strength_benchmark_frames.sql")
        self.assertIn("strength_benchmark_bootstrap", migration)
        self.assertIn("strength_benchmark_delta", migration)
        self.assertIn("strength_benchmark_contribution_inbox", migration)

    def test_strength_reference_is_embedded_in_evolution_not_separate_card(self):
        ios_detail = source("Apps/Repera/Sources/ExerciseDetailView.swift")
        ios_evolution = source("Apps/Repera/Sources/ExerciseProgressView.swift")
        android_detail = source("android/mobile/src/main/java/dev/repera/mobile/ExerciseDetailScreen.kt")
        self.assertNotIn("StrengthBenchmarkCard(", ios_detail)
        self.assertNotIn("StrengthBenchmarkCard(", android_detail)
        self.assertIn("StrengthBenchmarkVisual(", ios_evolution)
        self.assertIn("StrengthBenchmarkVisual(", android_detail)
        self.assertIn("summary?.estimatedOneRM ?: estimatedOneRM", android_detail)
        # After the personal records chart, not above metric pickers.
        self.assertLess(
            ios_evolution.index("chartBlock"),
            ios_evolution.index("StrengthBenchmarkVisual("),
        )
        self.assertLess(
            android_detail.index('testTag("exercise_evolution_chart")'),
            android_detail.index("StrengthBenchmarkVisual("),
        )
        self.assertIn('"Rendimiento"', source("Apps/Repera/Sources/StrengthBenchmarkCard.swift"))
        self.assertIn('"Rendimiento"', source(
            "android/mobile/src/main/java/dev/repera/mobile/StrengthBenchmarkCard.kt"))
        self.assertNotIn("Tu nivel · fuerza", source(
            "Apps/Repera/Sources/StrengthBenchmarkCard.swift"))
        self.assertNotIn("Referencia competitiva · orientativa", source(
            "Apps/Repera/Sources/StrengthBenchmarkCard.swift"))
        self.assertNotIn("Competición · orientativo", source(
            "android/mobile/src/main/java/dev/repera/mobile/StrengthBenchmarkCard.kt"))

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
