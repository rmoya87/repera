"""El splash de restauración no debe esperar el catálogo remoto.

Si prepareAccountDataAfterAuth (red / fromBytes pesado) corre con
restoringSession=true, Inicio nunca aparece en emuladores lentos.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"


class AndroidLaunchSplashContractTests(unittest.TestCase):
    def test_restore_dismisses_splash_before_account_prepare(self):
        text = MAIN.read_text(encoding="utf-8")
        restore = text.split("private fun restoreStoredSession()", 1)[1].split(
            "private fun persistSession(", 1
        )[0]
        self.assertIn("LaunchSplashScreen()", text)
        self.assertIn("if (restoringSession)", text)
        dismiss_at = restore.index("restoringSession = false")
        prepare_at = restore.index("prepareAccountDataAfterAuth(stored.uniqueId)")
        self.assertLess(
            dismiss_at,
            prepare_at,
            "restoringSession debe bajarse antes de prepareAccountDataAfterAuth",
        )


if __name__ == "__main__":
    unittest.main()
