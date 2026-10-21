import ReperaDomain
import SwiftUI
import UIKit

@main
struct ReperaApp: App {
    @State private var store = ReperaStore()
    @State private var subscriptions = SubscriptionManager()
    @State private var appleAuth = AppleAuthStore.shared
    @State private var businessAuth = BusinessAuthStore.shared
    @State private var businessData = BusinessDataStore.shared
    @State private var workoutSync = BusinessWorkoutSyncStore.shared
    @State private var aiInbox = AITrainingInboxStore.shared
    @State private var onboarding = OnboardingStore.shared
    @State private var locationTracker = WorkoutLocationTracker.shared
    @State private var wasBackgrounded = false
    @State private var authReady = false
    @Environment(\.scenePhase) private var scenePhase

    /// UI smoke tests run on clean simulators without an Apple ID. Only Debug
    /// builds launched explicitly from the test process may reveal the tab shell.
    /// Production/Release builds always require a valid Apple identity.
    private var uiTestTabShell: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("--repera-ui-test-tabs")
            && ProcessInfo.processInfo.environment["REPERA_UI_TEST_MODE"] == "1"
        #else
        return false
        #endif
    }

    init() {
        // Parallel disk/catalog warm before first frame / HealthKitStore.init.
        LaunchWarmup.start()
        LaunchTiming.mark("ReperaApp.init")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !authReady {
                    // Use exactly the UIKit scaling/layout of LaunchScreen.storyboard.
                    LaunchSplashView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                } else if uiTestTabShell || canEnterMainApp {
                    RootTabView()
                } else {
                    // Login normal (Bienvenido + SIWA). Sin pantalla intermedia de «Confirma tu cuenta».
                    OnboardingFlowView()
                }
            }
                .environment(store)
                .environment(subscriptions)
                .environment(HealthKitStore.shared)
                .environment(appleAuth)
                .environment(businessAuth)
                .environment(businessData)
                .environment(workoutSync)
                .environment(aiInbox)
                .environment(onboarding)
                .environment(locationTracker)
                .background(OG.bg)
                .sheet(isPresented: Binding(
                    get: { subscriptions.paywall.isPresented && onboarding.isComplete },
                    set: { if !$0 { subscriptions.dismissPaywall() } }
                )) {
                    PaywallView()
                        .environment(subscriptions)
                        .ogSheetChrome(detents: [.large])
                }
                .task {
                    LaunchTiming.mark("RootTabView.task")
                    // Paint first, then hydrate. Do not await seed/enrich before Home is visible.
                    Task(priority: .utility) {
                        ExerciseArt.warmArtManifest()
                    }

                    await store.hydrateFromDisk()
                    LaunchTiming.mark("hydrate.done→bootstrap")
                    store.bootstrap()
                    wireSubscriptionGates()

                    let appleOK = await appleAuth.ensureValidSession()
                    AuthSessionTrace.event(
                        "launch appleOK=\(appleOK) signedIn=\(appleAuth.isSignedIn) cache=\(businessAuth.hasCachedSupabaseSession) binding=\(businessAuth.hasPriorSupabaseBinding) connected=\(businessAuth.isConnected) onboardingDone=\(onboarding.isComplete) priceSeen=\(onboarding.priceAlreadySeen)"
                    )
                    // Restaurar Supabase aunque falle Apple local: las trazas mostraron
                    // cache=true binding=true con userID=false → antes se saltaba restore.
                    if appleOK
                        || businessAuth.hasCachedSupabaseSession
                        || businessAuth.hasPriorSupabaseBinding
                    {
                        await businessAuth.restoreSession()
                        if !businessAuth.isConnected {
                            _ = businessAuth.connectFromCachedSessionIfPossible()
                        }
                    }
                    // Nunca forzar sheet SIWA en splash. Binding previo → tabs aunque
                    // el SDK haya borrado el refresh tras un refresh fallido.
                    let onboardingFinished = onboarding.isComplete || onboarding.priceAlreadySeen
                    let decision = AuthSessionLaunchPolicy.decide(
                        .init(
                            appleSignedIn: appleAuth.isSignedIn,
                            hasCachedSupabaseSession: businessAuth.hasCachedSupabaseSession,
                            isConnected: businessAuth.isConnected,
                            hasPriorSupabaseBinding: businessAuth.hasPriorSupabaseBinding,
                            onboardingFinished: onboardingFinished
                        )
                    )
                    AuthSessionTrace.event(
                        "launch decision=\(decision) interactiveSIWA=\(AuthSessionLaunchPolicy.shouldPresentInteractiveAppleSignIn(appleSignedIn: appleAuth.isSignedIn, isConnected: businessAuth.isConnected, hasCachedSupabaseSession: businessAuth.hasCachedSupabaseSession, hasPriorSupabaseBinding: businessAuth.hasPriorSupabaseBinding))"
                    )
                    if decision == .enterApp {
                        _ = businessAuth.connectFromCachedSessionIfPossible()
                        onboarding.reconcile(isSignedIn: true)
                        if onboardingFinished { onboarding.advance(to: .done) }
                    } else {
                        onboarding.reconcile(isSignedIn: false)
                    }
                    authReady = true
                    AuthSessionTrace.event(
                        "launch authReady canEnter=\(canEnterMainApp) connected=\(businessAuth.isConnected) cache=\(businessAuth.hasCachedSupabaseSession) binding=\(businessAuth.hasPriorSupabaseBinding)"
                    )

                    // Suscripciones en paralelo — no bloquean el primer frame ni Health.
                    Task(priority: .utility) {
                        await subscriptions.start()
                        wireSubscriptionGates()
                    }

                    if canEnterMainApp {
                        Task(priority: .utility) {
                            await businessAuth.syncPublicProfile(
                                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                                avatarJPEG: store.state.settings.profileAvatarJPEG
                            )
                            await businessData.refresh()
                            await workoutSync.sync(store: store)
                            await aiInbox.sync(store: store)
                            wireSubscriptionGates()
                        }
                        await warmHealthAfterHydrate()
                    } else if appleAuth.isSignedIn {
                        await warmHealthAfterHydrate()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        wasBackgrounded = true
                        Task {
                            guard store.isHydrated else { return }
                            await LocalStore.shared.persistAndFlush(store.state)
                        }
                    } else if phase == .active, wasBackgrounded {
                        // Real return from background — not the initial launch `.active`.
                        Task {
                            guard store.isHydrated else { return }
                            await store.refreshFromiCloud()
                            await refreshHealthOnForeground(forceProgressiveIfNeeded: true)
                            await subscriptions.refreshOnForeground()
                            // Pull latest published trainer blocks, reservations and passes
                            // on foreground. Supabase RLS keeps personal history private.
                            if businessAuth.isConnected {
                                await businessData.refresh()
                                await workoutSync.sync(store: store)
                                await aiInbox.sync(store: store)
                            }
                            wireSubscriptionGates()
                        }
                    }
                }
                .onChange(of: businessAuth.isConnected) { _, connected in
                    if connected {
                        Task {
                            await workoutSync.sync(store: store)
                            await aiInbox.sync(store: store)
                        }
                    } else {
                        workoutSync.clearSession()
                        subscriptions.setBusinessSponsoredAccess(false)
                    }
                    wireSubscriptionGates()
                }
                .onChange(of: businessData.athleteCenterIds) { _, _ in
                    wireSubscriptionGates()
                }
                .onChange(of: store.didCompleteInitialRemoteSync) { _, finished in
                    if finished && businessAuth.isConnected {
                        Task {
                            await workoutSync.sync(store: store)
                            await aiInbox.sync(store: store)
                        }
                    }
                }
                .onChange(of: store.workoutsEpoch) { _, _ in
                    if businessAuth.isConnected {
                        Task { await workoutSync.sync(store: store) }
                    }
                }
                .onChange(of: store.state.syncRevision) { _, _ in
                    // Solo refresca conteos de cuota; no rehace sort de rutinas.
                    subscriptions.syncCounts(
                        libraryRoutines: store.libraryRoutineCount,
                        customExercises: store.customExerciseCount
                    )
                }
        }
    }

    /// Apple + (Supabase viva | cache | binding previo) + onboarding hecho.
    private var canEnterMainApp: Bool {
        AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: appleAuth.isSignedIn,
                hasCachedSupabaseSession: businessAuth.hasCachedSupabaseSession,
                isConnected: businessAuth.isConnected,
                hasPriorSupabaseBinding: businessAuth.hasPriorSupabaseBinding,
                onboardingFinished: onboarding.isComplete || onboarding.priceAlreadySeen
            )
        ) == .enterApp
    }

    private func wireSubscriptionGates() {
        // Conteos O(n) sin sort; syncCounts ignora si no cambian (menos churn Observation).
        subscriptions.syncCounts(
            libraryRoutines: store.libraryRoutineCount,
            customExercises: store.customExerciseCount
        )
        subscriptions.setBusinessSponsoredAccess(businessData.grantsFullAppAccess)
        store.featureAccess = { [subscriptions] in subscriptions.policy }
    }

    /// Progressive Health after local state exists — skip full window if disk cache is fresh.
    /// Hoy en paralelo ligero; ventana 180d en utility para no congelar Inicio.
    private func warmHealthAfterHydrate() async {
        let health = HealthKitStore.shared
        health.refreshAuthorizationStatus()
        guard health.isAuthorized else {
            LaunchWarmup.markLaunchHealthWarmFinished()
            return
        }
        health.startObservingHealthChanges()
        await health.refreshToday()
        await store.syncBodyWeightWithHealth()
        LaunchWarmup.markLaunchHealthWarmFinished()

        let needsProgressive = health.healthNeedsRefresh || !health.hasProgressiveCache
        if needsProgressive {
            let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
            let sessions = store.state.workouts
            Task(priority: .utility) {
                await health.refreshRecentExternalActivities(
                    excludingUUIDs: linked,
                    overlappingSessions: sessions,
                    days: 180
                )
            }
        } else {
            LaunchTiming.mark("health.warm.skipProgressive(cacheFresh)")
        }
    }

    private func refreshHealthOnForeground(forceProgressiveIfNeeded: Bool) async {
        let health = HealthKitStore.shared
        health.refreshAuthorizationStatus()
        guard health.isAuthorized else { return }
        health.startObservingHealthChanges()
        await health.refreshToday()
        await store.syncBodyWeightWithHealth()
        guard forceProgressiveIfNeeded else { return }
        if health.healthNeedsRefresh || !health.hasProgressiveCache {
            await health.refreshRecentExternalActivities(
                excludingUUIDs: Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID)),
                overlappingSessions: store.state.workouts,
                days: 180
            )
        }
    }
}


/// Matches LaunchScreen.storyboard: one UIKit image view, AspectFit and full-screen bounds.
/// Avoids a SwiftUI vs. UIKit sizing jump while the session is validated.
private struct LaunchSplashView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let canvas = UIView()
        canvas.backgroundColor = UIColor(red: 0, green: 0.180, blue: 0.141, alpha: 1)
        canvas.isUserInteractionEnabled = false

        let splash = UIImageView(image: UIImage(named: "Splash"))
        splash.contentMode = .scaleAspectFit
        splash.clipsToBounds = true
        splash.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(splash)

        NSLayoutConstraint.activate([
            splash.topAnchor.constraint(equalTo: canvas.topAnchor),
            splash.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            splash.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            splash.bottomAnchor.constraint(equalTo: canvas.bottomAnchor)
        ])
        return canvas
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
