import Foundation

/// Decisión de arranque tras leer Apple Keychain + sesión Supabase cacheada.
public enum AuthSessionLaunchDecision: Equatable, Sendable {
    /// Entrar a la app (sesión remota viva, cache o binding previo tras login exitoso).
    case enterApp
    /// Mostrar login Bienvenido (nunca hubo Supabase, o Apple/onboarding incompletos).
    case showLogin
}

public struct AuthSessionLaunchInput: Equatable, Sendable {
    public var appleSignedIn: Bool
    public var hasCachedSupabaseSession: Bool
    public var isConnected: Bool
    /// Hubo un login Supabase exitoso (UserDefaults). Sobrevive si el SDK borra el refresh.
    public var hasPriorSupabaseBinding: Bool
    public var onboardingFinished: Bool

    public init(
        appleSignedIn: Bool,
        hasCachedSupabaseSession: Bool,
        isConnected: Bool,
        hasPriorSupabaseBinding: Bool,
        onboardingFinished: Bool
    ) {
        self.appleSignedIn = appleSignedIn
        self.hasCachedSupabaseSession = hasCachedSupabaseSession
        self.isConnected = isConnected
        self.hasPriorSupabaseBinding = hasPriorSupabaseBinding
        self.onboardingFinished = onboardingFinished
    }
}

public enum AuthSessionLaunchPolicy: Sendable {
    /// Regla: onboarding + sesión remota (conectado | Keychain | binding).
    /// Apple en Keychain es lo normal; si se perdió (wipe por `.revoked` espurio) pero
    /// Supabase/binding siguen, **igual se entra** — no Bienvenido eterno.
    public static func decide(_ input: AuthSessionLaunchInput) -> AuthSessionLaunchDecision {
        guard input.onboardingFinished else { return .showLogin }
        let hasRemote = input.isConnected
            || input.hasCachedSupabaseSession
            || input.hasPriorSupabaseBinding
        guard hasRemote else { return .showLogin }
        // Primer acceso sin remoto → login. Con remoto (aunque falte Apple local) → app.
        return .enterApp
    }

    /// Solo borrar Keychain Supabase si cambia la cuenta Apple (binding distinto).
    /// Si no hay binding aún, **no** hacer signOut: destruiría el refresh token del update.
    public static func shouldSignOutBeforeConnect(
        storedBinding: String?,
        expectedBinding: String
    ) -> Bool {
        guard let storedBinding else { return false }
        return storedBinding != expectedBinding
    }

    /// SIWA automático en splash: solo si no hay cache ni binding previo.
    public static func shouldPresentInteractiveAppleSignIn(
        appleSignedIn: Bool,
        isConnected: Bool,
        hasCachedSupabaseSession: Bool,
        hasPriorSupabaseBinding: Bool
    ) -> Bool {
        appleSignedIn
            && !isConnected
            && !hasCachedSupabaseSession
            && !hasPriorSupabaseBinding
    }
}
