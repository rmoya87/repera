import AuthenticationServices
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

    private let keychainService = "com.app.repera.appleauth"
    private let userIDKey = "userID"
    private let nameKey = "displayName"
    private let emailKey = "email"
    /// Espejo durable: `getCredentialState(.revoked)` en sim/device a veces borraba Keychain
    /// y dejaba Supabase vivo → Bienvenido eterno. UserDefaults sobrevive ese wipe.
    private let defaultsUserIDKey = "repera.apple.userID.v1"
    private let defaultsNameKey = "repera.apple.displayName.v1"
    private let defaultsEmailKey = "repera.apple.email.v1"

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
            case .revoked:
                // NUNCA borrar Keychain/UserDefaults aquí. En Simulator (y a veces tras
                // update) Apple reporta revoked de forma espuria; borrar forzaba login
                // aunque Supabase/binding siguieran vivos.
                credentialState = .authorized
                lastErrorMessage = nil
                AuthSessionTrace.event("credentialState revoked→keep identity (no wipe)")
            case .notFound:
                // Conservar identidad: tras update/reinstall parcial Apple a veces
                // responde notFound aunque el usuario siga vinculado.
                credentialState = .authorized
                lastErrorMessage = nil
            @unknown default:
                credentialState = .authorized
            }
        } catch {
            // Error de red / temporal: no borrar la sesión local.
            lastErrorMessage = error.localizedDescription
            if credentialState != .authorized && credentialState != .transferred {
                credentialState = .authorized
            }
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
        // Optimista: con userID local ya somos "signed in" mientras Apple responde.
        if userID != nil,
           credentialState != .authorized,
           credentialState != .transferred {
            credentialState = .authorized
        }
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
        persistIdentity()
    }

    private func clearSession(keepKeychain: Bool) {
        userID = nil
        displayName = nil
        email = nil
        if !keepKeychain {
            deleteKeychain()
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: defaultsUserIDKey)
            defaults.removeObject(forKey: defaultsNameKey)
            defaults.removeObject(forKey: defaultsEmailKey)
        }
    }

    private func loadFromKeychain() {
        userID = readKeychain(account: userIDKey)
        displayName = readKeychain(account: nameKey)
        email = readKeychain(account: emailKey)
        // Fallback si Keychain se vació (revoked wipe histórico / flaky sim).
        let defaults = UserDefaults.standard
        if userID == nil, let backup = defaults.string(forKey: defaultsUserIDKey), !backup.isEmpty {
            userID = backup
            displayName = displayName ?? defaults.string(forKey: defaultsNameKey)
            email = email ?? defaults.string(forKey: defaultsEmailKey)
            persistToKeychainOnly()
            AuthSessionTrace.event("loadFromKeychain restored userID from UserDefaults backup")
        }
        // Restaurar UI/gates al arrancar sin esperar a getCredentialState.
        if userID != nil {
            credentialState = .authorized
        }
    }

    private func persistIdentity() {
        persistToKeychainOnly()
        let defaults = UserDefaults.standard
        if let userID { defaults.set(userID, forKey: defaultsUserIDKey) }
        if let displayName { defaults.set(displayName, forKey: defaultsNameKey) }
        if let email { defaults.set(email, forKey: defaultsEmailKey) }
    }

    private func persistToKeychainOnly() {
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
        // Survives app updates; readable after first unlock (cold start OK).
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            lastErrorMessage = "No se pudo guardar la sesión Apple (\(status))."
        }
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
