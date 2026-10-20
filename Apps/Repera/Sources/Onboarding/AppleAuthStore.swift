import AuthenticationServices
import Foundation
import Observation
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

    private let keychainService = "com.app.repera.appleauth"
    private let userIDKey = "userID"
    private let nameKey = "displayName"
    private let emailKey = "email"

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
            credentialState = try await withCheckedThrowingContinuation { cont in
                provider.getCredentialState(forUserID: userID) { state, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: state)
                    }
                }
            }
        } catch {
            // Error de red / temporal: no borrar la sesión local.
            lastErrorMessage = error.localizedDescription
            if credentialState != .authorized && credentialState != .transferred {
                credentialState = .authorized
            }
            return
        }
        if credentialState == .revoked || credentialState == .notFound {
            clearSession(keepKeychain: false)
        }
    }

    /// Valida sesión existente; si falta o está revocada, el onboarding debe forzar login.
    func ensureValidSession() async -> Bool {
        if userID == nil {
            loadFromKeychain()
        }
        await refreshCredentialState()
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
        if let existingID = userID, existingID != credential.user {
            throw AppleAuthError.accountMismatch
        }
        apply(credential: credential)
        guard await BusinessAuthStore.shared.connect(credential: credential, rawNonce: rawNonce) else {
            throw AppleAuthError.businessConnectionFailed(
                BusinessAuthStore.shared.lastErrorMessage ?? "No se pudo iniciar sesión en Supabase."
            )
        }
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
    }

    func signOut() {
        clearSession(keepKeychain: false)
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
        persistToKeychain()
    }

    private func clearSession(keepKeychain: Bool) {
        userID = nil
        displayName = nil
        email = nil
        if !keepKeychain {
            deleteKeychain()
        }
    }

    private func loadFromKeychain() {
        userID = readKeychain(account: userIDKey)
        displayName = readKeychain(account: nameKey)
        email = readKeychain(account: emailKey)
    }

    private func persistToKeychain() {
        if let userID { writeKeychain(account: userIDKey, value: userID) }
        if let displayName { writeKeychain(account: nameKey, value: displayName) }
        if let email { writeKeychain(account: emailKey, value: email) }
    }

    private func writeKeychain(account: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
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
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
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
