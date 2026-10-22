import SwiftUI
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

private struct ReperaWatchComplication: View {
    @Environment(\.widgetFamily) private var family
    private let accent = Color(red: 0.54, green: 0.91, blue: 0.49)

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                HStack(spacing: 7) {
                    Image("ReperaIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 29)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Repera").font(.headline)
                        Text("Entreno de hoy").font(.caption2)
                    }
                    Spacer(minLength: 0)
                }
            case .accessoryInline:
                Label("Repera · Entreno", systemImage: "figure.strengthtraining.traditional")
            default:
                Image("ReperaIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .accessibilityLabel("Abrir Repera en el Apple Watch")
            }
        }
        .containerBackground(.clear, for: .widget)
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
