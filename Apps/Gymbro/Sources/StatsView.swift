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
    @State private var secondaryExpanded = false

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
                    OGPageHeader(title: "Progreso", subtitle: range.title) {
                        Button {
                            showRangePicker = true
                        } label: {
                            Image(systemName: "calendar")
                                .font(.system(size: OG.toolbarGlassIcon, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Filtrar periodo")
                    }

                    tilesGrid

                    if health.isAuthorized {
                        ProgressCardioChartCard(
                            heartRateDays: health.recentDailyHeartRate,
                            range: range,
                            weekStartsOnMonday: mondayFirst
                        )
                        ProgressCaloriesChartCard(
                            energyDays: health.recentDailyActiveEnergy,
                            workouts: filteredWorkouts,
                            external: filteredExternal,
                            range: range,
                            weekStartsOnMonday: mondayFirst
                        )
                    } else {
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

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            secondaryExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Más detalle")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(OG.label)
                            Spacer()
                            Image(systemName: secondaryExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(OG.label3)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if secondaryExpanded {
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
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showRangePicker) {
                progressRangeSheet
                    .ogFittedSheet()
            }
            .task(id: range) {
                guard health.isAuthorized else { return }
                let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
                await health.refreshRecentExternalActivities(
                    excludingUUIDs: linked,
                    overlappingSessions: store.state.workouts,
                    days: range.healthFetchDayCount
                )
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
                        range = option
                        showRangePicker = false
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

    private var tilesGrid: some View {
        let summary = StatsEngine.progressHealthSummary(
            workouts: store.state.workouts,
            external: allExternalSamples,
            range: range,
            weekStartsOnMonday: mondayFirst
        )
        let previous: ProgressHealthSummary? = {
            guard range != .all else { return nil }
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
                range: .all,
                weekStartsOnMonday: mondayFirst
            )
        }()
        let streak = StatsEngine.consecutiveWeekStreak(
            workoutDates: store.state.workouts.compactMap { $0.finishedAt ?? $0.startedAt },
            externalDates: healthSessions.map(\.start),
            weekStartsOnMonday: mondayFirst
        )
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
                label: "Cardio",
                value: summary.cardioMinutes > 0 ? "\(Int(summary.cardioMinutes.rounded()))′" : "—",
                iconColor: OG.red,
                delta: previous.map { Int((summary.cardioMinutes - $0.cardioMinutes).rounded()) }
            )
            tile(icon: "flame.fill", label: "Racha", value: "\(streak)", iconColor: OG.orange)
        }
    }

    private func tile(
        icon: String,
        label: String,
        value: String,
        iconColor: Color,
        valueColor: Color = OG.label,
        delta: Int? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(label)
                    .foregroundStyle(OG.label2)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            .font(.system(size: 12, weight: .medium))
            .labelStyle(.titleAndIcon)
            Text(value)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(valueColor)
                .tracking(-0.5)
            if let delta, range != .all {
                Text(delta == 0 ? "=" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(delta > 0 ? OG.accent : (delta < 0 ? OG.red : OG.label3))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    // MARK: - Activity

    private var activityCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                OGCardSectionTitle(title: "Actividad · \(range.title.lowercased())")
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

    private var exerciseProgressCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                OGCardSectionTitle(title: "Progreso por ejercicio · \(range.title.lowercased())")
                if chartExercises.isEmpty {
                    Text("Sin ejercicios en este periodo.")
                        .foregroundStyle(OG.label2)
                } else {
                    ForEach(chartExercises.prefix(8)) { ex in
                        NavigationLink {
                            ExerciseProgressView(exerciseId: ex.id)
                        } label: {
                            HStack {
                                Text(ex.name)
                                    .foregroundStyle(OG.label)
                                Spacer()
                                let h = StatsEngine.history(for: ex.id, workouts: filteredWorkouts)
                                if let maxW = h.maxWeightKg {
                                    Text("\(maxW.formatted(.number.precision(.fractionLength(0...1)))) kg")
                                        .font(.system(size: 13).monospacedDigit())
                                        .foregroundStyle(OG.label2)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(OG.label3)
                            }
                        }
                        if ex.id != chartExercises.prefix(8).last?.id {
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                }
            }
        }
    }

    private var prSection: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                OGCardSectionTitle(title: "Récords (e1RM) · \(range.title.lowercased())")
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
