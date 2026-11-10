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
            VStack(spacing: 14) {
                Text("Bienvenido a Repera")
                    .font(.largeTitle.bold())
                    .foregroundStyle(OG.label)
                    .multilineTextAlignment(.center)
                Text("Todo tu entrenamiento. Cada vez mejor.")
                    .font(.headline)
                    .foregroundStyle(OG.label)
                    .multilineTextAlignment(.center)
                welcomeHighlights
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

            // Presentation matches Apple; signInGoogle still calls Google's SDK.
            Button {
                Task { await signInGoogle() }
            } label: {
                HStack(spacing: 10) {
                    if signingInWith == .google {
                        ProgressView()
                            .tint(googleButtonForeground)
                            .frame(width: signInIconSize, height: signInIconSize)
                    } else {
                        Image("GoogleSignInLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: signInIconSize, height: signInIconSize)
                            .accessibilityHidden(true)
                    }
                    Text(signingInWith == .google ? "Conectando con Google" : "Iniciar sesión con Google")
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
            .accessibilityLabel(
                signingInWith == .google
                    ? "Conectando con Google"
                    : "Iniciar sesión con Google"
            )

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(OG.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    private var welcomeHighlights: some View {
        let items: [(icon: String, title: String)] = [
            ("timer", "Rutinas"),
            ("camera", "Escanea"),
            ("chart.line.uptrend.xyaxis", "Estadísticas"),
            ("heart.text.square", "Recuperación"),
            ("applewatch", "Apple Watch"),
            ("sparkles", "IA")
        ]
        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(items, id: \.title) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(OG.accent)
                        .frame(width: 22, alignment: .center)
                        .accessibilityHidden(true)
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(item.title)
            }
        }
        .accessibilityElement(children: .contain)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "hand.raised.shield.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(OG.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)

                Text("Tus datos, bajo tu control")
                    .font(.title.bold())
                    .foregroundStyle(OG.label)

                Text("Tus entrenamientos viven en tu dispositivo y en tu iCloud. Repera no los vende ni los comparte con nadie.")
                    .font(.body)
                    .foregroundStyle(OG.label)

                VStack(spacing: 12) {
                    OnboardingPrivacyFactCard(
                        systemImage: "icloud.fill",
                        title: "Guardado en tu iCloud",
                        subtitle: "Historial y planes sincronizados con tu cuenta Apple. Tú controlas el acceso."
                    )
                    OnboardingPrivacyFactCard(
                        systemImage: "lock.shield.fill",
                        title: "Sin compartir con terceros",
                        subtitle: "No hay feed social ni venta de datos. Solo tú."
                    )
                    OnboardingPrivacyFactCard(
                        systemImage: "location.fill",
                        title: "Ubicación",
                        subtitle: "Solo al usar recorrido y navegación. Puedes denegarla y seguir entrenando."
                    )
                    OnboardingPrivacyFactCard(
                        systemImage: "heart.text.square.fill",
                        title: "Apple Salud",
                        subtitle: "Solo los datos que elijas para entrenos y actividad. Se solicitan al usar la función."
                    )
                }

                Text("Puedes rechazar los permisos del sistema y seguir utilizando las funciones que no los necesitan. También puedes modificarlos en Ajustes.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)

                Spacer(minLength: 16)

                Button {
                    onboarding.finishPermissions()
                } label: {
                    Text("Continuar")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(OG.accent)
                .controlSize(.large)
                .accessibilityHint("Continuar para elegir el plan. Los permisos se solicitan cuando usas las funciones correspondientes.")
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, minHeight: 560, alignment: .top)
        }
        .background(OG.bg.ignoresSafeArea())
    }
}

private struct OnboardingPrivacyFactCard: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(OG.accent)
                .frame(width: 44, height: 44)
                .background(OG.accent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
