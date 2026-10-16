import Charts
import GymbroDomain
import SwiftUI
import UIKit

struct StatsView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(HealthKitStore.self) private var health

    @State private var heatmapMetric: HeatmapMetric = .time
    @State private var range: ProgressTimeRange = .week
    @State private var showRangePicker = false
    @State private var preparedCharts = ProgressPreparedCharts.empty
    @State private var chartsPreparing = false
    @State private var prepareGeneration = 0

    private var mondayFirst: Bool {
        store.state.settings.weekStartsOn == .monday
    }

    private var healthSessions: [HealthKitStore.ExternalActivity] {
        health.recentExternalActivities
    }

    private var allExternalSamples: [ExternalDaySample] {
        HealthMuscleMapper.daySamples(from: healthSessions)
    }

    private var allStimuli: [ExternalMuscleStimulus] {
        HealthMuscleMapper.stimuli(from: healthSessions)
    }

    private var filteredWorkouts: [WorkoutSession] {
        StatsEngine.filterWorkouts(
            store.state.workouts,
            range: range,
            weekStartsOnMonday: mondayFirst
        )
    }

    private var filteredExternal: [ExternalDaySample] {
        StatsEngine.filterExternal(
            allExternalSamples,
            range: range,
            weekStartsOnMonday: mondayFirst
        )
    }

    private var filteredStimuli: [ExternalMuscleStimulus] {
        StatsEngine.filterStimuli(
            allStimuli,
            range: range,
            weekStartsOnMonday: mondayFirst
        )
    }

    private var records: [PersonalRecord] {
        StatsEngine.personalRecords(from: filteredWorkouts)
    }

    private var chartExercises: [Exercise] {
        let ids = Set(filteredWorkouts.flatMap { $0.exercises.map(\.exercise.id) })
        return store.state.exercises.filter { ids.contains($0.id) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    tilesGrid

                    if health.isAuthorized {
                        if chartsPreparing && preparedCharts.range != range {
                            ProgressView("Actualizando gráficas…")
                                .tint(OG.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        ProgressCardioChartCard(prepared: preparedCharts)
                        ProgressCaloriesChartCard(prepared: preparedCharts)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            OGCardSectionTitle(title: "Salud")
                            progressEmptyCard(
                                title: "Salud no conectada",
                                subtitle: "Autoriza Apple Salud para ver FC y kcal.",
                                systemImage: "heart.text.square",
                                cta: "Ajustes de Salud"
                            ) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }

                    ProgressWeightChartCard(
                        entries: store.state.bodyWeights,
                        goalKg: store.state.settings.bodyWeightGoalKg,
                        range: range,
                        weekStartsOnMonday: mondayFirst
                    )

                    activityCard

                    MuscleBalanceCard(
                        workouts: filteredWorkouts,
                        external: filteredStimuli,
                        rangeLabel: range.title,
                        weekStartsOnMonday: mondayFirst
                    )

                    if chartExercises.isEmpty {
                        progressEmptyCard(
                            title: "Sin ejercicios aún",
                            subtitle: "Escanea una pizarra o crea un plan desde Crear / Diario.",
                            systemImage: "dumbbell",
                            cta: nil,
                            action: nil
                        )
                    } else {
                        exerciseProgressCard
                    }

                    if records.isEmpty {
                        progressEmptyCard(
                            title: "Sin récords en el periodo",
                            subtitle: "Entrena y apunta cargas para ver e1RM.",
                            systemImage: "trophy",
                            cta: nil,
                            action: nil
                        )
                    } else {
                        prSection
                    }

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
                .padding(.top, 0)
                .padding(.bottom, 28)
            }
            .background(OG.bg)
            .ogFixedTopBar("Progreso", subtitle: range.title) {
                Button {
                    showRangePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: OG.toolbarGlassIcon, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                        .contentShape(Circle())
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filtrar periodo")
            }
            .sheet(isPresented: $showRangePicker) {
                progressRangeSheet
                    .ogFittedSheet()
            }
            .task {
                // Una sola carga amplia (360d); cambiar periodo solo filtra en local.
                guard health.isAuthorized else {
                    ProgressLog.info("Progreso: Salud no autorizada, skip HK")
                    return
                }
                ProgressLog.info("Progreso appear → refresh HK 360d")
                let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
                let sessions = store.state.workouts
                await Task.yield()
                await health.refreshRecentExternalActivities(
                    excludingUUIDs: linked,
                    overlappingSessions: sessions,
                    days: ProgressTimeRange.days360.healthFetchDayCount
                )
                rebuildPreparedCharts(reason: "hk-ready")
            }
            .onChange(of: range) { _, _ in
                rebuildPreparedCharts(reason: "range")
            }
            .onChange(of: health.recentDailyHeartRate.count) { _, _ in
                rebuildPreparedCharts(reason: "hr-count")
            }
            .onChange(of: health.recentDailyActiveEnergy.count) { _, _ in
                rebuildPreparedCharts(reason: "kcal-count")
            }
            .onAppear {
                if preparedCharts.heartRate.isEmpty && preparedCharts.calories.isEmpty {
                    rebuildPreparedCharts(reason: "appear")
                }
            }
        }
    }

    /// Agrega/filtra series fuera del `body` (evita el freeze al cambiar 90/180/360).
    private func rebuildPreparedCharts(reason: String) {
        prepareGeneration += 1
        let gen = prepareGeneration
        chartsPreparing = true
        ProgressLog.info("prepare enqueue \(reason) gen=\(gen) range=\(range.rawValue)")

        let range = range
        let monday = mondayFirst
        let hr = health.recentDailyHeartRate
        let energy = health.recentDailyActiveEnergy
        let workouts = StatsEngine.filterWorkouts(
            store.state.workouts,
            range: range,
            weekStartsOnMonday: monday
        )
        let external = StatsEngine.filterExternal(
            HealthMuscleMapper.daySamples(from: health.recentExternalActivities),
            range: range,
            weekStartsOnMonday: monday
        )

        Task(priority: .userInitiated) {
            let built = await Task.detached(priority: .userInitiated) {
                ProgressChartBuilder.build(
                    range: range,
                    weekStartsOnMonday: monday,
                    heartRateDays: hr,
                    energyDays: energy,
                    workouts: workouts,
                    external: external
                )
            }.value
            await MainActor.run {
                guard gen == prepareGeneration else {
                    ProgressLog.info("prepare stale drop gen=\(gen)")
                    return
                }
                preparedCharts = built
                chartsPreparing = false
            }
        }
    }

    @ViewBuilder
    private func progressEmptyCard(
        title: String,
        subtitle: String,
        systemImage: String,
        cta: String?,
        action: (() -> Void)?
    ) -> some View {
        OGCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                if let cta, let action {
                    Button(cta, action: action)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OG.accent)
                }
            }
        }
    }

    // MARK: - Range sheet

    private var progressRangeSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Periodo") {
                CloseToolbarButton { showRangePicker = false }
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(ProgressTimeRange.allCases.enumerated()), id: \.element.id) { index, option in
                    if index > 0 {
                        Divider().opacity(0.35).padding(.leading, 50)
                    }
                    Button {
                        guard option != range else {
                            showRangePicker = false
                            return
                        }
                        ProgressLog.rangeTap(from: range, to: option)
                        showRangePicker = false
                        // Cierra el sheet antes de recalcular Charts (evita el bloqueo percibido).
                        Task { @MainActor in
                            let t0 = CFAbsoluteTimeGetCurrent()
                            await Task.yield()
                            range = option
                            ProgressLog.rangeApplied(
                                option,
                                elapsedMs: (CFAbsoluteTimeGetCurrent() - t0) * 1000
                            )
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(range == option ? OG.accent : OG.label2)
                                .frame(width: 24)
                            Text(option.title)
                                .foregroundStyle(OG.label)
                            Spacer()
                            if range == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(OG.accent)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .tint(OG.accent)
        .preferredColorScheme(.dark)
    }

    // MARK: - Tiles

    /// Media de FC (lpm) de Salud en el periodo visible — alineada con la gráfica Cardio.
    private func averageHeartRate(in range: ProgressTimeRange) -> Double? {
        let pts = health.recentDailyHeartRate.filter {
            range.contains($0.date, weekStartsOnMonday: mondayFirst)
        }
        guard !pts.isEmpty else { return nil }
        return pts.map(\.avgBpm).reduce(0, +) / Double(pts.count)
    }

    private var tilesGrid: some View {
        let summary = StatsEngine.progressHealthSummary(
            workouts: store.state.workouts,
            external: allExternalSamples,
            range: range,
            weekStartsOnMonday: mondayFirst
        )
        let previous: ProgressHealthSummary? = {
            let prevWorkouts = StatsEngine.filterWorkoutsInPreviousPeriod(
                store.state.workouts,
                range: range,
                weekStartsOnMonday: mondayFirst
            )
            let prevExternal = allExternalSamples.filter {
                range.containsInPreviousPeriod($0.date, weekStartsOnMonday: mondayFirst)
            }
            return StatsEngine.progressHealthSummary(
                workouts: prevWorkouts,
                external: prevExternal,
                range: range,
                weekStartsOnMonday: mondayFirst,
                applyRangeFilter: false
            )
        }()
        let streak = StatsEngine.consecutiveWeekStreak(
            workoutDates: store.state.workouts.compactMap { $0.finishedAt ?? $0.startedAt },
            externalDates: healthSessions.map(\.start),
            weekStartsOnMonday: mondayFirst
        )
        let avgHr = preparedCharts.range == range
            ? preparedCharts.averageHeartRate
            : averageHeartRate(in: range)
        let prevAvgHr: Double? = {
            let pts = health.recentDailyHeartRate.filter {
                range.containsInPreviousPeriod($0.date, weekStartsOnMonday: mondayFirst)
            }
            guard !pts.isEmpty else { return nil }
            return pts.map(\.avgBpm).reduce(0, +) / Double(pts.count)
        }()
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            tile(
                icon: "dumbbell.fill",
                label: "Entrenos",
                value: "\(summary.sessionCount)",
                iconColor: OG.accent,
                delta: previous.map { summary.sessionCount - $0.sessionCount }
            )
            tile(
                icon: "clock.fill",
                label: "Tiempo medio",
                value: summary.averageMinutes.map { "\(Int($0.rounded()))′" } ?? "—",
                iconColor: OG.blue,
                delta: {
                    guard let prev = previous,
                          let cur = summary.averageMinutes,
                          let old = prev.averageMinutes
                    else { return nil }
                    return Int((cur - old).rounded())
                }()
            )
            tile(
                icon: "heart.fill",
                label: "FC media",
                value: avgHr.map { "\(Int($0.rounded()))" } ?? "—",
                iconColor: OG.red,
                delta: {
                    guard let cur = avgHr, let old = prevAvgHr else { return nil }
                    return Int((cur - old).rounded())
                }()
            )
            tile(
                icon: "flame.fill",
                label: "Racha",
                value: "\(streak)",
                iconColor: OG.orange,
                delta: nil
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tile(
        icon: String,
        label: String,
        value: String,
        iconColor: Color,
        valueColor: Color = OG.label,
        delta: Int? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(label)
                    .foregroundStyle(OG.label2)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            .font(.system(size: 11, weight: .medium))
            .labelStyle(.titleAndIcon)
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(valueColor)
                .tracking(-0.4)
            if let delta {
                Text(delta == 0 ? "=" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(delta > 0 ? OG.accent : (delta < 0 ? OG.red : OG.label3))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    // MARK: - Activity

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Actividad · \(range.title.lowercased())")
            OGCard {
                ActivityHeatmapView(
                    workouts: filteredWorkouts,
                    external: filteredExternal,
                    range: range,
                    weekStartsOnMonday: mondayFirst,
                    metric: heatmapMetric,
                    onMetricChange: { heatmapMetric = $0 }
                )
            }
        }
    }

    // MARK: - Exercise / weight / PRs

    /// Una pasada sobre el periodo (evita 8× `history` ordenando todos los entrenos en «Todo»).
    private var topExerciseMaxWeights: [UUID: Double] {
        var best: [UUID: Double] = [:]
        for workout in filteredWorkouts {
            for entry in workout.exercises {
                for set in entry.loggedSets where !set.isWarmup && set.reps > 0 {
                    guard let w = set.weightKg, w > 0 else { continue }
                    best[entry.exercise.id] = max(best[entry.exercise.id] ?? 0, w)
                }
            }
        }
        return best
    }

    private var exerciseProgressCard: some View {
        let tops = topExerciseMaxWeights
        let listed = Array(chartExercises.prefix(8))
        return VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Progreso por ejercicio · \(range.title.lowercased())")
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    if listed.isEmpty {
                        Text("Sin ejercicios en este periodo.")
                            .foregroundStyle(OG.label2)
                    } else {
                        ForEach(listed) { ex in
                            NavigationLink {
                                ExerciseProgressView(exerciseId: ex.id)
                            } label: {
                                HStack {
                                    Text(ex.name)
                                        .foregroundStyle(OG.label)
                                    Spacer()
                                    if let maxW = tops[ex.id] {
                                        Text("\(maxW.formatted(.number.precision(.fractionLength(0...1)))) kg")
                                            .font(.system(size: 13).monospacedDigit())
                                            .foregroundStyle(OG.label2)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            if ex.id != listed.last?.id {
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                        }
                    }
                }
            }
        }
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Récords (e1RM) · \(range.title.lowercased())")
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    if records.isEmpty {
                        Text("Sin PRs en este periodo.")
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
}
