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
                OG.bg
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OG.bg.ignoresSafeArea())
        .task {
            _ = await appleAuth.ensureValidSession()
            onboarding.reconcile(isSignedIn: appleAuth.isSignedIn)
            if appleAuth.isSignedIn {
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
    @State private var busy = false
    @State private var errorText: String?

    /// Día: botón negro / texto blanco. Noche: botón blanco / texto negro (HIG Apple SIWA).
    private var appleButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var appleButtonForeground: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            ReperaMascot(pose: .welcome, maxHeight: 240)
            VStack(spacing: 10) {
                Text("Bienvenido a Repera")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(OG.label)
                    .multilineTextAlignment(.center)
                Text("Accede con Apple para empezar. Tu historial de entrenamientos sigue bajo tu control en el iPhone e iCloud.")
                    .font(.body)
                    .foregroundStyle(OG.label2)
                    .multilineTextAlignment(.center)
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
                    if busy {
                        ProgressView()
                            .tint(appleButtonForeground)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text("Iniciar sesión con Apple")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(appleButtonForeground)
                .background(appleButtonBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(busy)
            .accessibilityLabel("Iniciar sesión con Apple")

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(OG.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, OG.pad)
        .onAppear {
            // Si Keychain ya tiene sesión (p. ej. tras actualizar), no pedir SIWA otra vez.
            if appleAuth.isSignedIn {
                onboarding.reconcile(isSignedIn: true)
            }
        }
    }

    private func signInSpanish() async {
        busy = true
        defer { busy = false }
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
            await BusinessAuthStore.shared.migrateLocalProfileIfNeeded(
                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName
            )
            onboarding.advance(to: .permissions)
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
    @Environment(\.openURL) private var openURL

    @State private var notificationsStatus: UNAuthorizationStatus = .notDetermined
    @State private var healthBusy = false
    @State private var requesting = false

    var body: some View {
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
            Text("Actívalos ahora para avisos de descanso, calorías reales y el mapa de dónde entrenaste. Puedes cambiarlos después en Ajustes.")
                .font(.body)
                .foregroundStyle(OG.label2)

            permissionRow(
                title: "Notificaciones",
                subtitle: "Aviso cuando termina el descanso",
                symbol: "bell.fill",
                statusText: notificationsLabel,
                isDone: notificationsGranted
            ) {
                await requestNotifications()
            }

            permissionRow(
                title: "Apple Salud",
                subtitle: "Calorías, tiempo y entrenos del Watch",
                symbol: "heart.fill",
                statusText: health.isAuthorized ? "Conectado" : "Pendiente",
                isDone: health.isAuthorized
            ) {
                healthBusy = true
                defer { healthBusy = false }
                await health.requestAccess()
            }

            permissionRow(
                title: "Ubicación",
                subtitle: "Pin del gym y ruta en entrenos outdoor",
                symbol: "location.fill",
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
        .task {
            await refreshNotificationsStatus()
            location.refreshStatus()
            health.refreshAuthorizationStatus()
        }
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
