#!/usr/bin/env python3
"""Contrato: swipe Controles↔Now Playing y barra FC en Always On / Ambient."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class WatchWearSwipeAmbientHrContract(unittest.TestCase):
    def test_watch_swipe_controls_left_now_playing_right(self):
        session = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        timer = read("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        self.assertIn("Controles ← Sesión → Now Playing", session)
        # L→R (dx > 0) → controles; R→L → now playing.
        swipe = session.split("DragGesture(minimumDistance: 35)", 1)[1].split(
            "struct WatchControlActionButton", 1
        )[0]
        self.assertIn("if dx > 0", swipe)
        self.assertIn("showingControls = true", swipe)
        self.assertIn("showingNowPlaying = true", swipe)
        self.assertIn("else if showingControls", swipe)
        # Timer: misma orientación.
        self.assertIn("Controles ← Reloj → Now Playing", timer)
        self.assertIn("if dx > 55", timer)
        self.assertIn("else if dx < -55", timer)

    def test_watch_ambient_keeps_attenuated_zone_bar(self):
        live = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        session = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("attenuated: isLuminanceReduced", live)
        self.assertIn("var attenuated: Bool = false", live)
        self.assertIn(".opacity(attenuated ? 0.72 : 1)", live)
        # Plan en curso: la barra también permanece en Always On.
        clock = session.split("@ViewBuilder\n    private var clockControls:", 1)[1].split(
            "private var wodContent:", 1
        )[0]
        self.assertIn("WatchHeartRateZoneBar(", clock)
        self.assertIn("attenuated: isLuminanceReduced", clock)
        self.assertNotIn("if !isLuminanceReduced {\n                WatchHeartRateZoneBar", clock)

    def test_wear_pager_controls_left_media_right_and_ambient_bar(self):
        live = read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        planned = read("android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt")
        timer = read("android/wear/src/main/java/dev/repera/wear/WearHubTimer.kt")
        ambient = read("android/wear/src/main/java/dev/repera/wear/WearAmbient.kt")
        media = read("android/wear/src/main/java/dev/repera/wear/WearNowPlayingPage.kt")
        for src in (live, planned, timer):
            self.assertIn("rememberPagerState(initialPage = 1, pageCount = { 3 })", src)
            self.assertIn("WearNowPlayingPage()", src)
        self.assertIn("page == 0 -> WearLiveControlsPage(", live)
        self.assertIn("onRequestCancel = { confirmCancel = true }", live)
        self.assertIn("onToggleAudioMuted = onToggleAudioMuted", live)
        self.assertIn("Icons.Filled.Close", live)
        self.assertIn("attenuated: Boolean = false", live)
        self.assertIn("rimBottomRight", live)
        self.assertIn("WearHeartRateZoneRim(", live)
        self.assertIn("WearHeartRateZoneBar(\n                bpm = snapshot.heartRate", ambient)
        self.assertIn("attenuated = true", ambient)
        self.assertIn("dispatchWearMediaKey", media)
        self.assertIn("KEYCODE_MEDIA_PLAY_PAUSE", media)
        # Solo teclas multimedia públicas; sin intents OEM de lanzamiento.
        self.assertIn("dispatchMediaKeyEvent", media)
        self.assertNotIn("OPEN_MEDIA_ACTIVITY", media)
        self.assertNotIn("getActiveSessions", media)

    def test_wear_active_workout_keeps_live_face(self):
        main = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        self.assertIn("workoutKeepsFace", main)
        self.assertIn('livePhase in setOf("recording", "paused")', main)
        self.assertIn('visibleSession?.phase == "counting"', main)
        self.assertIn("rootView.keepScreenOn = workoutKeepsFace", main)
        self.assertIn("!workoutKeepsFace", main)


if __name__ == "__main__":
    unittest.main()
