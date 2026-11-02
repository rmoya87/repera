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
        self.assertIn(".height(62.dp)", wear)
        self.assertIn("choosingMode = false", wear)
        self.assertIn("scrollState.scrollBy(it.verticalScrollPixels)", wear)
        self.assertIn("val phaseRemaining =", wear)
        self.assertIn("WearTimerAdaptiveClock(display)", wear)
        self.assertIn("TextAutoSize.StepBased(", wear)
        self.assertIn('"Ronda " + roundNumber', wear)
        self.assertIn('"Total " + wearClockLabel(remaining)', wear)
        self.assertIn("WearConfirmFinishModal(", wear)

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
