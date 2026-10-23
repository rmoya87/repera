import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import ReperaDomain
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
    /// UUID remoto estable: impide que una cuenta Google distinta abra los datos
    /// deportivos locales que antes pertenecían a otra identidad Apple.
    private let localOwnerUserIDKey = "repera.business.localOwnerSupabaseUserID.v1"
    /// Solo indica una sesión Google activa; se borra al cerrar sesión.
    private let googleSignedInKey = "repera.business.googleSignedIn.v1"
    private static let googleRedirectURL = URL(string: "repera://auth/callback")!

    var isGoogleSignedIn: Bool {
        UserDefaults.standard.bool(forKey: googleSignedInKey)
    }

    var accountEmail: String? { client?.auth.currentSession?.user.email }

    private var localOwnerID: String? {
        UserDefaults.standard.string(forKey: localOwnerUserIDKey)
    }

    private func isSameLocalOwner(_ remoteID: UUID) -> Bool {
        guard let localOwnerID else { return true }
        return localOwnerID == remoteID.uuidString.lowercased()
    }

    private func rememberOwner(_ remoteID: UUID) {
        UserDefaults.standard.set(remoteID.uuidString.lowercased(), forKey: localOwnerUserIDKey)
    }
    /// El usuario eligió no vincular Supabase ahora: no re-mostrar el muro de migración en cada arranque.
    private let continueLocalOnlyKey = "repera.business.continueLocalOnly.v1"
    private(set) var lastErrorMessage: String?
    private(set) var isConnecting = false

    /// Preferencia persistente: seguir solo con Apple/iCloud (sin forzar SIWA por Business).
    var prefersLocalOnly: Bool {
        UserDefaults.standard.bool(forKey: continueLocalOnlyKey)
    }

    func setPrefersLocalOnly(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: continueLocalOnlyKey)
        if value { isMigrationRequired = false }
    }

    @ObservationIgnored
    private let client: SupabaseClient?

    var apiClient: SupabaseClient? { client }

    /// Hay refresh/access token en Keychain del SDK (sobrevive updates). No hace falta SIWA.
    var hasCachedSupabaseSession: Bool {
        client?.auth.currentSession != nil
    }

    /// Login Supabase exitoso previo (UserDefaults). Sobrevive si el SDK borra el refresh
    /// tras un refresh fallido (`sessionCleanupErrorCodes`).
    var hasPriorSupabaseBinding: Bool {
        UserDefaults.standard.string(forKey: appleIdentityBindingKey) != nil
            || isGoogleSignedIn
    }

    private init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "ReperaSupabaseURL") as? String
        let key = Bundle.main.object(forInfoDictionaryKey: "ReperaSupabasePublishableKey") as? String
        if let urlString, let url = URL(string: urlString),
           url.scheme == "https", url.host == "uvzgujlrqohreoucirms.supabase.co",
           let key, key.hasPrefix("sb_publishable_") {
            // Sesión en Keychain (`supabase.gotrue.swift`); AfterFirstUnlock sobrevive updates.
            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key,
                options: SupabaseClientOptions(
                    auth: .init(
                        storage: KeychainLocalStorage(service: "supabase.gotrue.swift"),
                        autoRefreshToken: true,
                        emitLocalSessionAsInitialSession: true
                    )
                )
            )
        } else {
            client = nil
        }
    }

    /// Restaura sesión desde Keychain y renueva el access token si hace falta.
    /// Con cache local **no** exige SIWA (tampoco si el refresh de red falla una vez).
    /// Si el SDK ya no tiene tokens pero hay binding previo, no se fuerza re-login:
    /// la app entra y Business se reconecta desde Ajustes cuando haga falta.
    func restoreSession() async {
        hasRestoredSession = false
        defer { hasRestoredSession = true }
        AuthSessionTrace.event(
            "restoreSession start apple=\(AppleAuthStore.shared.isSignedIn) cache=\(hasCachedSupabaseSession) binding=\(hasPriorSupabaseBinding) connected=\(isConnected)"
        )
        guard let client else {
            isConnected = false
            isMigrationRequired = false
            lastErrorMessage = "Supabase Repera no está configurado en esta compilación."
            AuthSessionTrace.event("restoreSession abort: no client")
            return
        }
        let appleUserID = AppleAuthStore.shared.userID
        let appleOK = appleUserID != nil && AppleAuthStore.shared.isSignedIn
        if !appleOK {
            // No signOut. Si hay cache/binding, restaurar igual (Apple Keychain pudo
            // borrarse por .revoked espurio; trazas: cache=true binding=true userID=false).
            AuthSessionTrace.event(
                "restoreSession soft: no Apple local cache=\(hasCachedSupabaseSession) binding=\(hasPriorSupabaseBinding)"
            )
            if let cached = client.auth.currentSession {
                // Una sesión de otra cuenta no debe exponer datos locales.
                guard isSameLocalOwner(cached.user.id) else {
                    isConnected = false
                    lastErrorMessage = "Esta cuenta es diferente de la vinculada al historial local."
                    return
                }
                rememberOwner(cached.user.id)
                AuthSessionTrace.event(
                    "restoreSession HIT cache without Apple expired=\(cached.isExpired) user=\(cached.user.id)"
                )
                acceptCachedSessionKeepingExistingBinding()
                await refreshAccessTokenBestEffort(client: client)
                AuthSessionTrace.event(
                    "restoreSession done via cache-no-apple connected=\(isConnected)"
                )
                return
            }
            if hasPriorSupabaseBinding {
                markNeedsSoftReconnect(keepBinding: true)
                AuthSessionTrace.event("restoreSession no Apple no cache; keep binding")
                return
            }
            isConnected = false
            isMigrationRequired = false
            BusinessDataStore.shared.clear()
            AuthSessionTrace.event("restoreSession abort: no Apple and no remote")
            return
        }
        let expectedBinding = Self.hashedNonce(appleUserID!)

        // 1) Cache Keychain (rápido, offline, tras update). Preferir currentSession
        // y NO llamar auth.session si hay cache: ese path hace refresh y el SDK
        // puede borrar Keychain ante ciertos errores de sesión.
        if let cached = client.auth.currentSession {
            AuthSessionTrace.event(
                "restoreSession HIT cache expired=\(cached.isExpired) user=\(cached.user.id)"
            )
            acceptCachedSession(expectedBinding: expectedBinding)
            await refreshAccessTokenBestEffort(client: client)
            AuthSessionTrace.event(
                "restoreSession done via cache connected=\(isConnected) cacheNow=\(hasCachedSupabaseSession)"
            )
            return
        }

        // 2) Intentar hidratar desde storage (sin haber visto currentSession aún).
        do {
            let session = try await client.auth.session
            guard !session.accessToken.isEmpty else {
                markNeedsSoftReconnect(keepBinding: hasPriorSupabaseBinding)
                AuthSessionTrace.event("restoreSession empty accessToken binding=\(hasPriorSupabaseBinding)")
                return
            }
            AuthSessionTrace.event("restoreSession via auth.session expired=\(session.isExpired)")
            acceptCachedSession(expectedBinding: expectedBinding)
            if session.isExpired {
                await refreshAccessTokenBestEffort(client: client)
            }
            AuthSessionTrace.event("restoreSession done via session connected=\(isConnected)")
        } catch {
            if client.auth.currentSession != nil {
                acceptCachedSession(expectedBinding: expectedBinding)
                AuthSessionTrace.event("restoreSession recover cache after error: \(error.localizedDescription)")
                return
            }
            // Binding previo: no pedir Bienvenido; tokens los limpió el SDK.
            markNeedsSoftReconnect(keepBinding: hasPriorSupabaseBinding)
            lastErrorMessage = hasPriorSupabaseBinding
                ? "Sesión remota caducada. Entra a la app; reconecta en Ajustes si hace falta."
                : "No se pudo restaurar la sesión. Vuelve a iniciar sesión con Apple."
            AuthSessionTrace.event(
                "restoreSession MISS binding=\(hasPriorSupabaseBinding): \(error.localizedDescription)"
            )
        }
    }

    /// Acepta la sesión ya en Keychain sin UI (p. ej. tras timeout de red).
    @discardableResult
    func connectFromCachedSessionIfPossible() -> Bool {
        guard let appleUserID = AppleAuthStore.shared.userID,
              AppleAuthStore.shared.isSignedIn,
              client?.auth.currentSession != nil
        else {
            AuthSessionTrace.event("connectFromCache failed apple/cache missing")
            return false
        }
        acceptCachedSession(expectedBinding: Self.hashedNonce(appleUserID))
        AuthSessionTrace.event("connectFromCache OK")
        return true
    }

    private func acceptCachedSession(expectedBinding: String) {
        UserDefaults.standard.set(expectedBinding, forKey: appleIdentityBindingKey)
        if let session = client?.auth.currentSession {
            rememberOwner(session.user.id)
        }
        UserDefaults.standard.set(false, forKey: googleSignedInKey)
        isConnected = true
        isMigrationRequired = false
        setPrefersLocalOnly(false)
        lastErrorMessage = nil
        AuthSessionTrace.event("acceptCachedSession binding saved")
    }

    /// Restaura `isConnected` sin reescribir binding (Apple local ausente).
    private func acceptCachedSessionKeepingExistingBinding() {
        isConnected = true
        isMigrationRequired = false
        setPrefersLocalOnly(false)
        lastErrorMessage = nil
        AuthSessionTrace.event("acceptCachedSession keep existing binding=\(hasPriorSupabaseBinding)")
    }

    /// Sin tokens vivos: Business offline. Si `keepBinding`, la app sigue entrando.
    private func markNeedsSoftReconnect(keepBinding: Bool) {
        isConnected = false
        isMigrationRequired = true
        BusinessDataStore.shared.clear()
        if !keepBinding {
            UserDefaults.standard.removeObject(forKey: appleIdentityBindingKey)
        }
        AuthSessionTrace.event("softReconnect keepBinding=\(keepBinding)")
    }

    private func refreshAccessTokenBestEffort(client: SupabaseClient) async {
        guard let cached = client.auth.currentSession, cached.isExpired else {
            AuthSessionTrace.event("refresh skip (not expired or nil)")
            return
        }
        // Snapshot: si el SDK borra tras error de cleanup, al menos ya tenemos binding.
        let binding = UserDefaults.standard.string(forKey: appleIdentityBindingKey)
        do {
            _ = try await client.auth.refreshSession()
            AuthSessionTrace.event("refresh OK cacheNow=\(client.auth.currentSession != nil)")
        } catch {
            AuthSessionTrace.event(
                "refresh FAIL cacheNow=\(client.auth.currentSession != nil) binding=\(binding != nil): \(error.localizedDescription)"
            )
            // Mantener isConnected si aún hay cache; si el SDK limpió, soft reconnect.
            if client.auth.currentSession == nil {
                isConnected = false
                isMigrationRequired = true
                BusinessDataStore.shared.clear()
            }
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
        let expectedBinding = Self.hashedNonce(credential.user)
        let storedBinding = UserDefaults.standard.string(forKey: appleIdentityBindingKey)
        // Solo signOut si cambia la cuenta Apple. Si binding==nil, NO borrar Keychain
        // (antes se destruía el refresh token en cada re-SIWA / update).
        let wipe = AuthSessionLaunchPolicy.shouldSignOutBeforeConnect(
            storedBinding: storedBinding,
            expectedBinding: expectedBinding
        )
        AuthSessionTrace.event(
            "connect start wipe=\(wipe) hadCache=\(hasCachedSupabaseSession) storedBinding=\(storedBinding != nil)"
        )
        if wipe {
            try? await client.auth.signOut()
        }
        BusinessDataStore.shared.clear()
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
            guard isSameLocalOwner(session.user.id) else {
                throw AccountMigrationError.identityChanged
            }
            rememberOwner(session.user.id)
            UserDefaults.standard.set(false, forKey: googleSignedInKey)
            UserDefaults.standard.set(expectedBinding, forKey: appleIdentityBindingKey)
            isConnected = true
            isMigrationRequired = false
            setPrefersLocalOnly(false)
            hasRestoredSession = true
            lastErrorMessage = nil
            AuthSessionTrace.event("connect OK user=\(session.user.id) cacheNow=\(hasCachedSupabaseSession)")
            await BusinessDataStore.shared.refresh()
            return true
        } catch {
            // Si el id_token falla pero sigue habiendo sesión cacheada, no dejar al usuario fuera.
            if connectFromCachedSessionIfPossible() {
                AuthSessionTrace.event("connect failed but kept cache: \(error.localizedDescription)")
                return true
            }
            isConnected = false
            isMigrationRequired = true
            BusinessDataStore.shared.clear()
            lastErrorMessage = "No se ha podido conectar con Supabase: \(error.localizedDescription)"
            AuthSessionTrace.event("connect FAIL: \(error.localizedDescription)")
            return false
        }
    }

    /// OAuth con Google usa ASWebAuthenticationSession del SDK Supabase, con
    /// retorno protegido por la URL registrada en iOS y en Auth Redirect URLs.
    /// Supabase vincula identidades automáticamente solo con email verificado.
    /// La prueba definitiva de que es la misma persona es el UUID Supabase.
    @discardableResult
    func signInWithGoogle() async -> Bool {
        guard let client else {
            lastErrorMessage = "Supabase Repera no está configurado."
            return false
        }
        guard !isConnecting else { return false }
        isConnecting = true
        defer { isConnecting = false }
        lastErrorMessage = nil

        // No se borra el historial local, ni el propietario anterior.
        do {
            let session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: Self.googleRedirectURL
            )
            guard isSameLocalOwner(session.user.id) else {
                // Correo distinto/no verificado, Apple «Ocultar mi correo»,
                // o cuentas realmente diferentes: NUNCA fusionar datos.
                try? await client.auth.signOut()
                isConnected = false
                lastErrorMessage = "Google corresponde a otra cuenta. Entra con Apple y vincula Google desde Cuenta para usar tu historial."
                return false
            }
            rememberOwner(session.user.id)
            UserDefaults.standard.set(true, forKey: googleSignedInKey)
            UserDefaults.standard.removeObject(forKey: appleIdentityBindingKey)
            isConnected = true
            isMigrationRequired = false
            hasRestoredSession = true
            setPrefersLocalOnly(false)
            lastErrorMessage = nil
            await BusinessDataStore.shared.refresh()
            return true
        } catch {
            lastErrorMessage = "No se pudo iniciar sesión con Google: \(error.localizedDescription)"
            // No afirmar éxito ni aceptar una sesión de identidad desconocida.
            return false
        }
    }

    /// Vinculación iniciada DESDE una cuenta Apple ya autenticada. Es la vía
    /// segura si Apple devuelve una dirección privada diferente de Google.
    /// Requiere habilitar Manual Linking en Supabase Auth.
    @discardableResult
    func linkGoogleToCurrentAccount() async -> Bool {
        guard let client, isConnected, !isConnecting,
              let currentID = client.auth.currentSession?.user.id,
              isSameLocalOwner(currentID) else {
            lastErrorMessage = "Inicia sesión con Apple antes de vincular Google."
            return false
        }
        isConnecting = true
        defer { isConnecting = false }
        lastErrorMessage = nil
        do {
            try await client.auth.linkIdentity(
                provider: .google,
                redirectTo: Self.googleRedirectURL
            )
            guard client.auth.currentSession?.user.id == currentID else {
                lastErrorMessage = "No se ha podido comprobar la misma cuenta. No se han combinado datos."
                return false
            }
            rememberOwner(currentID)
            return true
        } catch {
            lastErrorMessage = "No se pudo vincular Google. Comprueba que esté habilitada la vinculación manual en Supabase."
            return false
        }
    }

    /// Empuja nombre y avatar públicos a Supabase (fuente de verdad = Ajustes local).
    /// No envía entrenamientos, Salud ni StoreKit. Idempotente; reintenta en el próximo arranque si falla.
    func migrateLocalProfileIfNeeded(displayName: String?, avatarJPEG: Data? = nil) async {
        await syncPublicProfile(displayName: displayName, avatarJPEG: avatarJPEG)
    }

    /// Edición desde Ajustes: alinea `profiles.display_name` + `avatar_url` (y el JPEG en Storage).
    func updateDisplayName(_ value: String?, avatarJPEG: Data? = nil) async {
        await syncPublicProfile(displayName: value, avatarJPEG: avatarJPEG)
    }

    /// Sube `display_name` y, si hay JPEG, el avatar a Storage (`profile-avatars/{uid}/avatar.jpg`).
    /// Usa `currentSession` + refresh best-effort: evita `auth.session` que puede
    /// borrar Keychain si el refresh falla con códigos de cleanup.
    func syncPublicProfile(displayName: String?, avatarJPEG: Data?) async {
        guard isConnected, let client else { return }
        do {
            if let cached = client.auth.currentSession, cached.isExpired {
                await refreshAccessTokenBestEffort(client: client)
            }
            guard let session = client.auth.currentSession,
                  !session.accessToken.isEmpty,
                  isSameLocalOwner(session.user.id),
                  (isGoogleSignedIn || (
                    AppleAuthStore.shared.userID.map { Self.hashedNonce($0) }
                        == UserDefaults.standard.string(forKey: appleIdentityBindingKey)
                  ))
            else {
                AuthSessionTrace.event("syncPublicProfile skip: no usable session")
                return
            }
            if session.isExpired {
                AuthSessionTrace.event("syncPublicProfile skip: still expired after refresh")
                return
            }

            let userID = session.user.id.uuidString.lowercased()
            let name = String((displayName ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(100))
            let storagePath = "\(userID)/avatar.jpg"
            var avatarURL: String?

            if let jpeg = avatarJPEG, !jpeg.isEmpty {
                guard jpeg.count <= 2_097_152 else {
                    throw ProfileSyncError.photoTooLarge
                }
                _ = try await client.storage
                    .from("profile-avatars")
                    .upload(
                        storagePath,
                        data: jpeg,
                        options: FileOptions(
                            cacheControl: "3600",
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )
                let publicURL = try client.storage
                    .from("profile-avatars")
                    .getPublicURL(path: storagePath)
                // Cache-bust para que Inicio/consola vean el JPEG nuevo al instante.
                avatarURL = publicURL.absoluteString + "?v=\(Int(Date().timeIntervalSince1970))"
            } else {
                _ = try? await client.storage
                    .from("profile-avatars")
                    .remove(paths: [storagePath])
                avatarURL = nil
            }

            try await client.from("profiles")
                .update(ProfilePublicPatch(displayName: name, avatarURL: avatarURL))
                .eq("id", value: userID)
                .execute()

            guard isConnected,
                  AppleAuthStore.shared.userID == appleUserID,
                  client.auth.currentSession?.user.id == session.user.id else { return }
            profileMigrationErrorMessage = nil
            AuthSessionTrace.event("syncPublicProfile OK")
        } catch {
            profileMigrationErrorMessage =
                "El nombre o la foto no se han sincronizado. Tus datos locales siguen guardados. Reintenta desde Cuenta."
            AuthSessionTrace.event("syncPublicProfile FAIL: \(error.localizedDescription)")
        }
    }
    private enum ProfileSyncError: LocalizedError {
        case photoTooLarge
        var errorDescription: String? {
            "La foto de perfil debe ocupar como máximo 2 MB."
        }
    }
    private struct ProfilePublicPatch: Encodable {
        let displayName: String
        let avatarURL: String?
        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case avatarURL = "avatar_url"
        }
        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: CodingKeys.self)
            try values.encode(displayName, forKey: .displayName)
            // A removed avatar MUST be encoded as SQL NULL, not omitted
            // by Optional's default synthesized encodeIfPresent.
            if let avatarURL {
                try values.encode(avatarURL, forKey: .avatarURL)
            } else {
                try values.encodeNil(forKey: .avatarURL)
            }
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
        // Conservar SOLO el UUID propietario para evitar mezcla al cambiar de
        // Apple a Google. La sesión/tokens sí se revocan.
        if let uid = client?.auth.currentSession?.user.id {
            rememberOwner(uid)
        }
        UserDefaults.standard.set(false, forKey: googleSignedInKey)
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
