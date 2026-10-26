import Foundation
import ReperaDomain

/// Cache / invalidation key for a prepared Progress period.
struct ProgressDataKey: Hashable, Sendable {
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var syncRevision: Int
    var healthDataRevision: Int
    var bodyWeightRevision: Int
}

/// Stable weight plot point (id = bucket date, never random UUID).
struct ProgressWeightPoint: Identifiable, Equatable, Sendable {
    var id: Date { date }
    var date: Date
    var weightKg: Double
}

/// Immutable, ready-to-draw payload for one Progress period.
struct ProgressSnapshot: Equatable, Sendable {
    var key: ProgressDataKey
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var charts: ProgressPreparedCharts
    var summary: ProgressHealthSummary
    var previousSummary: ProgressHealthSummary?
    var streak: Int
    /// Racha calculada al cierre de la semana anterior (para delta del tile).
    var previousStreak: Int
    var averageHeartRate: Double?
    var previousAverageHeartRate: Double?
    var records: [PersonalRecord]
    var muscleLoadAll: [String: Double]
    var muscleLoadHard: [String: Double]
    /// Fatiga retenida (vida media) para el BodyMap — independiente del ranking por series.
    var muscleFatigueAll: [String: Double]
    var muscleFatigueHard: [String: Double]
    var hasHardSets: Bool
    var heatmapTime: HeatmapGrid
    var heatmapVolume: HeatmapGrid
    var weightPoints: [ProgressWeightPoint]
    var chartExercises: [Exercise]
    /// Movilidad realmente registrada, no la duración prescrita de una plantilla.
    var mobilitySessions: Int
    var mobilitySeconds: Int
    var topExerciseMaxWeights: [UUID: Double]
    var filteredWorkouts: [WorkoutSession]
    var filteredExternal: [ExternalDaySample]
    var filteredStimuli: [ExternalMuscleStimulus]

    static func empty(range: ProgressTimeRange = .week, weekStartsOnMonday: Bool = true) -> ProgressSnapshot {
        ProgressSnapshot(
            key: ProgressDataKey(
                range: range,
                weekStartsOnMonday: weekStartsOnMonday,
                syncRevision: -1,
                healthDataRevision: -1,
                bodyWeightRevision: -1
            ),
            range: range,
            weekStartsOnMonday: weekStartsOnMonday,
            charts: .empty,
            summary: ProgressHealthSummary(
                averageMinutes: nil,
                totalKcal: 0,
                averageCardioMinutes: nil,
                volumeKg: 0,
                sessionCount: 0
            ),
            previousSummary: nil,
            streak: 0,
            previousStreak: 0,
            averageHeartRate: nil,
            previousAverageHeartRate: nil,
            records: [],
            muscleLoadAll: [:],
            muscleLoadHard: [:],
            muscleFatigueAll: [:],
            muscleFatigueHard: [:],
            hasHardSets: false,
            heatmapTime: .empty,
            heatmapVolume: .empty,
            weightPoints: [],
            chartExercises: [],
            mobilitySessions: 0,
            mobilitySeconds: 0,
            topExerciseMaxWeights: [:],
            filteredWorkouts: [],
            filteredExternal: [],
            filteredStimuli: []
        )
    }
}

/// Raw inputs copied off the MainActor before heavy prep.
struct ProgressBuildInput: Sendable {
    var key: ProgressDataKey
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var workouts: [WorkoutSession]
    var exercises: [Exercise]
    var bodyWeights: [BodyWeightEntry]
    var heartRateDays: [HealthKitStore.DailyHeartRatePoint]
    var energyDays: [HealthKitStore.DailyActiveEnergyPoint]
    var externalActivities: [HealthKitStore.ExternalActivity]
    var now: Date
}

