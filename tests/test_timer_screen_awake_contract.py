"""Timers keep iPhone awake in foreground and release the idle-timer on pause/end.

Static contracts complement runtime UI tests on a physical iPhone: UIKit's
isIdleTimerDisabled and sound output cannot be asserted from Python.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
AUDIO = (IOS / "RestFeedback.swift").read_text(encoding="utf-8")
ALONE = (IOS / "StandaloneTimerView.swift").read_text(encoding="utf-8")
WORKOUT = (IOS / "WorkoutClockCoordinator.swift").read_text(encoding="utf-8")
REST = (IOS / "RestSessionCoordinator.swift").read_text(encoding="utf-8")
APP = (IOS / "ReperaApp.swift").read_text(encoding="utf-8")


class ScreenAwakeContractTests(unittest.TestCase):
    def test_shared_lock_tracks_all_three_sources_without_overwriting(self):
        coordinator = AUDIO.split("enum TimerScreenAwake {", 1)[1].split(
            "/// Única familia de tonos", 1
        )[0]
        self.assertIn("case standalone", coordinator)
        self.assertIn("case workout", coordinator)
        self.assertIn("case rest", coordinator)
        self.assertIn("runningSources.insert(source)", coordinator)
        self.assertIn("runningSources.remove(source)", coordinator)
        self.assertIn("isAppForeground && !runningSources.isEmpty", coordinator)
        self.assertIn("UIApplication.shared.isIdleTimerDisabled = shouldStayAwake", coordinator)

    def test_standalone_countdown_and_completion_release_lock(self):
        self.assertIn(".onChange(of: isRunning)", ALONE)
        self.assertIn("TimerScreenAwake.setRunning(running, for: .standalone)", ALONE)
        self.assertIn("if !visible { stopTimer() }", ALONE)
        self.assertIn("if !showClock { stopTimer() }", ALONE)
        self.assertIn("if phase == .active, isRunning", ALONE)
        self.assertIn("syncFromWallClock()", ALONE)
        self.assertIn("RestFeedback.restComplete(sound: true, haptic: true)", ALONE)

    def test_workout_clock_observer_covers_precountdown_pause_finish_restore(self):
        self.assertIn("private(set) var isRunning = false {", WORKOUT)
        self.assertIn("didSet {", WORKOUT)
        self.assertIn("TimerScreenAwake.setRunning(isRunning, for: .workout)", WORKOUT)
        self.assertIn("isRunning = saved.isRunning", WORKOUT)
        self.assertIn("func pause()", WORKOUT)
        self.assertIn("func resume()", WORKOUT)
        self.assertIn("func stop(keepVisible:", WORKOUT)
        self.assertIn("func finishComplete()", WORKOUT)

    def test_rest_timer_does_not_keep_device_awake_while_paused(self):
        self.assertIn("didSet { updateScreenAwake() }", REST)
        self.assertIn("!isPaused && endDate.map { $0 > Date() } == true", REST)
        self.assertIn("for: .rest", REST)
        self.assertIn("func refreshWhenActive()", REST)
        self.assertIn("finish(announce: true)", REST)

    def test_app_releases_wake_permission_in_background_and_restores_on_foreground(self):
        self.assertIn("TimerScreenAwake.setAppForeground(scenePhase == .active)", APP)
        self.assertIn("TimerScreenAwake.setAppForeground(phase == .active)", APP)
        self.assertIn("store.restCoordinator.refreshWhenActive()", APP)

    def test_audible_tones_still_use_existing_audio_session(self):
        self.assertIn("try session.setCategory(.playback", AUDIO)
        self.assertIn("guard player.prepareToPlay(), player.play()", AUDIO)
        self.assertIn("RestFeedback.tick(remaining: preCountdown, sound: true", ALONE)
        self.assertIn("RestFeedback.intervalBeep(sound: soundEnabled", WORKOUT)
        self.assertIn("RestFeedback.tick(", REST)


if __name__ == "__main__":
    unittest.main()
