"""Native entry-point contracts: navigation first, sensor ownership stays in app."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class NativeSystemEntryContractTests(unittest.TestCase):
    def test_ios_shortcuts_only_enqueue_navigation(self):
        swift = source("Apps/Repera/Sources/ReperaSystemShortcuts.swift")
        self.assertIn("AppShortcutsProvider", swift)
        self.assertIn("static var openAppWhenRun = true", swift)
        self.assertIn("ReperaSystemCommand.request(.today)", swift)
        self.assertNotIn("HKWorkoutSession(", swift)
        self.assertNotIn("startActivity(with:", swift)
        root = source("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("guard store.isHydrated, let destination", root)
        self.assertIn('case "today":', root)

    def test_apple_widgets_and_watch_gesture_are_connected(self):
        bundle = source("Apps/ReperaRestWidget/RestLiveActivityWidget.swift")
        self.assertIn("ReperaHomeWidget()", bundle)
        widget = source("Apps/ReperaRestWidget/ReperaHomeWidget.swift")
        self.assertIn("repera://today", widget)
        self.assertIn("repera://live", widget)
        self.assertNotIn("HealthKit", widget)
        watch = source("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        self.assertIn(".handGestureShortcut(.primaryAction", watch)
        self.assertIn("!hub.nextActionIsFinish", watch)

    def test_android_external_actions_are_navigation_only(self):
        route = source("android/mobile/src/main/java/dev/repera/mobile/LiveNavigationTarget.kt")
        self.assertIn('"today" -> "inicio"', route)
        self.assertIn('"timer" -> "temporizador"', route)
        tile = source("android/mobile/src/main/java/dev/repera/mobile/ReperaQuickTileService.kt")
        self.assertIn("startActivityAndCollapse(pending)", tile)
        self.assertNotIn("ExerciseClient", tile)
        self.assertNotIn("startForegroundService", tile)
        manifest = source("android/mobile/src/main/AndroidManifest.xml")
        self.assertIn("BIND_QUICK_SETTINGS_TILE", manifest)
        self.assertIn("repera_home_widget_info", manifest)
        self.assertIn("repera_shortcuts", manifest)

    def test_export_is_explicit_and_uses_unmodified_gps(self):
        export = source("Apps/Repera/Sources/RouteGPXExporter.swift")
        self.assertIn("RouteGPXExporter", export)
        self.assertIn('xmlns=\\\"http://www.topografix.com/GPX/1/1', export)
        self.assertIn("(-90...90)", export)
        self.assertIn("(-180...180)", export)
        ui = source("Apps/Repera/Sources/HistoryView.swift")
        self.assertIn("ShareLink(item: exportedRoute)", ui)


if __name__ == "__main__":
    unittest.main()
