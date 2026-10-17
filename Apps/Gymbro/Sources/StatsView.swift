import Charts
import GymbroDomain
import SwiftUI
import UIKit

struct StatsView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(HealthKitStore.self) private var health

    @State private var model = ProgressViewModel()
    @State private var heatmapMetric: HeatmapMetric = .time
    @State private var showRangePicker = false

    private var mondayFirst: Bool {
        store.state.settings.weekStartsOn == .monday
    }

    private var snap: ProgressSnapshot { model.snapshot }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    tilesGrid

                    if health.isAuthorized {
                        if model.isPreparing && snap.range != model.range {
                            ProgressView("Actualizando gráficas…")
                                .tint(OG.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        ProgressCardioChartCard(prepared: snap.charts)
                        ProgressCaloriesChartCard(prepared: snap.charts)
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
                        range: model.range,
                        weekStartsOnMonday: mondayFirst,
                        preparedPoints: snap.range == model.range ? snap.weightPoints : nil
                    )

                    activityCard

                    MuscleBalanceCard(
                        workouts: snap.filteredWorkouts,
                        external: snap.filteredStimuli,
                        rangeLabel: model.range.title,
                        weekStartsOnMonday: mondayFirst,
                        preparedLoadAll: snap.muscleLoadAll,
                        preparedLoadHard: snap.muscleLoadHard,
                        preparedHasHardSets: snap.hasHardSets
                    )

                    if snap.chartExercises.isEmpty {
                        progressEmptyCard(
                            title: "Sin ejercicios aún",
                            subtitle: "Cuando registres series, verás el progreso aquí.",
                            systemImage: "figure.strengthtraining.traditional",
                            cta: nil,
                            action: nil
                        )
                    } else {
                        exerciseProgressCard
                    }

                    if snap.records.isEmpty {
                        progressEmptyCard(
                            title: "Sin récords en el periodo",
                            subtitle: "Entrena y apunta pesos para ver e1RM.",
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
            .ogFixedTopBar("Progreso", subtitle: model.range.title) {
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
                guard health.isAuthorized else {
                    ProgressLog.info("Progreso: Salud no autorizada, skip HK")
                    schedulePrepare(reason: "no-health")
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
                schedulePrepare(reason: "hk-ready")
            }
            .onChange(of: model.range) { _, _ in
                schedulePrepare(reason: "range")
            }
            .onChange(of: health.healthDataRevision) { _, _ in
                model.invalidateCache(reason: "health-rev")
                schedulePrepare(reason: "health-rev")
            }
            .onChange(of: store.state.syncRevision) { _, _ in
                model.invalidateCache(reason: "sync-rev")
                schedulePrepare(reason: "sync-rev")
            }
        }
    }

    private func schedulePrepare(reason: String) {
        if model.applyCacheIfPossible(
            weekStartsOnMonday: mondayFirst,
            syncRevision: store.state.syncRevision,
            healthDataRevision: health.healthDataRevision,
            bodyWeights: store.state.bodyWeights
        ) {
            return
        }
        model.requestPrepare(store: store, health: health, reason: reason)
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
                        guard option != model.range else {
                            showRangePicker = false
                            return
                        }
                        ProgressLog.rangeTap(from: model.range, to: option)
                        showRangePicker = false
                        // Close sheet first; prep runs after — selector stays instant.
                        Task { @MainActor in
                            let t0 = CFAbsoluteTimeGetCurrent()
                            await Task.yield()
                            model.setRange(option)
                            schedulePrepare(reason: "range")
                            ProgressLog.rangeApplied(
                                option,
                                elapsedMs: (CFAbsoluteTimeGetCurrent() - t0) * 1000
                            )
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(model.range == option ? OG.accent : OG.label2)
                                .frame(width: 24)
                            Text(option.title)
                                .foregroundStyle(OG.label)
                            Spacer()
                            if model.range == option {
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

    // MARK: - Tiles (data from snapshot only)

    private var tilesGrid: some View {
        let summary = snap.summary
        let previous = snap.previousSummary
        let streak = snap.streak
        let avgHr = snap.averageHeartRate
        let prevAvgHr = snap.previousAverageHeartRate
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label2)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold).monospacedDigit())
                        .foregroundStyle(valueColor)
                    if let delta, delta != 0 {
                        Text(delta > 0 ? "+\(delta)" : "\(delta)")
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(delta > 0 ? OG.accent : OG.yellow)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 64, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    // MARK: - Activity

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Actividad · \(model.range.title.lowercased())")
            OGCard {
                ActivityHeatmapView(
                    workouts: snap.filteredWorkouts,
                    external: snap.filteredExternal,
                    dataRevision: snap.key.syncRevision &+ snap.key.healthDataRevision,
                    preparedTime: snap.heatmapTime,
                    preparedVolume: snap.heatmapVolume,
                    range: model.range,
                    weekStartsOnMonday: mondayFirst,
                    metric: heatmapMetric,
                    onMetricChange: { heatmapMetric = $0 }
                )
            }
        }
    }

    // MARK: - Exercise / PRs

    private var exerciseProgressCard: some View {
        let tops = snap.topExerciseMaxWeights
        let listed = Array(snap.chartExercises.prefix(8))
        return VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Progreso por ejercicio · \(model.range.title.lowercased())")
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
            OGCardSectionTitle(title: "Récords (e1RM) · \(model.range.title.lowercased())")
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    if snap.records.isEmpty {
                        Text("Sin PRs en este periodo.")
                            .foregroundStyle(OG.label2)
                    } else {
                        ForEach(snap.records.prefix(12)) { pr in
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
                            if pr.id != snap.records.prefix(12).last?.id {
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                        }
                    }
                }
            }
        }
    }
}
