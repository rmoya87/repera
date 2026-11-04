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
    @State private var category: ProgressCategory = .training
    @State private var isExpandedLayout = false

    private var mondayFirst: Bool {
        store.state.settings.weekStartsOn == .monday
    }

    private var isPro: Bool { subscriptions.isPro }
    private var snap: ProgressSnapshot { model.snapshot }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
            ScrollView {
                // El título y el calendario se desplazan con el contenido; sin franja opaca.
                // Solo las pestañas quedan ancladas al alcanzar la parte superior.
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    OGFixedTopBar(title: "Progreso", subtitle: categoryHubSubtitle, drawsBackground: false) {
                        EmptyView()
                    }
                    .id("progress-scroll-top")

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            if categoryNeedsSnapshotPrep && (snap.key.syncRevision < 0 || snap.range != model.range) {
                                OGCard {
                                    ProgressView("Preparando progreso…")
                                        .tint(OG.accent)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 180)
                                }
                            } else {
                                categoryContent
                            }
                        }
                        .padding(.horizontal, OG.pad)
                        .padding(.top, 0)
                        .padding(.bottom, 28)
                        .frame(maxWidth: isExpandedLayout ? .infinity : OG.contentColumnMaxWidth)
                        .frame(maxWidth: .infinity, alignment: .center)
                    } header: {
                        ProgressCategoryChipBar(selection: $category) { chipGlanceValue(for: $0) }
                            .padding(.top, 4)
                            .padding(.bottom, 10)
                            // Transparente: sin franja opaca ni línea gris al anclar.
                    }
                }
            }
            .defaultScrollAnchor(.top, for: .sizeChanges)
            .background(OG.bg)
            .onGeometryChange(for: Bool.self, of: { $0.size.width >= 620 }) { _, expanded in
                isExpandedLayout = expanded
            }
            .ogContentTitleNav()
            .task {
                applyHubRangePolicy()
                schedulePrepare(reason: "initial")
                if BusinessAuthStore.shared.isConnected {
                    await BusinessDataStore.shared.refresh()
                    schedulePrepare(reason: "classes-ready")
                }
                guard health.isAvailable else {
                    ProgressLog.info("Progreso: HealthKit no disponible")
                    schedulePrepare(reason: "no-health")
                    return
                }
                await refreshHealthForSelectedRange(reason: "hk-ready")
            }
            .onChange(of: model.range) { _, _ in
                schedulePrepare(reason: "range")
                Task { await refreshHealthForSelectedRange(reason: "hk-range") }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                // A medianoche cambia el tramo comparable sin cambiar syncRevision.
                schedulePrepare(reason: "day-changed")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                schedulePrepare(reason: "foreground")
            }
            .onChange(of: health.healthDataRevision) { _, _ in
                model.invalidateCache(reason: "health-rev")
                schedulePrepare(reason: "health-rev")
            }
            .onChange(of: BusinessDataStore.shared.progressDataRevision) { _, _ in
                model.invalidateCache(reason: "class-attendance")
                schedulePrepare(reason: "class-attendance")
            }
            .onChange(of: store.state.syncRevision) { _, _ in
                model.invalidateCache(reason: "sync-rev")
                schedulePrepare(reason: "sync-rev")
            }
            .onChange(of: subscriptions.isPro) { _, _ in
                applyHubRangePolicy()
                schedulePrepare(reason: "subscription")
            }
            .onChange(of: category) { _, _ in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    scrollProxy.scrollTo("progress-scroll-top", anchor: .top)
                }
            }
            }
        }
    }

    private var categoryNeedsSnapshotPrep: Bool {
        switch category {
        case .recovery, .sports: return false
        case .training, .strength, .fitness, .heart: return true
        }
    }

    private var categoryHubSubtitle: String {
        switch category {
        case .training, .strength, .fitness, .sports:
            return isPro ? "Este mes" : "Esta semana"
        case .heart:
            return "Ahora"
        case .recovery:
            return "Preparación"
        }
    }

    private func chipGlanceValue(for category: ProgressCategory) -> String {
        switch category {
        case .training:
            if let last = snap.filteredWorkouts.compactMap({ $0.sessionReview }).last(where: { $0.scoreBasis == .personalHistory }) {
                return "\(last.overallScore)"
            }
            return snap.summary.sessionCount > 0 ? "\(snap.summary.sessionCount)" : "—"
        case .strength:
            return snap.records.isEmpty ? "—" : "\(min(snap.records.count, 99)) PR"
        case .fitness:
            let minutes = Int(snap.summary.totalMinutes.rounded())
            return minutes > 0 ? "\(minutes)′" : "—"
        case .heart:
            if let bpm = health.recentDailyHeartRate.last?.avgBpm, bpm > 0 {
                return "\(Int(bpm.rounded()))"
            }
            return "—"
        case .recovery:
            return "·"
        case .sports:
            return "·"
        }
    }

    @ViewBuilder
    private var categoryContent: some View {
        switch category {
        case .training:
            trainingCategoryContent
        case .strength:
            strengthCategoryContent
        case .fitness:
            fitnessCategoryContent
        case .heart:
            heartCategoryContent
        case .recovery:
            HealthRecoveryProgressView(
                range: model.range,
                weekStartsOnMonday: mondayFirst,
                usesExpandedLayout: isExpandedLayout
            )
        case .sports:
            sportsCategoryContent
        }
    }

    @ViewBuilder
    private var trainingCategoryContent: some View {
        trainingScoreAndMuscleSections
        trainingGlanceMetricsGrid
        thisWeekConsistencyCard
        mobilityProgressCard
        if isPro {
            longTermTrainingTeaser
        } else {
            ProTeaserCard(
                title: "Tendencias a largo plazo",
                bodyText: "Con Pro ves consistencia de 4 semanas y evolución de puntuación sin límites.",
                cta: "Descubrir Repera Pro",
                appearance: .progress
            ) {
                subscriptions.presentPaywall(.progress, feature: .advancedProgress)
            }
        }
        NavigationLink {
            HistoryView()
        } label: {
            ProgressInsightCard(
                title: "Historial",
                systemImage: "clock",
                narrative: "Revisa sesiones terminadas, edita resultados y consulta el detalle de cada entreno.",
                tint: OG.label2,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }

    /// Media / Racha / Entrenos / Tiempo — cards 2×2 estilo Salud (sin chevron falso).
    private var trainingGlanceMetricsGrid: some View {
        let summary = snap.summary
        let avg = trainingAverageScoreText
        let minutes = Int(summary.totalMinutes.rounded())
        let timeText: String = {
            if minutes >= 60 {
                let h = minutes / 60
                let m = minutes % 60
                return m == 0 ? "\(h) h" : "\(h) h \(m)"
            }
            return "\(minutes)′"
        }()
        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ProgressMetricGlanceCard(title: "Media \(isPro ? "mes" : "7 días")", value: avg)
            ProgressMetricGlanceCard(title: "Racha", value: snap.streak > 0 ? "\(snap.streak) sem" : "—")
            ProgressMetricGlanceCard(title: "Entrenos", value: "\(summary.sessionCount)")
            ProgressMetricGlanceCard(title: "Tiempo", value: timeText)
        }
    }

    private var trainingAverageScoreText: String {
        let scores = snap.filteredWorkouts.compactMap { session -> Int? in
            guard let review = session.sessionReview, review.scoreBasis == .personalHistory else { return nil }
            return review.overallScore
        }
        guard !scores.isEmpty else { return "—" }
        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
        return String(format: "%.1f", avg).replacingOccurrences(of: ".", with: ",")
    }

    private var thisWeekConsistencyCard: some View {
        let days = consistencyDays(count: 7)
        let trained = days.filter(\.trained).count
        return VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Esta semana")
            ProgressInsightCard(
                title: "Consistencia",
                systemImage: "calendar",
                narrative: trained == 0
                    ? "Aún no hay entrenos registrados esta semana."
                    : "Has entrenado \(trained) de \(days.count) días. Mantén el ritmo.",
                tint: OG.accent
            ) {
                ProgressConsistencyDots(days: days)
            }
        }
    }

    private func consistencyDays(count: Int) -> [ProgressConsistencyDots.DayMark] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let trainedDays: Set<Date> = Set(snap.filteredWorkouts.compactMap { session in
            guard let finished = session.finishedAt else { return nil }
            return cal.startOfDay(for: finished)
        })
        let symbols = cal.veryShortWeekdaySymbols
        return (0..<count).compactMap { offset -> ProgressConsistencyDots.DayMark? in
            let back = count - 1 - offset
            guard let day = cal.date(byAdding: .day, value: -back, to: today) else { return nil }
            let weekday = cal.component(.weekday, from: day) // 1=Sunday
            let label = symbols[(weekday - 1 + symbols.count) % symbols.count]
            return .init(
                id: day,
                label: label,
                trained: trainedDays.contains(day),
                isToday: day == today
            )
        }
    }

    @ViewBuilder
    private var strengthCategoryContent: some View {
        let prCount = snap.records.count
        OGCardSectionTitle(title: "Fuerza")
        ProgressInsightCard(
            title: "Carga y marcas",
            systemImage: ProgressCategory.strength.systemImage,
            narrative: strengthInsightCopy,
            tint: ProgressCategory.strength.accent
        ) {
            ProgressHeroMetricRow(
                value: prCount > 0 ? "\(prCount)" : "—",
                unit: prCount > 0 ? "PR" : nil,
                caption: prCount > 0 ? "en el periodo" : "sin marcas aún"
            ) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(ProgressCategory.strength.accent.opacity(0.85))
                    .accessibilityHidden(true)
            }
            if !snap.records.isEmpty {
                ProgressMiniRangeBars(
                    samples: strengthSparkSamples,
                    tint: ProgressCategory.strength.accent,
                    height: 56
                )
            }
        }
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ProgressMetricGlanceCard(
                title: "Sesiones fuerza",
                value: "\(snap.summary.sessionCount)",
                tint: ProgressCategory.strength.accent
            )
            ProgressMetricGlanceCard(
                title: "Ejercicios",
                value: snap.chartExercises.isEmpty ? "—" : "\(snap.chartExercises.count)",
                tint: ProgressCategory.strength.accent
            )
        }
        if isPro {
            proAdvancedSections
        } else {
            freeExerciseTrendPreview
            ProTeaserCard(
                title: "Evolución de fuerza",
                bodyText: "Sigue e1RM, progreso por ejercicio y tu índice de progresión con Repera Pro.",
                cta: "Descubrir Repera Pro",
                appearance: .progress
            ) {
                subscriptions.presentPaywall(.progress, feature: .advancedProgress)
            }
        }
    }

    private var strengthSparkSamples: [ClosedRange<Double>] {
        let values = snap.records.prefix(12).map { max(0.15, min(1.0, $0.estimatedOneRM / 200)) }
        if values.isEmpty { return [] }
        return values.map { v in (v * 0.55)...v }
    }

    private var strengthInsightCopy: String {
        let prCount = snap.records.count
        if prCount == 0 {
            return "Cuando registres series de fuerza, verás récords y volumen aquí."
        }
        return "Has logrado \(prCount) marca\(prCount == 1 ? "" : "s") en el periodo. Abajo tienes el detalle por ejercicio y e1RM."
    }

    @ViewBuilder
    private var fitnessCategoryContent: some View {
        let minutes = Int(snap.summary.totalMinutes.rounded())
        OGCardSectionTitle(title: "Forma física")
        ProgressInsightCard(
            title: "Estímulo activo",
            systemImage: ProgressCategory.fitness.systemImage,
            narrative: minutes > 0
                ? "Has acumulado \(minutes) minutos de actividad en el periodo. El mapa muestra tus días activos."
                : "Cuando camines o entrenes, verás aquí tu estímulo y el mapa de días activos.",
            tint: ProgressCategory.fitness.accent
        ) {
            ProgressHeroMetricRow(
                value: minutes > 0 ? "\(minutes)" : "—",
                unit: minutes > 0 ? "min" : nil,
                caption: isPro ? "este mes" : "esta semana"
            ) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(ProgressCategory.fitness.accent.opacity(0.9))
                    .accessibilityHidden(true)
            }
        }
        if isPro {
            activityCard
            healthChartsLayout {
                caloriesHealthSection
                weightHealthSection
            }
            healthPermissionCard
        } else {
            freeActivityCard
            freeCaloriesWeightPreview
            ProTeaserCard(
                title: "Forma física completa",
                bodyText: "Calorías, peso y tendencias largas con Repera Pro.",
                cta: "Descubrir Repera Pro",
                appearance: .activity
            ) {
                subscriptions.presentPaywall(.progress, feature: .advancedProgress)
            }
        }
    }

    @ViewBuilder
    private var heartCategoryContent: some View {
        let bpm = health.recentDailyHeartRate.last?.avgBpm
        let bpmText = bpm.map { "\(Int($0.rounded()))" } ?? "—"
        OGCardSectionTitle(title: "Corazón")
        ProgressInsightCard(
            title: "Frecuencia cardíaca",
            systemImage: ProgressCategory.heart.systemImage,
            narrative: heartInsightCopy,
            tint: ProgressCategory.heart.accent
        ) {
            ProgressHeroMetricRow(
                value: bpmText,
                unit: bpm == nil ? nil : "LPM",
                caption: bpm == nil ? nil : "media reciente"
            ) {
                ProgressMiniRangeBars(
                    samples: heartSparkSamples,
                    tint: ProgressCategory.heart.accent,
                    height: 64
                )
                .frame(width: 120)
            }
        }
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ProgressMetricGlanceCard(
                title: "Mín. reciente",
                value: heartExtremeText(\.minBpm),
                tint: ProgressCategory.heart.accent
            )
            ProgressMetricGlanceCard(
                title: "Máx. reciente",
                value: heartExtremeText(\.maxBpm),
                tint: ProgressCategory.heart.accent
            )
        }
        trainingHeartZonesSection
        if isPro {
            healthChartsLayout {
                cardioHealthSection
            }
        } else {
            freeCardioPreview
            ProTeaserCard(
                title: "Corazón en detalle",
                bodyText: "Consulta FC diaria, recuperación tras el entreno y tendencias con Repera Pro.",
                cta: "Descubrir Repera Pro",
                appearance: .activity
            ) {
                subscriptions.presentPaywall(.progress, feature: .advancedProgress)
            }
        }
        healthPermissionCard
    }

    private var heartInsightCopy: String {
        if let bpm = health.recentDailyHeartRate.last?.avgBpm, bpm > 0 {
            return "Recientemente, tu frecuencia cardíaca media ha sido de \(Int(bpm.rounded())) latidos por minuto."
        }
        return "Conecta Salud o entrena con pulsómetro para ver tu ritmo cardíaco aquí."
    }

    private var heartSparkSamples: [ClosedRange<Double>] {
        let points = health.recentDailyHeartRate.suffix(14)
        guard !points.isEmpty else {
            return (0..<10).map { _ in 0.25...0.55 }
        }
        let maxB = points.map(\.maxBpm).max() ?? 160
        let minB = points.map(\.minBpm).min() ?? 50
        let span = max(maxB - minB, 1)
        return points.map { p in
            let lo = (p.minBpm - minB) / span
            let hi = (p.maxBpm - minB) / span
            return lo...max(hi, lo + 0.08)
        }
    }

    private func heartExtremeText(_ keyPath: KeyPath<HealthKitStore.DailyHeartRatePoint, Double>) -> String {
        guard let last = health.recentDailyHeartRate.last else { return "—" }
        let v = last[keyPath: keyPath]
        guard v > 0 else { return "—" }
        return "\(Int(v.rounded()))"
    }

    @ViewBuilder
    private var sportsCategoryContent: some View {
        OGCardSectionTitle(title: "Deportes")
        NavigationLink {
            LiveSportsCatalogView()
        } label: {
            ProgressInsightCard(
                title: "Evolución y récords",
                systemImage: ProgressCategory.sports.systemImage,
                narrative: "Consulta distancias, ritmos y marcas por deporte desde tus salidas Comenzar y Salud.",
                tint: ProgressCategory.sports.accent,
                showsChevron: true
            ) {
                let sportSessions = store.state.workouts.filter {
                    $0.phase == .finished && $0.finishedAt != nil && $0.liveSportID != nil
                }
                ProgressHeroMetricRow(
                    value: sportSessions.isEmpty ? "—" : "\(sportSessions.count)",
                    unit: sportSessions.isEmpty ? nil : "salidas",
                    caption: sportSessions.isEmpty ? "sin actividades aún" : "registradas"
                ) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(ProgressCategory.sports.accent.opacity(0.9))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var longTermTrainingTeaser: some View {
        let days = consistencyDays(count: 28)
        let trained = days.filter(\.trained).count
        OGCardSectionTitle(title: "A largo plazo")
        ProgressInsightCard(
            title: "Consistencia",
            systemImage: "calendar",
            narrative: "En las últimas 4 semanas has entrenado \(trained) días distintos · \(snap.summary.sessionCount) sesiones · \(ReperaNumberFormat.integer(Int(snap.summary.totalMinutes.rounded()))) min.",
            tint: OG.accent
        ) {
            let rows = stride(from: 0, to: days.count, by: 7).map { start in
                Array(days[start..<min(start + 7, days.count)])
            }
            VStack(spacing: 6) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row) { day in
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(day.trained ? OG.accent : OG.surface3.opacity(0.45))
                                .frame(height: 16)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .accessibilityLabel("Mapa de consistencia: \(trained) días con entreno en 4 semanas")
        }
    }

    @ViewBuilder
    private var freeCaloriesWeightPreview: some View {
        let sample = ProgressPreparedCharts.teaserSample(weekStartsOnMonday: mondayFirst)
        healthChartsLayout {
            ProgressCaloriesChartCard(prepared: sample)
            freeHealthWeightCard
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Gráficas de ejemplo de calorías y peso. No son datos reales.")
    }

    @ViewBuilder
    private var freeCardioPreview: some View {
        let sample = ProgressPreparedCharts.teaserSample(weekStartsOnMonday: mondayFirst)
        healthChartsLayout {
            ProgressCardioChartCard(prepared: sample, showZones: false)
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Gráfica de ejemplo de frecuencia cardíaca. No son datos reales.")
    }

    @MainActor
    private func refreshHealthForSelectedRange(reason: String) async {
        guard health.isAvailable else { return }
        let days = model.range.healthFetchDayCount
        let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
        let sessions = store.state.workouts
        ProgressLog.info("Progreso → refresh HK \(days)d")
        await Task.yield()
        await health.refreshRecentExternalActivities(
            excludingUUIDs: linked,
            overlappingSessions: sessions,
            days: days
        )
        if !Task.isCancelled {
            schedulePrepare(reason: reason)
        }
    }

    /// Sin calendario en el hub: gratis = 7 días; Pro = este mes (largo plazo embebido).
    private func applyHubRangePolicy() {
        let target: ProgressTimeRange = isPro ? .month : .week
        guard model.range != target else { return }
        model.setRange(target)
    }

    /// Solo tiempo confirmado mediante series reales: los objetivos sin completar no suman.
    @ViewBuilder
    private var mobilityProgressCard: some View {
        if snap.mobilitySessions > 0 {
            let timeLabel = snap.mobilitySeconds < 60
                ? "\(snap.mobilitySeconds) s"
                : "\(snap.mobilitySeconds / 60) min"
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Movilidad")
                ProgressInsightCard(
                    title: "Trabajo de movilidad",
                    systemImage: "figure.flexibility",
                    narrative: "Has registrado movilidad en \(snap.mobilitySessions) sesión\(snap.mobilitySessions == 1 ? "" : "es") del periodo.",
                    tint: Color(red: 0.55, green: 0.45, blue: 0.95)
                ) {
                    ProgressHeroMetricRow(
                        value: timeLabel,
                        unit: nil,
                        caption: "tiempo confirmado"
                    ) {
                        EmptyView()
                    }
                    if isPro {
                        ForEach(snap.chartExercises.filter(\.isMobility).prefix(3)) { exercise in
                            NavigationLink {
                                ExerciseProgressView(exerciseId: exercise.id)
                            } label: {
                                HStack {
                                    Text(SportExerciseNames.localizedDisplayName(exercise.name))
                                        .foregroundStyle(OG.label)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// El mapa y las barras musculares son gratuitos, sin filtros de suscripción.
    private var muscleBalanceCard: some View {
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
    }

    @ViewBuilder
    private var proAdvancedSections: some View {
        if isExpandedLayout {
            HStack(alignment: .top, spacing: 12) {
                exerciseSummarySection.frame(maxWidth: .infinity, alignment: .top)
                recordSummarySection.frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            exerciseSummarySection
            recordSummarySection
        }
    }

    @ViewBuilder
    private var exerciseSummarySection: some View {
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
    }

    @ViewBuilder
    private var recordSummarySection: some View {
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

    /// Una sola retícula para los gráficos de Actividad, tanto de Pro como
    /// de la previsualización gratuita. No permitir que diverjan en tamaños
    /// o separación al cambiar la suscripción.
    private func healthChartsLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if isExpandedLayout {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12, alignment: .top),
                    GridItem(.flexible(), spacing: 12, alignment: .top)
                ], spacing: 12) {
                    content()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
            }
        }
    }

    /// La puntuación deportiva vive junto al equilibrio muscular, no
    /// entre las mediciones diarias de Salud.
    @ViewBuilder
    private var trainingScoreAndMuscleSections: some View {
        if isExpandedLayout {
            HStack(alignment: .top, spacing: 12) {
                trainingScoreSection.frame(maxWidth: .infinity, alignment: .top)
                muscleBalanceCard.frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            trainingScoreSection
            muscleBalanceCard
        }
    }

    @ViewBuilder
    private var trainingScoreSection: some View {
        if isPro { sessionScoreSection } else { freeHealthScoreCard }
    }

    /// Solo actividades finalizadas, con zonas vinculadas a datos de Salud.
    /// En la modalidad gratuita la vista de ejemplo queda rotulada.
    @ViewBuilder
    private var trainingHeartZonesSection: some View {
        if !isPro || snap.filteredWorkouts.contains(where: { $0.finishedAt != nil }) {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Zonas cardíacas")
                OGCard {
                    ProgressHeartZonesCard(
                        workouts: snap.filteredWorkouts,
                        isTeaserPreview: !isPro,
                        showTitle: false
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var healthSections: some View {
        healthChartsLayout {
            cardioHealthSection
            caloriesHealthSection
            weightHealthSection
        }
        healthPermissionCard
    }

    @ViewBuilder
    private var sessionScoreSection: some View {
        // La gráfica real solo incorpora notas verificadas. Si no existen,
        // mantiene los ejes y explica la ausencia de datos.
        ProgressSessionScoreChartCard(
            workouts: snap.filteredWorkouts,
            range: model.range,
            weekStartsOnMonday: mondayFirst
        )
    }

    @ViewBuilder
    private var healthPermissionCard: some View {
        // El aviso de permisos no desplaza los cuatro gráficos de la cuadrícula.
        if !health.isAuthorized && health.recentDailyHeartRate.isEmpty
            && health.recentDailyActiveEnergy.isEmpty {
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

    private var cardioHealthSection: some View {
        ProgressCardioChartCard(
            prepared: snap.charts,
            workouts: snap.filteredWorkouts,
            showZones: false
        )
    }

    private var caloriesHealthSection: some View {
        ProgressCaloriesChartCard(prepared: snap.charts)
    }

    private var weightHealthSection: some View {
        ProgressWeightChartCard(
            entries: store.state.bodyWeights,
            goalKg: store.state.settings.bodyWeightGoalKg,
            range: model.range,
            weekStartsOnMonday: mondayFirst,
            preparedPoints: snap.range == model.range ? snap.weightPoints : nil
        )
    }

    @ViewBuilder
    private var freeActivityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Días activos")
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

    /// Gráfica demostrativa Pro: nunca lee registros ni marcas del usuario.
    private var freeExerciseTrendPreview: some View {
        let weights: [Double] = [42, 45, 44, 49, 47, 52, 55]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                OGCardSectionTitle(title: "Evolución por ejercicio")
                Spacer()
                Text("Ejemplo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
            OGCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Evolución de carga · datos ficticios")
                        .font(.footnote)
                        .foregroundStyle(OG.label3)
                    Chart {
                        ForEach(0..<weights.count, id: \.self) { index in
                            LineMark(
                                x: .value("Sesión", index + 1),
                                y: .value("Peso", weights[index])
                            )
                            .foregroundStyle(OG.accent)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }
                    .chartXScale(domain: 0...8)
                    .chartYScale(domain: 35.0...65.0)
                    .chartPlotStyle { $0.clipped() }
                    .chartXAxis {
                        AxisMarks(values: [1, 3, 5, 7]) { _ in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .frame(height: 195)
                    .allowsHitTesting(false)
                }
            }
        }
        .accessibilityLabel("Ejemplo de evolución por ejercicio, datos simulados.")
    }

    /// Preview free de Actividad: mismas tarjetas, columnas y tamaños que
    /// Pro; solo cambian los datos de ejemplo y la interacción desactivada.
    @ViewBuilder
    private var freeHealthPreview: some View {
        let sample = ProgressPreparedCharts.teaserSample(weekStartsOnMonday: mondayFirst)
        healthChartsLayout {
            ProgressCardioChartCard(prepared: sample, showZones: false)
            ProgressCaloriesChartCard(prepared: sample)
            freeHealthWeightCard
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Gráficas de ejemplo de frecuencia cardíaca, calorías y peso. No son datos reales.")
    }

    private var freeHealthScoreCard: some View {
        ProgressSessionScoreChartCard(
            workouts: [], range: .week,
            weekStartsOnMonday: mondayFirst, isTeaserPreview: true
        )
    }

    private var freeHealthWeightCard: some View {
        ProgressWeightChartCard(
            entries: [],
            goalKg: 74.0, // Meta ficticia de la previsualización.
            range: .week,
            weekStartsOnMonday: mondayFirst,
            preparedPoints: ProgressPreparedCharts.teaserWeightPoints(),
            isTeaserPreview: true
        )
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

    // MARK: - Activity

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Días activos")
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
        let listed = Array(snap.chartExercises.prefix(5))
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
                                    Text(SportExerciseNames.localizedDisplayName(ex.name))
                                        .foregroundStyle(OG.label)
                                    Spacer()
                                    if let maxW = tops[ex.id] {
                                        Text("\(ReperaNumberFormat.decimal(maxW)) kg")
                                            .font(.system(size: 13).monospacedDigit())
                                            .foregroundStyle(OG.label2)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            if ex.id != listed.last?.id || snap.chartExercises.count > 5 {
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                        }
                        if snap.chartExercises.count > 5 {
                            NavigationLink {
                                ProgressAllExercisesView(exercises: snap.chartExercises, tops: tops)
                            } label: {
                                HStack {
                                    Text("Ver más")
                                        .foregroundStyle(OG.accent)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(OG.accent)
                                }
                            }
                            .accessibilityLabel("Ver todos los ejercicios")
                        }
                    }
                }
            }
        }
    }

    private var prSection: some View {
        // Récords únicos del periodo, pero primero los logrados más recientemente.
        let recentRecords = snap.records.sorted {
            $0.date == $1.date
                ? $0.estimatedOneRM > $1.estimatedOneRM
                : $0.date > $1.date
        }
        let listed = Array(recentRecords.prefix(5))
        return VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Récords (e1RM)")
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    if snap.records.isEmpty {
                        Text("Sin PRs en este periodo.")
                            .foregroundStyle(OG.label2)
                    } else {
                        ForEach(listed) { pr in
                            NavigationLink {
                                ExerciseDetailView(exerciseId: pr.exerciseId)
                            } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(SportExerciseNames.localizedDisplayName(pr.exerciseName))
                                        .foregroundStyle(OG.label)
                                    Text(SpanishDate.format(pr.date, date: .abbreviated, time: .omitted))
                                        .font(.system(size: 12))
                                        .foregroundStyle(OG.label2)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(ReperaNumberFormat.decimal(pr.weightKg))×\(pr.reps)")
                                        .monospacedDigit()
                                        .foregroundStyle(OG.label)
                                    Text("~\(ReperaNumberFormat.decimal(pr.estimatedOneRM, maximumFractionDigits: 0)) kg")
                                        .font(.system(size: 12))
                                        .foregroundStyle(OG.label2)
                                }
                            }
                            }
                            .buttonStyle(.plain)
                            if pr.id != listed.last?.id || snap.records.count > 5 {
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                        }
                        if snap.records.count > 5 {
                            NavigationLink {
                                ProgressAllRecordsView(records: recentRecords)
                            } label: {
                                HStack {
                                    Text("Ver más")
                                        .foregroundStyle(OG.accent)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(OG.accent)
                                }
                            }
                            .accessibilityLabel("Ver todos los récords")
                        }
                    }
                }
            }
        }
    }
}

/// Listados completos de la selección actual del periodo. Se abren como
/// páginas push nativas y no recrean / limitan los datos al navegar.
private struct ProgressAllExercisesView: View {
    let exercises: [Exercise]
    let tops: [UUID: Double]

    var body: some View {
        List {
            OGScrollablePageTitle("Progreso por ejercicio").ogScrollingTitleListRow()
            ForEach(exercises) { ex in
                NavigationLink {
                    ExerciseProgressView(exerciseId: ex.id)
                } label: {
                    HStack(spacing: 10) {
                        Text(SportExerciseNames.localizedDisplayName(ex.name))
                            .foregroundStyle(OG.label)
                        Spacer(minLength: 6)
                        if let maxW = tops[ex.id] {
                            Text("\(ReperaNumberFormat.decimal(maxW)) kg")
                                .font(.system(size: 13).monospacedDigit())
                                .foregroundStyle(OG.label2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
    }
}

private struct ProgressAllRecordsView: View {
    let records: [PersonalRecord]
    @State private var selectedExerciseID: UUID?

    var body: some View {
        List {
            OGScrollablePageTitle("Récords (e1RM)").ogScrollingTitleListRow()
            ForEach(records) { pr in
                Button {
                    selectedExerciseID = pr.exerciseId
                } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SportExerciseNames.localizedDisplayName(pr.exerciseName))
                            .foregroundStyle(OG.label)
                        Text(SpanishDate.format(pr.date, date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(ReperaNumberFormat.decimal(pr.weightKg))×\(pr.reps)")
                            .monospacedDigit()
                            .foregroundStyle(OG.label)
                        Text("~\(ReperaNumberFormat.decimal(pr.estimatedOneRM, maximumFractionDigits: 0)) kg")
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label2)
                    }
                }
                .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .ogListChrome()
        .navigationDestination(item: $selectedExerciseID) { id in
            ExerciseDetailView(exerciseId: id)
        }
        .ogScrollingTitleNav()
    }
}

/// Evolución de notas verificadas de entrenos. Nunca reintroduce puntuaciones
/// heurísticas antiguas: solo `personalHistory` persistido en cada sesión.
private struct ProgressSessionScoreChartCard: View {
    @State private var selectedDate: Date?
    var workouts: [WorkoutSession]
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var isTeaserPreview: Bool = false

    private struct ScoreDay: Identifiable {
        let date: Date
        let score: Double
        let segment: Int
        var id: Date { date }
    }

    private var points: [ScoreDay] {
        let calendar = Calendar.current
        if isTeaserPreview {
            let today = calendar.startOfDay(for: Date())
            let scores: [Double] = [6, 7, 7, 8, 6, 8, 9]
            return (0..<scores.count).compactMap { index in
                guard let date = calendar.date(byAdding: .day, value: index - 6, to: today) else {
                    return nil
                }
                return ScoreDay(date: date, score: scores[index], segment: 0)
            }
        }
        let rated: [(Date, Double)] = workouts.compactMap { session in
            guard let finishedAt = session.finishedAt,
                  let review = session.sessionReview,
                  review.scoreBasis == .personalHistory else { return nil }
            return (calendar.startOfDay(for: finishedAt), Double(review.overallScore))
        }
        let byDay = Dictionary(grouping: rated, by: { $0.0 })
        var previous: Date?
        var segment = 0
        return byDay.keys.sorted().compactMap { day in
            guard let scores = byDay[day], !scores.isEmpty else { return nil }
            if let previous, (calendar.dateComponents([.day], from: previous, to: day).day ?? 0) > 1 {
                segment += 1
            }
            previous = day
            return ScoreDay(
                date: day,
                score: (scores.reduce(0.0) { $0 + $1.1 } / Double(scores.count)).rounded(),
                segment: segment
            )
        }
    }

    private var latestConfidenceLabel: String? {
        let rated = workouts.filter {
            $0.finishedAt != nil && $0.sessionReview?.scoreBasis == .personalHistory
        }
        guard let latest = rated.max(by: {
            ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        }) else { return nil }
        return latest.sessionReview?.confidenceLabel
    }

    @ViewBuilder
    private var scoreSummary: some View {
        let values = points
        let average = values.isEmpty ? nil :
            Int((values.map(\.score).reduce(0, +) / Double(values.count)).rounded())
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 9) {
                    scoreMetric("Última nota", value: values.last.map { "\(Int($0.score))/10" } ?? "—")
                    scoreMetric("Mejor nota", value: values.map(\.score).max().map { "\(Int($0))/10" } ?? "—")
                    scoreMetric("Días evaluados", value: "\(values.count)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle().stroke(OG.surface3, lineWidth: 9)
                    if let average {
                        Circle()
                            .trim(from: 0, to: Double(average) / 10)
                            .stroke(OG.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    VStack(spacing: 1) {
                        Text(average.map { String($0) } ?? "—")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(OG.label)
                        Text("de 10")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(OG.label2)
                    }
                }
                .frame(width: 112, height: 112)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(average.map {
                    "Puntuación media de entrenamiento \($0) de 10"
                } ?? "Puntuación pendiente de aprendizaje")
            }
            // Mantener el mismo componente y geometría también en la tarjeta
            // gratuita; la propia tarjeta ya marca las métricas como «Ejemplo».
            TrainingScoreConfidenceBar(
                label: isTeaserPreview ? "Media" : latestConfidenceLabel,
                caption: "Confianza",
                compactInProgress: true,
                showSelectedLevelInCaption: true
            )
        }
        .padding(.bottom, 4)
    }

    private func scoreMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label2)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        let values = points
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                OGCardSectionTitle(title: "Último entreno")
                Spacer(minLength: 8)
                if isTeaserPreview {
                    Text("Ejemplo")
                        .font(.caption)
                        .foregroundStyle(OG.label2)
                }
            }
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
                    scoreSummary
                    if values.isEmpty {
                        ProgressEmptyChart(
                            message: "Repera está aprendiendo de ti. Completa al menos 2 días previos comparables y registra un 60% de rendimiento evaluable.",
                            height: 205,
                            yRange: 0.0...10.0
                        )
                    } else {
                        Chart {
                            ForEach(values) { point in
                                LineMark(
                                    x: .value("Día", point.date),
                                    y: .value("Puntuación", point.score),
                                    series: .value("Tramo observado", point.segment)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .foregroundStyle(OG.accent)
                                PointMark(
                                    x: .value("Día", point.date),
                                    y: .value("Puntuación", point.score)
                                )
                                .symbolSize(22)
                                .foregroundStyle(OG.accent)
                            }
                            if !isTeaserPreview, let selectedDate,
                               let selected = values.min(by: {
                                   abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
                               }) {
                                RuleMark(x: .value("Día seleccionado", selected.date))
                                    .foregroundStyle(OG.label2)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                                    .annotation(position: .top) {
                                        Text("\(Int(selected.score.rounded()))/10")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(OG.label)
                                            .padding(5)
                                            .background(OG.surface, in: RoundedRectangle(cornerRadius: 6))
                                    }
                            }
                        }
                        .chartXSelection(value: $selectedDate)
                        .chartXScale(domain: ProgressChartAxis.xDomain(
                            points: values.map(\.date),
                            range: range,
                            weekStartsOnMonday: weekStartsOnMonday,
                            isTeaserPreview: isTeaserPreview
                        ))
                        .chartYScale(domain: 0.0...10.0)
                        .chartPlotStyle { $0.clipped() }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [0.0, 5.0, 10.0])
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine()
                                AxisValueLabel(
                                    format: Date.FormatStyle()
                                        .day()
                                        .month(.abbreviated)
                                        .locale(SpanishDate.appLocale)
                                )
                            }
                        }
                        .frame(height: 205)
                        .allowsHitTesting(!isTeaserPreview)
                        if !isTeaserPreview {
                            Text("Media diaria de notas basadas en tu historial comparable.")
                                .font(.caption)
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
            }
        }
    }
}
