import SwiftUI
import UIKit
import WidgetKit

private struct ReperaWatchEntry: TimelineEntry {
    let date: Date
}

private struct ReperaWatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReperaWatchEntry {
        ReperaWatchEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ReperaWatchEntry) -> Void) {
        completion(ReperaWatchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReperaWatchEntry>) -> Void) {
        completion(Timeline(entries: [ReperaWatchEntry(date: Date())], policy: .never))
    }
}

/// Mismo AppIcon que la app (mascota sobre verde).
private var reperaAppIcon: UIImage? {
    if let named = UIImage(named: "ReperaIcon") { return named }
    if let url = Bundle.main.url(forResource: "repera_logo", withExtension: "png"),
       let data = try? Data(contentsOf: url),
       let image = UIImage(data: data) {
        return image
    }
    return nil
}

/// Icono de la app a color completo en la complicación.
/// Sin `.fullColor`, la esfera aplana el PNG a un disco verde sin mascota.
private struct ReperaAppIconMark: View {
    var body: some View {
        Group {
            if let icon = reperaAppIcon {
                Image(uiImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .renderingMode(.original)
                    // watchOS 11+/26: conserva mascota y colores bajo tinte de esfera.
                    .widgetAccentedRenderingMode(.fullColor)
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                // Solo si falta el asset en el .appex (no debería en build normal).
                Circle().fill(Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255))
            }
        }
        .accessibilityLabel("Abrir Repera en el Apple Watch")
    }
}

private struct ReperaWatchComplication: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                HStack(spacing: 7) {
                    ReperaAppIconMark()
                        .frame(width: 29, height: 29)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Repera").font(.headline)
                        Text("Entreno de hoy").font(.caption2)
                    }
                    Spacer(minLength: 0)
                }
            case .accessoryInline:
                Label {
                    Text("Repera · Entreno")
                } icon: {
                    if let icon = reperaAppIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .renderingMode(.original)
                            .widgetAccentedRenderingMode(.fullColor)
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "figure.strengthtraining.traditional")
                    }
                }
            default:
                ReperaAppIconMark()
            }
        }
        .containerBackground(for: .widget) {
            // El propio icono rellena el hueco circular (no un color plano).
            if family == .accessoryCircular, let icon = reperaAppIcon {
                Image(uiImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .renderingMode(.original)
                    .widgetAccentedRenderingMode(.fullColor)
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .widgetURL(URL(string: "repera-watch://today"))
    }
}

/// A WidgetBundle contains Widget values, never a WidgetConfiguration.
private struct ReperaWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.app.repera.watch.complication",
            provider: ReperaWatchProvider()
        ) { _ in
            ReperaWatchComplication()
        }
        .configurationDisplayName("Repera")
        .description("Abre tu entrenamiento desde la esfera del Apple Watch.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct ReperaWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReperaWatchWidget()
    }
}
