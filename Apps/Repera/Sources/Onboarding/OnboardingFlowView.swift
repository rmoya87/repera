import ReperaDomain
import SwiftUI
import UIKit
import UserNotifications

struct OnboardingFlowView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(HealthKitStore.self) private var health
    @Environment(AppleAuthStore.self) private var appleAuth
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(WorkoutLocationTracker.self) private var location

    var body: some View {
        Group {
            switch onboarding.step {
            case .appleSignIn:
                OnboardingSignInStep()
            case .choosePlan:
                OnboardingPlanStep()
            case .permissions:
                OnboardingPermissionsStep()
            case .done:
                // Si aún no hay tabs (falta Supabase), volver al login — nunca un spinner eterno.
                OnboardingSignInStep()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OG.bg.ignoresSafeArea())
        .task {
            let appleOK = await appleAuth.ensureValidSession()
            let business = BusinessAuthStore.shared
            if appleOK && !business.isConnected {
                await business.restoreSession()
                if !business.isConnected {
                    _ = business.connectFromCachedSessionIfPossible()
                }
            }
            // Misma regla que ReperaApp: cache o binding previo cuentan (no solo isConnected).
            let businessOK = business.isConnected
                || business.hasCachedSupabaseSession
                || business.hasPriorSupabaseBinding
            let ok = businessOK && (appleOK || business.isGoogleSignedIn)
            AuthSessionTrace.event(
                "onboardingFlow reconcile ok=\(ok) apple=\(appleOK) connected=\(business.isConnected) cache=\(business.hasCachedSupabaseSession) binding=\(business.hasPriorSupabaseBinding)"
            )
            onboarding.reconcile(isSignedIn: ok)
            if appleOK {
                await store.refreshFromiCloud(isInitial: true)
            }
        }
    }
}

// MARK: - Sign in

private struct OnboardingSignInStep: View {
    @Environment(ReperaStore.self) private var store
    @Environment(AppleAuthStore.self) private var appleAuth
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var signingInWith: SignInProvider?
    @State private var errorText: String?

    private enum SignInProvider {
        case apple, google
    }

    private var busy: Bool { signingInWith != nil }
    private let signInButtonHeight: CGFloat = 52
    private let signInIconSize: CGFloat = 20

    /// Día: botón negro / texto blanco. Noche: botón blanco / texto negro (HIG Apple SIWA).
    private var appleButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var appleButtonForeground: Color {
        colorScheme == .dark ? .black : .white
    }

    private var googleButtonBackground: Color {
        colorScheme == .dark
            ? Color(red: 19 / 255, green: 19 / 255, blue: 20 / 255)
            : .white
    }