enum ProgressDataEngine {
    /// Full period prep. Call from a cancellable detached task; check `Task.isCancelled` between phases.
    static func build(_ input: ProgressBuildInput) -> ProgressSnapshot? {
        if Task.isCancelled { return nil }

        let monday = input.weekStartsOnMonday
        let range = input.range
        let now = input.now

        var cal = Calendar.current
        cal.firstWeekday = monday ? 2 : 1

        let externalSamples = HealthMuscleMapper.daySamples(from: input.externalActivities)
        let stimuli = HealthMuscleMapper.stimuli(from: input.externalActivities)
        if Task.isCancelled { return nil }

        let filteredWorkouts = StatsEngine.filterWorkouts(
            input.workouts,
            range: range,
            weekStartsOnMonday: monday,
            now: now
        )
        let filteredExternal = StatsEngine.filterExternal(
            externalSamples,
            range: range,
            weekStartsOnMonday: monday,
            now: now
        )
        let filteredStimuli = StatsEngine.filterStimuli(
            stimuli,
            range: range,
            weekStartsOnMonday: monday,
            now: now
        )
        if Task.isCancelled { return nil }

        let charts = ProgressChartBuilder.build(
            range: range,
            weekStartsOnMonday: monday,
            heartRateDays: input.heartRateDays,
            energyDays: input.energyDays,
            workouts: filteredWorkouts,
            // El gráfico filtra por fecha internamente. Conservamos aquí
            // el histórico externo necesario para comparar el periodo previo.
            external: externalSamples,
            now: now
        )
        if Task.isCancelled { return nil }

        let baseSummary = StatsEngine.progressHealthSummary(
            workouts: input.workouts,
            external: externalSamples,
            range: range,
            weekStartsOnMonday: monday,
            now: now
        )
        // Kcal alineadas con Inicio / gráfica Calorías (max Salud día vs chips).
        let summary = ProgressHealthSummary(
            averageMinutes: baseSummary.averageMinutes,
            totalKcal: charts.caloriesTotal,
            averageCardioMinutes: baseSummary.averageCardioMinutes,
            volumeKg: baseSummary.volumeKg,
            sessionCount: baseSummary.sessionCount
        )
        let prevWorkouts = StatsEngine.filterWorkoutsInPreviousPeriod(
            input.workouts,
            range: range,
            weekStartsOnMonday: monday,
            now: now
        )
        let prevExternal = externalSamples.filter {
            range.containsInPreviousPeriod($0.date, now: now, weekStartsOnMonday: monday)
        }
        let basePrevious = StatsEngine.progressHealthSummary(
            workouts: prevWorkouts,
            external: prevExternal,
            range: range,
            weekStartsOnMonday: monday,
            now: now,
            applyRangeFilter: false
        )
        let previousSummary: ProgressHealthSummary? = {
            guard let bounds = range.previousPeriodBounds(
                now: now,
                weekStartsOnMonday: monday
            ) else {
                return basePrevious
            }
            let prevEnergy = input.energyDays.filter {
                range.containsInPreviousPeriod($0.date, now: now, weekStartsOnMonday: monday)
            }
            let prevKcal = ProgressChartBuilder.mergedDailyCalories(
                energyDays: prevEnergy,
                workouts: prevWorkouts,
                external: prevExternal,
                start: bounds.start,
                endExclusive: bounds.end
            ).reduce(0.0) { $0 + $1.value }
            return ProgressHealthSummary(
                averageMinutes: basePrevious.averageMinutes,
                totalKcal: prevKcal,
                averageCardioMinutes: basePrevious.averageCardioMinutes,
                volumeKg: basePrevious.volumeKg,
                sessionCount: basePrevious.sessionCount
            )
        }()
        if Task.isCancelled { return nil }

        // Rachas, calendario y filtro de Progreso atribuyen «Comenzar»
        // al día de inicio, incluso si la sesión termina después de medianoche.
        let workoutDates = input.workouts.compactMap { workout in
            workout.liveSportID == nil
                ? (workout.finishedAt ?? workout.startedAt)
                : (workout.startedAt ?? workout.finishedAt)
        }
        let externalDates = input.externalActivities.map(\.start)
        let streak = StatsEngine.consecutiveWeekStreak(
            workoutDates: workoutDates,
            externalDates: externalDates,
            weekStartsOnMonday: monday,
            now: now
        )
        let previousStreak: Int = {
            guard let priorWeek = cal.date(byAdding: .day, value: -7, to: now) else { return 0 }
            return StatsEngine.consecutiveWeekStreak(
                workoutDates: workoutDates,
                externalDates: externalDates,
                weekStartsOnMonday: monday,
                now: priorWeek
            )
        }()

        let prevAvgHr: Double? = {
            let pts = input.heartRateDays.filter {
                range.containsInPreviousPeriod($0.date, now: now, weekStartsOnMonday: monday)
            }
            guard !pts.isEmpty else { return nil }
            return pts.map(\.avgBpm).reduce(0, +) / Double(pts.count)
        }()

        let records = StatsEngine.personalRecords(from: filteredWorkouts)
        if Task.isCancelled { return nil }

        let muscleAll = MuscleLoadEngine.load(
            workouts: filteredWorkouts,
            external: filteredStimuli,
            window: .all,
            weekStartsOnMonday: monday,
            now: now,
            hardOnly: false
        )
        let muscleHard = MuscleLoadEngine.load(
            workouts: filteredWorkouts,
            external: filteredStimuli,
            window: .all,
            weekStartsOnMonday: monday,
            now: now,
            hardOnly: true
        )
        // Fatiga con decaimiento desde `now` (solo estímulos del periodo filtrado).
        let muscleFatigueAll = MuscleMapEngine.retainedLoad(
            workouts: filteredWorkouts,
            external: filteredStimuli,
            hardOnly: false,
            now: now
        )
        let muscleFatigueHard = MuscleMapEngine.retainedLoad(
            workouts: filteredWorkouts,
            external: filteredStimuli,
            hardOnly: true,
            now: now
        )
        let hasHardSets = filteredWorkouts.contains { session in
            session.exercises.contains { entry in
                !entry.exercise.isMobility && StatsEngine.confirmedWorkSets(entry, in: session)
                    .contains { Effort.isHard(rir: $0.rir) }
            }
        }
        if Task.isCancelled { return nil }

        let agg = StatsEngine.dailyActivity(
            workouts: filteredWorkouts,
            external: filteredExternal,
            calendar: cal
        )
        let heatmapTime = HeatmapGrid.build(agg: agg, metric: .time, range: range, calendar: cal, now: now)
        let heatmapVolume = HeatmapGrid.build(agg: agg, metric: .volume, range: range, calendar: cal, now: now)
        if Task.isCancelled { return nil }

        let weightPoints = buildWeightPoints(
            entries: input.bodyWeights,
            range: range,
            weekStartsOnMonday: monday,
            now: now
        )

        // Últimos ejercicios realmente entrenados, no los primeros alfabéticos.
        // Prepararlo aquí evita ordenar un historial completo durante el scroll.
        var lastExerciseDate: [UUID: Date] = [:]
        for workout in filteredWorkouts {
            let date = workout.finishedAt ?? workout.startedAt ?? .distantPast
            for entry in workout.exercises {
                lastExerciseDate[entry.exercise.id] = max(
                    lastExerciseDate[entry.exercise.id] ?? .distantPast, date
                )
            }
        }
        let chartExercises = input.exercises
            .filter { lastExerciseDate[$0.id] != nil }
            .sorted {
                let left = lastExerciseDate[$0.id] ?? .distantPast
                let right = lastExerciseDate[$1.id] ?? .distantPast
                return left == right ? $0.name < $1.name : left > right
            }
        var mobilitySessions = 0
        var mobilitySeconds = 0
        for workout in filteredWorkouts where workout.finishedAt != nil || workout.phase == .finished {
            let duration = workout.exercises
                .filter { $0.exercise.isMobility }
                .flatMap(\.loggedSets)
                .filter { !$0.isWarmup && $0.reps > 0 }
                .compactMap(\.durationSeconds)
                .filter { $0 > 0 }
                .reduce(0, +)
            if duration > 0 {
                mobilitySessions += 1
                mobilitySeconds += duration
            }
        }
        var tops: [UUID: Double] = [:]
        for workout in filteredWorkouts {
            for entry in workout.exercises {
                for set in StatsEngine.confirmedWorkSets(entry, in: workout) {
                    guard let w = set.weightKg, w > 0 else { continue }
                    tops[entry.exercise.id] = max(tops[entry.exercise.id] ?? 0, w)
                }
            }
        }

        return ProgressSnapshot(
            key: input.key,
            range: range,
            weekStartsOnMonday: monday,
            charts: charts,
            summary: summary,
            previousSummary: previousSummary,
            streak: streak,
            previousStreak: previousStreak,
            averageHeartRate: charts.averageHeartRate,
            previousAverageHeartRate: prevAvgHr,
            records: records,
            muscleLoadAll: muscleAll,
            muscleLoadHard: muscleHard,
            muscleFatigueAll: muscleFatigueAll,
            muscleFatigueHard: muscleFatigueHard,
            hasHardSets: hasHardSets,
            heatmapTime: heatmapTime,
            heatmapVolume: heatmapVolume,
            weightPoints: weightPoints,
            chartExercises: chartExercises,
            mobilitySessions: mobilitySessions,
            mobilitySeconds: mobilitySeconds,
            topExerciseMaxWeights: tops,
            filteredWorkouts: filteredWorkouts,
            filteredExternal: filteredExternal,
            filteredStimuli: filteredStimuli
        )
    }

    static func buildWeightPoints(
        entries: [BodyWeightEntry],
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool,
        now: Date = Date()
    ) -> [ProgressWeightPoint] {
        let start = range.startDate(now: now, weekStartsOnMonday: weekStartsOnMonday) ?? .distantPast
        let end = Calendar.current.date(
            byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)
        ) ?? now
        let raw = entries
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date < $1.date }
        let granularity = ProgressSeriesGranularity.forChart(range: range)
        guard granularity != .day, raw.count > 1 else {
            return raw.map { ProgressWeightPoint(date: $0.date, weightKg: $0.weightKg) }
        }
        let series = raw.map {
            ProgressDayPoint(dayKey: "\($0.date.timeIntervalSince1970)", date: $0.date, value: $0.weightKg)
        }
        let averaged = StatsEngine.averagedSeries(
            series,
            granularity: granularity,
            weekStartsOnMonday: weekStartsOnMonday
        )
        return averaged.map { ProgressWeightPoint(date: $0.date, weightKg: $0.value) }
    }
}
