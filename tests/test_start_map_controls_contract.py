"""Regresiones del mapa de Comenzar: sin acceso a Center y SF Symbol 3D."""

import unittest
from pathlib import Path


SOURCES = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def read_swift(name: str) -> str:
    return (SOURCES / name).read_text(encoding="utf-8")


class StartMapControlsContractTests(unittest.TestCase):
    def test_start_tab_only_opens_live_activity_not_professional_center(self):
        root = read_swift("RootTabView.swift")
        self.assertIn('SwiftUI.Tab("Comenzar"', root)
        self.assertIn("value: AppTab.start", root)
        self.assertIn("LiveActivityView(", root)
        self.assertNotIn("onOpenCenter:", root)
        self.assertNotIn("showCenter", root)
        self.assertNotIn("NavigationStack { CenterView() }", root)

    def test_map_has_no_center_entry_point_or_center_modal(self):
        live = read_swift("LiveActivityView.swift")
        self.assertNotIn("onOpenCenter", live)
        self.assertNotIn('label: "Mi centro"', live)
        self.assertNotIn('mapCircleButton("building.2"', live)

    def test_map_3d_button_uses_requested_symbol_and_keeps_2d_toggle(self):
        live = read_swift("LiveActivityView.swift")
        self.assertIn('navigationMapEnabled ? "map" : "view.3d"', live)
        self.assertIn("navigationMapEnabled.toggle()", live)
        self.assertIn('label: navigationMapEnabled ? "Cambiar a vista 2D"', live)
        self.assertNotIn('"cube.transparent"', live)


if __name__ == "__main__":
    unittest.main()
