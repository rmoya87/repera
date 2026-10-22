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
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3.bold())
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Repera").font(.headline)
                        Text("Entreno de hoy").font(.caption2)
                    }
                    Spacer(minLength: 0)
                }
            case .accessoryInline:
                Label("Repera · Entreno", systemImage: "figure.strengthtraining.traditional")
            default:
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(accent)
                    .accessibilityLabel("Abrir Repera en el Apple Watch")
            }
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(URL(string: "repera-watch://today"))
    }
}

@main
struct ReperaWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        StaticConfiguration(kind: "com.app.repera.watch.complication",
                            provider: ReperaWatchProvider()) { _ in
            ReperaWatchComplication()
        }
        .configurationDisplayName("Repera")
        .description("Abre tu entrenamiento desde la esfera del Apple Watch.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
