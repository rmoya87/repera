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
        # Finalizar oculto con pantalla bloqueada (hueco simétrico).
        self.assertIn("if isInteractionLocked", toolbar)
        self.assertIn("Hueco simétrico: Finalizar solo visible al desbloquear", toolbar)
        self.assertIn("if (locked)", android)
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
        # Idle: actividad a la derecha. En vivo: candado que se fusiona con Play.
        self.assertIn("recorder.sport.symbol", ios_row)
        self.assertIn("sportPicker = true", ios_row)
        self.assertIn("liveLockSideControl", ios_row)
        self.assertIn("beginLockMerge()", ios)
        self.assertIn("lockMergeProgress", ios)
        self.assertIn("showsFusedLockAtPlay", ios)
        self.assertIn("liveSessionSportBadge", ios)
        # Badge: nombre + icono, siempre a la izquierda en mapa y métricas.
        badge = ios.split("private var liveSessionSportBadge", 1)[1].split(
            "private func toggleNavigationMapMode", 1
        )[0]
        self.assertLess(badge.index("recorder.sport.symbol"), badge.index("recorder.sport.title"))
        map_header = ios.split("private var mapHeader:", 1)[1].split(
            "private var liveSessionSportBadge", 1
        )[0]
        self.assertLess(
            map_header.index("liveSessionSportBadge"),
            map_header.index("mapCircleButton("),
        )
        self.assertIn("if !isInteractionLocked {\n                    liveSessionPageDots", ios)
        self.assertIn("beginLockMerge()", ios)
        self.assertNotIn("liveSessionPage = 1\n        UIImpactFeedbackGenerator", ios)
        android_screen = read(ANDROID / "LiveActivityScreen.kt")
        self.assertIn("if (!touchLocked)", android_screen)
        self.assertIn(".sheet(isPresented: $sportPicker)", ios)
        self.assertIn('UserDefaults.standard.set(selection.rawValue, forKey: "repera.live.lastSport")', ios)
        self.assertIn("onClick = onSport", android)
        self.assertIn('testTag("live_sport_picker")', android)
        self.assertIn('testTag("live_lock")', android)
        self.assertIn("onLock: () -> Unit", android)
        self.assertIn("LiveGlassCircleButton(", android)
        self.assertIn('showSportPicker = false', read(ANDROID / "LiveActivityScreen.kt"))
        self.assertIn("LiveSessionSportBadge(", read(ANDROID / "LiveActivityScreen.kt"))


    def test_settings_and_route_are_full_size(self):
        ios = read(IOS / "LiveActivityView.swift")
        android = read(ANDROID / "LiveActivityScreen.kt")
        controls = read(ANDROID / "LiveStartToolbar.kt")
        self.assertIn(".fullScreenCover(isPresented: $routePicker", ios)
        self.assertIn('Label("Audio", systemImage: "speaker.wave.2.fill")', ios)
        self.assertIn('Label("Mapa", systemImage: "map.fill")', ios)
        self.assertIn('Label("Cuenta atrás", systemImage: "timer")', ios)
        # Bloqueo vive en el chrome (candado derecho → fusión con Play), no en Opciones.
        self.assertNotIn('Label("Bloquear pantalla", systemImage: "lock.fill")', ios)
        self.assertIn('accessibilityLabel("Bloquear pantalla")', ios)
        self.assertIn("idleOptionsSheet", ios)
        self.assertIn("idleBottomChromePad", ios)
        self.assertIn("10 + continueChromeLift", ios)
        self.assertIn("liveChromeHomeIndicatorPad", ios)
        self.assertIn(".ignoresSafeArea(.container, edges: .bottom)", ios)
        self.assertIn(
            "sessionActive || state.phase == LiveActivityState.Phase.REVIEW -> 8.dp",
            android,
        )
        self.assertNotIn("88 + continueChromeLift", ios)
        self.assertIn(".ogFittedSheet()", ios)
        # Controles flotantes idle (no dentro del ScrollView de métricas).
        self.assertIn(".overlay(alignment: .bottom)", ios)
        metrics = ios.split("private var metricsView:", 1)[1].split(
            "private func metricsPrimarySection", 1
        )[0]
        self.assertNotIn("bottomControls", metrics)
        self.assertIn("metricsBottomChromeReserve", metrics)
        self.assertIn(".scrollTargetBehavior(.paging)", metrics)
        self.assertIn(".scrollTargetLayout()", metrics)
        self.assertIn("geometry.size.height", metrics)
        self.assertIn("BoxWithConstraints(", android)
        self.assertIn(".height(pageHeight)", android)
        primary = ios.split("private func metricsPrimarySection", 1)[1].split(
            "private var metricsTrailingActions", 1
        )[0]
        self.assertIn("metricsKilometerSlot", primary)
        self.assertIn("metricsHeartRateSlot", ios)
        self.assertIn("includeLastReport: false", ios)
        self.assertIn("canLockLiveScreen", ios.split("private var metricsKilometerSlot", 1)[1])
        self.assertIn(".animation(", primary)
        self.assertIn("easeOut(duration: 0.28)", ios)
        self.assertIn(".padding(.top, OG.topBarTopInset)", ios)  # FAB mapa fijo idle/vivo
        self.assertNotIn("canLockLiveScreen ? max(4, OG.topBarTopInset - 8)", ios)
        pager = ios.split("private var liveSessionPager:", 1)[1].split(
            "private var liveSessionPageCount", 1
        )[0]
        # Mapa vivo = mismo mapView detrás del TabView (no dentro de una página).
        self.assertIn("if pageShowsMap {\n                mapView", pager)
        self.assertIn("Color.clear", pager)
        self.assertIn(".allowsHitTesting(!pageShowsMap)", pager)
        self.assertIn("if (pageShowsMap) {\n                LiveSessionMapPane(", android)
        android_idle_metrics = android.split(
            "// Métricas GPS (LiveActivityView.metricsView)", 1
        )[1].split("LiveStartToolbar(", 1)[0]
        self.assertIn("AnimatedVisibility(", android_idle_metrics)
        self.assertIn("expandVertically()", android)
        android_session_metrics = android.split(
            "private fun LiveSessionMetricsPane(", 1
        )[1].split("private fun LiveScreenTouchBlocker(", 1)[0]
        hero_block = android_session_metrics.split(
            'stringResource(R.string.live_activity_screen_duracion)', 1
        )[1].split("// Primera pantalla", 1)[0]
        self.assertIn("LiveKilometerSplitSummary(", hero_block)
        self.assertLess(
            hero_block.index("LiveKilometerSplitSummary("),
            android_session_metrics.index('"Parciales"'),
        )
        self.assertIn("onShowOptions", controls)
        self.assertIn("live_options", controls)
        self.assertIn("LiveIdleOptionsSheet(", android)
        self.assertIn('"Audio"', android)
        self.assertIn('"Mapa"', android)
        self.assertIn('"Cargar ruta"', android)
        self.assertIn('testTag("live_start_options")', android)
        self.assertIn(".sheet(isPresented: $showOptions)", ios)
        self.assertIn("idleOptionsSheet", ios)
        self.assertIn("if (showRoutes)", android)
        self.assertIn("Surface(Modifier.fillMaxSize()", android)
        self.assertIn("BackHandler { showRoutes = false }", android)

    def test_swipes_splits_and_no_expand_map(self):
        ios = read(IOS / "LiveActivityView.swift")
        android = read(ANDROID / "LiveActivityScreen.kt")
        self.assertIn("private var liveSessionPager", ios)
        self.assertIn(".tabViewStyle(.page(indexDisplayMode: .never))", ios)
        self.assertIn("liveSessionPageDots", ios)
        # Strip de mapa encima de Play en el chrome fijo (no detrás de botones).
        pager = ios.split("private var liveSessionPager:", 1)[1].split(
            "private var liveSessionPageCount", 1
        )[0]
        self.assertIn("if pageShowsMap {\n                    mapMetricStrip", pager)
        self.assertLess(
            pager.index("mapMetricStrip"),
            pager.index("bottomControls"),
        )
        # Swipe del chrome: el mapa no debe tragar el gesto del pager.
        self.assertIn("liveSessionChromeSwipeGesture", ios)
        self.assertIn(".simultaneousGesture(liveSessionChromeSwipeGesture)", pager)
        self.assertIn("liveSplitsSection", ios)
        map_view = ios.split("private var mapView: some View", 1)[1].split(
            "private var mapHeader:", 1
        )[0]
        self.assertNotIn("mapMetricStrip", map_view)
        self.assertIn("completedKilometerSplits", ios)
        self.assertIn("HorizontalPager(", android)
        self.assertIn("liveSessionPage", android)
        # Strip encima de Play; puntos debajo del toolbar.
        android_pager_chrome = android.split(
            "// El mapa captura el swipe del pager", 1
        )[1].split("LiveScreenTouchBlocker(", 1)[0]
        self.assertIn("detectHorizontalDragGestures(", android_pager_chrome)
        self.assertIn("animateScrollToPage(target)", android_pager_chrome)
        self.assertLess(
            android_pager_chrome.index("LiveMapMetricStrip("),
            android_pager_chrome.index("LiveStartToolbar("),
        )
        self.assertLess(
            android_pager_chrome.index("LiveStartToolbar("),
            android_pager_chrome.index("repeat(pageCount)"),
        )
        self.assertIn("countdownEnabled", android)
        self.assertIn('"Cuenta atrás"', android)
        self.assertIn("LiveSportOptionSwitchRow(", android)
        self.assertIn("state.splitsSeconds.forEachIndexed", android)
        self.assertIn(".mapControlVisibility(.hidden)", ios)
        self.assertNotIn("mapDetailsExpanded", ios)
        self.assertNotIn("mapDetailsExpanded", android)
        self.assertNotIn(".fullScreenCover(isPresented: $showSplits)", ios)
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
        # Mapa idle, métricas idle, indoor + pager de sesión en vivo.
        self.assertEqual(android.count("LiveStartToolbar("), 4)
        self.assertNotIn("private fun LiveStartToolbar(", android)
        self.assertIn("var showStartOptions by remember", android)
        self.assertIn("mutableStateOf(true)", android)
        self.assertIn("HorizontalPager(", android)
        self.assertIn("liveSessionPage", android)


if __name__ == "__main__":
    unittest.main()
