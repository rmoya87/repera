import SwiftUI
import WidgetKit

/// Kind legacy `com.app.repera.launch`: ya no hay widget de pantalla de inicio.
/// Se mantiene el kind registrado (vacío + desfavorecido) para que iOS retire
/// instancias antiguas del launcher medium tras actualizar la app.
private struct ReperaRetiredLaunchEntry: TimelineEntry {
    let date: Date
}

private struct ReperaRetiredLaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReperaRetiredLaunchEntry {
        ReperaRetiredLaunchEntry(date: .now)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (ReperaRetiredLaunchEntry) -> Void
    ) {
        completion(ReperaRetiredLaunchEntry(date: .now))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<ReperaRetiredLaunchEntry>) -> Void
    ) {
        completion(Timeline(entries: [ReperaRetiredLaunchEntry(date: .now)], policy: .never))
    }
}

struct ReperaHomeWidgetRetired: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.app.repera.launch",
            provider: ReperaRetiredLaunchProvider()
        ) { _ in
            // Sin accesos ni UI útil: el widget queda retirado de la galería.
            Color.clear
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Repera")
        .description("Este acceso ya no está disponible.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .disfavoredLocations([.homeScreen, .lockScreen], for: [.systemSmall, .systemMedium])
    }
}
