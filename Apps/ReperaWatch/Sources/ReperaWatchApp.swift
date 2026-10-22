import Observation
import SwiftUI
import WatchKit

/// watchOS notifies this delegate when a crash interrupted a native workout.
@Observable
@MainActor
final class ReperaWatchRecoveryDelegate: NSObject, WKApplicationDelegate {
    var recoveryRequested = false

    func handleActiveWorkoutRecovery() {
        recoveryRequested = true
    }
}

@main
struct ReperaWatchApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: ReperaWatchRecoveryDelegate
    @State private var hub = WatchSessionHub()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchSessionView()
                .environment(hub)
                .task {
                    hub.activate()
                    if appDelegate.recoveryRequested { hub.recoverHealthSession() }
                }
                .onChange(of: appDelegate.recoveryRequested) { _, wantsRecovery in
                    if wantsRecovery { hub.recoverHealthSession() }
                }
                .onChange(of: scenePhase) { _, next in
                    if next == .active {
                        hub.refreshToday()
                    } else {
                        hub.applicationWillResignActive()
                    }
                }
        }
    }
}
