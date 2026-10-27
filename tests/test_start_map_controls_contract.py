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

    def test_3d_uses_real_camera_even_before_first_gps_fix(self):
        live = read_swift("LiveActivityView.swift")
        self.assertIn("lastVisibleMapCamera = context.camera", live)
        self.assertIn("if navigationMapEnabled && !hasAppliedStored3DCamera", live)
        self.assertIn("hasAppliedStored3DCamera = false", live)
        self.assertIn("private func applyNavigationPitch(to camera: MapCamera)", live)
        self.assertIn("private func toggleNavigationMapMode()", live)
        self.assertIn("navigationMapEnabled.toggle()", live)
        self.assertIn("else if let camera = lastVisibleMapCamera", live)
        self.assertIn("centerCoordinate: camera.centerCoordinate", live)
        self.assertIn("pitch: navigationMapEnabled ? 67 : 0", live)
        self.assertIn(".mapStyle(.standard(elevation: navigationMapEnabled ? .realistic : .flat))", live)
        self.assertIn("pitch: 67", live)
        self.assertIn("center3DMap(on: user)", live)

    def test_metrics_button_visible_before_play_and_map_button_returns(self):
        live = read_swift("LiveActivityView.swift")
        header = live.split("private var mapHeader: some View", 1)[1].split(
            "private func center3DMap", 1
        )[0]
        self.assertIn('mapCircleButton("chart.bar.xaxis", label: "Ver métricas")', header)
        self.assertIn("if recorder.sport.usesGPS {", header)
        self.assertNotIn(
            'if recorder.phase == .recording || recorder.phase == .paused {\\n'
            '                    mapCircleButton("chart.bar.xaxis"',
            header,
        )
        actions = live.split("private var metricsTrailingActions: some View", 1)[1].split(
            "private var selectionCircleBackground", 1
        )[0]
        self.assertIn('metricsCircleButton("map", label: "Ver mapa")', actions)
        self.assertIn("showingMetrics = false", actions)

    def test_idle_map_does_not_show_redundant_metrics_panel(self):
        live = read_swift("LiveActivityView.swift")
        map_view = live.split("private var mapView: some View", 1)[1].split(
            "private var mapStatusMessages: some View", 1
        )[0]
        # Horizontal y vertical muestran las métricas SOLO al grabar o pausar.
        self.assertEqual(
            map_view.count(
                "if recorder.phase == .recording || recorder.phase == .paused {\\n"
                "                            mapMetricStrip"
            ),
            2,
        )
        self.assertNotIn(
            "Spacer(minLength: 0)\\n                        mapMetricStrip",
            map_view,
        )
        # La barra inferior de elegir actividad / Play / GPX sigue en idle.
        self.assertGreaterEqual(
            map_view.count("if recorder.phase == .idle {"),
            2,
        )
        self.assertIn("bottomControls", map_view)
        # Métricas es su pantalla completa, no la tarjeta superpuesta al mapa.
        metrics = live.split("private var metricsView: some View", 1)[1].split(
            "private var metricsTrailingActions: some View", 1
        )[0]
        self.assertNotIn("mapMetricStrip", metrics)

    def test_play_does_not_change_selection_and_choice_is_remembered(self):
        live = read_swift("LiveActivityView.swift")
        self.assertIn(
            '@AppStorage("repera.live.preferredDisplay.metrics") private var showingMetrics = false',
            live,
        )
        self.assertNotIn("showingMetrics = recorder.sport.usesGPS && recorder.chosenRoute == nil", live)
        self.assertNotIn(".onChange(of: recorder.phase) { previous, next in", live)
        self.assertNotIn("@State private var showingMetrics", live)
        # La selección no se borra al cambiar de deporte, descartar o guardar.
        self.assertEqual(live.count("showingMetrics = false"), 2)  # valor inicial y Ver mapa
        self.assertEqual(live.count("showingMetrics = true"), 1)   # botón Ver métricas



if __name__ == "__main__":
    unittest.main()
