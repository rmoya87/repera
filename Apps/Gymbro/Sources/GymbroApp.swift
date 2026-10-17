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
                    store.bootstrap()
                    // Manifest + thumbs after local bootstrap; do not block first paint.
                    ExerciseArt.warmArtManifest()
                    Task(priority: .utility) {
                        // Wait briefly so iCloud recovery can adopt remote catalog first.
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        ExerciseArt.prefetchThumbs(for: store.state.exercises)
                    }
                    let health = HealthKitStore.shared
                    health.refreshAuthorizationStatus()
                    // Contextual: only refresh if already authorized — never prompt on cold launch.
                    if health.isAuthorized {
                        await health.refreshToday()
                        await store.syncBodyWeightWithHealth()
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
