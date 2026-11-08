"""Etiquetas de equipo cortas: Colchoneta, sin frases largas ni «variante C»."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class EquipmentDisplayContractTests(unittest.TestCase):
    def test_ios_domain_canonicalizes_mat_and_variant_noise(self):
        src = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/ExerciseEquipmentDisplay.swift"
        )
        self.assertIn('return "Colchoneta"', src)
        self.assertIn("variante", src)
        self.assertIn("splitTokens", src)
        self.assertIn(";", src)

    def test_android_domain_mirrors_canonicalizer(self):
        src = read(
            "android/domain/src/main/java/dev/repera/domain/ExerciseEquipmentDisplay.kt"
        )
        self.assertIn('return "Colchoneta"', src)
        self.assertIn("variante", src)
        self.assertIn("splitTokens", src)

    def test_detail_views_use_display_chips(self):
        ios = read("Apps/Repera/Sources/ExerciseDetailView.swift")
        android = read(
            "android/mobile/src/main/java/dev/repera/mobile/ExerciseDetailScreen.kt"
        )
        self.assertIn("ExerciseEquipmentDisplay.chips", ios)
        self.assertIn("ExerciseEquipmentDisplay.chips", android)
        self.assertNotIn(
            '.split(separator: ",")\n            .map { LocalizedMuscle.es',
            ios,
        )

    def test_arch_hold_seed_uses_colchoneta(self):
        gym = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/CatalogGimnasia.swift"
        )
        block = gym.split('gy("Arch hold"', 1)[1].split("gy(", 1)[0]
        self.assertIn('equipment: "Colchoneta"', block)
        self.assertIn('contains("colchoneta")', read(
            "Apps/Repera/Sources/ExerciseDetailView.swift"
        ))


if __name__ == "__main__":
    unittest.main()
