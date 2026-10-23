"""Google OAuth en iOS: evita fusionar cuentas distintas y mantiene identidad Apple.

Contrato estático: el login OAuth requiere validación E2E en iPhone con dos
proveedores y redirect permitido; no se prueban credenciales reales en CI.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps/Repera/Sources"


def source(name):
    return (SRC / name).read_text(encoding="utf-8")


class GoogleIdentityContractTests(unittest.TestCase):
    def test_google_oauth_uses_native_web_auth_and_explicit_callback(self):
        auth = source("BusinessAuthStore.swift")
        self.assertIn("signInWithOAuth(", auth)
        self.assertIn("provider: .google", auth)
        self.assertIn('URL(string: "repera://auth/callback")', auth)
        self.assertIn("ASWebAuthenticationSession(", auth)
        self.assertIn("client.auth.getLinkIdentityURL(", auth)
        self.assertIn("client.auth.session(from: callback)", auth)
        self.assertIn("confirmed.user.id == currentID", auth)

    def test_apple_google_same_uid_required_before_local_workouts_are_reused(self):
        auth = source("BusinessAuthStore.swift")
        self.assertIn("localOwnerSupabaseUserID.v1", auth)
        self.assertIn("isSameLocalOwner(session.user.id)", auth)
        self.assertIn("guard confirmed.user.id == currentID", auth)
        self.assertIn("try? await client.auth.signOut()", auth)
        self.assertIn("rememberOwner(session.user.id)", auth)
        self.assertIn("func signInWithGoogle()", auth)
        self.assertIn("func connect(credential:", auth)
        self.assertIn("provider: .apple", auth)
        self.assertNotIn("auth.users", auth)
        self.assertNotIn("update auth.identities", auth)

    def test_signout_keeps_owner_but_revokes_remote_tokens(self):
        auth = source("BusinessAuthStore.swift")
        signout = auth.split("func signOut() async {", 1)[1]
        self.assertIn("rememberOwner(uid)", signout)
        self.assertIn("client.auth.signOut()", signout)
        self.assertIn("UserDefaults.standard.set(false, forKey: googleSignedInKey)", signout)
        self.assertNotIn("removeObject(forKey: localOwnerUserIDKey)", signout)

    def test_login_and_account_ui_include_both_providers(self):
        login = source("Onboarding/OnboardingFlowView.swift")
        self.assertIn('Text("Iniciar sesión con Apple")', login)
        self.assertIn('Text("Continuar con Google")', login)
        self.assertIn("signInGoogle() async", login)
        self.assertIn("business.isGoogleSignedIn", login)
        account = source("SettingsView.swift")
        self.assertIn("Vincular cuenta de Google", account)
        self.assertIn("businessAuth.accountEmail", account)
        self.assertIn("businessAuth.linkGoogleToCurrentAccount()", account)

    def test_scheme_configured_in_plist_and_project_yml(self):
        plist = (ROOT / "Apps/Repera/Resources/Info.plist").read_text()
        project = (ROOT / "project.yml").read_text()
        self.assertIn("<key>CFBundleURLSchemes</key>", plist)
        self.assertIn("<string>repera</string>", plist)
        self.assertIn("CFBundleURLSchemes:", project)
        self.assertIn("- repera", project)

    def test_logout_does_not_reset_paid_onboarding(self):
        wizard = source("Onboarding/OnboardingStore.swift")
        snippet = wizard.split("func resetToSignIn() {", 1)[1].split("    }", 1)[0]
        self.assertNotIn("priceAlreadySeen = false", snippet)
        self.assertIn("advance(to: .appleSignIn)", snippet)
        app = source("ReperaApp.swift")
        self.assertIn("businessAuth.isGoogleSignedIn", app)


if __name__ == "__main__":
    unittest.main()
