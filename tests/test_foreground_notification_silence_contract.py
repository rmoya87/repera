"""No system notification banners while Repera is in the foreground."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class ForegroundNotificationSilenceContract(unittest.TestCase):
    def test_ios_will_present_suppresses_banner(self):
        notifier = read("Apps/Repera/Sources/WorkoutCompletionNotifier.swift")
        present = notifier.split(
            "withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)",
            1,
        )[1].split("func userNotificationCenter(\n        _ center: UNUserNotificationCenter,\n        didReceive", 1)[0]
        self.assertIn("completionHandler([])", present)
        self.assertNotIn("completionHandler([.banner, .sound])", present)

    def test_android_skips_timer_done_and_rest_when_foreground(self):
        standalone = read(
            "android/mobile/src/main/java/dev/repera/mobile/StandaloneTimerService.kt"
        )
        rest = read("android/mobile/src/main/java/dev/repera/mobile/RestNotifier.kt")
        done = standalone.split("private fun notifyFinished()", 1)[1].split(
            "private fun buildNotification(", 1
        )[0]
        self.assertIn("IMPORTANCE_FOREGROUND", done)
        self.assertIn("return", done)
        self.assertIn("IMPORTANCE_FOREGROUND", rest)
        self.assertLess(
            rest.index("IMPORTANCE_FOREGROUND"),
            rest.index("manager.notify(NOTIFICATION_ID"),
        )


if __name__ == "__main__":
    unittest.main()
