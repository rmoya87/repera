"""Ajustes oculta el menú principal (animación hacia abajo) en iOS/Android."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_SETTINGS = (ROOT / "Apps/Repera/Sources/SettingsView.swift").read_text(encoding="utf-8")
IOS_AI = (ROOT / "Apps/Repera/Sources/AIAccessView.swift").read_text(encoding="utf-8")
ANDROID_TABS = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaFloatingTabBar.kt"
).read_text(encoding="utf-8")
ANDROID_SETTINGS = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt"
).read_text(encoding="utf-8")


class SettingsTabBarHideContractTests(unittest.TestCase):
    def test_ios_settings_hides_tab_bar(self):
        self.assertIn(".toolbar(.hidden, for: .tabBar)", IOS_SETTINGS)
        self.assertIn(".toolbar(.hidden, for: .tabBar)", IOS_AI)
        self.assertNotIn("Exercise data by RepDB", IOS_SETTINGS)

    def test_ios_workout_detail_and_preview_hide_tab_bar(self):
        detail = (ROOT / "Apps/Repera/Sources/HistoryView.swift").read_text(encoding="utf-8")
        preview = (ROOT / "Apps/Repera/Sources/SessionPreviewView.swift").read_text(encoding="utf-8")
        self.assertIn(".toolbar(.hidden, for: .tabBar)", detail)
        self.assertIn(".toolbar(.hidden, for: .tabBar)", preview)

    def test_android_settings_routes_hide_tab_bar_with_slide(self):
        keeps = ANDROID_TABS.split(
            "internal fun reperaRouteKeepsTabBar(route: String?): Boolean", 1
        )[1].split("internal val REPERA_TAB_BAR_MAX_WIDTH", 1)[0]
        self.assertIn('route == "ajustes" || route.startsWith("ajustes-") -> false', keeps)
        self.assertIn('route == "acceso-ia" || route == "programas-ia" -> false', keeps)
        self.assertIn('route.startsWith("historial-detalle") -> false', keeps)
        self.assertIn('route.startsWith("preview/") -> false', keeps)
        self.assertNotIn('route == "ajustes" -> true', keeps)
        self.assertIn("slideOutVertically", ANDROID_TABS)
        self.assertNotIn("Exercise data by RepDB", ANDROID_SETTINGS)


if __name__ == "__main__":
    unittest.main()
