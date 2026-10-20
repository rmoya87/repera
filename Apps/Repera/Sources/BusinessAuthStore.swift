import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Security
import Supabase

/// Secondary, business-only Supabase identity; the existing Apple/iCloud personal workout
/// identity and private local training history are never replaced by this service.
@MainActor
@Observable
final class BusinessAuthStore {
    static let shared = BusinessAuthStore()

    private(set) var isConnected = false
    /// A previously signed-in Apple/iCloud account needs a fresh nonce-bound
    /// Apple ID token before it can be registered or restored in Supabase.
    private(set) var isMigrationRequired = false
    private(set) var hasRestoredSession = false
    private(set) var profileMigrationErrorMessage: String?
    private let appleIdentityBindingKey = "repera.business.appleIdentityHash.v1"
    private(set) var lastErrorMessage: String?
    private(set) var isConnecting = false

    @ObservationIgnored
    private let client: SupabaseClient?

    var apiClient: SupabaseClient? { client }

    private init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "ReperaSupabaseURL") as? String
        let key = Bundle.main.object(forInfoDictionaryKey: "ReperaSupabasePublishableKey") as? String
        if let urlString, let url = URL(string: urlString),
           url.scheme == "https", url.host == "uvzgujlrqohreoucirms.supabase.co",
           let key, key.hasPrefix("sb_publishable_") {
            // Supabase Swift 2.55.4 emits the stored (possibly expired) session
            // immediately. Never authorize users from that initial event:
            // restoreSession() always awaits auth.session to validate/refresh it.
            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key,
                options: SupabaseClientOptions(
                    auth: .init(emitLocalSessionAsInitialSession: true)
                )
            )
        } else {
            client = nil
        }
    }

    /// Restores the SDK's validated/auto-refreshed session, never an expired
    /// `initialSession` or an account not linked to the current Apple identity.
    func restoreSession() async {
        hasRestoredSession = false
        defer { hasRestoredSession = true }
        isConnected = false
        BusinessDataStore.shared.clear()
        guard let client else {
            isMigrationRequired = AppleAuthStore.shared.isSignedIn
            lastErrorMessage = "Supabase Repera no está configurado en esta compilación."
            return
        }
        guard let appleUserID = AppleAuthStore.shared.userID,
              AppleAuthStore.shared.isSignedIn else {
            isMigrationRequired = false
            try? await client.auth.signOut()
            return
        }
        let expectedBinding = Self.hashedNonce(appleUserID)
        guard UserDefaults.standard.string(forKey: appleIdentityBindingKey) == expectedBinding else {
            // Legacy Apple-only identity: require a new Apple authentication with
            // nonce instead of attempting to translate Keychain IDs into JWTs.
            isMigrationRequired = true
            lastErrorMessage = nil
            try? await client.auth.signOut()
            return
        }
        do {
            let session = try await client.auth.session
            guard UserDefaults.standard.string(forKey: appleIdentityBindingKey) == expectedBinding,
                  AppleAuthStore.shared.userID == appleUserID else {
                isMigrationRequired = true
                return
            }
            if session.isExpired {
                // Intentar renovar; no empujar al login Apple solo por un token caducado.
                _ = try await client.auth.refreshSession()
                let refreshed = try await client.auth.session
                guard !refreshed.isExpired else {
                    isMigrationRequired = true
                    lastErrorMessage = "La sesión con Supabase ha caducado. Vuelve a conectar con Apple."
                    return
                }
            }
            isConnected = true
            isMigrationRequired = false
            lastErrorMessage = nil
        } catch {
            isConnected = false
            // Tras actualizar la app, un fallo de red no debe pedir Sign in with Apple otra vez
            // si el vínculo Apple↔Supabase ya estaba guardado.
            isMigrationRequired = false
            lastErrorMessage = "No se pudo renovar la sesión Business. Se reintentará al volver a la app."
        }
    }

    /// A short-lived, secure random nonce prevents Apple ID token replay.
    nonisolated static func makeNonce() -> String {
        var data = [UInt8](repeating: 0, count: 32)
        let result = data.withUnsafeMutableBytes { bytes -> OSStatus in
            guard let address = bytes.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, bytes.count, address)
        }
        precondition(result == errSecSuccess, "No se ha podido generar un nonce seguro.")
        return Data(data).map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func hashedNonce(_ rawNonce: String) -> String {
        let digest = SHA256.hash(data: Data(rawNonce.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Sign in to Supabase with a genuine nonce-bound Apple identity token.
    /// Returns false if the backend login failed; UI must not treat Apple-only
    /// sign-in as a completed Supabase login.
    @discardableResult
    func connect(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async -> Bool {
        guard let client else {
            lastErrorMessage = "Supabase Repera no está configurado."
            isConnected = false
            return false
        }
        guard !isConnecting else { return false }
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              !idToken.isEmpty else {
            lastErrorMessage = "Apple no ha proporcionado un token de identidad. Vuelve a intentarlo."
            isConnected = false
            return false
        }
        guard credential.user == AppleAuthStore.shared.userID,
              !rawNonce.isEmpty else {
            lastErrorMessage = "La identidad Apple no coincide. Vuelve a iniciar sesión."
            isConnected = false
            return false
        }

        isConnecting = true
        defer { isConnecting = false }
        isConnected = false
        BusinessDataStore.shared.clear()
        let expectedBinding = Self.hashedNonce(credential.user)
        if UserDefaults.standard.string(forKey: appleIdentityBindingKey) != expectedBinding {
            // Invalidate a previous account's SDK tokens before changing identity.
            try? await client.auth.signOut()
        }
        do {
            _ = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: rawNonce
                )
            )
            let session = try await client.auth.session
            guard !session.isExpired, AppleAuthStore.shared.userID == credential.user else {
                throw AccountMigrationError.identityChanged
            }
            UserDefaults.standard.set(expectedBinding, forKey: appleIdentityBindingKey)
            isConnected = true
            isMigrationRequired = false
            hasRestoredSession = true
            lastErrorMessage = nil
            await BusinessDataStore.shared.refresh()
            return true
        } catch {
            isConnected = false
            isMigrationRequired = AppleAuthStore.shared.isSignedIn
            BusinessDataStore.shared.clear()
            lastErrorMessage = "No se ha podido conectar con Supabase: \(error.localizedDescription)"
            return false
        }
    }

    /// One-time, idempotent migration of the *public profile name only*.
    /// Existing remote values win, and private iCloud workouts are never sent.
    func migrateLocalProfileIfNeeded(displayName: String?) async {
        guard isConnected, let client else { return }
        do {
            let session = try await client.auth.session
            guard !session.isExpired,
                  let appleUserID = AppleAuthStore.shared.userID,
                  UserDefaults.standard.string(forKey: appleIdentityBindingKey) == Self.hashedNonce(appleUserID)
            else { return }
            let userID = session.user.id.uuidString
            let migrationKey = "repera.business.migratedProfile.v1.\(userID)"
            guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

            let profiles: [RemoteProfileName] = try await client
                .from("profiles")
                .select("display_name")
                .eq("id", value: userID)
                .limit(1)
                .execute().value
            guard let profile = profiles.first else {
                throw AccountMigrationError.profileMissing
            }
            let localName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if (profile.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !localName.isEmpty {
                try await client.from("profiles")
                    .update(["display_name": String(localName.prefix(100))])
                    .eq("id", value: userID)
                    .execute()
            }
            guard isConnected,
                  AppleAuthStore.shared.userID == appleUserID,
                  (try await client.auth.session).user.id == session.user.id else { return }
            UserDefaults.standard.set(true, forKey: migrationKey)
            profileMigrationErrorMessage = nil
        } catch {
            // No success marker on failure: retry on the next authenticated launch.
            profileMigrationErrorMessage = "No se pudo sincronizar el nombre del perfil. Los entrenamientos locales están intactos."
        }
    }

    /// Explicit profile edit from Ajustes, separate from the one-time migration.
    /// Keeps a visible local profile name and remote profile aligned, without
    /// sending workout data, photos or StoreKit entitlements to Supabase.
    func updateDisplayName(_ value: String?) async {
        guard isConnected, let client else { return }
        do {
            let session = try await client.auth.session
            guard !session.isExpired else { return }
            let name = String((value ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(100))
            try await client.from("profiles")
                .update(["display_name": name])
                .eq("id", value: session.user.id.uuidString)
                .execute()
            profileMigrationErrorMessage = nil
        } catch {
            profileMigrationErrorMessage = "No se ha podido sincronizar el nombre. Puedes reintentarlo más adelante."
        }
    }

    private struct RemoteProfileName: Decodable {
        let displayName: String?
        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    private enum AccountMigrationError: LocalizedError {
        case identityChanged
        case profileMissing
        var errorDescription: String? {
            switch self {
            case .identityChanged: "La cuenta Apple ha cambiado."
            case .profileMissing: "Supabase no ha creado aún el perfil."
            }
        }
    }

    /// Sign out from business platform independently of the Apple/iCloud personal store.
    func signOut() async {
        BusinessWorkoutSyncStore.shared.clearSession()
        isConnected = false
        isMigrationRequired = false
        profileMigrationErrorMessage = nil
        BusinessDataStore.shared.clear()
        UserDefaults.standard.removeObject(forKey: appleIdentityBindingKey)
        if let client { try? await client.auth.signOut() }
        isConnected = false
        lastErrorMessage = nil
    }
}
