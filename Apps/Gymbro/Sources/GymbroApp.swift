import SwiftUI

@main
struct GymbroApp: App {
    @State private var store = GymbroStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(HealthKitStore.shared)
                .task {
                    // First paint wins: connectivity + deferred catalog/iCloud only.
                    store.bootstrap()
                    ExerciseArt.warmArtManifest()

                    // HealthKit + thumbs off the critical path (do not await before UI settles).
                    Task(priority: .utility) {
                        let health = HealthKitStore.shared
                        health.refreshAuthorizationStatus()
                        if health.isAuthorized {
                            await health.refreshToday()
                            await store.syncBodyWeightWithHealth()
                        }
                    }
                    Task(priority: .utility) {
                        // Prefer local thumbs first; refresh after a short settle if catalog grew.
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        ExerciseArt.prefetchThumbs(for: store.state.exercises)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task {
                            // Pull remote first; uploads remain gated until recovery allows them.
                            await store.refreshFromiCloud()
                            let health = HealthKitStore.shared
                            health.refreshAuthorizationStatus()
                            if health.isAuthorized {
                                await health.refreshToday()
                                await store.syncBodyWeightWithHealth()
                            }
                        }
                    } else if phase == .background {
                        store.persist(immediate: true)
                        Task { await LocalStore.shared.flush() }
                    }
                }
        }
    }
}
