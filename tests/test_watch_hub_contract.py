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
        self.assertIn("showDiscardConfirmation = true", watch)
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
        self.assertIn('"Ronda " + roundNumber', wear)
        self.assertIn('"Total " + wearClockLabel(remaining)', wear)
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
        self.assertIn("WearStatsLine(\"Transcurrido\"", wear)
        self.assertIn("metricsScroll.scrollBy(it.verticalScrollPixels)", wear)
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 2 })", wear)

    def test_watch_right_swipe_controls_cover_live_and_planned(self):
        session = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        live = source("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        self.assertIn("struct WatchSwipeControlSurface", session)
        self.assertIn("if dx > 0", session)
        self.assertIn("showingControls = true", session)
        self.assertIn("showingControls = false", session)
        self.assertIn("WatchSwipeControlSurface(onSwipeLeft: { hub.swipeSet(1) })", session)
        self.assertIn("private func plannedRecordingView(", session)
        self.assertIn("WatchSwipeControlSurface {", live)
        self.assertIn("hub.toggleWatchLivePause()", live)
        self.assertIn("showWorkoutFinishConfirmation = true", session)
        self.assertIn("showPlannedDiscardConfirmation = true", session)

    def test_wear_right_swipe_controls_cover_all_sessions(self):
        live = source("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        planned = source("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 2 })", live)
        self.assertIn("page == 1 -> WearLiveMetricsPage", live)
        self.assertIn("val runningPlan = state.session?.phase == \"counting\"", planned)
        self.assertIn("HorizontalPager(state = pager", planned)
        self.assertIn("if (page == 1) {", planned)
        self.assertIn("WearHomeSessionList(state, callbacks", planned)
        self.assertIn("callbacks.onTogglePause()", planned)
        self.assertIn("callbacks.onFinishSession(session)", planned)
        self.assertIn("callbacks.onDiscardSession(session)", planned)
        self.assertIn("confirmFinish by remember(session.sessionId)", planned)
        self.assertIn("confirmDiscard by remember(session.sessionId)", planned)

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


if __name__ == "__main__":
    unittest.main()
