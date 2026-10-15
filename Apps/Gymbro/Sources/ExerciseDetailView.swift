import GymbroDomain
import SwiftUI

/// Ficha de ejercicio: arte → técnica → impacto → historial.
struct ExerciseDetailView: View {
    @Environment(GymbroStore.self) private var store
    let exerciseId: UUID

    private var exercise: Exercise? {
        store.state.exercises.first { $0.id == exerciseId }
    }

    var body: some View {
        Group {
            if let exercise {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ExerciseArtView(exercise: exercise, showStepCaptions: true)

                        muscleSection(exercise)

                        if let eq = exercise.equipment {
                            metaChips(equipment: eq, bodyPart: exercise.bodyPart)
                        } else if exercise.bodyPart != nil {
                            metaChips(equipment: nil, bodyPart: exercise.bodyPart)
                        }

                        historySection(exercise)
                    }
                    .padding(.horizontal, OG.pad)
                    .padding(.vertical, 12)
                }
                .background(OG.bg)
                .navigationTitle(exercise.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.toggleFavorite(exerciseId)
                        } label: {
                            Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(exercise.isFavorite ? OG.yellow : OG.label2)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Ejercicio no encontrado", systemImage: "questionmark")
            }
        }
        .toolbarBackground(OG.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func historySection(_ exercise: Exercise) -> some View {
        let h = StatsEngine.history(for: exercise.id, workouts: store.state.workouts)
        return OGCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tu historial")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                if !h.hasData {
                    Text("Cuando lo entrenes, verás máximos y la última sesión aquí.")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                } else {
                    HStack(spacing: 10) {
                        histTile("Máx.", h.maxWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(0)))) kg" } ?? "—")
                        histTile("Reps máx.", h.bestReps.map(String.init) ?? "—")
                        histTile("Veces", "\(h.timesPerformed)")
                    }
                    if let w = h.maxWeightKg, let r = h.repsAtMaxWeight {
                        labeled("Mejor serie", "\(r) reps × \(w.formatted(.number.precision(.fractionLength(1)))) kg", tint: OG.accent)
                    }
                    if let e1 = h.estimatedOneRM {
                        labeled("1RM est.", "\(e1.formatted(.number.precision(.fractionLength(1)))) kg", tint: OG.yellow)
                    }
                    if let date = h.lastDate {
                        let last = [
                            h.lastReps.map { "\($0) reps" },
                            h.lastWeightKg.map { "\($0.formatted(.number.precision(.fractionLength(1)))) kg" },
                        ].compactMap { $0 }.joined(separator: " · ")
                        labeled("Última vez", "\(SpanishDate.short(date))" + (last.isEmpty ? "" : " · \(last)"), tint: OG.label)
                    }
                }
            }
        }
    }

    private func histTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func muscleSection(_ exercise: Exercise) -> some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Impacto muscular")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                if let target = exercise.targetMuscle {
                    labeled("Principal", LocalizedMuscle.es(target), tint: OG.accent)
                } else {
                    labeled("Grupo", exercise.muscleGroup, tint: OG.accent)
                }
                let secs = exercise.secondaryMuscles.map(LocalizedMuscle.es)
                if !secs.isEmpty {
                    labeled("Secundarios", secs.joined(separator: " · "), tint: OG.orange)
                }
                FlowChips(items: ([exercise.muscleGroup] + exercise.secondaryMuscles.map(LocalizedMuscle.es)))
            }
        }
    }

    private func metaChips(equipment: String?, bodyPart: String?) -> some View {
        OGCard {
            VStack(alignment: .leading, spacing: 8) {
                if let eq = equipment {
                    labeled("Equipo", eq, tint: OG.blue)
                }
                if let bp = bodyPart {
                    labeled("Zona", LocalizedMuscle.es(bp), tint: OG.label2)
                }
            }
        }
    }

    private func labeled(_ title: String, _ value: String, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(OG.label2)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint == OG.label2 ? OG.label : tint)
        }
    }
}

struct FlowChips: View {
    var items: [String]
    var body: some View {
        FlexibleChipWrap(items: Array(Set(items)).sorted())
    }
}

