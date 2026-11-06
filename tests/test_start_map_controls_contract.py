"""Contratos de Comenzar: selector lateral, sesión live, mapa y parciales.

La inspección de fuentes detecta regresiones sin sustituir Xcode, Gradle,
pruebas en dispositivos ni accesibilidad física.
"""

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps/Repera/Sources"
ANDROID = ROOT / "android/mobile/src/main/java/dev/repera/mobile"


def read(path):
    return path.read_text(encoding="utf-8")


class LiveStartControlsContractTests(unittest.TestCase):
    def test_start_tab_is_live_activity_not_center(self):
        root = read(IOS / "RootTabView.swift")
        self.assertIn('"Comenzar"', root)
        self.assertIn("value: AppTab.start", root)
        self.assertIn("LiveActivityView(", root)
        self.assertNotIn("onOpenCenter:", root)

    def test_play_button_is_icon_only(self):
        ios = read(IOS / "LiveActivityView.swift")
        android = read(ANDROID / "LiveStartToolbar.kt")
        toolbar = ios.split("private var bottomControls: some View", 1)[1].split(
            "private var liveSplitScreen", 1
        )[0]
        self.assertIn('Image(systemName: recorder.phase == .recording ? "pause.fill"', toolbar)
        self.assertIn('"gearshape.fill"', toolbar)
        self.assertIn('"flag.checkered"', toolbar)
        self.assertNotIn('Text(store.hasActiveSession ? "CONTINUAR" : "COMENZAR")', toolbar)
        self.assertIn("Icons.Filled.PlayArrow", android)
        self.assertIn("Icons.Filled.Pause", android)
        self.assertNotIn('Text("COMENZAR")', android)
        self.assertNotIn('"CONTINUAR" else "COMENZAR"', android)

    def test_activity_circle_is_right_and_opens_bottom_sheet(self):
        ios = read(IOS / "LiveActivityView.swift")
        android = read(ANDROID / "LiveStartToolbar.kt")
        ios_row = ios.split("private var bottomControls: some View", 1)[1].split(
            "private var liveSplitScreen", 1
        )[0]
        self.assertIn("recorder.sport.symbol", ios_row)
        self.assertIn("liveGlassSideButton(", ios_row)
        self.assertIn("sportPicker = true", ios_row)
        self.assertIn(".sheet(isPresented: $sportPicker)", ios)
        self.assertIn('UserDefaults.standard.set(selection.rawValue, forKey: "repera.live.lastSport")', ios)
        self.assertIn("onClick = onSport", android)
        self.assertIn('testTag("live_sport_picker")', android)
        self.assertIn("LiveGlassCircleButton(", android)
        self.assertIn('showSportPicker = false', read(ANDROID / "LiveActivityScreen.kt"))


    def test_settings_and_route_are_full_size(self):
        ios = read(IOS / "LiveActivityView.swift")
        android = read(ANDROID / "LiveActivityScreen.kt")
        controls = read(ANDROID / "LiveStartToolbar.kt")
        self.assertIn(".fullScreenCover(isPresented: $routePicker", ios)
        self.assertIn('Label("Audio", systemImage: "speaker.wave.2")', ios)
        self.assertIn('Label("Mapa", systemImage: "map")', ios)
        self.assertIn("showOptions", controls)
        self.assertIn('"Audio"', controls)
        self.assertIn('"Mapa"', controls)
        self.assertIn('"Cargar ruta"', controls)
        self.assertIn("Icons.Outlined.Close", controls)
        self.assertIn("if (showRoutes)", android)
        self.assertIn("Surface(Modifier.fillMaxSize()", android)
        self.assertIn("BackHandler { showRoutes = false }", android)

    def test_swipes_splits_and_no_expand_map(self):
        ios = read(IOS / "LiveActivityView.swift")
        android = read(ANDROID / "LiveActivityScreen.kt")
        self.assertIn(".fullScreenCover(isPresented: $showSplits)", ios)
        self.assertIn("completedKilometerSplits", ios)
        self.assertIn("showSplits = true", android)
        self.assertIn("state.splitsSeconds.forEachIndexed", android)
        self.assertIn("detectVerticalDragGestures(", android)
        self.assertIn("dy < -100", ios)
        self.assertIn("showingMetrics = false", ios)
        self.assertIn(".mapControlVisibility(.hidden)", ios)
        self.assertNotIn("mapDetailsExpanded", ios)
        self.assertNotIn("mapDetailsExpanded", android)
        header = ios.split("private var mapHeader: some View", 1)[1].split(
            "private func toggleNavigationMapMode", 1
        )[0]
        self.assertIn('effectiveNavigation3D ? "map" : "view.3d"', header)
        self.assertNotIn("chart.bar.xaxis", header)
        self.assertNotIn("applewatch", header)

    def test_map_3d_keeps_entitlement_and_manual_follow(self):
        ios = read(IOS / "LiveActivityView.swift")
        self.assertIn('effectiveNavigation3D ? "map" : "view.3d"', ios)
        self.assertIn("private func toggleNavigationMapMode()", ios)
        self.assertIn("navigation3DAllowed", ios)
        self.assertIn("suspendMapFollowingForUserGesture()", ios)
        self.assertIn("center3DMap(on: user)", ios)
        android = read(ANDROID / "LiveActivityScreen.kt")
        self.assertIn("LiveMapCamera.FOLLOW_RESUME_DELAY_MS", android)
        self.assertIn("canNavigate3D", android)

    def test_android_reuses_one_toolbar_in_map_metrics_and_indoor(self):
        android = read(ANDROID / "LiveActivityScreen.kt")
        self.assertEqual(android.count("LiveStartToolbar("), 3)
        self.assertNotIn("private fun LiveStartToolbar(", android)
        self.assertIn("var showStartOptions by remember", android)
        self.assertIn("mutableStateOf(true)", android)


if __name__ == "__main__":
    unittest.main()