    private var googleButtonForeground: Color {
        colorScheme == .dark
            ? Color(red: 227 / 255, green: 227 / 255, blue: 227 / 255)
            : Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255)
    }

    private var googleButtonBorder: Color {
        colorScheme == .dark
            ? Color(red: 142 / 255, green: 145 / 255, blue: 143 / 255)
            : Color(red: 116 / 255, green: 119 / 255, blue: 117 / 255)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                welcomeContent
                    .frame(maxWidth: 480)
                    .frame(minHeight: max(0, geometry.size.height - 48))
                    .padding(.horizontal, OG.pad)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            let business = BusinessAuthStore.shared
            let businessOK = business.isConnected
                || business.hasCachedSupabaseSession
                || business.hasPriorSupabaseBinding
            if (appleAuth.isSignedIn || business.isGoogleSignedIn) && businessOK {
                onboarding.reconcile(isSignedIn: true)
            }
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            ReperaMascot(pose: .welcome, maxHeight: verticalSizeClass == .compact ? 120 : 220)
            VStack(spacing: 10) {
                Text("Bienvenido a Repera")
                    .font(.largeTitle.bold())
                    .foregroundStyle(OG.label)
                    .multilineTextAlignment(.center)
                Text("Todo tu entrenamiento. Cada vez mejor.")
                    .font(.headline)
                    .foregroundStyle(OG.label)
                    .multilineTextAlignment(.center)
                Text("Crea tus rutinas, escanea la pizarra y registra cada serie o WOD. Supera tus marcas, sigue tu actividad y recuperación, y entrena con tu Apple Watch y la ayuda de tu entrenador o tu IA favorita.")
                    .font(.body)
                    .foregroundStyle(OG.label2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.iCloudStatus == .signedOut {
                Label(
                    "iCloud no está activo en este iPhone. Podrás entrenar en local; actívalo en Ajustes del sistema para no perder datos.",
                    systemImage: "exclamationmark.icloud"
                )
                .font(.footnote)
                .foregroundStyle(OG.label2)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
            }

            Button {
                Task { await signInSpanish() }
            } label: {
                HStack(spacing: 10) {
                    if signingInWith == .apple {
                        ProgressView()
                            .tint(appleButtonForeground)
                            .frame(width: signInIconSize, height: signInIconSize)
                    } else {
                        Image(systemName: "apple.logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: signInIconSize, height: signInIconSize)
                            .accessibilityHidden(true)
                    }
                    Text("Iniciar sesión con Apple")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: signInButtonHeight)
                .foregroundStyle(appleButtonForeground)
                .background(appleButtonBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(busy)
            .accessibilityLabel("Iniciar sesión con Apple")

            VStack(spacing: 8) {
                // Presentation matches Apple; signInGoogle still calls Google's SDK.
                Button {
                    Task { await signInGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        Image("GoogleSignInLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: signInIconSize, height: signInIconSize)
                            .accessibilityHidden(true)
                        Text("Iniciar sesión con Google")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: signInButtonHeight)
                    .foregroundStyle(googleButtonForeground)
                    .background(googleButtonBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(googleButtonBorder, lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(busy)
                .accessibilityLabel("Iniciar sesión con Google")

                if signingInWith == .google {
                    ProgressView("Conectando con Google…")
                        .font(.footnote)
                        .tint(OG.label)
                        .foregroundStyle(OG.label2)
                }
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(OG.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    private func signInGoogle() async {
        guard !busy else { return }
        signingInWith = .google
        defer { signingInWith = nil }
        errorText = nil
        let auth = BusinessAuthStore.shared
        guard await auth.signInWithGoogle() else {
            // Closing Google's account picker is not an authentication error.
            errorText = auth.lastErrorMessage
            return
        }
        // Mismo flujo de permisos/planes que con Apple.
        // No se borra ni se reemplaza ningún entrenamiento local.
        onboarding.reconcile(isSignedIn: true)
        if onboarding.step == .appleSignIn {
            onboarding.advance(to: .permissions)
        }
    }

    private func signInSpanish() async {
        guard !busy else { return }
        signingInWith = .apple
        defer { signingInWith = nil }
        errorText = nil
        do {
            try await appleAuth.signIn()
            if let name = appleAuth.displayName,
               (store.state.settings.profileDisplayName ?? "").isEmpty {
                var s = store.state.settings
                s.profileDisplayName = name
                store.updateSettings(s)
            }
            await store.refreshFromiCloud(isInitial: true)
            // Existing Apple/iCloud members keep their local history, while
            // their public profile name is copied into their Supabase identity.
            await BusinessAuthStore.shared.syncPublicProfile(
                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                avatarJPEG: store.state.settings.profileAvatarJPEG
            )
            // Ya vio onboarding / precios → entrar; si no, permisos (se saltan si ya están OK).
            onboarding.reconcile(isSignedIn: BusinessAuthStore.shared.isConnected)
            if onboarding.step == .appleSignIn {
                onboarding.advance(to: .permissions)
            }
        } catch let error as AppleAuthError where error == .cancelled {
            return
        } catch {
            errorText = error.localizedDescription
        }
    }
}

// MARK: - Plan

private struct OnboardingPlanStep: View {
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(OnboardingStore.self) private var onboarding

    var body: some View {
        PaywallView(
            mode: .onboarding,
            onContinueFree: {
                onboarding.finishPrices()
            },
            onPurchaseSuccess: {
                onboarding.finishPrices()
            }
        )
        .environment(subscriptions)
        .task {
            // Asegura SDK + catálogo StoreKit/ASC antes de mostrar precios.
            await subscriptions.start()
            await subscriptions.loadOfferings()
        }
    }
}

// MARK: - Permissions

struct OnboardingPermissionsStep: View {
    @Environment(HealthKitStore.self) private var health
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(WorkoutLocationTracker.self) private var location
    @State private var recovery = HealthRecoveryStore.shared
    @Environment(\.openURL) private var openURL

    @State private var notificationsStatus: UNAuthorizationStatus = .notDetermined
    @State private var healthBusy = false
    @State private var requesting = false
    /// false hasta comprobar si ya están todos concedidos (evitar flash de la pantalla).
    @State private var showPermissionsUI = false

    var body: some View {
        Group {
            if showPermissionsUI {
                permissionsContent
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(OG.bg.ignoresSafeArea())
            }
        }
        .task {
            await refreshNotificationsStatus()
            location.refreshStatus()
            health.refreshAuthorizationStatus()
            if allPermissionsGranted {
                onboarding.finishPermissions()
                return
            }
            showPermissionsUI = true
        }
    }

    private var allPermissionsGranted: Bool {
        notificationsGranted && healthPermissionsComplete && location.isAuthorized
    }

    private var healthPermissionsComplete: Bool {
        health.isAuthorized
    }

    private var permissionsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer(minLength: 0)
                ReperaMascot(pose: .permissions, maxHeight: 140)
                Spacer(minLength: 0)
            }
            .padding(.top, 4)

            Text("Permisos")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(OG.label)
            Text("Puedes activar notificaciones, Apple Salud y ubicación si los necesitas. Al autorizar Apple Salud, eliges qué datos compartir, incluidos sueño y ciclo.")
                .font(.body)
                .foregroundStyle(OG.label2)

            permissionRow(
                title: "Notificaciones",
                subtitle: "Aviso cuando termina el descanso",
                symbol: "bell",
                statusText: notificationsLabel,
                isDone: notificationsGranted
            ) {
                await requestNotifications()
            }

            permissionRow(
                title: "Salud",
                subtitle: "Entrenos, sueño, ciclo y constantes",
                symbol: "heart",
                statusText: healthPermissionsComplete ? "Conectado" : "Pendiente",
                isDone: healthPermissionsComplete
            ) {
                healthBusy = true
                defer { healthBusy = false }
                await health.requestAccess(includeAllOptional: true)
            }

            permissionRow(
                title: "Ubicación",
                subtitle: "Pin del gym y ruta en entrenos outdoor",
                symbol: "location",
                statusText: locationLabel,
                isDone: location.isAuthorized
            ) {
                _ = await location.ensureWhenInUseAuthorized()
                location.refreshStatus()
            }

            Spacer(minLength: 8)

            Button {
                onboarding.finishPermissions()
            } label: {
                Text("Continuar")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(OG.onAccent)
                    .background(OG.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button("Abrir Ajustes del sistema") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.subheadline)
            .foregroundStyle(OG.label2)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 28)
    }

    private var notificationsGranted: Bool {
        switch notificationsStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private var notificationsLabel: String {
        if notificationsGranted { return "Permitidas" }
        switch notificationsStatus {
        case .denied: return "Denegadas"
        default: return "Pendiente"
        }
    }

    private var locationLabel: String {
        location.refreshStatus()
        if location.isAuthorized { return "Permitida" }
        switch location.authorizationStatus {
        case .denied, .restricted: return "Denegada"
        default: return "Pendiente"
        }
    }

    private func permissionRow(
        title: String,
        subtitle: String,
        symbol: String,
        statusText: String,
        isDone: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isDone ? OG.accent : OG.label2)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(OG.label)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isDone ? OG.accent : OG.label3)
            }
            Spacer(minLength: 0)
            if isDone {
                Text("Hecho")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.accent)
                    .accessibilityLabel("\(title): hecho")
            } else {
                Button("Permitir") {
                    Task {
                        requesting = true
                        defer { requesting = false }
                        await action()
                        await refreshNotificationsStatus()
                        location.refreshStatus()
                        health.refreshAuthorizationStatus()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.accent)
                .disabled(requesting || healthBusy)
            }
        }
        .padding(OG.pad)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        await refreshNotificationsStatus()
    }

    private func refreshNotificationsStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsStatus = settings.authorizationStatus
    }
}