struct FlexibleChipWrap: View {
    var items: [String]
    var body: some View {
        let rows = items.chunked(into: 3)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(OG.label)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(OG.surface2, in: Capsule())
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

struct MuscleImpactDiagram: View {
    var primaries: [String]
    var secondaries: [String]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(zoneColor("chest").opacity(0.35))
                    .frame(width: w * 0.42, height: h * 0.38)
                    .position(x: w * 0.5, y: h * 0.38)
                Capsule()
                    .fill(zoneColor("shoulders").opacity(0.55))
                    .frame(width: w * 0.62, height: h * 0.10)
                    .position(x: w * 0.5, y: h * 0.22)
                Capsule()
                    .fill(zoneColor("arms").opacity(0.5))
                    .frame(width: w * 0.10, height: h * 0.34)
                    .position(x: w * 0.22, y: h * 0.40)
                Capsule()
                    .fill(zoneColor("arms").opacity(0.5))
                    .frame(width: w * 0.10, height: h * 0.34)
                    .position(x: w * 0.78, y: h * 0.40)
                RoundedRectangle(cornerRadius: 12)
                    .fill(zoneColor("core").opacity(0.45))
                    .frame(width: w * 0.28, height: h * 0.14)
                    .position(x: w * 0.5, y: h * 0.58)
                Capsule()
                    .fill(zoneColor("legs").opacity(0.5))
                    .frame(width: w * 0.14, height: h * 0.32)
                    .position(x: w * 0.40, y: h * 0.82)
                Capsule()
                    .fill(zoneColor("legs").opacity(0.5))
                    .frame(width: w * 0.14, height: h * 0.32)
                    .position(x: w * 0.60, y: h * 0.82)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(OG.label.opacity(0.85))
                    .position(x: w * 0.5, y: h * 0.36)
            }
        }
    }

    private func zoneColor(_ zone: String) -> Color {
        let keys = (primaries + secondaries).map { $0.lowercased() }
        let hitPrimary = keys.contains { matches($0, zone: zone) && primaries.map { $0.lowercased() }.contains($0) }
        let hitSecondary = keys.contains { matches($0, zone: zone) }
        if hitPrimary { return OG.accent }
        if hitSecondary { return OG.orange }
        return OG.surface3
    }

    private func matches(_ token: String, zone: String) -> Bool {
        switch zone {
        case "chest":
            return ["chest", "pectorals", "pecho", "upper chest"].contains(where: { token.contains($0) })
        case "shoulders":
            return ["shoulder", "delt", "hombro"].contains(where: { token.contains($0) })
        case "arms":
            return ["bicep", "tricep", "forearm", "arm", "bíceps", "tríceps"].contains(where: { token.contains($0) })
        case "core":
            return ["core", "abs", "oblique", "abdominal"].contains(where: { token.contains($0) })
        case "legs":
            return ["quad", "glute", "hamstring", "calf", "leg", "pierna", "isquio", "glút"].contains(where: { token.contains($0) })
                || token.contains("back") && token.contains("lower")
        default:
            return false
        }
    }
}

enum LocalizedMuscle {
    static func es(_ raw: String) -> String {
        let map: [String: String] = [
            "pectorals": "Pectorales",
            "chest": "Pecho",
            "triceps": "Tríceps",
            "biceps": "Bíceps",
            "shoulders": "Hombros",
            "delts": "Deltoides",
            "deltoids": "Deltoides",
            "lats": "Dorsales",
            "upper back": "Espalda alta",
            "lower back": "Zona lumbar",
            "back": "Espalda",
            "quads": "Cuádriceps",
            "quadriceps": "Cuádriceps",
            "hamstrings": "Isquiotibiales",
            "glutes": "Glúteos",
            "gluteal": "Glúteos",
            "calves": "Gemelos",
            "forearms": "Antebrazos",
            "abs": "Abdominales",
            "core": "Core",
            "trapezius": "Trapecio",
            "cardio": "Cardio",
            "upper legs": "Piernas",
            "upper arms": "Brazos",
            "waist": "Cintura",
        ]
        let key = raw.lowercased()
        return map[key] ?? raw.capitalized
    }
}
