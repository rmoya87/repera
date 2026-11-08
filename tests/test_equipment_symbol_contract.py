"""Chips de equipo: materiales nuevos (AbMat, etc.) no deben caer al dumbbell genérico."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class EquipmentSymbolContractTests(unittest.TestCase):
    def test_ios_maps_abmat_and_parallettes(self):
        symbols = read("Apps/Repera/Sources/ExerciseDetailView.swift")
        block = symbols.split("static func equipmentSymbol(for material: String)", 1)[1]
        block = block.split("return equipment", 1)[0]
        self.assertIn('contains("abmat")', block)
        self.assertIn('contains("ab mat")', block)
        self.assertIn('contains("colchoneta")', block)
        self.assertIn('contains("parallette")', block)
        self.assertIn('contains("neumatico")', block)
        self.assertIn('contains("maza")', block)
        self.assertIn('contains("husafell")', block)

    def test_android_maps_same_materials(self):
        symbols = read(
            "android/mobile/src/main/java/dev/repera/mobile/ExerciseCategorySymbols.kt"
        )
        block = symbols.split("fun equipmentSymbol(material: String)", 1)[1]
        block = block.split("return equipment", 1)[0]
        self.assertIn('contains("abmat")', block)
        self.assertIn('contains("ab mat")', block)
        self.assertIn('contains("colchoneta")', block)
        self.assertIn('contains("parallette")', block)
        self.assertIn('contains("neumatico")', block)
        self.assertIn('contains("maza")', block)
        self.assertIn('contains("husafell")', block)

    def test_equipment_group_lists_abmats(self):
        ios = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/ExerciseEquipmentGroup.swift"
        )
        android = read(
            "android/domain/src/main/java/dev/repera/domain/ExerciseEquipmentGroup.kt"
        )
        self.assertIn("abmat", ios.lower())
        self.assertIn("AbMats", ios)
        self.assertIn("abmat", android.lower())
        self.assertIn("AbMats", android)

    def test_equipment_group_declared_wins_and_mat_is_safe(self):
        ios = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/ExerciseEquipmentGroup.swift"
        )
        android = read(
            "android/domain/src/main/java/dev/repera/domain/ExerciseEquipmentGroup.kt"
        )
        for src in (ios, android):
            self.assertIn("isMatEquipment", src)
            self.assertIn("Neumáticos", src)
            self.assertIn("genericEquipment", src)
            self.assertIn("couch stretch", src.lower())
            self.assertIn("back lever", src.lower())
            # No usar `mat` como substring libre (pillar «neumatico»).
            self.assertNotIn('equipped(["colchoneta", "yoga mat", "exercise mat", "mat"])', src)
            self.assertNotIn('equipped(listOf("colchoneta", "yoga mat", "exercise mat", "mat"))', src)

    def test_seed_back_lever_and_pullups_use_correct_equipment(self):
        gim = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/CatalogGimnasia.swift"
        )
        cf = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/CatalogCrossFit.swift"
        )
        mov = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/CatalogMovilidad.swift"
        )
        self.assertIn('gy("Back lever tuck", equipment: "Anillas"', gim)
        self.assertIn('equipment: "Pared"', mov)
        self.assertIn("Couch stretch", mov)
        for name in (
            'cf("Jumping Pull-Up", equipment: "Barra de dominadas"',
            'cf("L Pull Up", equipment: "Barra de dominadas"',
            'cf("Negative Pull Up", equipment: "Barra de dominadas"',
            'cf("Dead Hang", equipment: "Barra de dominadas"',
            'cf("Dumbbell Box Step Up", equipment: "Cajón, Mancuernas"',
            'cf("Tire Flip", equipment: "Neumático"',
        ):
            self.assertIn(name, cf)


if __name__ == "__main__":
    unittest.main()
