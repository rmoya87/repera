import ReperaDomain
import SwiftUI

/// Equilibrio muscular: mapa por **fatiga retenida** (vida media) + barras por series del periodo.
struct MuscleBalanceCard: View {
    var workouts: [WorkoutSession]
    var external: [ExternalMuscleStimulus]
    var rangeLabel: String
    var weekStartsOnMonday: Bool = true
    /// Precomputed loads from ProgressSnapshot (skip MainActor MuscleLoadEngine).
    var preparedLoadAll: [String: Double]? = nil
    var preparedLoadHard: [String: Double]? = nil
    var preparedFatigueAll: [String: Double]? = nil
    var preparedFatigueHard: [String: Double]? = nil
    var preparedHasHardSets: Bool? = nil

    @State private var hardOnly = false
    @State private var selected: String? = nil
    @State private var expanded = false

    private var load: [String: Double] {
        if hardOnly, let preparedLoadHard { return preparedLoadHard }
        if !hardOnly, let preparedLoadAll { return preparedLoadAll }
        return MuscleLoadEngine.load(
            workouts: workouts,
            external: external,
            window: .all,
            weekOffset: 0,
            weekStartsOnMonday: weekStartsOnMonday,
            hardOnly: hardOnly
        )
    }

    private var fatigue: [String: Double] {
        if hardOnly, let preparedFatigueHard { return preparedFatigueHard }
        if !hardOnly, let preparedFatigueAll { return preparedFatigueAll }
        return MuscleMapEngine.retainedLoad(
            workouts: workouts,
            external: external,
            hardOnly: hardOnly
        )
    }

    private var hasHardSets: Bool {
        if let preparedHasHardSets { return preparedHasHardSets }
        return workouts.contains { session in
            session.exercises.contains { entry in
                entry.loggedSets.contains { !$0.isWarmup && $0.reps > 0 && Effort.isHard(rir: $0.rir) }
            }
        }
    }

    var body: some View {
        let load = self.load
        let fatigue = self.fatigue
        let ranked = MuscleLoadEngine.ranked(load: load)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    OGCardSectionTitle(title: "Equilibrio muscular")
                    Text("Fatiga actual · \(hardOnly ? "series duras" : "series trabajadas") · \(rangeLabel)")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label3)
                        .padding(.horizontal, 4)
                }
                Spacer()
                if hasHardSets {
                    Button {
                        hardOnly.toggle()
                        selected = nil
                    } label: {
                        Text(hardOnly ? "Duras" : "Todas")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(hardOnly ? OG.yellow : OG.label2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(OG.surface2, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    BodyMapView(load: load, fatigueScores: fatigue, selected: selected) { slug in
                        selected = (selected == slug) ? nil : slug
                    }
                    BodyMapLegend()

                    barsSection(load: load, fatigue: fatigue, ranked: ranked)

                    if ranked.missed.count > 0 {
                        Text(hardOnly ? "Sin series duras en este periodo" : "Sin entrenar en este periodo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .padding(.top, 4)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(ranked.missed, id: \.self) { slug in
                                    Text(MuscleTaxonomy.displayName(slug))
                                        .font(.system(size: 12))
                                        .foregroundStyle(OG.label3)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(OG.surface2, in: Capsule())
                                        .overlay { Capsule().stroke(OG.label3.opacity(0.35), lineWidth: 1) }
                                }
                            }
                        }
                    } else if !ranked.worked.isEmpty {
                        Text(hardOnly
                             ? "Cada grupo tuvo al menos una serie dura."
                             : "Cada grupo muscular recibió trabajo.")
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label3)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func barsSection(
        load: [String: Double],
        fatigue: [String: Double],
        ranked: (worked: [String], missed: [String])
    ) -> some View {
        let worked = ranked.worked
        let maxLoad = worked.first.flatMap { load[$0] } ?? 0
        let visible: [String] = {
            if let selected { return [selected] }
            if expanded { return worked }
            return Array(worked.prefix(4))
        }()

        if visible.isEmpty {
            Text("Sin series en \(rangeLabel.lowercased()).")
                .font(.system(size: 13))
                .foregroundStyle(OG.label3)
        } else {
            ForEach(visible, id: \.self) { slug in
                let value = load[slug] ?? 0
                let level = MuscleMapEngine.level(forScore: fatigue[slug] ?? 0)
                HStack(spacing: 8) {
                    Text(MuscleTaxonomy.displayName(slug))
                        .font(.system(size: 13, weight: selected == slug ? .bold : .regular))
                        .foregroundStyle(OG.label)
                        .frame(width: 96, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(OG.surface2)
                            Capsule()
                                .fill(BodyMapPalette.fill(level: max(level, 1)))
                                .frame(width: maxLoad > 0 ? geo.size.width * CGFloat(value / maxLoad) : 0)
                        }
                    }
                    .frame(height: 8)
                    Text("\(formatSets(value)) series")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(OG.label2)
                        .frame(width: 72, alignment: .trailing)
                }
            }

            if selected == nil, worked.count > 4 {
                Button {
                    expanded.toggle()
                } label: {
                    HStack {
                        Text(expanded ? "Ver menos" : "Ver más")
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.label2)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private func formatSets(_ v: Double) -> String {
        String(format: v == floor(v) ? "%.0f" : "%.1f", v)
    }
}
