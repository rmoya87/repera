import SwiftUI

@main
struct ReperaWatchApp: App {
    @State private var hub = WatchSessionHub()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchSessionView()
                .environment(hub)
                .task { hub.activate() }
                .onChange(of: scenePhase) { _, next in
                    if next != .active { hub.applicationWillResignActive() }
                }
        }
    }
}
