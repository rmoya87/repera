import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import ReperaDomain
import Security
import UIKit

/// Sign in with Apple: identidad obligatoria. iCloud Documents sigue siendo el espejo de datos.
@MainActor
@Observable
final class AppleAuthStore: NSObject {
    static let shared = AppleAuthStore()

    private(set) var userID: String?
    private(set) var displayName: String?
    private(set) var email: String?
    private(set) var credentialState: ASAuthorizationAppleIDProvider.CredentialState = .notFound
    private(set) var lastErrorMessage: String?
    private(set) var isSigningIn = false

    var isSignedIn: Bool {
        userID != nil && (credentialState == .authorized || credentialState == .transferred)
    }

    /// Non-reversible per-account scope for local keys and caches. The raw
    /// Apple user ID, name and email live only in Keychain.
    var ownerScope: String? { userID.map(Self.ownerScope(forUserID:)) }

    nonisolated static func ownerScope(forUserID userID: String) -> String {
        SHA256.hash(data: Data(userID.utf8)).prefix(16)
            .map { String(format: "%02x", $0) }.joined()
    }

    /// Readable without a main-actor hop (e.g. Health disk cache warm start).
    nonisolated static let ownerScopeDefaultsKey = "repera.apple.ownerScope.v1"

    private let keychainService = "com.app.repera.appleauth"
    private let userIDKey = "userID"
    private let nameKey = "displayName"
    private let emailKey = "email"
    /// Legacy plaintext mirrors (pre-2026-11). Only read once to migrate into
    /// Keychain, then deleted. Never written again.
    private let legacyDefaultsUserIDKey = "repera.apple.userID.v1"
    private let legacyDefaultsNameKey = "repera.apple.displayName.v1"
    private let legacyDefaultsEmailKey = "repera.apple.email.v1"
    private let revokedMarkerKey = "repera.apple.credentialInvalid.v1"

    private var continuityContinuation: CheckedContinuation<ASAuthorization, Error>?

    private override init() {
        super.init()
        loadFromKeychain()
    }

