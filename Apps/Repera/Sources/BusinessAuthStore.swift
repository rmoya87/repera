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
            client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        } else {
            client = nil
        }
    }

    /// Restore SDK-managed secure session asynchronously. Never gate the app's local startup.
    func restoreSession() async {
        guard let client else {
            isConnected = false
            lastErrorMessage = "Supabase Repera no está configurado en esta compilación."
            return
        }
        // Do not revive the previous Supabase session under a different Apple account.
        guard let appleUserID = AppleAuthStore.shared.userID,
              let boundHash = UserDefaults.standard.string(forKey: appleIdentityBindingKey),
              boundHash == Self.hashedNonce(appleUserID) else {
            isConnected = false
            return
        }
        do {
            _ = try await client.auth.session
            isConnected = true
            lastErrorMessage = nil
        } catch {
            isConnected = false
            // An existing Apple-only user may legitimately have no backend session yet.
            lastErrorMessage = nil
        }
    }

    /// A short-lived, secure random nonce prevents Apple ID token replay.
    nonisolated static func makeNonce() -> String {
        var data = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, data.count, &data)
        precondition(result == errSecSuccess, "No se ha podido generar un nonce seguro.")
        return Data(data).map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func hashedNonce(_ rawNonce: String) -> String {
        let digest = SHA256.hash(data: Data(rawNonce.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func connect(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async {
        guard let client else {
            lastErrorMessage = "Supabase Repera no está configurado."
            isConnected = false
            return
        }
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              !idToken.isEmpty else {
            lastErrorMessage = "Apple no ha proporcionado un token de identidad. Vuelve a intentarlo."
            isConnected = false
            return
        }
        isConnecting = true
        defer { isConnecting = false }
        do {
            _ = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: rawNonce
                )
            )
            // Never persist raw Apple user ID; bind the reusable SDK session locally.
            UserDefaults.standard.set(Self.hashedNonce(credential.user), forKey: appleIdentityBindingKey)
            isConnected = true
            lastErrorMessage = nil
            await BusinessDataStore.shared.refresh()
        } catch {
            // Do not erase the Apple/iCloud login or past local workouts if networking fails.
            isConnected = false
            lastErrorMessage = "No se ha podido conectar con Repera Business: \(error.localizedDescription)"
        }
    }

    /// Sign out from business platform independently of the Apple/iCloud personal store.
    func signOut() async {
        UserDefaults.standard.removeObject(forKey: appleIdentityBindingKey)
        if let client { try? await client.auth.signOut() }
        isConnected = false
        lastErrorMessage = nil
    }
}
