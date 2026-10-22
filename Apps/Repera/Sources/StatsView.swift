import Charts
import ReperaDomain
import SwiftUI
import UIKit

struct StatsView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(SubscriptionManager.self) private var subscriptions

    @State private var model = ProgressViewModel()
    @State private var heatmapMetric: HeatmapMetric = .time
    @State private var showRangePicker = false
    @State private var topic: ProgressTopic = .training

    private enum ProgressTopic: String, CaseIterable {
        case training = "Entreno"
        case health = "Actividad"
        case recovery = "Recuperación"
    }

    private var mondayFirst: Bool {
        store.state.settings.weekStartsOn == .monday
    }

    private var isPro: Bool { subscriptions.isPro }
    private var snap: ProgressSnapshot { model.snapshot }

    var body: some View {
        NavigationStack {
            ScrollView {
                // El título y el calendario se desplazan con el contenido; sin franja opaca.
                // Solo las pestañas quedan ancladas al alcanzar la parte superior.
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    OGFixedTopBar(title: "Progreso", subtitle: model.range.title) {
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

                    Section {
                        // Un único VStack no lazy evita reciclar gráficas y saltos de offset.
                        VStack(alignment: .leading, spacing: 12) {
                            // No dibujar primero métricas vacías ni reorganizar tarjetas a mitad de carga.
                            if topic != .recovery && (snap.key.syncRevision < 0 || snap.range != model.range) {
                                OGCard {
                                    ProgressView("Preparando progreso…")
                                        .tint(OG.accent)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 180)
                                }
                            } else {
                            switch topic {
                            case .training:
                                if isPro {
                                    tilesGrid
                                    proAdvancedSections
                                } else {
                                    freeTilesGrid
                                    freeActivityCard
                                    ProTeaserCard(
                                        title: "Descubre todo tu progreso",
                                        bodyText: "Analiza tu evolución, tus marcas personales y el equilibrio muscular.",
                                        cta: "Descubrir Repera Pro"
                                    ) {
                                        subscriptions.presentPaywall(.progress, feature: .advancedProgress)
                                    }
                                }
                            case .health:
                                if isPro {
                                    healthSections
                                } else {
                                    freeHealthPreview
                                    ProTeaserCard(
                                        title: "Métricas de actividad avanzadas",
                                        bodyText: "Consulta frecuencia cardíaca, calorías y evolución de peso con Repera Pro.",
                                        cta: "Descubrir Repera Pro"
                                    ) {
                                        subscriptions.presentPaywall(.progress, feature: .advancedProgress)
                                    }
                                }
                            case .recovery:
                                HealthRecoveryProgressView(
                                    range: model.range,
                                    weekStartsOnMonday: mondayFirst
                                )
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
                    } header: {
                        // El control nativo mantiene la animación Liquid Glass
                        // de la selección al pulsar y arrastrar entre pestañas.
                        Picker("Categoría", selection: $topic) {
                            ForEach(ProgressTopic.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.large)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.horizontal, OG.pad)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                    }
                }
            }
            .background(OG.bg)
            .ogContentTitleNav()
            .sheet(isPresented: $showRangePicker) {
                progressRangeSheet
                    .ogFittedSheet()
            }
            .task {
                enforceFreeRangeIfNeeded()
                // Preparar datos locales inmediatamente; Salud puede tardar en refrescar.
                schedulePrepare(reason: "initial")
                guard health.isAuthorized else {
                    ProgressLog.info("Progreso: Salud no autorizada, skip HK")
                    schedulePrepare(reason: "no-health")
                    return
                }
                let fetchDays = isPro
                    ? ProgressTimeRange.days360.healthFetchDayCount
                    : ProgressTimeRange.week.healthFetchDayCount
                ProgressLog.info("Progreso appear → refresh HK \(fetchDays)d")
                let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
                let sessions = store.state.workouts
                await Task.yield()
                await health.refreshRecentExternalActivities(
                    excludingUUIDs: linked,
                    overlappingSessions: sessions,
                    days: fetchDays
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
            .onChange(of: subscriptions.isPro) { _, _ in
                // Solo si cambia el acceso Pro; ignorar churn isConfigured / refresh.
                enforceFreeRangeIfNeeded()
                schedulePrepare(reason: "subscription")
            }
        }
    }

    private func enforceFreeRangeIfNeeded() {
        guard !isPro, model.range != .week else { return }
        model.setRange(.week)
    }

    @ViewBuilder
    private var proAdvancedSections: some View {
        activityCard

        MuscleBalanceCard(
            workouts: snap.filteredWorkouts,
            external: snap.filteredStimuli,
            rangeLabel: model.range.title,
            weekStartsOnMonday: mondayFirst,
            preparedLoadAll: snap.muscleLoadAll,
            preparedLoadHard: snap.muscleLoadHard,
            preparedFatigueAll: snap.muscleFatigueAll,
            preparedFatigueHard: snap.muscleFatigueHard,
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
    }

    @ViewBuilder
    private var healthSections: some View {
        // Solo sesiones con nota real basada en historial personal comparable.
        // Sin nota no aparece ni la tarjeta ni una gráfica simulada.
        ProgressSessionScoreChartCard(
            workouts: snap.filteredWorkouts,
            range: model.range,
            weekStartsOnMonday: mondayFirst
        )

        if health.isAuthorized {
            if model.isPreparing && snap.range != model.range {
                ProgressView("Actualizando gráficas…")
                    .tint(OG.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            ProgressHeartZonesCard(workouts: snap.filteredWorkouts)
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

    }

    private var freeTilesGrid: some View {
        let summary = snap.summary
        let streak = snap.streak
        let totalMinutes: String = {
            if let avg = summary.averageMinutes, summary.sessionCount > 0 {
                return "\(Int((avg * Double(summary.sessionCount)).rounded()))′"
            }
            return "—"
        }()
        // Sin FC: 3 tiles en una sola fila.
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
            spacing: 8
        ) {
            tile(
                icon: "dumbbell.fill",
                label: "Entrenos",
                value: "\(summary.sessionCount)",
                iconColor: OG.accent,
                delta: nil
            )
            tile(
                icon: "clock.fill",
                label: "Tiempo",
                value: totalMinutes,
                iconColor: OG.blue,
                delta: nil
            )
            tile(
                icon: "flame.fill",
                label: "Racha",
                value: "\(streak)",
                iconColor: OG.orange,
                delta: streak - snap.previousStreak
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var freeActivityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Actividad")
            OGCard {
                ActivityHeatmapView(
                    workouts: snap.filteredWorkouts,
                    external: snap.filteredExternal,
                    dataRevision: snap.key.syncRevision &+ snap.key.healthDataRevision,
                    preparedTime: snap.heatmapTime,
                    preparedVolume: snap.heatmapVolume,
                    range: .week,
                    weekStartsOnMonday: mondayFirst,
                    metric: heatmapMetric,
                    onMetricChange: { heatmapMetric = $0 }
                )
            }
        }
    }

    /// Preview free de Actividad: datos simulados (no Salud real) para mostrar el valor de Pro.
    @ViewBuilder
    private var freeHealthPreview: some View {
        let sample = ProgressPreparedCharts.teaserSample(weekStartsOnMonday: mondayFirst)
        VStack(alignment: .leading, spacing: 12) {
            ProgressCardioChartCard(prepared: sample)
            ProgressCaloriesChartCard(prepared: sample)
            ProgressWeightChartCard(
                entries: [],
                goalKg: nil,
                range: .week,
                weekStartsOnMonday: mondayFirst,
                preparedPoints: ProgressPreparedCharts.teaserWeightPoints(),
                isTeaserPreview: true
            )
        }
        .opacity(0.88)
        .allowsHitTesting(false)
        .accessibilityLabel("Gráficas de ejemplo de actividad. Los valores no son datos reales.")
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
                        let decision = subscriptions.canSelectProgressRange(option)
                        guard decision.allowed else {
                            showRangePicker = false
                            subscriptions.presentPaywall(
                                decision.paywallContext,
                                feature: .progressPeriodBeyondWeek
                            )
                            return
                        }
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
                            if ReperaFeature.requiresPro(for: option) && !isPro {
                                Text("Pro")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(OG.accent)
                            } else if model.range == option {
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
    }

    // MARK: - Tiles (data from snapshot only)

    private var tilesGrid: some View {
        let summary = snap.summary
        let previous = snap.previousSummary
        let streak = snap.streak
        // FC media ya está en Actividad: tres indicadores estables en una fila.
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
            spacing: 8
        ) {
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
                          let old = prev.averageMinutes else { return nil }
                    return Int((cur - old).rounded())
                }()
            )
            tile(
                icon: "flame.fill",
                label: "Racha",
                value: "\(streak)",
                iconColor: OG.orange,
                delta: streak - snap.previousStreak
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
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OG.label2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold).monospacedDigit())
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            // Reserva siempre la misma altura (aunque el delta sea 0 o nil).
            Group {
                if let delta, delta != 0 {
                    Text(delta > 0 ? "+\(delta)" : "\(delta)")
                        .foregroundStyle(delta > 0 ? OG.accent : OG.yellow)
                } else {
                    Text("+0")
                        .foregroundStyle(OG.label3)
                        .opacity(0)
                }
            }
            .font(.system(size: 11, weight: .semibold).monospacedDigit())
            .frame(height: 14)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }

    // MARK: - Activity

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Actividad")
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
            OGCardSectionTitle(title: "Progreso por ejercicio")
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
            OGCardSectionTitle(title: "Récords (e1RM)")
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

/// Evolución de notas verificadas de entrenos. Nunca reintroduce puntuaciones
/// heurísticas antiguas: solo `personalHistory` persistido en cada sesión.
private struct ProgressSessionScoreChartCard: View {
    var workouts: [WorkoutSession]
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool

    private struct ScoreDay: Identifiable {
        let date: Date
        let score: Double
        var id: Date { date }
    }

    private var points: [ScoreDay] {
        let calendar = Calendar.current
        let rated: [(Date, Double)] = workouts.compactMap { session in
            guard let finishedAt = session.finishedAt,
                  let review = session.sessionReview,
                  review.scoreBasis == .personalHistory else { return nil }
            return (calendar.startOfDay(for: finishedAt), Double(review.overallScore))
        }
        let byDay = Dictionary(grouping: rated, by: { $0.0 })
        return byDay.keys.sorted().compactMap { day in
            guard let scores = byDay[day], !scores.isEmpty else { return nil }
            return ScoreDay(
                date: day,
                score: (scores.reduce(0.0) { $0 + $1.1 } / Double(scores.count)).rounded()
            )
        }
    }

    @ViewBuilder
    var body: some View {
        let values = points
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    OGCardSectionTitle(title: "Puntuación de entrenos")
                    Spacer(minLength: 8)
                    Text("\(Int((values.map(\.score).reduce(0, +) / Double(values.count)).rounded()))/10")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label)
                }
                OGCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Chart(values) { point in
                            LineMark(
                                x: .value("Día", point.date),
                                y: .value("Puntuación", point.score)
                            )
                            .interpolationMethod(.linear)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .foregroundStyle(OG.accent)
                            PointMark(
                                x: .value("Día", point.date),
                                y: .value("Puntuación", point.score)
                            )
                            .symbolSize(42)
                            .foregroundStyle(OG.accent)
                        }
                        .chartXScale(domain: ProgressChartAxis.xDomain(
                            points: values.map(\.date),
                            range: range,
                            weekStartsOnMonday: weekStartsOnMonday
                        ))
                        .chartYScale(domain: 0.0...10.0)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [0.0, 5.0, 10.0])
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            }
                        }
                        .frame(height: 164)
                        Text("Media diaria de notas basadas en tu historial comparable.")
                            .font(.caption)
                            .foregroundStyle(OG.label3)
                    }
                }
            }
        }
    }
}
