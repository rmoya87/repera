"""SDK Google en iOS: evita fusionar cuentas y mantiene identidad Apple.

Contrato estático: el SDK necesita validación E2E con cliente OAuth iOS,
dispositivo firmado y dos proveedores; no se prueban credenciales reales en CI.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps/Repera/Sources"


def source(name):
    return (SRC / name).read_text(encoding="utf-8")


class GoogleIdentityContractTests(unittest.TestCase):
    def test_google_sdk_exchanges_nonce_bound_credentials_and_links_current_user(self):
        auth = source("BusinessAuthStore.swift")
        self.assertIn("import GoogleSignIn", auth)
        self.assertIn("GIDSignIn.sharedInstance.signIn(", auth)
        self.assertIn("client.auth.signInWithIdToken(credentials: credentials)", auth)
        self.assertIn("provider: .google", auth)
        self.assertIn("nonce: hashedNonce", auth)
        self.assertIn("nonce: rawNonce", auth)
        self.assertIn("accessToken: user.accessToken.tokenString", auth)
        self.assertIn("client.auth.linkIdentityWithIdToken(credentials: credentials)", auth)
        self.assertIn("confirmed.user.id == currentID", auth)
        self.assertIn("client.auth.currentSession?.user.id == currentID", auth)
        self.assertIn("googleAuthAttemptID == attemptID", auth)
        self.assertNotIn("signInWithOAuth(", auth)
        self.assertNotIn("getLinkIdentityURL(", auth)

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
        self.assertIn("didExplicitlySignOut = true", signout)
        self.assertIn("UserDefaults.standard.set(true, forKey: explicitSignOutKey)", signout)
        self.assertIn("guard !didExplicitlySignOut else", auth)
        self.assertIn("clearExplicitSignOutAfterVerifiedLogin()", auth)
        self.assertIn("GIDSignIn.sharedInstance.signOut()", signout)
        self.assertIn("googleAuthAttemptID = UUID()", signout)

    def test_login_and_account_ui_include_both_providers(self):
        login = source("Onboarding/OnboardingFlowView.swift")
        self.assertIn('Text("Iniciar sesión con Apple")', login)
        self.assertIn("import GoogleSignInSwift", login)
        self.assertIn("GoogleSignInButton(", login)
        self.assertIn("style: .wide", login)
        self.assertNotIn('Image(systemName: "g.circle.fill")', login)
        self.assertNotIn('Image("GoogleSignInLogo")', login)
        self.assertNotIn("Tu historial permanece protegido", login)
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
        for key in ("GIDClientID", "GIDServerClientID", "REPERA_GOOGLE_REVERSED_CLIENT_ID"):
            self.assertIn(key, plist)
            self.assertIn(key, project)
        self.assertIn("exactVersion: 10.1.0", project)
        self.assertIn("product: GoogleSignInSwift", project)
        self.assertIn("product: GoogleSignIn", project)
        self.assertIn('GIDSignIn.sharedInstance.handle(url)', source("ReperaApp.swift"))
        auth = source("BusinessAuthStore.swift")
        self.assertIn("schemes.contains(reversedID)", auth)
        self.assertIn("clientID != serverID", auth)
        self.assertIn("GoogleNativeSignInError.configurationMissing", auth)

    def test_profile_sync_accepts_apple_or_google_without_unbound_apple_id(self):
        auth = source("BusinessAuthStore.swift")
        profile = auth.split("func syncPublicProfile(", 1)[1].split("private enum ProfileSyncError", 1)[0]
        self.assertIn("isSameLocalOwner(session.user.id)", profile)
        self.assertIn("client.auth.currentSession?.user.id == session.user.id", profile)
        self.assertNotIn("AppleAuthStore.shared.userID == appleUserID", profile)
        self.assertNotIn("== UserDefaults.standard.string(forKey: appleIdentityBindingKey)\n                  ))", profile)
        self.assertIn("} == true", profile)

    def test_logout_does_not_reset_paid_onboarding(self):
        wizard = source("Onboarding/OnboardingStore.swift")
        snippet = wizard.split("func resetToSignIn() {", 1)[1].split("    }", 1)[0]
        self.assertNotIn("priceAlreadySeen = false", snippet)
        self.assertIn("advance(to: .appleSignIn)", snippet)
        app = source("ReperaApp.swift")
        self.assertIn("businessAuth.isGoogleSignedIn", app)
        self.assertIn("guard !businessAuth.didExplicitlySignOut else { return false }", app)


if __name__ == "__main__":
    unittest.main()
