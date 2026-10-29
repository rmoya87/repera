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
            let business = BusinessAuthStore.shared
            // Tras «Cerrar sesión» no restaurar ni avanzar: mostrar login.
            guard !business.didExplicitlySignOut else {
                AuthSessionTrace.event("onboardingFlow skip restore: explicitSignOut")
                onboarding.reconcile(isSignedIn: false)
                return
            }
            let appleOK = await appleAuth.ensureValidSession()
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
            guard !business.didExplicitlySignOut else { return }
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
        LocalStore.shared.resumeStorageForNewLogin()
        // Mismo flujo de permisos/planes que con Apple.
        // No se borra ni se reemplaza ningún entrenamiento local.
        onboarding.reconcile(isSignedIn: true)
        if onboarding.step == .appleSignIn {
            onboarding.finishPermissions()
        }
    }

    private func signInSpanish() async {
        guard !busy else { return }
        signingInWith = .apple
        defer { signingInWith = nil }
        errorText = nil
        do {
            try await appleAuth.signIn()
            LocalStore.shared.resumeStorageForNewLogin()
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
                onboarding.finishPermissions()
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
// Permissions are requested in context, not as an onboarding gate.
// Legacy installs at .permissions advance without showing a pre-permission page.
struct OnboardingPermissionsStep: View {
    @Environment(OnboardingStore.self) private var onboarding

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OG.bg.ignoresSafeArea())
            .task { onboarding.finishPermissions() }
    }
}