    func refreshCredentialState() async {
        guard let userID else {
            credentialState = .notFound
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let remote = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ASAuthorizationAppleIDProvider.CredentialState, Error>) in
                provider.getCredentialState(forUserID: userID) { state, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: state)
                    }
                }
            }
            switch remote {
            case .authorized, .transferred:
                credentialState = remote
                UserDefaults.standard.removeObject(forKey: revokedMarkerKey)
                lastErrorMessage = nil
            case .revoked, .notFound:
                // A confirmed negative response is not a transient network error.
                // Keep the local identity for deliberate reauthentication/recovery,
                // but never promote a revoked credential to an authorized session.
                credentialState = remote
                UserDefaults.standard.set(true, forKey: revokedMarkerKey)
                lastErrorMessage = "La autorización de Apple debe verificarse de nuevo."
                AuthSessionTrace.event("credentialState invalid; reauthentication required")
            @unknown default:
                credentialState = .notFound
                lastErrorMessage = "Estado de autorización Apple no reconocido."
            }
        } catch {
            // A temporary network error must not clear a previously confirmed revocation.
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Valida sesión existente; si falta o está revocada, el onboarding debe forzar login.
    func ensureValidSession() async -> Bool {
        if userID == nil {
            loadFromKeychain()
        }
        AuthSessionTrace.event(
            "ensureValidSession after load userID=\(userID != nil) state=\(String(describing: credentialState))"
        )
        await refreshCredentialState()
        AuthSessionTrace.event(
            "ensureValidSession result signedIn=\(isSignedIn) state=\(String(describing: credentialState))"
        )
        return isSignedIn
    }

    func signIn() async throws {
        isSigningIn = true
        lastErrorMessage = nil
        defer { isSigningIn = false }

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let rawNonce = BusinessAuthStore.makeNonce()
        request.nonce = BusinessAuthStore.hashedNonce(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        let authorization = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ASAuthorization, Error>) in
            self.continuityContinuation = cont
            controller.performRequests()
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleAuthError.invalidCredential
        }
        // An existing local Apple identity must not be silently replaced by
        // another Apple account while private workouts remain on the device.
        let isFirstAccount = userID == nil
        if let existingID = userID, existingID != credential.user {
            throw AppleAuthError.accountMismatch
        }
        apply(credential: credential)
        // Entrada a la app = Apple ID token → sesión Supabase. Los datos siguen
        // en local/iCloud y se sincronizan con Supabase; sin sesión remota no hay acceso.
        let connected = await BusinessAuthStore.shared.connect(
            credential: credential,
            rawNonce: rawNonce
        )
        if !connected {
            let reason = BusinessAuthStore.shared.lastErrorMessage
                ?? "No se pudo conectar con el servidor."
            lastErrorMessage = reason
            throw AppleAuthError.businessConnectionFailed(reason)
        }
        ReperaAnalytics.track(isFirstAccount ? .signUp : .login, parameters: [
            "feature_area": "account",
            "entry_point": "apple",
            "result": "success"
        ])
    }

    /// Aplica el credential ya obtenido por `SignInWithAppleButton`.
    func signInWithCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        isSigningIn = true
        lastErrorMessage = nil
        defer { isSigningIn = false }
        if let existingID = userID, existingID != credential.user {
            throw AppleAuthError.accountMismatch
        }
        apply(credential: credential)
        guard userID != nil else { throw AppleAuthError.invalidCredential }
        ReperaAnalytics.track(.login, parameters: [
            "feature_area": "account",
            "entry_point": "apple_button",
            "result": "success"
        ])
    }

    func signOut() {
        clearSession(keepKeychain: false)
        UserDefaults.standard.removeObject(forKey: revokedMarkerKey)
        credentialState = .notFound
    }

    private func apply(credential: ASAuthorizationAppleIDCredential) {
        userID = credential.user
        if let fullName = credential.fullName {
            let formatted = PersonNameComponentsFormatter().string(from: fullName)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty {
                displayName = formatted
            }
        }
        if let mail = credential.email, !mail.isEmpty {
            email = mail
        }
        credentialState = .authorized
        UserDefaults.standard.removeObject(forKey: revokedMarkerKey)
        persistIdentity()
    }

    private func clearSession(keepKeychain: Bool) {
        userID = nil
        displayName = nil
        email = nil
        if !keepKeychain {
            deleteKeychain()
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: legacyDefaultsUserIDKey)
            defaults.removeObject(forKey: legacyDefaultsNameKey)
            defaults.removeObject(forKey: legacyDefaultsEmailKey)
            defaults.removeObject(forKey: Self.ownerScopeDefaultsKey)
        }
    }

    private func loadFromKeychain() {
        userID = readKeychain(account: userIDKey)
        displayName = readKeychain(account: nameKey)
        email = readKeychain(account: emailKey)
        migrateLegacyDefaultsIdentity()
        let defaults = UserDefaults.standard
        if let userID {
            defaults.set(Self.ownerScope(forUserID: userID), forKey: Self.ownerScopeDefaultsKey)
        }
        // Restaurar UI/gates al arrancar sin esperar a getCredentialState.
        if userID != nil && !defaults.bool(forKey: revokedMarkerKey) {
            credentialState = .authorized
        } else {
            credentialState = .notFound
        }
    }

    /// Older builds mirrored the identity in plaintext UserDefaults. Fill any
    /// Keychain gaps from it, and delete each mirror only once Keychain holds it
    /// (a locked device keeps the mirror for the next launch).
    private func migrateLegacyDefaultsIdentity() {
        let defaults = UserDefaults.standard
        let legacyUserID = defaults.string(forKey: legacyDefaultsUserIDKey)
        let legacy: [(key: String, account: String)] = [
            (legacyDefaultsUserIDKey, userIDKey),
            (legacyDefaultsNameKey, nameKey),
            (legacyDefaultsEmailKey, emailKey),
        ]
        for item in legacy {
            guard let value = defaults.string(forKey: item.key) else { continue }
            if value.isEmpty {
                defaults.removeObject(forKey: item.key)
                continue
            }
            // Never attach a mirrored name/email to a different Keychain identity.
            let belongsToOtherIdentity = item.account != userIDKey && userID != nil
                && legacyUserID.map { $0 != userID } == true
            if !belongsToOtherIdentity, readKeychain(account: item.account) == nil {
                guard writeKeychain(account: item.account, value: value) else { continue }
            }
            defaults.removeObject(forKey: item.key)
        }
        if userID == nil, let restored = readKeychain(account: userIDKey) {
            userID = restored
            displayName = displayName ?? readKeychain(account: nameKey)
            email = email ?? readKeychain(account: emailKey)
            AuthSessionTrace.event("loadFromKeychain migrated identity from legacy defaults")
        }
    }

    private func persistIdentity() {
        if let userID { writeKeychain(account: userIDKey, value: userID) }
        if let displayName { writeKeychain(account: nameKey, value: displayName) }
        if let email { writeKeychain(account: emailKey, value: email) }
        if let userID {
            UserDefaults.standard.set(Self.ownerScope(forUserID: userID), forKey: Self.ownerScopeDefaultsKey)
        }
    }

    @discardableResult
    private func writeKeychain(account: String, value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        // Survives app updates; readable after first unlock (cold start OK).
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            lastErrorMessage = "No se pudo guardar la sesión Apple (\(status))."
            return false
        }
        return true
    }

    private func readKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        // Antes se usaba AfterFirstUnlock (sin ThisDeviceOnly): intentar leer legacy.
        if status == errSecItemNotFound {
            return nil
        }
        // Dispositivo aún bloqueado u otro error temporal: no borrar Keychain.
        return nil
    }

    private func deleteKeychain() {
        for account in [userIDKey, nameKey, emailKey] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: account,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}

enum AppleAuthError: LocalizedError, Equatable {
    case invalidCredential
    case cancelled
    case accountMismatch
    case businessConnectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "No se pudo completar el inicio de sesión con Apple."
        case .cancelled: return "Inicio de sesión cancelado."
        case .accountMismatch: return "Esta cuenta Apple es distinta de la que tiene los entrenamientos locales. Usa la cuenta anterior para evitar mezclar historiales."
        case .businessConnectionFailed(let reason): return reason
        }
    }
}

extension AppleAuthStore: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            continuityContinuation?.resume(returning: authorization)
            continuityContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            let ns = error as NSError
            if ns.domain == ASAuthorizationError.errorDomain,
               ns.code == ASAuthorizationError.canceled.rawValue {
                continuityContinuation?.resume(throwing: AppleAuthError.cancelled)
            } else {
                lastErrorMessage = error.localizedDescription
                continuityContinuation?.resume(throwing: error)
            }
            continuityContinuation = nil
        }
    }
}

extension AppleAuthStore: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let key = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
                return key
            }
            if let any = scenes.flatMap(\.windows).first {
                return any
            }
            // SIWA solo se presenta con una Scene activa; crear ventana ligada a ella.
            let scene = scenes.first
                ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            if let scene {
                return UIWindow(windowScene: scene)
            }
            // Sin Scene no hay UI que presentar; degradar con la primera window disponible del proceso.
            preconditionFailure("Sign in with Apple requires an active UIWindowScene")
        }
    }
}
