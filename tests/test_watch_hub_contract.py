"""Contratos estáticos del hub Watch/Wear (plan efectivo, home, live, timer)."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WatchHubContractTests(unittest.TestCase):
    def test_effective_watch_plan_resolves_overdue(self):
        phone = source("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("effectiveWatchPlan", phone)
        self.assertIn("mostRecentOverdueWatchPlan", phone)
        self.assertIn("effectiveWatchPlan()", phone)

    def test_watch_connectivity_carries_recents_and_audio(self):
        phone = source("Apps/Repera/Sources/PhoneConnectivity.swift")
        watch = source("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        self.assertIn("recentLiveSportIDs", phone)
        self.assertIn("audioMuted", phone)
        self.assertIn("recentLiveSportIDs", watch)
        self.assertIn("audioMuted", watch)

    def test_watch_home_hub_exists(self):
        hub = source("Apps/ReperaWatch/Sources/WatchHomeHubView.swift")
        self.assertIn("WatchHomeHubView", hub)
        self.assertIn("timer", hub.lower())
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("WatchHomeHubView", view)

    def test_watch_home_corners_keep_priority_over_activity(self):
        watch = source("Apps/ReperaWatch/Sources/WatchHomeHubView.swift")
        self.assertIn("ZStack(alignment: .bottom)", watch)
        self.assertIn(".padding(.bottom, 58)", watch)
        self.assertIn(".zIndex(1)", watch)
        self.assertIn(".frame(width: 44, height: 44)", watch)
        self.assertIn("hub.toggleAudioMuted()", watch)
        self.assertIn("showTimer = true", watch)
        self.assertNotIn(".overlay(alignment: .bottomTrailing)", watch)

    def test_watch_live_and_timer_surfaces(self):
        live = source("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        timer = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        self.assertIn("WatchLiveSessionView", live)
        self.assertIn("WatchStandaloneTimerView", timer)
        self.assertIn("TimerCompletionDetails", timer)

    def test_watch_timer_mode_selection_is_full_size(self):
        watch = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        self.assertIn("modeSelectionView", watch)
        self.assertIn('modeButton("down", title: "Cuenta atrás"', watch)
        self.assertIn('modeButton("up", title: "Cronómetro"', watch)
        self.assertIn('modeButton("intervals", title: "Intervalos"', watch)
        self.assertIn("minHeight: 56", watch)
        self.assertIn("stepperButton", watch)
        self.assertIn("width: 44, height: 44", watch)
        # Pausa no debe volver al formulario, ni terminar sin confirmación.
        self.assertIn("else if started", watch)
        self.assertIn("timerExitPrompt = .finish", watch)
        self.assertIn("timerExitPrompt = .discard", watch)
        self.assertIn(".confirmationDialog(", watch)

    def test_wear_timer_uses_large_mode_buttons_and_interval_phases(self):
        wear = source("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        self.assertIn("WearTimerModeOption(", wear)
        self.assertIn(".heightIn(min = 62.dp)", wear)
        self.assertIn("choosingMode = false", wear)
        self.assertIn("scrollState.scrollBy(it.verticalScrollPixels)", wear)
        self.assertIn("val phaseRemaining =", wear)
        self.assertIn("WearTimerAdaptiveClock(display)", wear)
        self.assertIn("TextAutoSize.StepBased(", wear)
        self.assertIn("roundNumber.toString()", wear)
        self.assertIn('WearStatsLine("Restante", wearClockLabel(remaining))', wear)
        self.assertIn("WearConfirmFinishModal(", wear)

    def test_timer_matches_iphone_led_colors_and_crown_metrics(self):
        iphone = source("Apps/Repera/Sources/DigitalClockDisplay.swift")
        watch = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        wear = source("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        self.assertIn("red: 1.0, green: 0.22, blue: 0.18", iphone)
        self.assertIn("red: 0.22, green: 1.0, blue: 0.35", iphone)
        self.assertIn("private let timerRed = Color(red: 1, green: 0.22, blue: 0.18)", watch)
        self.assertIn("private let timerRoundGreen = Color(red: 0.22, green: 1, blue: 0.35)", watch)
        self.assertIn("WearTimerRed = Color(0xFFFF382E)", wear)
        self.assertIn("WearTimerRoundGreen = Color(0xFF38FF59)", wear)
        self.assertIn(".digitalCrownRotation(", watch)
        self.assertIn("showingTimerMetrics = value >= 0.5", watch)
        self.assertIn('Button("Finalizar") {', watch)
        self.assertIn("finishRun()", watch)
        self.assertIn('Button("Guardar") { complete(save: true) }', watch)
        self.assertIn("WearStatsLine(\"Transcurrido\"", wear)
        self.assertIn("metricsScroll.scrollBy(it.verticalScrollPixels)", wear)
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 3 })", wear)
        self.assertIn("draft.toDetails().copy(countdownSeconds = elapsed)", wear)
        self.assertIn("discarded = 1", wear)
        self.assertIn("Icons.Filled.Close", wear)
        self.assertIn("Icons.Filled.Flag", wear)
        self.assertIn("WearOg.red", wear)

    def test_watch_left_swipe_controls_cover_live_and_planned(self):
        session = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        live = source("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        self.assertIn("struct WatchSwipeControlSurface", session)
        self.assertIn("if showingNowPlaying", session)
        self.assertIn("NowPlayingView()", session)
        # L→R abre controles; R→L abre Now Playing.
        self.assertIn("if showingNowPlaying {\n                        showingNowPlaying = false", session)
        self.assertIn("showingControls = true", session)
        self.assertIn("showingControls = false", session)
        self.assertIn("showingNowPlaying = true", session)
        self.assertIn("WatchSwipeControlSurface {", session)
        self.assertNotIn("onSwipeLeft:", session)
        self.assertIn("private func plannedRecordingView(", session)
        self.assertIn("WatchSwipeControlSurface {", live)
        self.assertIn("hub.toggleWatchLivePause()", live)
        self.assertIn("trainingPrompt = .finish", session)
        self.assertIn("trainingPrompt = .discard", session)

    def test_watch_live_back_and_explicit_crown_editing(self):
        view = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        running = view.split("private func runningView(", 1)[1].split(
            "private var seriesContent:", 1
        )[0]
        self.assertNotIn('Button("Resumen")', running)
        self.assertIn("if !hub.goToPreviousStep() { showOutline = true }", running)
        self.assertIn("func goToPreviousStep() -> Bool", hub)
        self.assertIn("swipeSet(-1)", hub)
        self.assertIn("editingRepsWithCrown.toggle()", view)
        self.assertIn(".focusable(editingRepsWithCrown)", view)
        self.assertIn(".focused($repsCrownFocused)", view)

    def test_wear_live_back_and_rotary_scroll_by_default(self):
        wear = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        activity = source("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        chrome = source("android/wear/src/main/java/dev/repera/wear/WearChrome.kt")
        running = wear.split("private fun TransformingLazyColumnScope.runningItems(", 1)[1].split(
            "private fun TransformingLazyColumnScope.wodRunningBody(", 1
        )[0]
        reps = wear.split("private fun RotaryRepsHost(", 1)[1].split(
            "private fun TransformingLazyColumnScope.seriesSteppers(", 1
        )[0]
        self.assertNotIn('Text("Resumen"', running)
        self.assertIn('callbacks.onPreviousStep()', running)
        self.assertIn("private fun goToPreviousLiveStep()", activity)
        self.assertIn('showOutline = true', activity)
        self.assertIn("lastOrNull { it.first <= currentIndex }", activity)
        self.assertIn('.put("currentIndex", previousIndex)', activity)
        self.assertIn('onSwipeSet = { delta ->', activity)
        self.assertIn("if (editing) focus.requestFocus()", reps)
        self.assertNotIn("LaunchedEffect(Unit) { focus.requestFocus() }", reps)
        self.assertIn("onValueClick = onValueClick", wear)
        self.assertIn("Modifier.clickable(onClick = onValueClick)", chrome)

    def test_wear_left_swipe_controls_cover_all_sessions(self):
        live = source("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        planned = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        media = source("android/wear/src/main/java/dev/repera/wear/WearNowPlayingPage.kt")
        # Controles ← Centro → Now Playing (initialPage = 1).
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 3 })", live)
        self.assertIn("page == 0 -> WearLiveControlsPage(", live)
        self.assertIn("page == 2 -> WearNowPlayingPage()", live)
        self.assertIn("VerticalPager(state = verticalPages", live)
        self.assertIn("WearLiveNavigationPage(live)", live)
        self.assertIn("WearLiveMetricsPage(live = live", live)
        self.assertIn("val runningPlan = state.session?.phase == \"counting\"", planned)
        self.assertIn("HorizontalPager(state = pager", planned)
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 3 })", planned)
        self.assertIn("2 -> WearNowPlayingPage()", planned)
        self.assertIn("WearHomeSessionList(state, callbacks", planned)
        self.assertIn("callbacks.onTogglePause()", planned)
        self.assertIn("callbacks.onFinishSession(session)", planned)
        self.assertIn("callbacks.onDiscardSession(session)", planned)
        self.assertIn("confirmFinish by remember(session.sessionId)", planned)
        self.assertIn("confirmDiscard by remember(session.sessionId)", planned)
        self.assertIn("dispatchWearMediaKey", media)
        self.assertIn("KEYCODE_MEDIA_PLAY_PAUSE", media)

    def test_watch_ui_omits_empty_conditions_and_swipe_instructions(self):
        conditions = source("Apps/ReperaWatch/Sources/WatchActivityConditionsBlock.swift")
        session = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        live = source("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        timer = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        self.assertIn("if let conditions, hasApple || hasMarineOrSnowDepth", conditions)
        self.assertIn(".background(.white.opacity(0.07)", conditions)
        self.assertNotIn("Sin datos de condiciones", conditions)
        self.assertNotIn('Text("Controles")', session)
        self.assertNotIn('Text("Controles")', timer)
        self.assertIn("if dx < -55", timer)
        self.assertIn("NowPlayingView()", timer)
        self.assertIn("if showingTimerControls", timer)
        self.assertNotIn("Corona ↓ métricas", timer)
        self.assertNotIn("Corona ↑ reloj", timer)
        for view in (session, live, timer):
            self.assertNotIn('Text("Desliza', view)
            self.assertNotIn('Text("Deslizar', view)

    def test_wear_ui_omits_empty_conditions_and_swipe_instructions(self):
        live = source("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        planned = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        timer = source("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        self.assertIn("if (temperature == null && wind == null && tide == null", live)
        self.assertIn(".background(Color.White.copy(alpha = 0.07f)", live)
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 3 })", planned)
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 3 })", timer)
        for view in (live, planned, timer):
            self.assertNotIn('"Desliza ', view)
            self.assertNotIn('Text("Controles"', view)

    def test_timer_config_unboxed_and_swipe_back_from_type(self):
        watch = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        watch_root = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        wear = source("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        chrome = source("android/wear/src/main/java/dev/repera/wear/WearChrome.kt")
        self.assertIn("if dx > 55 && dx > abs(drag.translation.height)", watch)
        self.assertNotIn('Label("Cambiar tipo", systemImage:', watch)
        self.assertNotIn(".background(Color.white.opacity(0.08), in: RoundedRectangle", watch)
        self.assertIn("flatControls = true", wear)
        self.assertIn("flatControls: Boolean = false", chrome)
        self.assertIn("pointerInput(choosingMode)", wear)
        self.assertIn("if (swipeRight > 55f)", wear)
        self.assertIn("if (choosingMode) onBack() else choosingMode = true", wear)
        self.assertNotIn(".sheet(isPresented: $showTimer)", watch_root)
        self.assertIn("WatchStandaloneTimerView(", watch_root)
        self.assertIn("onClose: { showTimer = false }", watch_root)
        self.assertIn('Text(inWork ? "TRABAJAR" : "DESCANSAR")', watch)
        self.assertIn('if (resting) "DESCANSAR" else "TRABAJAR"', wear)
        # Fase debajo del tiempo (no a la derecha); reloj centrado y grande.
        self.assertNotIn("HStack(alignment: .firstTextBaseline, spacing: 4)", watch)
        self.assertIn('size: modeRaw == "intervals" ? 44 : 48', watch)
        self.assertIn("minFontSize = 28.sp, maxFontSize = 48.sp", wear)

    def test_watch_timer_compact_topbar_and_native_styled_vertical_actions(self):
        watch = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        root = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertNotIn('Label("Volver", systemImage:', watch)
        self.assertNotIn('Text("Elige un temporizador")', watch)
        self.assertNotIn('.navigationTitle(started && !finished', watch)
        self.assertNotIn('Text(modeTitle)', watch)
        self.assertNotIn('Text(modeTitle.uppercased())', watch)
        self.assertIn('onTitleChange(headerTitle)', watch)
        self.assertIn('if showTimer { return timerPageTitle }', root)
        self.assertIn('onTitleChange: { timerPageTitle = $0 }', root)
        self.assertIn('choosingMode ? "Temporizador" : modeTitle', watch)
        self.assertIn('WatchSessionControlsGrid(', watch)
        self.assertIn('timerExitPrompt = .discard', watch)
        self.assertIn('Button("Descartar", role: .destructive)', watch)
        self.assertIn('Button("Cancelar", role: .cancel)', watch)
        grid = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn('systemName: "flag.checkered"', grid)
        self.assertIn('systemName: "xmark"', grid)
        self.assertIn('Color(red: 0.90, green: 0.22, blue: 0.21)', grid)
        self.assertIn("finished = true", watch)
        self.assertIn('publishMirror(save ? "finished" : "discarded")', watch)
        self.assertIn('if dx > 55 && dx > abs(drag.translation.height)', watch)

    def test_wear_timer_header_and_back_swipe_without_extra_picker_text(self):
        wear = source("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        self.assertNotIn('"Elige un temporizador"', wear)
        self.assertNotIn('contentDescription = "Volver"', wear)
        self.assertIn('text = if (choosingMode) "Temporizador" else when (draft.modeRaw)', wear)
        self.assertIn('if (swipeRight > 55f)', wear)
        self.assertIn('if (choosingMode) onBack() else choosingMode = true', wear)
        self.assertIn("Icons.Filled.Flag", wear)
        self.assertIn("Icons.Filled.Close", wear)
        self.assertIn("onToggleAudioMuted", wear)

    def test_timer_live_mirror_watch_phone(self):
        model = source("Packages/ReperaDomain/Sources/ReperaDomain/WatchTimerMirror.swift")
        watch = source("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        wtransport = source("Apps/ReperaWatch/Sources/WatchConnectivityClient.swift")
        ptransport = source("Apps/Repera/Sources/PhoneConnectivity.swift")
        store = source("Apps/Repera/Sources/ReperaStore.swift")
        home = source("Apps/Repera/Sources/HomeView.swift")
        self.assertIn("public struct WatchTimerMirror", model)
        self.assertIn("private func publishMirror(", watch)
        for phase in ('"running"', '"paused"', '"finished"', '"discarded"'):
            self.assertIn(phase, watch)
        self.assertIn("watchConnectivityDidReceiveTimerCommand", hub)
        self.assertIn("sendTimerMirror", wtransport)
        self.assertIn('"timerMirror": data', wtransport)
        self.assertIn("sendTimerCommand(id:", ptransport)
        self.assertIn("phoneConnectivityDidReceiveTimer", store)
        self.assertIn("WatchTimerHomeCard", home)
        self.assertIn("id: timerId", watch)
        self.assertIn("connectivity.sendFinishedTimer(session)", hub)

    def test_timer_live_mirror_wear_android_and_offline_ack(self):
        wear = source("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        timer = source("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        phone = source("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        listener = source("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        mirror = source("android/mobile/src/main/java/dev/repera/mobile/WearTimerMirrorStore.kt")
        home = source("android/mobile/src/main/java/dev/repera/mobile/HomeTab.kt")
        for path in ("/repera/timer-state", "/repera/timer-save",
                     "/repera/timer-save-ack", "/repera/timer-command"):
            self.assertIn(path, wear)
        self.assertIn("resendPendingTimers()", wear)
        self.assertIn('getSharedPreferences("repera.timer.completed.outbox.v1"', wear)
        self.assertIn("onMirror:", timer)
        self.assertIn("remoteCommandEpoch:", timer)
        self.assertIn('if (event.path == "/repera/timer-save")', phone)
        self.assertIn('if (event.path == "/repera/timer-save")', listener)
        self.assertIn("WearTimerMirrorStore", phone)
        self.assertIn("WearTimerMirrorStore", listener)
        self.assertIn("old.optString(\"phase\")", mirror)
        self.assertIn("WearLiveTimerHomeCard", home)
        self.assertIn("onWearTimerCommand", home)

    def test_wear_home_hub_carousel(self):
        wear = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        self.assertIn("WearHubHome", wear)
        self.assertIn("onHubPlay", wear)
        bridge = source(
            "android/mobile/src/main/java/dev/repera/mobile/WearActiveSessionBridge.kt"
        )
        self.assertIn("recentLiveSportIDs", bridge)
        repo = source(
            "android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt"
        )
        self.assertIn("effectivePlanSession", repo)

    def test_watch_crossfit_healthkit_type_matches_iphone(self):
        """Toda la tabla Comenzar Watch = iPhone; planes WOD → crossTraining."""
        import re

        phone = source("Apps/Repera/Sources/LiveActivityView.swift")
        watch = source("Apps/ReperaWatch/Sources/WatchLiveSportCatalog.swift")
        planned = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        store = source("Apps/Repera/Sources/ReperaStore.swift")
        mapper = source("Apps/Repera/Sources/HealthMuscleMapper.swift")
        phone_segment = phone.split("var healthType: HKWorkoutActivityType", 1)[1].split(
            "struct LiveSavedRoute", 1
        )[0]
        watch_segment = watch.split(
            "var healthKitActivityType: HKWorkoutActivityType", 1
        )[1].split("enum WatchHubItem", 1)[0]

        def mapping(segment: str) -> dict[str, str]:
            out: dict[str, str] = {}
            for match in re.finditer(r"case ([^:]+): \.(\w+)", segment):
                for sport in [
                    part.strip().lstrip(".") for part in match.group(1).split(",")
                ]:
                    out[sport] = match.group(2)
            return out

        phone_map = mapping(phone_segment)
        watch_map = mapping(watch_segment)
        self.assertEqual(phone_map, watch_map)
        self.assertEqual(phone_map.get("crossfit"), "crossTraining")
        self.assertEqual(phone_map.get("hyrox"), "crossTraining")
        self.assertEqual(phone_map.get("hiit"), "highIntensityIntervalTraining")
        start_segment = planned.split(
            "func start(id: UUID, at date: Date, includesWOD:", 1
        )[1].split("func startLive(", 1)[0]
        self.assertIn(".crossTraining", start_segment)
        self.assertIn(".traditionalStrengthTraining", start_segment)
        self.assertNotIn(".highIntensityIntervalTraining", start_segment)
        self.assertNotIn(".functionalStrengthTraining", start_segment)
        health_type = store.split("private func workoutHealthType", 1)[1].split(
            "private func beginHealthTracking", 1
        )[0]
        self.assertIn("if hasWOD { return .crossTraining }", health_type)
        self.assertIn("matchesRecordedHealthType(", mapper)
        self.assertIn("HKWorkout antiguos", mapper)
        self.assertIn("highIntensityIntervalTraining", mapper)

    def test_watch_kcal_indicator_always_visible_and_collects_energy(self):
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        health = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        live = source("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        session = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("var displayedEnergyKcal: Double { health.kcal ?? 0 }", hub)
        self.assertIn("enableCollection(for: energy, predicate: nil)", health)
        self.assertIn("enableCollection(for: heart, predicate: nil)", health)
        self.assertIn("makeLiveDataSource(", health)
        self.assertIn("hub.displayedEnergyKcal", live)
        self.assertIn("hub.displayedEnergyKcal", session)
        self.assertNotIn(
            'hub.measuredEnergyKcal.map { String(format: "%.0f", $0) } ?? "—"',
            live,
        )
        self.assertNotIn(
            'hub.measuredEnergyKcal.map { String(format: "%.0f", $0) } ?? "—"',
            session,
        )

    def test_wear_kcal_indicator_always_visible_and_collects_energy(self):
        chrome = source("android/wear/src/main/java/dev/repera/wear/WearChrome.kt")
        live = source("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        home = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        caps = source("android/wear/src/main/java/dev/repera/wear/WearExerciseCapabilities.kt")
        session = source("android/wear/src/main/java/dev/repera/wear/WearHealthSession.kt")
        self.assertIn("fun displayedEnergyKcal(kcal: Double?): Double", chrome)
        self.assertIn("displayedEnergyKcal(kcal).toInt().toString()", chrome)
        self.assertIn("displayedEnergyKcal(health?.second)", live)
        self.assertIn('WearStatsLine("Calorías", "${finished.kcal ?: 0} kcal")', home)
        self.assertIn("add(DataType.CALORIES_TOTAL)", caps)
        self.assertIn("add(DataType.CALORIES)", caps)
        self.assertIn("DataType.CALORIES_TOTAL", session)
        self.assertIn("DataType.CALORIES", session)

    def test_wear_home_prefers_today_plan_then_recency_alpha(self):
        home = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        main = source("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        phone = source("android/mobile/src/main/java/dev/repera/mobile/WearActiveSessionBridge.kt")
        repo = source("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        self.assertIn("Entreno(s) del día si existen", home)
        self.assertIn("LiveSport.selectableCases", home)
        self.assertIn("preferHomeHubLanding", main)
        self.assertIn("todayPlanJson != null && items.first() is WearHubCarouselItem.Plan", main)
        self.assertIn("wearMergeRecentSports", home)
        self.assertIn("applyMergedRecentSports", main)
        self.assertIn("/repera/wear-hub-recents", main)
        self.assertIn("storeWearHubRecents", phone)
        self.assertIn("wearHubRecents(context", repo)


if __name__ == "__main__":
    unittest.main()
