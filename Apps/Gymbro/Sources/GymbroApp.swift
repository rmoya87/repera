import GymbroDomain
import SwiftUI

@main
struct GymbroApp: App {
    @State private var store = GymbroStore()
    @State private var wasBackgrounded = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Parallel disk/catalog warm before first frame / HealthKitStore.init.
        LaunchWarmup.start()
        LaunchTiming.mark("GymbroApp.init")
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(HealthKitStore.shared)
                .preferredColorScheme(.dark)
                .background(Color.black)
                .task {
                    LaunchTiming.mark("RootTabView.task")
                    // Paint first, then hydrate. Do not await seed/enrich before Home is visible.
                    Task(priority: .utility) {
                        ExerciseArt.warmArtManifest()
                    }

                    await store.hydrateFromDisk()
                    LaunchTiming.mark("hydrate.done→bootstrap")
                    store.bootstrap()

                    await warmHealthAfterHydrate()
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
                        }
                    }
                }
        }
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
