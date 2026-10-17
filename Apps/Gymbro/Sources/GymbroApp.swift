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
                    // Thumbs listos antes del 1.er foco en Ejercicios (no esperar a onAppear de la tab).
                    ExerciseArt.prefetchThumbs(for: store.state.exercises)
                    let health = HealthKitStore.shared
                    health.refreshAuthorizationStatus()
                    if health.isAuthorized {
                        await health.refreshToday()
                        await store.syncBodyWeightWithHealth()
                    } else if health.isAvailable {
                        await health.requestAccess()
                        if health.isAuthorized {
                            await store.syncBodyWeightWithHealth()
                        }
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
