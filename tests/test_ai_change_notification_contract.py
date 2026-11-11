#!/usr/bin/env python3
"""Contract: AI create/update/delete use native system notifications, not in-app banners."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class AIChangeNotificationContract(unittest.TestCase):
    def test_ios_has_native_notifier_and_no_floating_banner(self) -> None:
        notifier = read("Apps/Repera/Sources/AIChangeNotifier.swift")
        app = read("Apps/Repera/Sources/ReperaApp.swift")
        inbox = read("Apps/Repera/Sources/AITrainingInboxStore.swift")
        changes = read("Apps/Repera/Sources/AIChangeRequestStore.swift")
        completion = read("Apps/Repera/Sources/WorkoutCompletionNotifier.swift")
        root = read("Apps/Repera/Sources/RootTabView.swift")

        self.assertIn("enum AIChangeNotifier", notifier)
        self.assertIn("ha añadido un entreno", notifier)
        self.assertIn("quiere corregir un entreno", notifier)
        self.assertIn("pide eliminar un entreno", notifier)
        self.assertIn("Tu asistente", notifier)
        self.assertIn("connectionLabel", notifier)

        self.assertNotIn("Entrenamiento de IA recibido", app)
        self.assertNotIn("lastImportedTitle", app)
        self.assertNotIn("dismissArrival", inbox)
        self.assertNotIn("lastImportedTitle", inbox)

        self.assertIn("AIChangeNotifier.notifyCreate", inbox)
        self.assertIn("created_by_token_id", inbox)
        self.assertIn("AIChangeNotifier.notifyPendingChanges", changes)
        self.assertIn("token_id", changes)
        self.assertIn("AIChangeNotifier.handleNotificationResponse", completion)
        self.assertIn("openAIChangeTarget", root)
        self.assertIn("openPendingAIChangeNotification", root)

    def test_android_has_native_notifier_and_no_status_toast(self) -> None:
        notifier = read("android/mobile/src/main/java/dev/repera/mobile/AIChangeNotification.kt")
        main = read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        inbox = read("android/mobile/src/main/java/dev/repera/mobile/AITrainingInbox.kt")
        screen = read("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")

        self.assertIn("object AIChangeNotification", notifier)
        self.assertIn("ha añadido un entreno", notifier)
        self.assertIn("quiere corregir un entreno", notifier)
        self.assertIn("pide eliminar un entreno", notifier)
        self.assertIn("repera://ai-change", notifier)
        self.assertIn("routeFromUri", notifier)

        self.assertNotIn("Plan de IA aplicado", main)
        self.assertIn("AIChangeNotification.notifyCreate", main)
        self.assertIn("notifyAIPendingChanges", main)
        self.assertIn('uri.host == "ai-change"', main)
        self.assertIn("created_by_token_id", inbox)
        self.assertIn('route.startsWith("inicio?")', screen)
        self.assertIn('route.startsWith("historial-detalle/")', screen)

    def test_xcode_sources_require_notifier(self) -> None:
        check = read("scripts/check_xcode_sources.py")
        self.assertIn("AIChangeNotifier.swift", check)


if __name__ == "__main__":
    unittest.main()
