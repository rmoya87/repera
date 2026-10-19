import ReperaDomain
import SwiftUI
import UIKit

@main
struct ReperaApp: App {
    @State private var store = ReperaStore()
    @State private var subscriptions = SubscriptionManager()
    @State private var appleAuth = AppleAuthStore.shared
    @State private var businessAuth = BusinessAuthStore.shared
    @State private var onboarding = OnboardingStore.shared
    @State private var locationTracker = WorkoutLocationTracker.shared
    @State private var wasBackgrounded = false
    @State private var authReady = false
    @Environment(\.scenePhase) private var scenePhase

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
                } else if onboarding.isComplete && appleAuth.isSignedIn {
                    RootTabView()
                } else {
                    OnboardingFlowView()
                }
            }
                .environment(store)
                .environment(subscriptions)
                .environment(HealthKitStore.shared)
                .environment(appleAuth)
                .environment(businessAuth)
                .environment(onboarding)
                .environment(locationTracker)
                .preferredColorScheme(.dark)
                .background(Color.black)
                .sheet(isPresented: Binding(
                    get: { subscriptions.paywall.isPresented && onboarding.isComplete },
                    set: { if !$0 { subscriptions.dismissPaywall() } }
                )) {
                    PaywallView()
                        .environment(subscriptions)
                        .ogSheetCorners()
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

                    let signedIn = await appleAuth.ensureValidSession()
                    onboarding.reconcile(isSignedIn: signedIn)
                    authReady = true

                    // Suscripciones en paralelo — no bloquean el primer frame ni Health.
                    Task(priority: .utility) {
                        await subscriptions.start()
                        wireSubscriptionGates()
                    }

                    if signedIn {
                        Task(priority: .utility) { await businessAuth.restoreSession() }
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
                            wireSubscriptionGates()
                        }
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

    private func wireSubscriptionGates() {
        // Conteos O(n) sin sort; syncCounts ignora si no cambian (menos churn Observation).
        subscriptions.syncCounts(
            libraryRoutines: store.libraryRoutineCount,
            customExercises: store.customExerciseCount
        )
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
