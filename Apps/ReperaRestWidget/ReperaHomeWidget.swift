import SwiftUI
import WidgetKit

private struct ReperaLaunchEntry: TimelineEntry {
    let date: Date
}

private struct ReperaLaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReperaLaunchEntry {
        ReperaLaunchEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReperaLaunchEntry) -> Void) {
        completion(ReperaLaunchEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReperaLaunchEntry>) -> Void) {
        // The widget is deliberately action-only: no unauthenticated snapshots
        // of workouts, health metrics or subscription details on the home screen.
        completion(Timeline(entries: [ReperaLaunchEntry(date: .now)], policy: .never))
    }
}

struct ReperaHomeWidget: Widget {
    private let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.app.repera.launch", provider: ReperaLaunchProvider()) { _ in
            ReperaLaunchView(accent: accent)
        }
        .configurationDisplayName("Entrenar con Repera")
        .description("Abre tu entrenamiento de hoy o comienza una actividad.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ReperaLaunchView: View {
    @Environment(\.widgetFamily) private var family
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Repera", systemImage: "dumbbell")
                .font(.headline.weight(.bold))
                .foregroundStyle(accent)
            if family == .systemMedium {
                Text("Accesos rápidos").font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Link(destination: URL(string: "repera://today")!) {
                        Label("Entreno de hoy", systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                    Link(destination: URL(string: "repera://live")!) {
                        Label("Comenzar", systemImage: "play.fill")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .foregroundStyle(.primary)
            } else {
                Spacer(minLength: 0)
                Text("Entreno de hoy")
                    .font(.title3.weight(.semibold))
                Text("Abrir en Repera")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(family == .systemSmall ? URL(string: "repera://today") : nil)
    }
}
