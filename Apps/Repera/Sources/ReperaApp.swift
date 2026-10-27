import BackgroundTasks
import GoogleSignIn
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
    /// Two visible startup poses. The native frame uses the same barbell asset.
    @State private var launchMascotStage = 0
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
            appWindowContent
        }
        .backgroundTask(.appRefresh(CatalogBackgroundRefreshScheduler.identifier)) {
            await CatalogBackgroundRefreshScheduler.runHeadless()
        }
    }

    /// Isolate the root environment graph from the startup/lifecycle closures.
    private var appEnvironmentContent: some View {
            launchRootView
                .environment(\.locale, Locale(identifier: "es_ES"))
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .environment(store)
                .environment(subscriptions)
                .environment(HealthKitStore.shared)
                .environment(appleAuth)
                .environment(businessAuth)
                .environment(businessData)
                .environment(workoutSync)
                .environment(aiInbox)
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appArrivalContent: some View {
        appEnvironmentContent
                .overlay(alignment: .top) {
                    if let title = aiInbox.lastImportedTitle {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Entrenamiento de IA recibido").font(.subheadline.bold())
                                Text(title).font(.footnote).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Button {
                                aiInbox.dismissArrival()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel("Cerrar aviso")
                        }
                        .padding(14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 8)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: title) {
                            try? await Task.sleep(for: .seconds(6))
                            if !Task.isCancelled && aiInbox.lastImportedTitle == title {
                                aiInbox.dismissArrival()
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: aiInbox.lastImportedTitle)
                .environment(onboarding)
                .environment(locationTracker)
                .background(OG.bg)
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appPresentationContent: some View {
        appArrivalContent
                .sheet(isPresented: Binding(
                    get: { subscriptions.paywall.isPresented && onboarding.isComplete },
                    set: { if !$0 { subscriptions.dismissPaywall() } }
                )) {
                    PaywallView()
                        .environment(subscriptions)
                        .ogSheetChrome(detents: [.large])
                }
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appLaunchContent: some View {
        appPresentationContent
                .task {
                    if uiTestTabShell {
                        // UI tests must not wait for ornamental startup frames.
                        launchMascotStage = 2
                    } else {
                        // Keep the weightlifting mascot visible when the real UI is first drawn,
                        // even if the system's launch snapshot is stale. Then show the runner.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(550))
                            guard !Task.isCancelled else { return }
                            launchMascotStage = 1
                            try? await Task.sleep(for: .milliseconds(330))
                            guard !Task.isCancelled else { return }
                            launchMascotStage = 2
                        }
                    }
                    LaunchTiming.mark("RootTabView.task")
                    // Paint first, then hydrate. Do not await seed/enrich before Home is visible.
                    Task(priority: .utility) {
                        ExerciseArt.warmArtManifest()
                    }

                    await store.hydrateFromDisk()
                    // Restablecer Comenzar y sus muestras antes del trabajo de red.
                    // La grabación programada tiene su propio dueño del sensor.
                    if store.state.activeSession == nil {
                        LiveActivityRecorder.shared.resumeInterruptedRecordingIfNeeded()
                    }
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
                        || businessAuth.isGoogleSignedIn
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
                        if businessAuth.isConnected || businessAuth.hasPriorSupabaseBinding {
                            CatalogBackgroundRefreshScheduler.schedule()
                        }
                        Task(priority: .utility) {
                            await businessAuth.syncPublicProfile(
                                displayName: store.state.settings.profileDisplayName ?? appleAuth.displayName,
                                avatarJPEG: store.state.settings.profileAvatarJPEG
                            )
                            await businessData.refresh()
                            await RemoteExerciseCatalogStore.shared.refresh(store: store)
                            await workoutSync.sync(store: store)
                            _ = await aiInbox.sync(store: store)
                            _ = await AITrainingContextStore.shared.syncCalendar(store: store)
                            _ = await AIChangeRequestStore.shared.syncCustomExercises(store: store)
                            await AIChangeRequestStore.shared.refresh(store: store)
                            if scenePhase == .active {
                                aiInbox.startRealtime(store: store)
                            }
                            wireSubscriptionGates()
                        }
                        await warmHealthAfterHydrate()
                    } else if appleAuth.isSignedIn {
                        await warmHealthAfterHydrate()
                    }
                }
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appScenePhaseContent: some View {
        appLaunchContent
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        if businessAuth.isConnected || businessAuth.hasPriorSupabaseBinding {
                            CatalogBackgroundRefreshScheduler.schedule()
                        }
                        aiInbox.stopRealtime()
                        wasBackgrounded = true
                        // Recording takes precedence over network/background work.
                        // Checkpoint both workout types and GPS immediately.
                        LiveActivityRecorder.shared.checkpoint(force: true)
                        locationTracker.checkpoint()
                        store.workoutClock.checkpoint()
                        let backgroundID = UIApplication.shared.beginBackgroundTask(
                            withName: "Repera workout checkpoint"
                        )
                        Task { @MainActor in
                            defer { UIApplication.shared.endBackgroundTask(backgroundID) }
                            guard store.isHydrated else { return }
                            await LocalStore.shared.persistAndFlush(store.state)
                        }
                    } else if phase == .inactive {
                        aiInbox.stopRealtime()
                        LiveActivityRecorder.shared.checkpoint(force: true)
                        locationTracker.checkpoint()
                        store.workoutClock.checkpoint()
                    } else if phase == .active, wasBackgrounded {
                        store.resumePlannedGPSTrackingIfNeeded()
                        store.workoutClock.syncFromWallClock()
                        LiveActivityRecorder.shared.refreshWhenActive()
                        // No cloud state replacement, Health history or business
                        // refresh while a workout is actively being recorded.
                        guard !store.hasWorkoutInProgress else { return }
                        // Real return from background — not the initial launch `.active`.
                        Task {
                            guard store.isHydrated else { return }
                            await store.refreshFromiCloud()
                            await RemoteExerciseCatalogStore.shared.restoreCached(to: store)
                            await refreshHealthOnForeground(forceProgressiveIfNeeded: true)
                            await subscriptions.refreshOnForeground()
                            // Validar / renovar JWT al volver; si el refresh token
                            // fue revocado, la raíz cambiará a la página de login.
                            if businessAuth.isConnected { _ = await businessAuth.ensureUsableSession() }
                            // Pull latest published trainer blocks, reservations and passes
                            // on foreground. Supabase RLS keeps personal history private.
                            if businessAuth.isConnected && !businessAuth.requiresReauthentication {
                                await businessData.refresh()
                                await RemoteExerciseCatalogStore.shared.refresh(store: store)
                                await workoutSync.sync(store: store)
                                _ = await aiInbox.sync(store: store)
                                _ = await AITrainingContextStore.shared.syncCalendar(store: store)
                                _ = await AIChangeRequestStore.shared.syncCustomExercises(store: store)
                                await AIChangeRequestStore.shared.refresh(store: store)
                                if scenePhase == .active {
                                    aiInbox.startRealtime(store: store)
                                }
                            }
                            wireSubscriptionGates()
                        }
                    } else if phase == .active, businessAuth.isConnected,
                              !store.hasWorkoutInProgress {
                        aiInbox.startRealtime(store: store)
                    }
                }
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appBusinessConnectionContent: some View {
        appScenePhaseContent
                .onChange(of: businessAuth.isConnected) { _, connected in
                    if connected {
                        CatalogBackgroundRefreshScheduler.schedule()
                        Task {
                            await RemoteExerciseCatalogStore.shared.refresh(store: store)
                            await workoutSync.sync(store: store)
                            _ = await aiInbox.sync(store: store)
                            _ = await AITrainingContextStore.shared.syncCalendar(store: store)
                            _ = await AIChangeRequestStore.shared.syncCustomExercises(store: store)
                            await AIChangeRequestStore.shared.refresh(store: store)
                            if scenePhase == .active {
                                aiInbox.startRealtime(store: store)
                            }
                        }
                    } else {
                        workoutSync.clearSession()
                        aiInbox.clearSession()
                        AITrainingContextStore.shared.clearSession()
                        AIChangeRequestStore.shared.clearSession()
                        subscriptions.setBusinessSponsoredAccess(false)
                    }
                    wireSubscriptionGates()
                }
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appCenterSyncContent: some View {
        appBusinessConnectionContent
                .onChange(of: businessData.athleteCenterIds) { _, _ in
                    wireSubscriptionGates()
                }
                .onChange(of: store.didCompleteInitialRemoteSync) { _, finished in
                    if finished && businessAuth.isConnected {
                        Task {
                            await RemoteExerciseCatalogStore.shared.refresh(store: store)
                            await workoutSync.sync(store: store)
                            _ = await aiInbox.sync(store: store)
                            _ = await AITrainingContextStore.shared.syncCalendar(store: store)
                            _ = await AIChangeRequestStore.shared.syncCustomExercises(store: store)
                            await AIChangeRequestStore.shared.refresh(store: store)
                            if scenePhase == .active {
                                aiInbox.startRealtime(store: store)
                            }
                        }
                    }
                }
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appCatalogSyncContent: some View {
        appCenterSyncContent
                .onChange(of: store.catalogEpoch) { _, _ in
                    if businessAuth.isConnected, !store.hasWorkoutInProgress {
                        Task { _ = await AIChangeRequestStore.shared.syncCustomExercises(store:store) }
                    }
                }
                .onChange(of: store.workoutsEpoch) { _, _ in
                    if businessAuth.isConnected, !store.hasWorkoutInProgress {
                        Task { await workoutSync.sync(store: store) }
                    }
                }
    }

    /// Deliberately separate View expressions: Swift 6 cannot efficiently type-check
    /// all environment, overlay, lifecycle and synchronization modifiers at once.
    private var appWindowContent: some View {
        appCatalogSyncContent
                .onChange(of: store.hasWorkoutInProgress) { wasRecording, isRecording in
                    guard wasRecording, !isRecording, scenePhase == .active else { return }
                    // Resume deferred sync once both Play/Comenzar have committed
                    // the workout; never block the recording UI.
                    Task(priority: .utility) {
                        await store.refreshFromiCloud()
                        if businessAuth.isConnected {
                            await workoutSync.sync(store: store)
                            await RemoteExerciseCatalogStore.shared.refresh(store: store)
                            _ = await aiInbox.sync(store: store)
                        }
                        await refreshHealthOnForeground(forceProgressiveIfNeeded: false)
                    }
                }
                .onChange(of: store.state.syncRevision) { _, _ in
                    if businessAuth.isConnected, scenePhase == .active,
                       !store.hasWorkoutInProgress {
                        Task { _ = await AITrainingContextStore.shared.syncCalendar(store: store)
                            _ = await AIChangeRequestStore.shared.syncCustomExercises(store: store)
                            await AIChangeRequestStore.shared.refresh(store: store) }
                    }
                    // Solo refresca conteos de cuota; no rehace sort de rutinas.
                    subscriptions.syncCounts(
                        libraryRoutines: store.libraryRoutineCount,
                        customExercises: store.customExerciseCount
                    )
                }
    }

    /// `WindowGroup` accepts Views. Keep the auth state switch in an explicit
    /// ViewBuilder so SwiftUI cannot select the SceneBuilder overload of Group.
    /// All environment, overlay and lifecycle modifiers stay inside the window.
    @ViewBuilder
    private var launchRootView: some View {
        // Stable parent preserves the hydration .task when the intro switches
        // from the barbell to the runner and then into the authenticated UI.
        ZStack {
            if !uiTestTabShell && launchMascotStage == 0 {
                LaunchBarbellSplashView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else if !authReady || (!uiTestTabShell && launchMascotStage == 1) {
                LaunchSplashView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else if uiTestTabShell || canEnterMainApp {
                RootTabView()
            } else {
                // Login normal (Bienvenido + SIWA).
                OnboardingFlowView()
            }
        }
    }

    /// Apple o Google verificado + Supabase + onboarding hecho.
    private var canEnterMainApp: Bool {
        guard !businessAuth.didExplicitlySignOut, !businessAuth.requiresReauthentication else { return false }
        return AuthSessionLaunchPolicy.decide(
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
        // Resume Core Location independently of HealthKit permissions.
        store.resumePlannedGPSTrackingIfNeeded()
        // Cold launch after an interrupted session: GPS + disk recovery first.
        guard !store.hasWorkoutInProgress else {
            LaunchWarmup.markLaunchHealthWarmFinished()
            return
        }
        let health = HealthKitStore.shared
        health.refreshAuthorizationStatus()
        guard health.isAvailable else {
            LaunchWarmup.markLaunchHealthWarmFinished()
            return
        }
        health.startObservingHealthChanges()
        await health.refreshToday()
        // Apple Salud puede sincronizar el HKWorkout después de WatchConnectivity.
        await store.reconcileWatchHealthMetrics()
        await store.syncBodyWeightWithHealth()
        AutomaticHealthWorkoutReconciler.schedule(store: store)
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
        guard !store.hasWorkoutInProgress else { return }
        let health = HealthKitStore.shared
        health.refreshAuthorizationStatus()
        guard health.isAvailable else { return }
        health.startObservingHealthChanges()
        await health.refreshToday()
        await store.syncBodyWeightWithHealth()
        AutomaticHealthWorkoutReconciler.schedule(store: store)
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


/// The second-stage runner shown while the session is being restored.
private struct LaunchSplashView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let canvas = UIView()
        canvas.backgroundColor = UIColor(red: 48 / 255, green: 209 / 255, blue: 88 / 255, alpha: 1)
        canvas.isUserInteractionEnabled = false

        let mascot = UIImageView(image: UIImage(named: "MascotRunning"))
        mascot.contentMode = .scaleAspectFit
        mascot.clipsToBounds = true
        mascot.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(mascot)

        NSLayoutConstraint.activate([
            mascot.centerXAnchor.constraint(equalTo: canvas.centerXAnchor),
            mascot.centerYAnchor.constraint(equalTo: canvas.centerYAnchor),
            mascot.widthAnchor.constraint(equalTo: canvas.widthAnchor, multiplier: 0.64),
            mascot.heightAnchor.constraint(equalTo: canvas.heightAnchor, multiplier: 0.52)
        ])
        return canvas
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


/// Restores the HealthKit retry path previously available only through the
/// manual sync button. Runs silently, only with existing write permission.
@MainActor
private enum AutomaticHealthWorkoutReconciler {
    private static var isRunning = false
    private static var lastAttempt: Date?

    static func schedule(store: ReperaStore) {
        guard HealthKitStore.shared.canWriteWorkouts, !isRunning else { return }
        if let lastAttempt, Date().timeIntervalSince(lastAttempt) < 3600 { return }
        guard store.state.workouts.contains(where: {
            $0.startedAt != nil && $0.finishedAt != nil && $0.healthKitWorkoutUUID == nil
        }) else { return }
        isRunning = true
        lastAttempt = Date()
        Task(priority: .utility) {
            _ = await store.syncMissingWorkoutsToHealth()
            isRunning = false
        }
    }
}

private enum CatalogBackgroundRefreshScheduler {
    static let identifier = "com.app.repera.catalog.refresh"

    /// Native iOS refresh is opportunistic: never assume this is an exact timer.
    static func schedule() {
        // Never cancel/restart a pending request on every foreground transition:
        // doing so could indefinitely postpone the OS-selected opportunity.
        BGTaskScheduler.shared.getPendingTaskRequests { pending in
            guard !pending.contains(where: { $0.identifier == identifier }) else { return }
            let request = BGAppRefreshTaskRequest(identifier: identifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
            BGTaskScheduler.shared.submitTaskRequest(request) { error in
                if let error {
                    // Background scheduling is opportunistic; foreground catalog
                    // synchronization continues even if the system rejects it.
                    NSLog("Repera: catalog background refresh not scheduled: %@", error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    static func runHeadless() async {
        guard !Task.isCancelled else { return }
        let auth = BusinessAuthStore.shared
        guard auth.hasCachedSupabaseSession || auth.hasPriorSupabaseBinding else { return }
        schedule() // Re-arm only when an authenticated session may be restored.
        if !auth.isConnected {
            await auth.restoreSession() // Keychain; never show an interactive sign-in.
        }
        guard auth.isConnected, !Task.isCancelled else { return }
        // Update ONLY the shared catalog disk cache. The personal/iCloud store
        // is not hydrated or modified during a background-only launch.
        await RemoteExerciseCatalogStore.shared.refresh(force: true)
    }
}

/// First visible SwiftUI frame. A copy of the barbell PNG is packaged as a
/// direct bundle resource in addition to the iOS native launch image set.
/// This avoids a blank/black first frame even when iOS has cached a launch snapshot.
private struct LaunchBarbellSplashView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let canvas = UIView()
        canvas.backgroundColor = UIColor(red: 48 / 255, green: 209 / 255, blue: 88 / 255, alpha: 1)
        canvas.isUserInteractionEnabled = false

        // Use exactly the same full-screen artwork and content mode as
        // LaunchScreen.storyboard: avoids mascot size/position jumps between
        // the native launch screen and the first SwiftUI frame.
        let mascot = UIImageView(image: UIImage(named: "ReperaNativeOpaqueHero"))
        mascot.contentMode = .scaleAspectFit
        mascot.clipsToBounds = true
        mascot.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(mascot)
        NSLayoutConstraint.activate([
            mascot.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            mascot.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            mascot.topAnchor.constraint(equalTo: canvas.topAnchor),
            mascot.bottomAnchor.constraint(equalTo: canvas.bottomAnchor)
        ])
        return canvas
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
