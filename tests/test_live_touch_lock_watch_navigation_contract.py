"""Contratos estáticos para bloqueo táctil de Comenzar y navegación Watch/Wear.

Estos checks no sustituyen compilar con Xcode/Gradle ni las pruebas de toques
y modos de pantalla en dispositivos reales.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class LiveTouchLockWatchNavigationContractTests(unittest.TestCase):
    def test_ios_lock_is_screen_only_and_has_one_second_unlock(self):
        ios = source("Apps/Repera/Sources/LiveActivityView.swift")
        timer = source("Apps/Repera/Sources/RestFeedback.swift")
        self.assertIn("case liveLock", timer)
        self.assertIn("runningSources.insert(source)", timer)
        self.assertIn("isAppForeground && !runningSources.isEmpty", timer)
        self.assertIn("isInteractionLocked && canLockLiveScreen, for: .liveLock", ios)
        self.assertIn("TimerScreenAwake.setRunning(false, for: .liveLock)", ios)
        self.assertIn("recorder.phase == .recording || recorder.phase == .paused", ios)
        self.assertIn(".allowsHitTesting(!isInteractionLocked)", ios)
        self.assertIn(".overlayPreferenceValue(LiveInteractionLockAnchorKey.self)", ios)
        self.assertIn("unlockInteractionLock()", ios)
        self.assertIn(".onLongPressGesture(minimumDuration: 1)", ios)
        self.assertIn(".anchorPreference(key: LiveInteractionLockAnchorKey.self", ios)
        self.assertIn("isInteractionLocked = true", ios)
        self.assertIn("beginLockMerge()", ios)
        self.assertIn("lockMergeProgress", ios)
        self.assertIn(".glassEffect(.regular.tint(OG.accent).interactive(), in: .circle)", ios)
        self.assertIn('Image(systemName: "lock.fill")', ios)
        self.assertIn('"lock.open"', ios)
        self.assertIn(
            "recorder.phase == .recording", ios
        )
        self.assertIn("for: .tabBar", ios)

    def test_android_intercepts_all_gestures_and_releases_awake(self):
        android = source("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        toolbar = source("android/mobile/src/main/java/dev/repera/mobile/LiveStartToolbar.kt")
        self.assertIn("BackHandler(enabled = touchLocked)", android)
        self.assertIn("rootView.keepScreenOn = true", android)
        self.assertIn("rootView.keepScreenOn = false", android)
        self.assertIn("PointerEventPass.Initial", android)
        self.assertIn("withTimeoutOrNull(1_000L)", android)
        self.assertIn("if (!touchLockAvailable) { touchLocked = false; liveSessionPage = 1 }", android)
        self.assertIn(".size(94.dp)", android)
        self.assertIn("onPrimaryPositioned = { lockTarget = it }", android)
        self.assertIn('testTag("live_touch_unlock")', android)
        self.assertNotIn(".background(brandGreen)", android.split("private fun LiveScreenTouchBlocker", 1)[1].split("/** Aviso sin GPS", 1)[0])
        self.assertIn('testTag("live_lock")', toolbar)
        self.assertIn("onLock: () -> Unit", toolbar)
        self.assertIn("showsFusedLock", toolbar)
        self.assertIn("onLock = {", android)
        self.assertEqual(android.count("LiveScreenTouchBlocker(lockTarget, lockContainer"), 4)
        self.assertIn("live_touch_unlock", android)
        shell = source("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")
        self.assertIn("LiveActivityTouchLockState.locked = keepAwake", android)
        self.assertIn("liveSessionHidesTab", shell)
        self.assertIn("LiveActivityState.Phase.RECORDING", shell)
        self.assertIn("!liveSessionHidesTab", shell)
        self.assertIn('val mapUnderTabs = currentRoute == "en-vivo"', shell)

    def test_watch_vertical_navigation_preserves_lateral_controls(self):
        watch = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn("WatchLiveNavigationPage(instruction: turn, distanceMeters: live.nextTurnMeters)", watch)
        self.assertIn(".tabViewStyle(.verticalPage)", watch)
        self.assertIn(".tag(0)", watch)
        self.assertIn(".tag(1)", watch)
        self.assertIn("WatchSwipeControlSurface {", watch)
        self.assertIn("hub.controlLiveActivity(\"finish\")", watch)
        self.assertIn("current <= 100, !companionTurnAlerted", watch)
        self.assertIn("previouslySeenCompanionTurnMeters", watch)

    def test_wear_vertical_inside_horizontal_and_real_cue_only(self):
        wear = source("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        bridge = source("android/mobile/src/main/java/dev/repera/mobile/WearActiveSessionBridge.kt")
        self.assertIn("VerticalPager(state = verticalPages", wear)
        self.assertIn("HorizontalPager(\n            state = pager", wear)
        self.assertIn("!live.isNull(\"nextTurn\")", wear)
        self.assertIn("WearLiveMetricsPage(live = live", wear)
        self.assertIn("haptic.performHapticFeedback(HapticFeedbackType.LongPress)", wear)
        self.assertIn("runtime.upcomingCue?.distanceMeters ?: JSONObject.NULL", bridge)
        self.assertIn('.put("nextTurnMeters",', bridge)

    def test_watch_ambient_mode_is_not_forced_fully_on(self):
        docs = source("docs/WATCH_WEAR_ALWAYS_ON_AND_SPLITS_2026_10_31.md")
        self.assertIn("WKSupportsAlwaysOnDisplay", docs)
        self.assertIn("View.keepScreenOn", docs)
        self.assertIn("WearAmbientScreen", docs)
        # Live/plan activo: keepScreenOn + no AmbientScreen.
        wear = source("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        self.assertIn("rootView.keepScreenOn = workoutKeepsFace", wear)
        self.assertIn("hubOverlay == WearHubOverlay.HOME && !workoutKeepsFace", wear)


if __name__ == "__main__":
    unittest.main()
