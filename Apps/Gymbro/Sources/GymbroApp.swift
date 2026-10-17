import GymbroDomain
import SwiftUI

@main
struct GymbroApp: App {
    @State private var store = GymbroStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Warm catalog on a background thread ASAP — before bootstrap merges touch `seed()`.
        Task.detached(priority: .userInitiated) {
            Catalog.prewarm()
        }
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

                    Task(priority: .utility) {
                        let health = HealthKitStore.shared
                        health.refreshAuthorizationStatus()
                        if health.isAuthorized {
                            await health.refreshToday()
                            await store.syncBodyWeightWithHealth()
                        }
                    }
                    Task(priority: .utility) {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        ExerciseArt.prefetchThumbs(for: Array(store.state.exercises.prefix(40)))
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task {
                            guard store.isHydrated else { return }
                            await store.refreshFromiCloud()
                            let health = HealthKitStore.shared
                            health.refreshAuthorizationStatus()
                            if health.isAuthorized {
                                await health.refreshToday()
                                await store.syncBodyWeightWithHealth()
                            }
                        }
                    } else if phase == .background {
                        guard store.isHydrated else { return }
                        store.persist(immediate: true)
                        Task { await LocalStore.shared.flush() }
                    }
                }
        }
    }
}
