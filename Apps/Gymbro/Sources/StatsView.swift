import Charts
import GymbroDomain
import SwiftUI

struct StatsView: View {
    @Environment(GymbroStore.self) private var store
    @State private var chartExerciseId: UUID?

    private var records: [PersonalRecord] {
        StatsEngine.personalRecords(from: store.state.workouts)
    }

    private var chartExercises: [Exercise] {
        let ids = Set(store.state.workouts.flatMap { $0.exercises.map(\.exercise.id) })
        return store.state.exercises.filter { ids.contains($0.id) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    metricsRow
                    volumeTrendCard
                    sessionsTrendCard
                    muscleMap
                    exerciseProgressCard
                    if !store.state.bodyWeights.isEmpty {
                        weightChart
                    }
                    prSection
                    NavigationLink {
                        HistoryView()
                    } label: {
                        OGCard {
                            HStack {
                                Label("Historial", systemImage: "clock")
                                    .foregroundStyle(OG.label)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(OG.label3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, OG.pad)
                .padding(.vertical, 12)
            }
            .background(OG.bg)
            .navigationTitle("Estadísticas")
            .toolbarBackground(OG.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var metricsRow: some View {
        let avg = StatsEngine.averageSessionMinutes(from: store.state.workouts)
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                metric("Esta semana", "\(Int(StatsEngine.weeklyVolume(from: store.state.workouts))) kg")
                metric("30 días", "\(StatsEngine.workoutCount(from: store.state.workouts)) ses.")
                metric("PRs", "\(records.count)")
            }
            HStack(spacing: 10) {
                metric(
                    "Duración media",
                    avg.map { "\(Int($0.rounded()))′" } ?? "—"
                )
                metric(
                    "Volumen 30d",
                    "\(Int(volumeLast30Days.rounded())) kg"
                )
            }
        }
    }

    private var volumeLast30Days: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return store.state.workouts
            .filter { ($0.finishedAt ?? $0.startedAt ?? .distantPast) >= cutoff }
            .reduce(0) { $0 + $1.totalVolumeKg }
    }

    private var volumeTrendCard: some View {
        let points = StatsEngine.weeklyVolumeSeries(from: store.state.workouts, weeks: 8)
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Volumen semanal")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                if points.allSatisfy({ $0.volumeKg <= 0 }) {
                    Text("Entrena para ver la tendencia de kg movidos.")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label3)
                } else {
                    Chart(points, id: \.weekStart) { pt in
                        BarMark(
                            x: .value("Semana", pt.weekStart, unit: .weekOfYear),
                            y: .value("kg", pt.volumeKg)
                        )
                        .foregroundStyle(OG.accent)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 140)
                }
            }
        }
    }

    private var sessionsTrendCard: some View {
        let points = StatsEngine.weeklySessionSeries(from: store.state.workouts, weeks: 8)
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sesiones por semana")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                if points.allSatisfy({ $0.count == 0 }) {
                    Text("Aquí verás la frecuencia de entrenos.")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label3)
                } else {
                    Chart(points, id: \.weekStart) { pt in
                        LineMark(
                            x: .value("Semana", pt.weekStart, unit: .weekOfYear),
                            y: .value("Sesiones", pt.count)
                        )
                        .foregroundStyle(OG.blue)
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Semana", pt.weekStart, unit: .weekOfYear),
                            y: .value("Sesiones", pt.count)
                        )
                        .foregroundStyle(OG.blue)
                    }
                    .chartYScale(domain: 0...(max(4, (points.map(\.count).max() ?? 0) + 1)))
                    .frame(height: 120)
                }
            }
        }
    }

    private var exerciseProgressCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Progreso por ejercicio")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                if chartExercises.isEmpty {
                    Text("Cuando entrenes, aquí verás la curva de peso.")
                        .foregroundStyle(OG.label2)
                } else {
                    Picker("Ejercicio", selection: Binding(
                        get: { chartExerciseId ?? chartExercises.first?.id },
                        set: { chartExerciseId = $0 }
                    )) {
                        ForEach(chartExercises) { ex in
                            Text(ex.name).tag(Optional(ex.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(OG.accent)

                    let points = weightSeries(for: chartExerciseId ?? chartExercises.first?.id)
                    if points.count >= 2 {
                        Chart(points) { pt in
                            LineMark(x: .value("Fecha", pt.date), y: .value("kg", pt.kg))
                                .foregroundStyle(OG.accent)
                            PointMark(x: .value("Fecha", pt.date), y: .value("kg", pt.kg))
                                .foregroundStyle(OG.accent)
                        }
                        .frame(height: 140)
                    } else {
                        Text("Haz al menos 2 sesiones de este ejercicio.")
                            .font(.caption)
                            .foregroundStyle(OG.label3)
                    }
                }
            }
        }
    }

    private struct WeightPoint: Identifiable {
        var id: Date { date }
        var date: Date
        var kg: Double
    }

    private func weightSeries(for exerciseId: UUID?) -> [WeightPoint] {
        guard let exerciseId else { return [] }
        var points: [WeightPoint] = []
        for session in store.state.workouts.reversed() {
            guard let ex = session.exercises.first(where: { $0.exercise.id == exerciseId }) else { continue }
            let work = ex.loggedSets.filter { !$0.isWarmup && ($0.weightKg ?? 0) > 0 }
            guard let best = work.max(by: { ($0.weightKg ?? 0) < ($1.weightKg ?? 0) }),
                  let kg = best.weightKg,
                  let date = session.finishedAt ?? session.startedAt
            else { continue }
            points.append(WeightPoint(date: date, kg: kg))
        }
        return points.suffix(30).map { $0 }
    }

    private var muscleMap: some View {
        let statuses = MuscleMapEngine.statuses(from: store.state.workouts)
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mapa muscular")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                Text("Fatiga estimada por grupo.")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label3)
                ForEach(statuses.filter { $0.setsLast7Days > 0 || $0.score > 0.05 }) { status in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(status.name)
                                .foregroundStyle(OG.label)
                            Text("\(status.state.label) · \(status.setsLast7Days.formatted(.number.precision(.fractionLength(0)))) series/7d")
                                .font(.system(size: 12))
                                .foregroundStyle(OG.label2)
                        }
                        Spacer()
                        ProgressView(value: min(status.score, 1.0))
                            .tint(color(for: status.state))
                            .frame(width: 72)
                    }
                }
                if statuses.allSatisfy({ $0.score < 0.05 }) {
                    Text("Entrena para ver la fatiga por músculo.")
                        .foregroundStyle(OG.label2)
                }
            }
        }
    }

    private func color(for state: FatigueState) -> Color {
        switch state {
        case .ready: OG.accent
        case .recovering: OG.orange
        case .fatigued: OG.red
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(OG.label2)
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(OG.label)
                .tracking(-0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    private var weightChart: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Peso corporal")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                Chart(store.state.bodyWeights.prefix(30).reversed()) { entry in
                    LineMark(
                        x: .value("Fecha", entry.date),
                        y: .value("kg", entry.weightKg)
                    )
                    .foregroundStyle(OG.accent)
                    PointMark(
                        x: .value("Fecha", entry.date),
                        y: .value("kg", entry.weightKg)
                    )
                    .foregroundStyle(OG.accent)
                }
                .frame(height: 160)
                if let goal = store.state.settings.bodyWeightGoalKg {
                    Text("Objetivo: \(goal.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.yellow)
                }
            }
        }
    }

    private var prSection: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Récords (e1RM)")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
                if records.isEmpty {
                    Text("Completa series con peso para ver PRs.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(records.prefix(12)) { pr in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pr.exerciseName)
                                    .foregroundStyle(OG.label)
                                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 12))
                                    .foregroundStyle(OG.label2)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(pr.weightKg.formatted(.number.precision(.fractionLength(1))))×\(pr.reps)")
                                    .monospacedDigit()
                                    .foregroundStyle(OG.label)
                                Text("~\(pr.estimatedOneRM.formatted(.number.precision(.fractionLength(0)))) kg")
                                    .font(.system(size: 12))
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        if pr.id != records.prefix(12).last?.id {
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                }
            }
        }
    }
}
