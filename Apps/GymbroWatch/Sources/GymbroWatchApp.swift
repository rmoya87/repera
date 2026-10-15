import SwiftUI

@main
struct GymbroWatchApp: App {
    @State private var hub = WatchSessionHub()

    var body: some Scene {
        WindowGroup {
            WatchSessionView()
                .environment(hub)
                .task {
                    hub.activate()
                }
        }
    }
}
