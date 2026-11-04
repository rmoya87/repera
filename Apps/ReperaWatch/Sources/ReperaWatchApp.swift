import Observation
import SwiftUI
import WatchKit
import WidgetKit

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
                .environment(\.locale, Locale(identifier: "es_ES"))
                .environment(hub)
                .task {
                    hub.activate()
                    // Registra / refresca la complicación (Chrono) al abrir la app — como Cafesito.
                    WidgetCenter.shared.reloadTimelines(
                        ofKind: "com.app.repera.watch.complication.brand6"
                    )
                    WidgetCenter.shared.reloadAllTimelines()
                    hub.publishComplicationSnapshot(force: true)
                    if appDelegate.recoveryRequested { hub.recoverHealthSession() }
                }
                .onChange(of: appDelegate.recoveryRequested) { _, wantsRecovery in
                    if wantsRecovery { hub.recoverHealthSession() }
                }
                .onChange(of: hub.active?.id) { _, _ in hub.publishComplicationSnapshot(force: true) }
                .onChange(of: hub.presentedSummary?.id) { _, _ in hub.publishComplicationSnapshot(force: true) }
                .onChange(of: hub.heartRateBpm) { _, _ in hub.publishComplicationSnapshot() }
                .onChange(of: hub.measuredEnergyKcal) { _, _ in hub.publishComplicationSnapshot() }
                .onChange(of: hub.sessionElapsed) { _, _ in hub.publishComplicationSnapshot() }
                .onChange(of: hub.watchLiveElapsedSeconds) { _, _ in hub.publishComplicationSnapshot() }
                .onChange(of: hub.restRemaining) { _, _ in hub.publishComplicationSnapshot(force: true) }
                .onChange(of: hub.todayPlan?.id) { _, _ in hub.publishComplicationSnapshot(force: true) }
                .onChange(of: scenePhase) { _, next in
                    if next == .active {
                        hub.refreshToday()
                        hub.reportWatchAppOpened()
                    } else {
                        hub.applicationWillResignActive()
                    }
                }
                // Complicación de esfera: repera-watch://today
                .onOpenURL { url in
                    hub.openFromComplication(url: url)
                }
        }
    }
}
