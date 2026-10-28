"""Lock-screen timer, fallback sound and Start Hub menu regression contracts.

These static source checks do not replace a physical iPhone UI/notification test.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
WIDGET = ROOT / "Apps" / "ReperaRestWidget" / "RestLiveActivityWidget.swift"
SHARED = ROOT / "Apps" / "Shared" / "RestActivityAttributes.swift"


def read(path):
    return path.read_text(encoding="utf-8")


class LockScreenTimerContracts(unittest.TestCase):
    def test_live_widget_counts_down_from_absolute_dates_even_without_app_ticks(self):
        widget = read(WIDGET)
        self.assertIn("let start = state.endDate.addingTimeInterval(", widget)
        self.assertIn("Text(timerInterval: start...state.endDate, countsDown: true)", widget)
        self.assertNotIn("Date()...context.state.endDate", widget)
        self.assertIn("if let paused = state.pausedRemainingSeconds", widget)
        self.assertIn("format: .stopwatch(", widget)

    def test_rest_activity_is_not_staled_or_removed_on_pause(self):
        coordinator = read(IOS / "RestLiveActivity.swift")
        rest = read(IOS / "RestSessionCoordinator.swift")
        shared = read(SHARED)
        self.assertIn("pausedRemainingSeconds: Int?", shared)
        self.assertIn("countUpAnchor: Date?", shared)
        self.assertIn("sourceKey: String?", shared)
        self.assertIn("content: .init(state: state, staleDate: nil)", coordinator)
        self.assertIn("state.pausedRemainingSeconds = remaining", coordinator)
        pause = rest.split("func pause()", 1)[1].split("func resume()", 1)[0]
        self.assertIn("RestLiveActivityCoordinator.shared.pause(", pause)
        self.assertNotIn("RestLiveActivityCoordinator.shared.end()", pause)
        self.assertIn("RestLiveActivityCoordinator.shared.resume(", rest)

    def test_standalone_and_workout_use_separate_live_activities(self):
        coordinator = read(IOS / "RestLiveActivity.swift")
        alone = read(IOS / "StandaloneTimerView.swift")
        workout = read(IOS / "WorkoutClockCoordinator.swift")
        self.assertIn("case standalone", coordinator)
        self.assertIn("case workout", coordinator)
        self.assertIn("attributes.sourceKey == source.rawValue", coordinator)
        self.assertIn("relevanceScore: 100", coordinator)
        self.assertIn("TimerLiveActivityCoordinator.shared.countdown(", alone)
        self.assertIn("TimerLiveActivityCoordinator.shared.countUp(", alone)
        self.assertIn("TimerLiveActivityCoordinator.shared.pause(", alone)
        self.assertIn("TimerLiveActivityCoordinator.shared.countdown(", workout)
        self.assertIn("TimerLiveActivityCoordinator.shared.countUp(", workout)
        self.assertIn("publishPausedLiveTimer()", workout)

    def test_lock_screen_sounds_use_system_notifications_without_duplicate_foreground_tones(self):
        notifier = read(IOS / "RestLocalNotifier.swift")
        alone = read(IOS / "StandaloneTimerView.swift")
        workout = read(IOS / "WorkoutClockCoordinator.swift")
        rest = read(IOS / "RestSessionCoordinator.swift")
        self.assertIn("content.sound = .default", notifier)
        self.assertIn("UNTimeIntervalNotificationTrigger(", notifier)
        self.assertIn("TimerBoundaryNotifier.schedule(.standalone", alone)
        self.assertIn("TimerBoundaryNotifier.schedule(.workout", workout)
        self.assertIn("TimerBoundaryNotifier.cancel(.standalone)", alone)
        self.assertIn("TimerBoundaryNotifier.cancel(.workout)", workout)
        self.assertIn("RestLocalNotifier.schedule(token: token, at: end", rest)
        self.assertIn("RestLocalNotifier.cancel(token: notifyToken)", rest)

    def test_add_workout_has_exact_requested_four_options_in_order(self):
        modal = read(IOS / "DayPlusSheet.swift")
        modal_menu = modal.split("private var menuContent:", 1)[1].split(
            "private var menuDivider:", 1
        )[0]
        modal_titles = (
            'title: "Crear entreno"',
            'title: "Temporizador"',
            'title: "Escanear entreno"',
            'title: "Favoritos"',
        )
        positions = [modal_menu.index(value) for value in modal_titles]
        self.assertEqual(positions, sorted(positions))
        self.assertNotIn('title: "Escanear pizarra o TV"', modal_menu)
        self.assertEqual(modal_menu.count("menuDivider"), 3)

        sheet = read(IOS / "StartHubSheet.swift")
        visible = sheet.split('Section("Entrenamiento") {', 1)[1].split("if isReading {", 1)[0]
        requested = (
            'Text("Crear entreno")',
            'Text("Temporizador")',
            'Text("Escanear entreno")',
            'Text("Favoritos")',
        )
        indexes = [visible.index(entry) for entry in requested]
        self.assertEqual(indexes, sorted(indexes))
        self.assertNotIn('Text("Crear mi entreno")', visible)
        self.assertNotIn('Text("Escanear pizarra o TV")', visible)
        self.assertNotIn('Text("Apuntar series")', visible)


if __name__ == "__main__":
    unittest.main()
