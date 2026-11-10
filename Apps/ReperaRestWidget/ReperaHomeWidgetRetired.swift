import SwiftUI
import WidgetKit

/// Kind legacy `com.app.repera.launch`.
/// No borrar el registro: si desaparece del bundle, SpringBoard **sigue
/// ofreciendo** small/medium desde caché. Con `supportedFamilies([])` iOS
/// deja de mostrar el widget en la galería de Inicio.
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
            Color.clear
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Repera")
        .description("Este acceso ya no está disponible.")
        // Vacío = no aparece en la galería (small/medium quedan fuera).
        .supportedFamilies([])
    }
}
