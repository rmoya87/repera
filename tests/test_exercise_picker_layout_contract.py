"""Contrato Elegir ejercicio: título→búsqueda, chips glass, Recientes máx. 5."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = (ROOT / "Apps/Repera/Sources/ExerciseCatalogSearchList.swift").read_text(encoding="utf-8")
DAY_PLUS = (ROOT / "Apps/Repera/Sources/DayPlusSheet.swift").read_text(encoding="utf-8")
ANDROID = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ExercisePickerSheet.kt"
).read_text(encoding="utf-8")


class ExercisePickerLayoutContract(unittest.TestCase):
    def test_ios_title_before_inline_search_not_nav_drawer(self):
        self.assertIn("OGScrollablePageTitle(pageTitle)", IOS)
        self.assertIn("pickerSearchField", IOS)
        self.assertIn("glassEffect(.regular, in: Capsule", IOS)
        self.assertNotIn(
            "searchable(text: $query, placement: .navigationBarDrawer",
            IOS,
        )
        # Título aparece en el body antes del campo de búsqueda.
        title_at = IOS.index("OGScrollablePageTitle(pageTitle)")
        search_at = IOS.index("pickerSearchField")
        self.assertLess(title_at, search_at)
        # Sin caja agrupada que corta la «j»; buscador al ancho de las cards.
        self.assertIn(".ogScrollingTitleSection()", IOS)
        self.assertIn(
            "listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))",
            IOS,
        )
        # Chips edge-to-edge (no recorte insetGrouped).
        self.assertIn("listSectionMargins(.horizontal, 0)", IOS)

    def test_ios_chips_liquid_glass_when_unselected(self):
        self.assertIn("ExercisePickerChipChrome", IOS)
        self.assertIn("glassEffect(.regular.interactive(), in: shape)", IOS)
        chrome = IOS.split("struct ExercisePickerChipChrome", 1)[1].split(
            "extension ExerciseCatalogSearchList", 1
        )[0]
        self.assertIn("if isSelected", chrome)
        self.assertIn("glassEffect", chrome)

    def test_ios_recents_max_five_and_only_all_filter(self):
        self.assertIn("if ids.count >= 5 { return ids }", IOS)
        self.assertIn("showsRecents", IOS)
        self.assertIn("filter == .all", IOS)
        self.assertIn("if showsRecents", IOS)

    def test_android_title_before_search_and_chip_day_night(self):
        self.assertIn('title = "Elegir ejercicio"', ANDROID)
        self.assertIn("ReperaPageHeader", ANDROID)
        self.assertIn("ReperaSearchField", ANDROID)
        header_at = ANDROID.index("ReperaPageHeader")
        search_at = ANDROID.index('placeholder = "Buscar ejercicio"')
        self.assertLess(header_at, search_at)
        self.assertIn("isSystemInDarkTheme()", ANDROID)
        chip = ANDROID.split("private fun MuscleFilterChip", 1)[1].split(
            "private fun PickerRow", 1
        )[0]
        self.assertIn("Color.White", chip)
        self.assertIn("Color.Black", chip)
        self.assertIn("brandGreen", chip)

    def test_android_recents_max_five_hidden_when_filtered(self):
        self.assertIn(".take(5)", ANDROID)
        self.assertIn("showsRecents", ANDROID)
        self.assertIn("muscleFilter == null", ANDROID)
        self.assertIn("recentExerciseIdsFromHistory", ANDROID)

    def test_day_plus_menu_rows_geometry_group(self):
        """Icono + texto del sheet Añadir entreno animan juntos al reaparecer."""
        self.assertIn(".geometryGroup()", DAY_PLUS)
        label = DAY_PLUS.split("private func menuLabel", 1)[1].split(
            "private func requestBoardScan", 1
        )[0]
        self.assertIn(".geometryGroup()", label)


if __name__ == "__main__":
    unittest.main()
