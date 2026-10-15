import GymbroDomain
import SwiftUI

struct HistoryView: View {
    @Environment(GymbroStore.self) private var store

    /// Solo sesiones terminadas (no planes guardados ni borradores).
    private var finishedWorkouts: [WorkoutSession] {
        store.state.workouts.filter { $0.finishedAt != nil && $0.phase == .finished }
    }

    var body: some View {
        Group {
            if finishedWorkouts.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        OGPageHeader(title: "Historial")
                        ContentUnavailableView(
                            "Sin entrenos",
                            systemImage: "tray",
                            description: Text("Las sesiones terminadas aparecerán aquí.")
                        )
                        .foregroundStyle(OG.label2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                    .padding(.horizontal, OG.pad)
                    .padding(.top, 8)
                }
            } else {
                List {
                    Section {
                        OGPageHeader(title: "Historial")
                            .ogListPageHeaderRow()
                    }
                    ForEach(finishedWorkouts) { session in
                        NavigationLink {
                            WorkoutDetailView(session: session)
                        } label: {
                            historyRow(session)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet {
                            store.deleteWorkout(finishedWorkouts[i].id)
                        }
                    }
                }
                .ogListChrome()
            }
        }
        .background(OG.bg)
        .ogContentTitleNav()
    }

    private func dateLabel(_ session: WorkoutSession) -> String {
        (session.finishedAt ?? session.startedAt)?.formatted(date: .abbreviated, time: .omitted) ?? "—"
    }

    private func historyRow(_ session: WorkoutSession) -> some View {
        let sets = StatsEngine.totalSets(in: session)
        let mins = Int(session.durationMinutes.rounded())
        let prs = StatsEngine.personalRecordCount(in: session, allWorkouts: store.state.workouts)
        let duration = mins >= 60
            ? "\(mins / 60)h \(mins % 60)m"
            : (mins > 0 ? "\(mins) min" : "—")

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(OG.accent.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(OG.accent)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundStyle(OG.label)
                    if let notes = session.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(OG.accent)
                    }
                }
                Text("\(dateLabel(session)) · \(duration) · \(sets) series · \(Int(session.totalVolumeKg)) kg")
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if prs > 0 {
                Text("\(prs) PR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(OG.yellow, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkoutDetailView: View {
    @Environment(GymbroStore.self) private var store
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                OGPageHeader(title: session.title)
                    .ogListPageHeaderRow()
            }
            Section("Resumen") {
                LabeledContent("Volumen", value: "\(Int(session.totalVolumeKg)) kg")
                LabeledContent("Estado", value: session.phase.rawValue)
            }
            if let notes = session.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                Section("Notas") {
                    Text(notes)
                        .foregroundStyle(OG.label)
                }
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
        .ogListChrome()
        .ogContentTitleNav()
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
