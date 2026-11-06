"""Contratos del rediseño Comenzar (2026-11-06): interfaz y navegación sin alterar sensores.

La prueba estática complementa, pero no sustituye, CI nativo y hardware.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources" / "LiveActivityView.swift"
ANDROID = ROOT / "android" / "mobile" / "src" / "main" / "java" / "dev" / "repera" / "mobile" / "LiveActivityScreen.kt"


class StartMapControlsContractTests(unittest.TestCase):
    def test_start_tab_still_opens_live_recorder_without_center(self):
        tabs = (ROOT / "Apps" / "Repera" / "Sources" / "RootTabView.swift").read_text()
        self.assertIn('SwiftUI.Tab("Comenzar"', tabs)
        self.assertIn("LiveActivityView(", tabs)
        self.assertNotIn("onOpenCenter:", tabs)

    def test_ios_uses_three_circular_actions_and_activity_on_the_right(self):
        ios = IOS.read_text()
        bar = ios.split("private var bottomControls: some View", 1)[1].split(
            "private var liveSplitScreen: some View", 1
        )[0]
        self.assertIn('Image(systemName: canLockLiveScreen ? "flag.checkered" : "gearshape.fill")', bar)
        self.assertIn('Text(store.hasActiveSession ? "CONTINUAR" : "COMENZAR")', bar)
        self.assertIn('Button {\n                        sportPicker = true', bar)
        self.assertIn('Image(systemName: recorder.sport.symbol)', bar)
        self.assertLess(bar.index('"gearshape.fill"'), bar.index("recorder.sport.symbol"))
        self.assertNotIn('Text("Selecciona actividad")', bar)
        self.assertNotIn('Color.clear.frame(width: 64', bar)

    def test_activity_picker_uses_native_bottom_sheet_and_last_selected_sport(self):
        ios = IOS.read_text()
        self.assertIn(".sheet(isPresented: $sportPicker)", ios)
        self.assertIn("LiveSportPicker { sport in", ios)
        self.assertIn("recorder.choose(sport)", ios)
        self.assertIn("dismiss()", ios)
        self.assertIn('UserDefaults.standard.set(selection.rawValue, forKey: "repera.live.lastSport")', ios)
        self.assertIn('UserDefaults.standard.string(forKey: "repera.live.lastSport")', ios)

    def test_ios_options_splits_and_touch_lock_share_the_live_screen(self):
        ios = IOS.read_text()
        self.assertIn("@State private var showingMetrics = true", ios)
        self.assertIn('Label("Audio", systemImage: "speaker.wave.2")', ios)
        self.assertIn('Label("Mapa", systemImage: "map")', ios)
        self.assertIn(".fullScreenCover(isPresented: $routePicker", ios)
        self.assertIn(".fullScreenCover(isPresented: $showSplits)", ios)
        self.assertIn("recorder.completedKilometerSplits", ios)
        self.assertIn("showSplits = true", ios)
        self.assertIn("recorder.pause()", ios)
        self.assertIn("recorder.resume()", ios)
        self.assertIn(".onLongPressGesture(minimumDuration: 1)", ios)
        self.assertIn(".overlayPreferenceValue(LiveInteractionLockAnchorKey.self)", ios)
        top = ios.split("private var metricsTrailingActions: some View", 1)[1].split(
            "private var selectionCircleBackground", 1
        )[0]
        self.assertNotIn("guidanceSymbol", top)
        self.assertNotIn('"pause.fill"', top)

    def test_map_stays_compact_and_does_not_expand(self):
        ios = IOS.read_text()
        strip = ios.split("private var mapMetricStrip: some View", 1)[1].split(
            "private var elevationMetricStrip:", 1
        )[0]
        self.assertNotIn("mapDetailsExpanded", strip)
        self.assertNotIn(".onTapGesture", strip)
        self.assertNotIn('Image(systemName: "chevron.down")', strip)

    def test_android_parity_uses_the_same_activity_icon_and_full_screens(self):
        android = ANDROID.read_text()
        self.assertIn("private fun LiveStartToolbar(", android)
        self.assertIn('modifier = Modifier.size(64.dp).testTag("live_sport_picker")', android)
        self.assertIn('Icon(sportIcon, "Elegir actividad: $sportTitle"', android)
        self.assertIn("onSport = { showSportPicker = true }", android)
        self.assertIn("mutableStateOf(true)", android)
        self.assertIn("detectHorizontalDragGestures(", android)
        self.assertIn("detectVerticalDragGestures(", android)
        self.assertIn("if (showRoutes) {", android)
        self.assertIn("if (showSplits && state.phase", android)
        self.assertIn('Text("Parciales"', android)
        self.assertNotIn("mapDetailsExpanded", android)


if __name__ == "__main__":
    unittest.main()
