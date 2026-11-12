"""Regresiones del acceso Google Android: auth válida no se invalida por catálogo.

Estos contratos revisan el orden crítico y las ramas de error en MainActivity.
No sustituyen la prueba instrumental Google Play / Supabase con un dispositivo.
"""
from pathlib import Path
import unittest

MAIN = (
    Path(__file__).resolve().parents[1]
    / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
)


class AndroidGoogleLoginRecoveryContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = MAIN.read_text(encoding="utf-8")
        cls.login = source.split("private fun signInWithGoogle()", 1)[1].split(
            "/** Tras terminar una sesión:", 1
        )[0]
        cls.restore = source.split("private fun restoreStoredSession()", 1)[1].split(
            "private fun persistSession(", 1
        )[0]

    def test_supabase_validation_and_durable_identity_precede_optional_loading(self):
        login = self.login
        verified = login.index("SupabaseIdentity().signInWithGoogle(google.idToken, nonce.raw)")
        stored = login.index("persistSession(session, signedIn)")
        populated = login.index("profile = signedIn")
        hydration = login.index("CatalogBootstrap.ensureHydrated(")
        sync = login.index("DriveSyncWorker.schedulePeriodic(")
        self.assertLess(verified, stored)
        self.assertLess(stored, populated)
        self.assertLess(populated, hydration)
        self.assertLess(stored, sync)
        self.assertEqual(login.count("persistSession(session, signedIn)"), 1)

    def test_post_login_error_keeps_verified_identity_and_workout_state(self):
        error_block = self.login.split("} catch (error: Exception)", 1)[1].split(
            "} finally {", 1
        )[0]
        authenticated = error_block.split("if (saved != null) {", 1)[1].split(
            "} else {", 1
        )[0]
        self.assertIn("if (verifiedSupabase == null) verifiedSupabase = saved.first", authenticated)
        self.assertIn("if (profile == null) profile = saved.second", authenticated)
        for forbidden in (
            "sessionStore.clear(",
            "sessionStore.clearIfCurrent(",
            "snapshot = null",
            "snapshotCache.clear()",
            "activeWorkout = null",
            "profile = null",
            "verifiedSupabase = null",
            "aiPlansRealtime.stop()",
        ):
            self.assertNotIn(forbidden, authenticated)
        self.assertIn("if (error is kotlinx.coroutines.CancellationException) throw error", error_block)

    def test_google_errors_are_distinguished_without_changing_oauth_nonce(self):
        login = self.login
        self.assertIn(".setNonce(nonce.hashedHex)", login)
        self.assertIn("signInWithGoogle(google.idToken, nonce.raw)", login)
        self.assertIn("GetCredentialCancellationException", login)
        self.assertIn("GetCredentialException", login)
        self.assertIn("is AuthHttpException", login)
        self.assertNotIn("response.body", login)

    def test_offline_restore_does_not_throw_a_second_catalog_exception(self):
        restore = self.restore
        offline = restore.split('if(!SupabaseAuthErrors.isUnrecoverable(error)) {', 1)[1].split(
            "// Revoked refresh token", 1
        )[0]
        self.assertIn("try {", offline)
        self.assertIn("ensureCatalogHydrated(stored.uniqueId) { current() }", offline)
        self.assertIn("catch (recoveryError: Exception)", offline)
        self.assertIn("if (recoveryError is kotlinx.coroutines.CancellationException) throw recoveryError", offline)
        self.assertIn("return@launch", offline)
        self.assertNotIn("sessionStore.clear", offline)


if __name__ == "__main__":
    unittest.main()
