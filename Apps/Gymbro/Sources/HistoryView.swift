import GymbroDomain
import SwiftUI

struct HistoryView: View {
    @Environment(GymbroStore.self) private var store

    var body: some View {
        Group {
            if store.state.workouts.isEmpty {
                ContentUnavailableView(
                    "Sin entrenos",
                    systemImage: "tray",
                    description: Text("Las sesiones terminadas aparecerán aquí.")
                )
                .foregroundStyle(OG.label2)
            } else {
                List {
                    ForEach(store.state.workouts) { session in
                        NavigationLink {
                            WorkoutDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.headline)
                                    .foregroundStyle(OG.label)
                                Text(dateLabel(session))
                                    .font(.subheadline)
                                    .foregroundStyle(OG.label2)
                                Text("\(session.exercises.filter(\.isCompleted).count)/\(session.exercises.count) · \(Int(session.totalVolumeKg)) kg vol.")
                                    .font(.caption)
                                    .foregroundStyle(OG.label3)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet {
                            store.deleteWorkout(store.state.workouts[i].id)
                        }
                    }
                }
                .ogListChrome()
            }
        }
        .background(OG.bg)
        .navigationTitle("Historial")
        .toolbarBackground(OG.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func dateLabel(_ session: WorkoutSession) -> String {
        (session.finishedAt ?? session.startedAt)?.formatted(date: .abbreviated, time: .shortened) ?? "—"
    }
}

struct WorkoutDetailView: View {
    @Environment(GymbroStore.self) private var store
    let session: WorkoutSession

    var body: some View {
        List {
            Section("Resumen") {
                LabeledContent("Volumen", value: "\(Int(session.totalVolumeKg)) kg")
                LabeledContent("Estado", value: session.phase.rawValue)
            }
            ForEach(session.exercises) { exercise in
                Section(exercise.exercise.name) {
                    if exercise.loggedSets.isEmpty {
                        Text("Sin series")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(exercise.loggedSets.enumerated()), id: \.element.id) { idx, set in
                            VStack(alignment: .leading) {
                                Text(detailLine(index: idx + 1, set: set))
                                ForEach(set.drops) { drop in
                                    Text("  drop \(drop.weightKg.map { String(format: "%g", $0) } ?? "—") × \(drop.reps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if !set.clusters.isEmpty {
                                    Text("  RP: " + set.clusters.map { "\($0.reps)" }.joined(separator: "+"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.title)
    }

    private func detailLine(index: Int, set: LoggedSet) -> String {
        var parts = ["Serie \(index)"]
        if set.isWarmup { parts.append("WU") }
        switch set.kind {
        case .dropset: parts.append("Drop")
        case .restpause: parts.append("RP")
        case .straight: break
        }
        parts.append("\(set.weightKg.map { String(format: "%g", $0) } ?? "—") kg × \(set.reps)")
        if let effort = Effort.label(rir: set.rir, unit: store.state.settings.effortUnit) {
            parts.append(effort)
        }
        return parts.joined(separator: " · ")
    }
}
