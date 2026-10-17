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
                    // No global thumb prefetch on launch — LibraryView warms visible rows only.
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
                        Task {
                            guard store.isHydrated else { return }
                            // Durable flush without bumping syncRevision (no mutation implied).
                            await LocalStore.shared.persistAndFlush(store.state)
                        }
                    }
                }
        }
    }
}
