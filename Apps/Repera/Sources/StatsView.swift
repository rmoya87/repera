import Charts
import HealthKit
import ReperaDomain
import SwiftUI
import UIKit

struct StatsView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = ProgressViewModel()
    @State private var heatmapMetric: HeatmapMetric = .time
    @State private var category: ProgressCategory = .training
    @State private var isExpandedLayout = false
    /// Nota de preparación (0…10) para el chip Recuperación; nil = sin evidencia.
    @State private var recoveryGlanceScore: Int?

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
            .onAppear {
                ReperaAnalytics.track(.progressSectionViewed, parameters: [
                    "feature_area": "progress", "section_name": category.rawValue
                ])
            }
            .onChange(of: category) { _, selected in
                ReperaAnalytics.track(.progressSectionViewed, parameters: [
                    "feature_area": "progress", "section_name": selected.rawValue
                ])
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("repera.openProgressRecovery")
            )) { _ in
                category = .recovery
            }
            .task {
                applyHubRangePolicy()
                schedulePrepare(reason: "initial")
                refreshRecoveryGlance()
                if BusinessAuthStore.shared.isConnected {
                    await BusinessDataStore.shared.refresh()
                    schedulePrepare(reason: "classes-ready")
                    // Tras entitlements B2B, reaplicar rango Pro si acaba de desbloquearse.
                    applyHubRangePolicy()
                }
                guard health.isAvailable else {
                    ProgressLog.info("Progreso: HealthKit no disponible")
                    schedulePrepare(reason: "no-health")
                    return
                }
                await refreshHealthForSelectedRange(reason: "hk-ready")
                await HealthRecoveryStore.shared.refresh()
                await HealthPhysiologyStore.shared.refresh()
                refreshRecoveryGlance()
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
                refreshRecoveryGlance()
            }
            .onChange(of: BusinessDataStore.shared.progressDataRevision) { _, _ in
                model.invalidateCache(reason: "class-attendance")
                schedulePrepare(reason: "class-attendance")
            }
            .onChange(of: store.state.syncRevision) { _, _ in
                model.invalidateCache(reason: "sync-rev")
                schedulePrepare(reason: "sync-rev")
                refreshRecoveryGlance()
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
            return "Últimos 7 días"
        case .heart, .recovery:
            return "Ahora"
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
            // Misma métrica que Estímulo activo: media diaria de los últimos 7 días (no total ni mes).
            let total = fitnessReperaMinutes + fitnessExternalMinutes
            let avg = Self.dailyAverageMinutes(total: total)
            return avg > 0 ? Self.compactActiveDuration(avg) : "—"
        case .heart:
            if let bpm = health.recentDailyHeartRate.last?.avgBpm, bpm > 0 {
                return "\(Int(bpm.rounded()))"
            }
            return "—"
        case .recovery:
            if let score = recoveryGlanceScore {
                return "\(score)"
            }
            return "—"
        case .sports:
            let count = sportsActivityCount
            return count > 0 ? "\(count)" : "—"
        }
    }

    private var hubPeriodCaption: String { "últimos 7 días" }

    /// Resumen de mes calendario (estilo Apple Salud), aunque el hub esté en 7 días.
    private var calendarMonthSummary: ProgressHealthSummary {
        StatsEngine.progressHealthSummary(
            workouts: store.state.workouts,
            external: HealthMuscleMapper.daySamples(from: health.recentExternalActivities),
            range: .month,
            weekStartsOnMonday: mondayFirst
        )
    }

    private var calendarMonthHeartPoints: [HealthKitStore.DailyHeartRatePoint] {
        let now = Date()
        return health.recentDailyHeartRate.filter {
            ProgressTimeRange.month.contains($0.date, now: now, weekStartsOnMonday: mondayFirst)
                && $0.avgBpm > 0
        }
        .sorted { $0.date < $1.date }
    }

    private var calendarMonthHeartAvgBpm: Int? {
        let monthPoints = calendarMonthHeartPoints
        guard !monthPoints.isEmpty else { return nil }
        let avg = monthPoints.map(\.avgBpm).reduce(0, +) / Double(monthPoints.count)
        return avg > 0 ? Int(avg.rounded()) : nil
    }

    /// Media de las medias semanales del mes (días con FC; no inventa ceros).
    private var calendarMonthHeartWeeklyAvgBpm: Int? {
        let points = calendarMonthHeartPoints
        guard !points.isEmpty else { return nil }
        let cal = Calendar.current
        var weeks: [Date: [Double]] = [:]
        for point in points {
            let weekStart = StatsEngine.startOfWeek(
                containing: point.date,
                calendar: {
                    var c = cal
                    c.firstWeekday = mondayFirst ? 2 : 1
                    return c
                }()
            )
            weeks[weekStart, default: []].append(point.avgBpm)
        }
        let weekAvgs = weeks.values.map { vals in vals.reduce(0, +) / Double(vals.count) }
        guard !weekAvgs.isEmpty else { return nil }
        let avg = weekAvgs.reduce(0, +) / Double(weekAvgs.count)
        return avg > 0 ? Int(avg.rounded()) : nil
    }

    private var heartMonthSparkSamples: [ClosedRange<Double>] {
        Self.heartRangeSamples(from: calendarMonthHeartPoints)
    }

    private var calendarMonthSportSessions: [WorkoutSession] {
        store.state.workouts.filter {
            $0.phase == .finished && $0.finishedAt != nil && $0.liveSportID != nil
                && ProgressTimeRange.month.contains(
                    $0.startedAt ?? $0.finishedAt ?? .distantPast,
                    weekStartsOnMonday: mondayFirst
                )
        }
    }

    /// Salidas En vivo dentro del periodo del hub (semana o mes).
    private var sportsInHub: [WorkoutSession] {
        snap.filteredWorkouts.filter { $0.liveSportID != nil }
    }

    private var sportsActivityCount: Int { sportsInHub.count }

    private var sportsHubMinutes: Int {
        Int(sportsInHub.reduce(0.0) { $0 + max(0, $1.durationMinutes) }.rounded())
    }

    private var plannedWorkoutCount: Int {
        snap.filteredWorkouts.filter { $0.routineId != nil }.count
    }

    private var fitnessReperaMinutes: Int {
        Int(snap.filteredWorkouts.reduce(0.0) { $0 + max(0, $1.durationMinutes) }.rounded())
    }

    private var fitnessExternalMinutes: Int {
        Int(snap.filteredExternal.reduce(0.0) { $0 + max(0, $1.minutes) }.rounded())
    }

    /// Progresiones e1RM = mejores marcas / historial completo (no limitado a 7 días).
    private var exerciseProgressDeltas: [(id: UUID, name: String, ratio: Double)] {
        var rows: [(id: UUID, name: String, ratio: Double)] = []
        let workouts = store.state.workouts
        for exercise in snap.chartExercises.prefix(40) {
            let points = StatsEngine.exerciseProgressSeries(
                exerciseId: exercise.id,
                metric: .estimatedOneRM,
                range: .all,
                workouts: workouts,
                catalog: snap.chartExercises
            )
            guard let first = points.first?.value, let last = points.last?.value,
                  points.count >= 2, first > 0, last > first * 1.01
            else { continue }
            rows.append((id: exercise.id, name: exercise.name, ratio: last / first))
        }
        return rows.sorted { lhs, rhs in lhs.ratio > rhs.ratio }
    }

    private var improvedExerciseCount: Int { exerciseProgressDeltas.count }

    /// Minutos En vivo por día en el hub (últimos 7 días).
    private var sportsDailySparkSamples: [ClosedRange<Double>] {
        sportsSparkSamples(from: sportsInHub)
    }

    /// Evolución En vivo / récords: historial completo (mejores marcas no limitadas a 7 días).
    private var sportsEvolutionSparkSamples: [ClosedRange<Double>] {
        let allLive = store.state.workouts.filter { $0.liveSportID != nil && $0.finishedAt != nil }
        return sportsSparkSamples(from: allLive)
    }

    private func sportsSparkSamples(from sessions: [WorkoutSession]) -> [ClosedRange<Double>] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.startedAt ?? session.finishedAt ?? Date())
            byDay[day, default: 0] += max(0, session.durationMinutes)
        }
        let ordered = byDay.filter { $0.value > 0 }.sorted { $0.key < $1.key }.suffix(14)
        guard let peak = ordered.map(\.value).max(), peak > 0 else { return [] }
        return ordered.map { entry in
            let hi = max(0.12, min(1.0, entry.value / peak))
            return 0...hi
        }
    }

    private func refreshRecoveryGlance() {
        let recovery = HealthRecoveryStore.shared
        let physiology = HealthPhysiologyStore.shared
        let calendar = Calendar.current
        let now = Date()
        let sleepHours: Double? = {
            guard recovery.sleepEnabled else { return nil }
            return recovery.nights.last { calendar.isDate($0.date, inSameDayAs: now) }?.hours
        }()
        let workouts = store.state.workouts.filter { $0.finishedAt != nil }
        let external = health.recentExternalActivities.map {
            RecoveryEngine.ObservedActivity(
                date: $0.end,
                durationMinutes: $0.durationMinutes,
                isCardio: HealthMuscleMapper.isCardio($0.activityType)
            )
        }
        let readiness = RecoveryEngine.trainingReadiness(
            at: now,
            sleepHours: sleepHours,
            recentAverageSleepHours: recovery.averageHours,
            workouts: workouts,
            vitalHistory: physiology.days,
            observedActivities: external
        )
        recoveryGlanceScore = readiness.map { Int($0.score.rounded()) }
    }

    /// Formato compacto para chips: `45′`, `1 h`, `1 h 20`.
    /// `nonisolated` + `fileprivate`: puro, usable desde `MonthActivityBucket` (fuera del MainActor).
    nonisolated fileprivate static func compactActiveDuration(_ minutes: Int) -> String {
        guard minutes > 0 else { return "—" }
        if minutes < 60 { return "\(minutes)′" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m)"
    }

    /// Valor + unidad del héroe de estímulo (≥60 min → horas y minutos). Unidad corta «m».
    private static func activeDurationHero(_ minutes: Int) -> (value: String, unit: String?) {
        guard minutes > 0 else { return ("—", nil) }
        if minutes < 60 { return ("\(minutes)", "m") }
        let h = minutes / 60
        let m = minutes % 60
        if m == 0 { return ("\(h)", "h") }
        return ("\(h) h \(m)", "m")
    }

    /// Media diaria = minutos totales / 7 (ventana fija; días sin estímulo cuentan como 0 min).
    private static func dailyAverageMinutes(total: Int, days: Int = 7) -> Int {
        guard total > 0, days > 0 else { return 0 }
        return Int((Double(total) / Double(days)).rounded())
    }

    /// Media por semana en el mes calendario = total / (días transcurridos / 7).
    private static func weeklyAverageMinutes(total: Int, daysElapsedInMonth: Int) -> Int {
        guard total > 0 else { return 0 }
        let weeks = max(1.0, Double(max(1, daysElapsedInMonth)) / 7.0)
        return Int((Double(total) / weeks).rounded())
    }

    private func activeDurationNarrative(averageDaily: Int) -> String {
        guard averageDaily > 0 else {
            return "Cuando camines o entrenes, verás aquí tu estímulo."
        }
        // Con dato el héroe + caption bastan; no repetir la media en narrativa.
        return ""
    }

    /// Minutos/día (Repera + Salud) en la ventana de 7 días; huecos = 0 sin inventar fisiología.
    private var fitnessDailyMinutesLast7: [Double] {
        dailyStimulusMinutes(range: .week)
    }

    private var fitnessMonthDailyMinutes: [Double] {
        dailyStimulusMinutes(range: .month)
    }

    private func dailyStimulusMinutes(range: ProgressTimeRange) -> [Double] {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        guard let start = range.startDate(now: now, weekStartsOnMonday: mondayFirst) else { return [] }
        var byDay: [Date: Double] = [:]
        let workouts: [WorkoutSession]
        let external: [ExternalDaySample]
        if range == .week {
            workouts = snap.filteredWorkouts
            external = snap.filteredExternal
        } else {
            workouts = store.state.workouts.filter {
                ($0.finishedAt != nil || $0.phase == .finished)
                    && range.contains($0.startedAt ?? $0.finishedAt ?? .distantPast,
                                     now: now, weekStartsOnMonday: mondayFirst)
            }
            external = HealthMuscleMapper.daySamples(from: health.recentExternalActivities)
                .filter { range.contains($0.date, now: now, weekStartsOnMonday: mondayFirst) }
        }
        for workout in workouts {
            let day = cal.startOfDay(for: workout.startedAt ?? workout.finishedAt ?? now)
            // Reloj de pared (no duración Salud/Watch outlier) para barras de estímulo.
            byDay[day, default: 0] += max(0, workout.displayDurationMinutes)
        }
        for sample in external {
            let day = cal.startOfDay(for: sample.date)
            byDay[day, default: 0] += max(0, sample.minutes)
        }
        var values: [Double] = []
        var cursor = start
        while cursor <= today {
            values.append(byDay[cursor] ?? 0)
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return values
    }

    private func minuteBarSamples(_ minutes: [Double]) -> [ClosedRange<Double>] {
        let active = minutes.filter { $0 > 0 }
        guard !active.isEmpty else { return [] }
        // Escala por percentil alto (no el pico outlier) para que varios días se vean.
        let sorted = active.sorted()
        let p90Index = min(sorted.count - 1, Int(Double(sorted.count - 1) * 0.9))
        let scale = max(sorted[p90Index], 1)
        return minutes.map { m in
            if m <= 0 { return 0...0.08 }
            let hi = max(0.18, min(1.0, m / scale))
            return 0...hi
        }
    }

    private var daysElapsedInCalendarMonth: Int {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        guard let start = ProgressTimeRange.month.startDate(
            now: now, weekStartsOnMonday: mondayFirst
        ) else { return 1 }
        return max(1, (cal.dateComponents([.day], from: start, to: today).day ?? 0) + 1)
    }

    @ViewBuilder
    private var categoryContent: some View {
        Group {
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
                VStack(alignment: .leading, spacing: 12) {
                    HealthRecoveryProgressView(
                        range: .week,
                        weekStartsOnMonday: mondayFirst,
                        usesExpandedLayout: isExpandedLayout
                    )
                    recoveryMonthSummaryCard
                }
            case .sports:
                sportsCategoryContent
            }
        }
        .id(category)
        .ogChartAppear()
    }

    @ViewBuilder
    private var trainingCategoryContent: some View {
        trainingScoreAndMuscleSections
        thisWeekConsistencyCard
        trainingGlanceMetricsGrid
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

    /// Media mes / Racha / Entrenos / Tiempo — métricas de mes calendario (tras «Últimos 7 días»).
    private var trainingGlanceMetricsGrid: some View {
        let summary = calendarMonthSummary
        let avg = trainingMonthAverageScoreText
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
            ProgressMetricGlanceCard(title: "Media mes", value: avg)
            ProgressMetricGlanceCard(title: "Racha", value: snap.streak > 0 ? "\(snap.streak) sem" : "—")
            ProgressMetricGlanceCard(title: "Entrenos", value: "\(summary.sessionCount)")
            ProgressMetricGlanceCard(title: "Tiempo", value: timeText)
        }
    }

    private var trainingMonthAverageScoreText: String {
        let scores = store.state.workouts.compactMap { session -> Int? in
            guard let when = session.finishedAt ?? session.startedAt,
                  ProgressTimeRange.month.contains(when, weekStartsOnMonday: mondayFirst),
                  let review = session.sessionReview, review.scoreBasis == .personalHistory
            else { return nil }
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
            OGCardSectionTitle(title: "Últimos 7 días")
            ProgressInsightCard(
                title: "Consistencia",
                systemImage: "calendar",
                narrative: trained == 0
                    ? "Aún no hay entrenos registrados en los últimos 7 días."
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
        let trainedDays: Set<Date> = Set(store.state.workouts.compactMap { session in
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
        let volumeKg = Int(snap.summary.volumeKg.rounded())
        OGCardSectionTitle(title: "Fuerza")
        if (prCount > 0 || volumeKg > 0), !strengthSparkSamples.isEmpty {
            ProgressInsightElevatedCard(
                title: "Carga y marcas",
                systemImage: ProgressCategory.strength.systemImage,
                tint: ProgressCategory.strength.accent,
                value: prCount > 0 ? "\(prCount)" : "—",
                unit: prCount > 0 ? "PR" : nil,
                caption: volumeKg > 0
                    ? "\(ReperaNumberFormat.integer(volumeKg)) kg / 7 d"
                    : nil,
                valuePointSize: 64,
                chartHeight: 118,
                chartBesideTitle: true
            ) {
                // Área/spark distinta de las barras de estímulo y del rango de FC.
                ProgressMiniAreaSpark(
                    fractions: strengthSparkSamples.map(\.upperBound),
                    tint: ProgressCategory.strength.accent,
                    height: 118
                )
                .accessibilityLabel("Carga diaria, últimos 7 días")
            }
        } else {
            ProgressInsightCard(
                title: "Carga y marcas",
                systemImage: ProgressCategory.strength.systemImage,
                narrative: strengthInsightCopy,
                tint: ProgressCategory.strength.accent
            ) {
                ProgressHeroMetricRow(
                    value: "—",
                    unit: nil,
                    caption: "sin marcas aún",
                    valuePointSize: 64
                ) {
                    EmptyView()
                }
            }
        }
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ProgressMetricGlanceCard(
                title: "Sesiones fuerza",
                value: strengthGlanceSessions > 0 ? "\(strengthGlanceSessions)" : "—",
                tint: ProgressCategory.strength.accent
            )
            ProgressMetricGlanceCard(
                title: "Ejercicios",
                value: strengthGlanceExercises > 0 ? "\(strengthGlanceExercises)" : "—",
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

    /// Sesiones del hub (últimos 7 días) con series de fuerza confirmadas — no caminatas ni En vivo.
    private var strengthGlanceSessions: Int {
        snap.filteredWorkouts.filter { workout in
            (workout.finishedAt != nil || workout.phase == .finished)
                && workout.exercises.contains { entry in
                    !entry.exercise.isMobility
                        && !StatsEngine.confirmedWorkSets(entry, in: workout).isEmpty
                }
        }.count
    }

    /// Ejercicios distintos practicados en esas sesiones de fuerza del hub (no historial all-time).
    private var strengthGlanceExercises: Int {
        var ids = Set<UUID>()
        for workout in snap.filteredWorkouts
        where workout.finishedAt != nil || workout.phase == .finished {
            for entry in workout.exercises where !entry.exercise.isMobility {
                guard !StatsEngine.confirmedWorkSets(entry, in: workout).isEmpty else { continue }
                ids.insert(entry.exercise.id)
            }
        }
        return ids.count
    }

    /// Barras = volumen kg por día en los últimos 7 días.
    /// Escala logarítmica respecto al pico: un día con ~10 % del pico sigue
    /// leyéndose ~alto; evita que un outlier aplasté el resto de la curva.
    private var strengthSparkSamples: [ClosedRange<Double>] {
        let volumes = strengthDailyVolumeLast7
        guard let peak = volumes.max(), peak > 0 else { return [] }
        let logPeak = log1p(peak)
        return volumes.map { vol in
            guard vol > 0, logPeak > 0 else { return 0...0.08 }
            let hi = max(0.16, min(1.0, log1p(vol) / logPeak))
            return 0...hi
        }
    }

    /// Volumen confirmado por día (hoy − 6 … hoy).
    private var strengthDailyVolumeLast7: [Double] {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        guard let start = ProgressTimeRange.week.startDate(
            now: now, weekStartsOnMonday: mondayFirst
        ) else { return [] }
        var byDay: [Date: Double] = [:]
        for workout in snap.filteredWorkouts
        where workout.finishedAt != nil || workout.phase == .finished {
            guard let raw = workout.finishedAt ?? workout.startedAt else { continue }
            let day = cal.startOfDay(for: raw)
            byDay[day, default: 0] += max(0, StatsEngine.confirmedVolumeKg(in: workout))
        }
        var values: [Double] = []
        var cursor = cal.startOfDay(for: start)
        while cursor <= today {
            values.append(byDay[cursor] ?? 0)
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return values
    }

    /// Actividades de hoy desde Repera y Salud, sin duplicar el mismo registro.
    private var trainingSessionsToday: Int {
        let today = Date()
        let logged = store.state.workouts.filter {
            $0.finishedAt.map { Calendar.current.isDate($0, inSameDayAs: today) } == true
                && $0.timerDetails == nil
        }.count
        let external = HealthMuscleMapper.uniqueExternalActivities(
            health.recentExternalActivities, workouts: store.state.workouts
        ).filter { Calendar.current.isDate($0.end, inSameDayAs: today) }.count
        return logged + external
    }

    private var strengthInsightCopy: String {
        let prCount = snap.records.count
        let volumeKg = Int(snap.summary.volumeKg.rounded())
        if prCount == 0 && volumeKg == 0 {
            let count = trainingSessionsToday
            return count > 0
                ? "\(count) actividades hoy. La carga en kg requiere series y pesos registrados; tu tiempo de entrenamiento sí cuenta."
                : "Cuando registres series de fuerza, verás aquí la carga y tus marcas."
        }
        return ""
    }

    @ViewBuilder
    private var fitnessCategoryContent: some View {
        // Estímulo del hub = solo ventana de 7 días (filteredWorkouts/External), no el resumen de mes.
        let minutes = fitnessReperaMinutes + fitnessExternalMinutes
        let averageDaily = Self.dailyAverageMinutes(total: minutes)
        let hero = Self.activeDurationHero(averageDaily)
        let spark = minuteBarSamples(fitnessDailyMinutesLast7)
        OGCardSectionTitle(title: "Físico")
        if averageDaily > 0, !spark.isEmpty {
            ProgressInsightElevatedCard(
                title: "Estímulo activo",
                systemImage: ProgressCategory.fitness.systemImage,
                tint: ProgressCategory.fitness.accent,
                value: hero.value,
                unit: hero.unit,
                caption: "media diaria",
                valuePointSize: 64,
                chartHeight: 118,
                chartBesideTitle: true
            ) {
                ProgressMiniFillBars(
                    fractions: spark.map(\.upperBound),
                    tint: ProgressCategory.fitness.accent,
                    height: 118
                )
                .accessibilityLabel("Minutos de estímulo por día, últimos 7 días")
            }
        } else {
            ProgressInsightCard(
                title: "Estímulo activo",
                systemImage: ProgressCategory.fitness.systemImage,
                narrative: activeDurationNarrative(averageDaily: averageDaily),
                tint: ProgressCategory.fitness.accent
            ) {
                ProgressHeroMetricRow(
                    value: hero.value,
                    unit: hero.unit,
                    caption: averageDaily > 0 ? "media diaria" : nil,
                    valuePointSize: 64
                ) {
                    EmptyView()
                }
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
                title: "Físico completo",
                bodyText: "Calorías, peso y tendencias largas con Repera Pro.",
                cta: "Descubrir Repera Pro",
                appearance: .activity
            ) {
                subscriptions.presentPaywall(.progress, feature: .advancedProgress)
            }
        }
        fitnessMonthSummaryCard
    }

    @ViewBuilder
    private var heartCategoryContent: some View {
        let bpm = health.recentDailyHeartRate.last?.avgBpm
        let bpmText = bpm.map { "\(Int($0.rounded()))" } ?? "—"
        OGCardSectionTitle(title: "Corazón")
        if bpm != nil, !heartSparkSamples.isEmpty {
            ProgressInsightElevatedCard(
                title: "Frecuencia cardíaca",
                systemImage: ProgressCategory.heart.systemImage,
                tint: ProgressCategory.heart.accent,
                value: bpmText,
                unit: "LPM",
                caption: "media reciente",
                valuePointSize: 64,
                chartHeight: 72,
                chartAlignsBottom: false
            ) {
                // A la derecha: cápsulas redondeadas levitando entre mín–máx (nunca desde 0).
                ProgressMiniRangeBars(
                    samples: heartSparkSamples,
                    tint: ProgressCategory.heart.accent,
                    height: 72
                )
                .accessibilityLabel("Rango diario de frecuencia cardíaca")
            }
        } else {
            ProgressInsightCard(
                title: "Frecuencia cardíaca",
                systemImage: ProgressCategory.heart.systemImage,
                narrative: heartInsightCopy,
                tint: ProgressCategory.heart.accent
            ) {
                ProgressHeroMetricRow(
                    value: bpmText,
                    unit: nil,
                    caption: nil,
                    valuePointSize: 64
                ) {
                    EmptyView()
                }
            }
        }
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ProgressMetricGlanceCard(
                title: "Mín. 7 d",
                value: heartExtremeText(minimum: true),
                tint: ProgressCategory.heart.accent
            )
            ProgressMetricGlanceCard(
                title: "Máx. 7 d",
                value: heartExtremeText(minimum: false),
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
        heartMonthSummaryCard
    }

    private var heartInsightCopy: String {
        if let bpm = health.recentDailyHeartRate.last?.avgBpm, bpm > 0 {
            return ""
        }
        return "Conecta Salud o un pulsómetro para ver tu ritmo aquí."
    }

    /// Barras reales mín–máx por día (HealthKit), últimos 7 días. Vacío si no hay muestras.
    private var heartPointsLast7Days: [HealthKitStore.DailyHeartRatePoint] {
        let now = Date()
        return health.recentDailyHeartRate.filter {
            ProgressTimeRange.week.contains($0.date, now: now, weekStartsOnMonday: mondayFirst)
        }
    }

    private var heartSparkSamples: [ClosedRange<Double>] {
        Self.heartRangeSamples(from: heartPointsLast7Days)
    }

    /// Normaliza lpm min–máx → Y 0…1. El suelo del plot NO es 0 lpm: es dominioLo (p.ej. 40).
    /// Así un día 58…120 flota a media altura; no nace en el eje X.
    private static func heartRangeSamples(
        from points: [HealthKitStore.DailyHeartRatePoint]
    ) -> [ClosedRange<Double>] {
        let valid = points.filter { $0.minBpm > 0 && $0.maxBpm > 0 && $0.maxBpm >= $0.minBpm }
        guard !valid.isEmpty else { return [] }
        let dataMin = valid.map(\.minBpm).min() ?? 50
        let dataMax = valid.map(\.maxBpm).max() ?? 160
        // Dominio holgado (estilo Salud): el mín del periodo queda claramente por encima del eje.
        let domainLo = min(dataMin - 12, dataMin * 0.85)
        let domainHi = max(dataMax + 12, dataMin + 40)
        let span = max(domainHi - domainLo, 1)
        return valid.map { p in
            let lo = (p.minBpm - domainLo) / span
            let hi = (p.maxBpm - domainLo) / span
            return min(max(lo, 0.04), 0.9)...max(min(hi, 0.98), min(max(lo, 0.04), 0.9) + 0.08)
        }
    }

    private func heartExtremeText(minimum: Bool) -> String {
        let points = heartPointsLast7Days
        guard !points.isEmpty else { return "—" }
        let values = points.map { minimum ? $0.minBpm : $0.maxBpm }.filter { $0 > 0 }
        guard let extreme = minimum ? values.min() : values.max() else { return "—" }
        return "\(Int(extreme.rounded()))"
    }

    @ViewBuilder
    private var sportsCategoryContent: some View {
        let sportCount = sportsActivityCount
        let sportMins = sportsHubMinutes
        let improved = improvedExerciseCount
        let planned = plannedWorkoutCount
        let evolutionBars = sportsEvolutionSparkSamples
        let allLiveMins = Int(
            store.state.workouts
                .filter { $0.liveSportID != nil && $0.finishedAt != nil }
                .reduce(0.0) { $0 + max(0, $1.durationMinutes) }
                .rounded()
        )
        OGCardSectionTitle(title: "Deportes")
        OGCard {
            // Icono alineado a la 1.ª línea del título; datos a la derecha.
            HStack(alignment: .top, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: ProgressCategory.sports.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ProgressCategory.sports.accent)
                        .symbolRenderingMode(.hierarchical)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] * 0.72 }
                        .accessibilityHidden(true)
                    Text("Actividad\ndeportiva")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ProgressCategory.sports.accent)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .center, spacing: 10) {
                    Text(sportCount > 0 ? "\(sportCount)" : "—")
                        .ogFont(52, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                        .monospacedDigit()
                        .foregroundStyle(OG.label)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(sportCount > 0 ? Self.compactActiveDuration(sportMins) : "—")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(OG.label2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("salidas")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label2)
                            .lineLimit(1)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                sportCount > 0
                    ? "Actividad deportiva, \(sportCount) salidas, \(Self.compactActiveDuration(sportMins))"
                    : "Actividad deportiva sin salidas En vivo"
            )
        }
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ProgressMetricGlanceCard(
                title: "Ejercicios al alza",
                value: improved > 0 ? "\(improved)" : "—",
                tint: ProgressCategory.sports.accent
            )
            ProgressMetricGlanceCard(
                title: "Del plan",
                value: planned > 0 ? "\(planned)" : "—",
                tint: ProgressCategory.sports.accent
            )
        }
        NavigationLink {
            LiveSportsCatalogView()
        } label: {
            ProgressInsightCard(
                title: "Evolución y récords",
                systemImage: "chart.line.uptrend.xyaxis",
                narrative: allLiveMins == 0
                    ? "Registra salidas En vivo para ver evolución y récords."
                    : "",
                tint: ProgressCategory.sports.accent,
                showsChevron: true
            ) {
                if evolutionBars.isEmpty {
                    ProgressHeroMetricRow(
                        value: "—",
                        unit: nil,
                        caption: nil
                    ) {
                        EmptyView()
                    }
                } else {
                    ProgressHeroMetricRow(
                        value: Self.compactActiveDuration(allLiveMins),
                        unit: nil,
                        caption: nil
                    ) {
                        ProgressMiniRangeBars(
                            samples: evolutionBars,
                            tint: ProgressCategory.sports.accent,
                            height: CGFloat(max(36, min(56, 28 + evolutionBars.count * 2)))
                        )
                        .frame(width: CGFloat(max(88, min(132, evolutionBars.count * 10))))
                        .accessibilityLabel("Minutos de deporte por día")
                    }
                }
            }
        }
        .buttonStyle(.plain)
        if improved > 0 {
            // Mismo patrón de héroe grande que «Este mes · Resumen por actividad».
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "arrow.up.right")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ProgressCategory.strength.accent)
                                .symbolRenderingMode(.hierarchical)
                                .alignmentGuide(.firstTextBaseline) { $0[.bottom] * 0.72 }
                                .accessibilityHidden(true)
                            Text("Progresión en\nejercicios")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ProgressCategory.strength.accent)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(improved)")
                                .ogFont(52, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                                .monospacedDigit()
                                .foregroundStyle(OG.label)
                                .minimumScaleFactor(0.55)
                                .lineLimit(1)
                            Text("al alza")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(OG.label2)
                                .lineLimit(1)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Progresión en ejercicios, \(improved) al alza")

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(exerciseProgressDeltas.prefix(5).enumerated()), id: \.element.id) { _, row in
                            let pct = Int(((row.ratio - 1) * 100).rounded())
                            HStack {
                                Text(row.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(OG.label)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Text("+\(pct)%")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ProgressCategory.strength.accent)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Mejoras de e1RM por ejercicio")
                }
            }
        }
        sportsMonthSummaryCard
    }

    /// Bloque «Este mes» estilo Apple Salud: cierre narrativo aunque el hub mire 7 días.
    @ViewBuilder
    private var fitnessMonthSummaryCard: some View {
        let month = calendarMonthSummary
        let minutes = Int(month.totalMinutes.rounded())
        let weeklyAvg = Self.weeklyAverageMinutes(
            total: minutes,
            daysElapsedInMonth: daysElapsedInCalendarMonth
        )
        let hero = Self.activeDurationHero(weeklyAvg)
        let spark = minuteBarSamples(fitnessMonthDailyMinutes)
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Este mes")
            if minutes > 0, !spark.isEmpty {
                ProgressInsightElevatedCard(
                    title: "Actividad del mes",
                    systemImage: ProgressCategory.fitness.systemImage,
                    tint: ProgressCategory.fitness.accent,
                    value: hero.value,
                    unit: hero.unit,
                    caption: "media semana",
                    valuePointSize: 54,
                    chartHeight: 108,
                    chartBesideTitle: true
                ) {
                    ProgressMiniFillBars(
                        fractions: spark.map(\.upperBound),
                        tint: ProgressCategory.fitness.accent,
                        height: 108
                    )
                    .accessibilityLabel("Minutos de estímulo por día este mes")
                }
            } else {
                ProgressInsightCard(
                    title: "Actividad del mes",
                    systemImage: ProgressCategory.fitness.systemImage,
                    narrative: minutes > 0
                        ? ""
                        : "Cuando registres actividad este mes, verás aquí el resumen.",
                    tint: ProgressCategory.fitness.accent
                ) {
                    ProgressHeroMetricRow(
                        value: hero.value,
                        unit: hero.unit,
                        caption: minutes > 0 ? "media semana" : nil,
                        valuePointSize: 54
                    ) {
                        EmptyView()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var heartMonthSummaryCard: some View {
        let avg = calendarMonthHeartAvgBpm
        let weekly = calendarMonthHeartWeeklyAvgBpm
        let spark = heartMonthSparkSamples
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Este mes")
            if (weekly ?? avg) != nil, !spark.isEmpty {
                ProgressInsightElevatedCard(
                    title: "Cardio del mes",
                    systemImage: ProgressCategory.heart.systemImage,
                    tint: ProgressCategory.heart.accent,
                    value: weekly.map(String.init) ?? avg.map(String.init) ?? "—",
                    unit: "LPM",
                    caption: "media/semana",
                    valuePointSize: 54,
                    chartHeight: 72,
                    chartAlignsBottom: false
                ) {
                    ProgressMiniRangeBars(
                        samples: spark,
                        tint: ProgressCategory.heart.accent,
                        height: 72
                    )
                    .accessibilityLabel("Progresión de frecuencia cardíaca del mes")
                }
            } else {
                ProgressInsightCard(
                    title: "Cardio del mes",
                    systemImage: ProgressCategory.heart.systemImage,
                    narrative: (weekly ?? avg) == nil
                        ? "Con más lecturas de pulso este mes verás aquí la media."
                        : "",
                    tint: ProgressCategory.heart.accent
                ) {
                    ProgressHeroMetricRow(
                        value: weekly.map(String.init) ?? avg.map(String.init) ?? "—",
                        unit: (weekly ?? avg) == nil ? nil : "LPM",
                        caption: (weekly ?? avg) == nil ? nil : "media/semana",
                        valuePointSize: 54
                    ) {
                        EmptyView()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recoveryMonthSummaryCard: some View {
        let cal = Calendar.current
        let now = Date()
        let nights = HealthRecoveryStore.shared.nights.filter {
            ProgressTimeRange.month.contains($0.date, now: now, calendar: cal, weekStartsOnMonday: mondayFirst)
        }
        let avgHours: Double? = {
            guard !nights.isEmpty else { return nil }
            return nights.map(\.hours).reduce(0, +) / Double(nights.count)
        }()
        let weeklyRows: [(label: String, avg: String, nights: Int)] = {
            guard let monthStart = ProgressTimeRange.month.startDate(
                now: now, weekStartsOnMonday: mondayFirst
            ) else { return [] }
            var rows: [(String, String, Int)] = []
            var cursor = monthStart
            var weekIndex = 1
            while cursor <= now, weekIndex <= 6 {
                let weekEnd = min(
                    cal.date(byAdding: .day, value: 6, to: cursor) ?? cursor,
                    cal.startOfDay(for: now)
                )
                let inWeek = nights.filter { $0.date >= cursor && $0.date <= weekEnd }
                let avg: String = {
                    guard !inWeek.isEmpty else { return "—" }
                    let h = inWeek.map(\.hours).reduce(0, +) / Double(inWeek.count)
                    return "\(ReperaNumberFormat.decimal(h)) h"
                }()
                rows.append(("Sem \(weekIndex)", avg, inWeek.count))
                guard let next = cal.date(byAdding: .day, value: 7, to: cursor) else { break }
                cursor = next
                weekIndex += 1
            }
            return rows
        }()
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Este mes")
            ProgressInsightCard(
                title: "Descanso del mes",
                systemImage: ProgressCategory.recovery.systemImage,
                narrative: nights.isEmpty
                    ? "Cuando Salud registre sueño este mes, verás aquí el resumen de descanso."
                    : "",
                tint: ProgressCategory.recovery.accent
            ) {
                HStack(alignment: .top, spacing: 14) {
                    ProgressHeroMetricRow(
                        value: avgHours.map { ReperaNumberFormat.decimal($0) } ?? "—",
                        unit: avgHours == nil ? nil : "h",
                        caption: nights.isEmpty ? "sin noches aún" : "media del mes"
                    ) {
                        EmptyView()
                    }
                    if !weeklyRows.isEmpty {
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack {
                                Text("Semana")
                                    .frame(width: 52, alignment: .leading)
                                Text("Media")
                                    .frame(width: 48, alignment: .trailing)
                                Text("Noches")
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(OG.label3)
                            ForEach(Array(weeklyRows.enumerated()), id: \.offset) { _, row in
                                HStack {
                                    Text(row.label)
                                        .frame(width: 52, alignment: .leading)
                                    Text(row.avg)
                                        .frame(width: 48, alignment: .trailing)
                                        .monospacedDigit()
                                    Text("\(row.nights)")
                                        .frame(width: 44, alignment: .trailing)
                                        .monospacedDigit()
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(OG.label2)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Media y noches registradas por semana")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sportsMonthSummaryCard: some View {
        let sessions = calendarMonthSportSessions
        let minutes = Int(sessions.reduce(0.0) { $0 + max(0, $1.durationMinutes) }.rounded())
        let highlights = monthActivityHighlights
        let salidaCount = max(sessions.count, highlights.isEmpty ? 0 : highlights.reduce(0) { $0 + $1.sessionCount })
        let hasData = !sessions.isEmpty || !highlights.isEmpty
        VStack(alignment: .leading, spacing: 8) {
            OGCardSectionTitle(title: "Este mes")
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: ProgressCategory.sports.systemImage)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ProgressCategory.sports.accent)
                                .symbolRenderingMode(.hierarchical)
                                .alignmentGuide(.firstTextBaseline) { $0[.bottom] * 0.72 }
                                .accessibilityHidden(true)
                            Text("Resumen por\nactividad")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ProgressCategory.sports.accent)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center, spacing: 10) {
                            Text(hasData ? "\(salidaCount)" : "—")
                                .ogFont(52, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                                .monospacedDigit()
                                .foregroundStyle(OG.label)
                                .minimumScaleFactor(0.55)
                                .lineLimit(1)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(hasData ? Self.compactActiveDuration(minutes) : "—")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(OG.label2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("salidas")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(OG.label2)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        hasData
                            ? "Resumen por actividad, \(salidaCount) salidas, \(Self.compactActiveDuration(minutes))"
                            : "Resumen por actividad sin datos"
                    )

                    if highlights.isEmpty && sessions.isEmpty {
                        Text("Cuando registres salidas o actividades este mes, verás aquí el resumen.")
                            .font(.subheadline)
                            .foregroundStyle(OG.label2)
                    }

                    if !highlights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(highlights.prefix(6)) { row in
                                HStack(alignment: .center, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.title)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(OG.label)
                                            .lineLimit(2)
                                        Text("\(row.sessionCount)× · \(row.bestLine)")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(OG.label3)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(row.primaryValue)
                                        .ogFont(28, weight: .bold, design: .rounded, relativeTo: .title)
                                        .monospacedDigit()
                                        .foregroundStyle(OG.label)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Resumen de actividades del mes")
                    }
                }
            }
        }
    }

    /// Totales + mejor marca del mes por deporte En vivo y por actividad de Salud.
    private var monthActivityHighlights: [MonthActivityHighlight] {
        var buckets: [String: MonthActivityBucket] = [:]
        let now = Date()
        for session in calendarMonthSportSessions {
            guard let id = session.liveSportID, let sport = LiveSport(rawValue: id) else { continue }
            let key = "live:\(id)"
            var bucket = buckets[key] ?? MonthActivityBucket(
                title: sport.title,
                symbol: sport.symbol,
                prefersDistance: sport.usesGPS
            )
            bucket.add(
                minutes: max(0, session.durationMinutes),
                meters: session.recordedDistanceMeters
            )
            buckets[key] = bucket
        }
        for activity in health.recentExternalActivities where ProgressTimeRange.month.contains(
            activity.start, now: now, weekStartsOnMonday: mondayFirst
        ) {
            let type = activity.activityType
            let key = "hk:\(type.rawValue)"
            let prefersDistance = activity.distanceMeters.map { $0 > 0 } ?? false
            var bucket = buckets[key] ?? MonthActivityBucket(
                title: Self.healthActivityTitle(type),
                symbol: HealthActivityIcons.symbolName(for: type),
                prefersDistance: prefersDistance
            )
            if activity.distanceMeters != nil { bucket.prefersDistance = true }
            bucket.add(minutes: max(0, activity.durationMinutes), meters: activity.distanceMeters)
            buckets[key] = bucket
        }
        return buckets.values
            .map { $0.highlight() }
            .sorted {
                if $0.sortMeters != $1.sortMeters { return $0.sortMeters > $1.sortMeters }
                return $0.sortMinutes > $1.sortMinutes
            }
    }

    private static func healthActivityTitle(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Fuerza"
        case .functionalStrengthTraining: return "Fuerza funcional"
        case .highIntensityIntervalTraining: return "HIIT"
        case .running: return "Carrera"
        case .walking: return "Caminar"
        case .cycling: return "Ciclismo"
        case .swimming: return "Natación"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .hiking: return "Senderismo"
        case .rowing: return "Remo"
        case .elliptical: return "Elíptica"
        case .stairClimbing: return "Escaleras"
        case .dance: return "Baile"
        case .mixedCardio: return "Cardio"
        case .crossTraining: return "Cross-training"
        default: return "Actividad · Salud"
        }
    }

    nonisolated fileprivate static func compactDistance(_ meters: Double) -> String {
        guard meters > 0 else { return "—" }
        if meters < 1000 { return "\(Int(meters.rounded())) m" }
        return "\(ReperaNumberFormat.decimal(meters / 1000)) km"
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

    /// Sin calendario en el hub: ventana fija Últimos 7 días (mes solo en bloques «Este mes» / Media mes).
    private func applyHubRangePolicy() {
        let target: ProgressTimeRange = .week
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
                    tint: ProgressCategory.fitness.accent
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
                title: "Sin récords aún",
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
            workouts: store.state.workouts,
            range: model.range,
            weekStartsOnMonday: mondayFirst,
            externalActivities: HealthMuscleMapper.uniqueExternalActivities(
                health.recentExternalActivities, workouts: store.state.workouts
            )
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
                    .ogChartAppear()
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
                        Text("Sin ejercicios registrados aún.")
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
                        Text("Sin PRs aún.")
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
                                        .ogNumericText(
                                            value: "\(pr.weightKg)-\(pr.reps)",
                                            reduceMotion: reduceMotion
                                        )
                                    Text("~\(ReperaNumberFormat.decimal(pr.estimatedOneRM, maximumFractionDigits: 0)) kg")
                                        .font(.system(size: 12))
                                        .foregroundStyle(OG.label2)
                                        .ogNumericText(
                                            value: pr.estimatedOneRM,
                                            reduceMotion: reduceMotion
                                        )
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
    @State private var selectedRecentWorkoutIndex: Int?
    var workouts: [WorkoutSession]
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var isTeaserPreview: Bool = false
    var externalActivities: [HealthKitStore.ExternalActivity] = []

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
                  range.contains(finishedAt, weekStartsOnMonday: weekStartsOnMonday),
                  session.timerDetails == nil,
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

    /// Incluye todos los entrenamientos realizados, también Comenzar y Watch
    /// sin series ni puntuación comparable. No contabiliza temporizadores.
    private struct RecentActivity {
        let title: String
        let endedAt: Date
        let durationMinutes: Int
        let activeEnergyKcal: Double?
        let averageHeartRateBpm: Double?
        let hasVerifiedScore: Bool
    }

    private var latestActivity: RecentActivity? {
        let recorded = workouts.filter { $0.finishedAt != nil && $0.timerDetails == nil }
            .max { ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast) }
        let external = externalActivities.max { $0.end < $1.end }
        if let external, external.end > (recorded?.finishedAt ?? .distantPast) {
            return RecentActivity(
                title: external.title, endedAt: external.end,
                durationMinutes: Int(external.durationMinutes.rounded()),
                activeEnergyKcal: external.activeEnergyKcal,
                averageHeartRateBpm: nil,
                hasVerifiedScore: false
            )
        }
        guard let recorded, let endedAt = recorded.finishedAt else { return nil }
        return RecentActivity(
            title: recorded.title, endedAt: endedAt,
            durationMinutes: Int(recorded.durationMinutes.rounded()),
            activeEnergyKcal: recorded.appleActiveEnergyKcal,
            averageHeartRateBpm: recorded.appleAverageHeartRateBpm,
            hasVerifiedScore: recorded.sessionReview?.scoreBasis == .personalHistory
        )
    }

    /// Últimas sesiones con nota personal verificada (eje 0–10).
    /// Una marca por entreno puntuado; no agrega por día ni inventa notas.
    private struct RecentScoredWorkout: Identifiable {
        let id: String
        let title: String
        let finishedAt: Date
        let verifiedScore: Int
    }

    private var recentScoredWorkouts: [RecentScoredWorkout] {
        let logged: [RecentScoredWorkout] = workouts.compactMap { session in
            guard let ended = session.finishedAt, session.timerDetails == nil,
                  let review = session.sessionReview,
                  review.scoreBasis == .personalHistory else { return nil }
            return RecentScoredWorkout(
                id: session.id.uuidString,
                title: session.title,
                finishedAt: ended,
                verifiedScore: review.overallScore
            )
        }
        return Array(logged.sorted { $0.finishedAt > $1.finishedAt }.prefix(7).reversed())
    }

    @ViewBuilder
    private var sevenWorkoutChart: some View {
        let recent = recentScoredWorkouts
        if recent.isEmpty {
            ProgressEmptyChart(
                message: "Cuando tengas notas verificadas de entrenos aparecerán aquí (0–10).",
                height: 205, yRange: 0.0...10.0
            )
        } else {
            Chart {
                ProgressChartYOverlay.marks(
                    values: [0.0, 5.0, 10.0],
                    domainLow: 0.0
                )
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, item in
                    LineMark(
                        x: .value("Entreno", index + 1),
                        y: .value("Puntuación", Double(item.verifiedScore))
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(OG.accent)
                    PointMark(
                        x: .value("Entreno", index + 1),
                        y: .value("Puntuación", Double(item.verifiedScore))
                    )
                    .symbolSize(28)
                    .foregroundStyle(OG.accent)
                    .accessibilityLabel("\(item.title), \(item.verifiedScore) de 10")
                }
                if let selectedRecentWorkoutIndex,
                   recent.indices.contains(selectedRecentWorkoutIndex - 1) {
                    let item = recent[selectedRecentWorkoutIndex - 1]
                    RuleMark(x: .value("Entreno seleccionado", selectedRecentWorkoutIndex))
                        .foregroundStyle(OG.label2)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    PointMark(
                        x: .value("Entreno seleccionado", selectedRecentWorkoutIndex),
                        y: .value("Puntuación", Double(item.verifiedScore))
                    )
                    .foregroundStyle(OG.accent)
                    .symbolSize(56)
                }
            }
            .chartXSelection(value: $selectedRecentWorkoutIndex)
            // 1…N con aire para caps redondos; revelado L→R del plot.
            .chartXScale(
                domain: 1...max(1, recent.count),
                range: .plotDimension(startPadding: 4, endPadding: 4)
            )
            .progressChartYScale(domain: 0.0...10.0)
            .progressChartSelectionBadge(
                x: selectedRecentWorkoutIndex.flatMap { recent.indices.contains($0 - 1) ? $0 : nil },
                y: selectedRecentWorkoutIndex.flatMap { idx -> Double? in
                    recent.indices.contains(idx - 1) ? Double(recent[idx - 1].verifiedScore) : nil
                },
                text: selectedRecentWorkoutIndex.flatMap { idx -> String? in
                    guard recent.indices.contains(idx - 1) else { return nil }
                    let item = recent[idx - 1]
                    return "\(item.verifiedScore)/10 · \(item.finishedAt.formatted(Date.FormatStyle().day().month(.abbreviated).locale(SpanishDate.appLocale)))"
                }
            )
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: Array(1...recent.count))
            }
            .frame(height: 180)
            .ogChartReveal(.line)
            .accessibilityLabel("Últimos \(recent.count) entrenos puntuados de 0 a 10")
        }
    }

    private var latestConfidenceLabel: String? {
        latestVerifiedReviewSession?.sessionReview?.confidenceLabel
    }

    /// Última sesión del periodo con nota personal verificada (defiende el anillo).
    private var latestVerifiedReviewSession: WorkoutSession? {
        workouts.filter {
            guard let finished = $0.finishedAt, $0.timerDetails == nil,
                  $0.sessionReview?.scoreBasis == .personalHistory else { return false }
            return range.contains(finished, weekStartsOnMonday: weekStartsOnMonday)
        }.max(by: {
            ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        })
    }

    private var latestEffortGlance: (relative: String, coverage: String, references: String) {
        if isTeaserPreview {
            return ("+5 %", "80 %", "4")
        }
        guard let review = latestVerifiedReviewSession?.sessionReview else {
            return ("—", "—", "—")
        }
        let relative: String = {
            guard let pct = review.relativeChangePercent else { return "—" }
            return pct > 0 ? "+\(pct) %" : "\(pct) %"
        }()
        let coverage: String = {
            guard let raw = review.evidenceCoverage else { return "—" }
            return "\(Int((raw * 100).rounded())) %"
        }()
        let references: String = {
            if let days = review.referenceDays, days > 0 { return "\(days)" }
            let fromIndicators = review.indicators
                .filter { $0.score != nil }
                .map(\.referenceSessions)
                .filter { $0 > 0 }
                .min()
            return fromIndicators.map(String.init) ?? "—"
        }()
        return (relative, coverage, references)
    }

    @ViewBuilder
    private var scoreSummary: some View {
        let values = points
        let average = values.isEmpty ? nil :
            Int((values.map(\.score).reduce(0, +) / Double(values.count)).rounded())
        let effort = latestEffortGlance
        VStack(alignment: .leading, spacing: 12) {
            if !isTeaserPreview, let latest = latestActivity {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Actividad")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(OG.label2)
                    Text(latest.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                    Text("\(latest.endedAt.formatted(Date.FormatStyle().day().month(.abbreviated).hour().minute().locale(SpanishDate.appLocale))) · \(latest.durationMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(OG.label2)
                    HStack(spacing: 8) {
                        if let kcal = latest.activeEnergyKcal, kcal > 0 {
                            Text("\(Int(kcal.rounded())) kcal")
                        }
                        if let bpm = latest.averageHeartRateBpm, bpm > 0 {
                            Text("\(Int(bpm.rounded())) lpm")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(OG.label2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 9) {
                    scoreMetric("Rendimiento", value: effort.relative)
                    scoreMetric("Referencias", value: effort.references)
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
                    if !isTeaserPreview {
                        sevenWorkoutChart
                    } else if values.isEmpty {
                        ProgressEmptyChart(
                            message: "Repera está aprendiendo de ti. Completa al menos 2 días previos comparables y registra un 60% de rendimiento evaluable.",
                            height: 205,
                            yRange: 0.0...10.0
                        )
                    } else {
                        Chart {
                            ProgressChartYOverlay.marks(
                                values: [0.0, 5.0, 10.0],
                                domainLow: 0.0
                            )
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
                                PointMark(
                                    x: .value("Día seleccionado", selected.date),
                                    y: .value("Puntuación", selected.score)
                                )
                                .foregroundStyle(OG.accent)
                                .symbolSize(56)
                            }
                        }
                        .chartXSelection(value: $selectedDate)
                        .chartXScale(
                            domain: ProgressChartAxis.xDomain(
                                points: values.map(\.date),
                                range: range,
                                weekStartsOnMonday: weekStartsOnMonday,
                                isTeaserPreview: isTeaserPreview
                            ),
                            range: .plotDimension(startPadding: 4, endPadding: 4)
                        )
                        .progressChartYScale(domain: 0.0...10.0)
                        .progressChartSelectionBadge(
                            x: {
                                guard !isTeaserPreview, let selectedDate else { return nil as Date? }
                                return values.min(by: {
                                    abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
                                })?.date
                            }(),
                            y: {
                                guard !isTeaserPreview, let selectedDate else { return nil as Double? }
                                return values.min(by: {
                                    abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
                                })?.score
                            }(),
                            text: {
                                guard !isTeaserPreview, let selectedDate,
                                      let selected = values.min(by: {
                                          abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
                                      }) else { return nil as String? }
                                return "\(Int(selected.score.rounded()))/10"
                            }()
                        )
                        .chartPlotStyle { $0.clipped() }
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine()
                                AxisValueLabel(
                                    format: Date.FormatStyle()
                                        .day()
                                        .month(.abbreviated)
                                        .locale(SpanishDate.appLocale)
                                )
                                .foregroundStyle(OG.label2)
                                .font(.system(size: 10))
                            }
                        }
                        .frame(height: 205)
                        .ogChartReveal(.line)
                        .allowsHitTesting(!isTeaserPreview)
                        if !isTeaserPreview {
                            Text("Media diaria de notas basadas en tu historial comparable.")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
                    }
                }
            }
        }
    }
}

/// Fila del resumen «Este mes» por actividad (Deportes).
private struct MonthActivityHighlight: Identifiable {
    var id: String { title + primaryValue + bestLine }
    var title: String
    var symbol: String
    var sessionCount: Int
    /// Dato grande a la derecha (km o duración).
    var primaryValue: String
    var bestLine: String
    var sortMeters: Double
    var sortMinutes: Double
}

private struct MonthActivityBucket {
    var title: String
    var symbol: String
    var prefersDistance: Bool
    var sessionCount = 0
    var totalMinutes = 0.0
    var totalMeters = 0.0
    var bestMinutes = 0.0
    var bestMeters = 0.0

    mutating func add(minutes: Double, meters: Double?) {
        sessionCount += 1
        totalMinutes += minutes
        bestMinutes = max(bestMinutes, minutes)
        if let meters, meters > 0 {
            totalMeters += meters
            bestMeters = max(bestMeters, meters)
        }
    }

    func highlight() -> MonthActivityHighlight {
        let useDistance = prefersDistance && totalMeters > 0
        let primaryValue: String
        let bestLine: String
        if useDistance {
            primaryValue = StatsView.compactDistance(totalMeters)
            bestLine = "Más larga · \(StatsView.compactDistance(bestMeters))"
        } else {
            primaryValue = StatsView.compactActiveDuration(Int(totalMinutes.rounded()))
            bestLine = "Más larga · \(StatsView.compactActiveDuration(Int(bestMinutes.rounded())))"
        }
        return MonthActivityHighlight(
            title: title,
            symbol: symbol,
            sessionCount: sessionCount,
            primaryValue: primaryValue,
            bestLine: bestLine,
            sortMeters: totalMeters,
            sortMinutes: totalMinutes
        )
    }
}
