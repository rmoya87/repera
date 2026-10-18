import Foundation

public enum StatsEngine {
    public static func personalRecords(from workouts: [WorkoutSession]) -> [PersonalRecord] {
        var best: [UUID: PersonalRecord] = [:]

        for workout in workouts where workout.phase == .finished || workout.finishedAt != nil {
            let date = workout.finishedAt ?? workout.startedAt ?? Date()
            for exercise in workout.exercises {
                for set in exercise.loggedSets {
                    guard let weight = set.weightKg, weight > 0, set.reps > 0 else { continue }
                    let candidate = PersonalRecord(
                        exerciseId: exercise.exercise.id,
                        exerciseName: exercise.exercise.name,
                        weightKg: weight,
                        reps: set.reps,
                        date: date
                    )
                    if let existing = best[exercise.exercise.id] {
                        if candidate.estimatedOneRM > existing.estimatedOneRM {
                            best[exercise.exercise.id] = candidate
                        }
                    } else {
                        best[exercise.exercise.id] = candidate
                    }
                }
            }
        }

        return best.values.sorted { $0.estimatedOneRM > $1.estimatedOneRM }
    }

    public static func weeklyVolume(from workouts: [WorkoutSession], now: Date = Date()) -> Double {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        return workouts
            .filter { ($0.finishedAt ?? $0.startedAt ?? .distantPast) >= start }
            .reduce(0) { $0 + $1.totalVolumeKg }
    }

    public static func workoutCount(from workouts: [WorkoutSession], days: Int = 30, now: Date = Date()) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return workouts.filter { ($0.finishedAt ?? $0.startedAt ?? .distantPast) >= cutoff }.count
    }

    /// Volumen (kg) por semana ISO, más antigua → más reciente.
    public static func weeklyVolumeSeries(
        from workouts: [WorkoutSession],
        weeks: Int = 8,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [(weekStart: Date, volumeKg: Double)] {
        guard weeks > 0 else { return [] }
        var result: [(Date, Double)] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let anchor = calendar.date(byAdding: .weekOfYear, value: -offset, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)),
                  let end = calendar.date(byAdding: .day, value: 7, to: start)
            else { continue }
            let vol = workouts
                .filter {
                    let d = $0.finishedAt ?? $0.startedAt ?? .distantPast
                    return d >= start && d < end
                }
                .reduce(0.0) { $0 + $1.totalVolumeKg }
            result.append((start, vol))
        }
        return result
    }

    /// Sesiones completadas por semana ISO.
    public static func weeklySessionSeries(
        from workouts: [WorkoutSession],
        weeks: Int = 8,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [(weekStart: Date, count: Int)] {
        guard weeks > 0 else { return [] }
        var result: [(Date, Int)] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let anchor = calendar.date(byAdding: .weekOfYear, value: -offset, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)),
                  let end = calendar.date(byAdding: .day, value: 7, to: start)
            else { continue }
            let count = workouts.filter {
                let d = $0.finishedAt ?? $0.startedAt ?? .distantPast
                return d >= start && d < end
            }.count
            result.append((start, count))
        }
        return result
    }

    public static func averageSessionMinutes(from workouts: [WorkoutSession], days: Int = 30, now: Date = Date()) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        let recent = workouts.filter { ($0.finishedAt ?? $0.startedAt ?? .distantPast) >= cutoff }
        let mins = recent.compactMap { session -> Double? in
            let m = session.durationMinutes
            return m > 0 ? m : nil
        }
        guard !mins.isEmpty else { return nil }
        return mins.reduce(0, +) / Double(mins.count)
    }

    public static func lastWorkingWeight(exerciseId: UUID, workouts: [WorkoutSession]) -> Double? {
        history(for: exerciseId, workouts: workouts).lastWeightKg
    }

    /// Resumen de historial de un ejercicio (PR, última sesión, veces…).
    public static func history(for exerciseId: UUID, workouts: [WorkoutSession]) -> ExerciseHistorySummary {
        var maxWeight: Double = 0
        var maxWeightReps = 0
        var bestReps = 0
        var lastDate: Date?
        var lastWeight: Double?
        var lastReps: Int?
        var times = 0
        var best1RM: Double = 0

        let sorted = workouts.sorted {
            ($0.finishedAt ?? $0.startedAt ?? .distantPast) > ($1.finishedAt ?? $1.startedAt ?? .distantPast)
        }

        for workout in sorted {
            guard let ex = workout.exercises.first(where: { $0.exercise.id == exerciseId }) else { continue }
            let work = ex.loggedSets.filter { !$0.isWarmup && $0.reps > 0 }
            guard !work.isEmpty else { continue }
            times += 1
            let date = workout.finishedAt ?? workout.startedAt
            if lastDate == nil {
                lastDate = date
                lastWeight = work.last?.weightKg
                lastReps = work.last?.reps
            }
            for set in work {
                bestReps = max(bestReps, set.reps)
                if let w = set.weightKg, w > 0 {
                    let e1 = w * (1 + Double(set.reps) / 30.0)
                    if e1 > best1RM {
                        best1RM = e1
                    }
                    if w > maxWeight || (abs(w - maxWeight) < 0.05 && set.reps > maxWeightReps) {
                        maxWeight = w
                        maxWeightReps = set.reps
                    }
                }
            }
        }

        return ExerciseHistorySummary(
            timesPerformed: times,
            maxWeightKg: maxWeight > 0 ? maxWeight : nil,
            repsAtMaxWeight: maxWeight > 0 ? maxWeightReps : nil,
            estimatedOneRM: best1RM > 0 ? best1RM : nil,
            bestReps: bestReps > 0 ? bestReps : nil,
            lastDate: lastDate,
            lastWeightKg: lastWeight,
            lastReps: lastReps
        )
    }
}

public struct ExerciseHistorySummary: Sendable, Equatable {
    public var timesPerformed: Int
    public var maxWeightKg: Double?
    public var repsAtMaxWeight: Int?
    public var estimatedOneRM: Double?
    public var bestReps: Int?
    public var lastDate: Date?
    public var lastWeightKg: Double?
    public var lastReps: Int?

    public init(
        timesPerformed: Int = 0,
        maxWeightKg: Double? = nil,
        repsAtMaxWeight: Int? = nil,
        estimatedOneRM: Double? = nil,
        bestReps: Int? = nil,
        lastDate: Date? = nil,
        lastWeightKg: Double? = nil,
        lastReps: Int? = nil
    ) {
        self.timesPerformed = timesPerformed
        self.maxWeightKg = maxWeightKg
        self.repsAtMaxWeight = repsAtMaxWeight
        self.estimatedOneRM = estimatedOneRM
        self.bestReps = bestReps
        self.lastDate = lastDate
        self.lastWeightKg = lastWeightKg
        self.lastReps = lastReps
    }

    public var hasData: Bool { timesPerformed > 0 }
}

// MARK: - Progreso por ejercicio (estilo openGym)

public enum ExerciseProgressMetric: String, CaseIterable, Sendable, Identifiable {
    case topSet
    case estimatedOneRM
    case effort

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .topSet: return "Top set"
        case .estimatedOneRM: return "1RM est."
        case .effort: return "Esfuerzo"
        }
    }
}

public enum ProgressRange: String, CaseIterable, Sendable, Identifiable {
    case oneMonth
    case threeMonths
    case oneYear
    case all

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .oneYear: return "1A"
        case .all: return "Todo"
        }
    }

    public func startDate(from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        switch self {
        case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: now)
        case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: now)
        case .oneYear: return calendar.date(byAdding: .year, value: -1, to: now)
        case .all: return nil
        }
    }
}

public struct ExerciseProgressPoint: Identifiable, Sendable, Equatable {
    public var id: Date { date }
    public var date: Date
    public var value: Double
    public var weightKg: Double?
    public var reps: Int?
    public var rir: Double?

    public init(date: Date, value: Double, weightKg: Double? = nil, reps: Int? = nil, rir: Double? = nil) {
        self.date = date
        self.value = value
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
    }
}

public struct ExerciseSessionSnapshot: Identifiable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var setLines: [String]
    public var topWeightKg: Double?

    public init(id: UUID, date: Date, setLines: [String], topWeightKg: Double?) {
        self.id = id
        self.date = date
        self.setLines = setLines
        self.topWeightKg = topWeightKg
    }
}

/// Última sesión de trabajo de un ejercicio (series estructuradas para orientar la carga).
public struct ExerciseLastSession: Sendable, Equatable {
    public struct WorkSet: Sendable, Equatable, Identifiable {
        public var id: UUID
        public var weightKg: Double?
        public var reps: Int
        public var rir: Double?

        public init(id: UUID = UUID(), weightKg: Double?, reps: Int, rir: Double?) {
            self.id = id
            self.weightKg = weightKg
            self.reps = reps
            self.rir = rir
        }

        public var line: String {
            let w = weightKg.map { String(format: "%g", $0) } ?? "—"
            var s = "\(w)×\(reps)"
            if let rir {
                s += " · RIR \(String(format: "%g", rir))"
            }
            return s
        }
    }

    public var sessionId: UUID
    public var date: Date
    public var sets: [WorkSet]

    public init(sessionId: UUID, date: Date, sets: [WorkSet]) {
        self.sessionId = sessionId
        self.date = date
        self.sets = sets
    }

    public var topSet: WorkSet? {
        sets.max { ($0.weightKg ?? 0) < ($1.weightKg ?? 0) }
    }
}

extension StatsEngine {
    /// Serie temporal para la ficha de progreso de un ejercicio.
    public static func exerciseProgressSeries(
        exerciseId: UUID,
        metric: ExerciseProgressMetric,
        range: ProgressRange,
        workouts: [WorkoutSession],
        now: Date = Date()
    ) -> [ExerciseProgressPoint] {
        let start = range.startDate(from: now)
        var points: [ExerciseProgressPoint] = []

        for workout in workouts.sorted(by: {
            ($0.finishedAt ?? $0.startedAt ?? .distantPast) < ($1.finishedAt ?? $1.startedAt ?? .distantPast)
        }) {
            guard workout.finishedAt != nil || workout.phase == .finished else { continue }
            guard let date = workout.finishedAt ?? workout.startedAt else { continue }
            if let start, date < start { continue }
            guard let ex = workout.exercises.first(where: { $0.exercise.id == exerciseId }) else { continue }
            let work = ex.loggedSets.filter { !$0.isWarmup && $0.reps > 0 }
            guard !work.isEmpty else { continue }

            switch metric {
            case .topSet:
                guard let best = work.max(by: { ($0.weightKg ?? 0) < ($1.weightKg ?? 0) }),
                      let kg = best.weightKg, kg > 0
                else { continue }
                points.append(
                    ExerciseProgressPoint(date: date, value: kg, weightKg: kg, reps: best.reps, rir: best.rir)
                )
            case .estimatedOneRM:
                var bestE1: Double = 0
                var bestSet: LoggedSet?
                for set in work {
                    guard let w = set.weightKg, w > 0 else { continue }
                    let e1 = w * (1 + Double(set.reps) / 30.0)
                    if e1 > bestE1 {
                        bestE1 = e1
                        bestSet = set
                    }
                }
                guard bestE1 > 0, let bestSet else { continue }
                points.append(
                    ExerciseProgressPoint(
                        date: date,
                        value: bestE1,
                        weightKg: bestSet.weightKg,
                        reps: bestSet.reps,
                        rir: bestSet.rir
                    )
                )
            case .effort:
                let withRir = work.compactMap(\.rir)
                guard let avg = withRir.isEmpty ? nil : withRir.reduce(0, +) / Double(withRir.count) else { continue }
                let top = work.compactMap(\.weightKg).max()
                points.append(
                    ExerciseProgressPoint(date: date, value: avg, weightKg: top, reps: nil, rir: avg)
                )
            }
        }
        return points
    }

    /// Última sesión con series de trabajo (más reciente primero).
    public static func lastWorkingSession(
        for exerciseId: UUID,
        workouts: [WorkoutSession]
    ) -> ExerciseLastSession? {
        for workout in workouts.sorted(by: {
            ($0.finishedAt ?? $0.startedAt ?? .distantPast) > ($1.finishedAt ?? $1.startedAt ?? .distantPast)
        }) {
            guard workout.finishedAt != nil || workout.phase == .finished else { continue }
            guard let date = workout.finishedAt ?? workout.startedAt else { continue }
            guard let ex = workout.exercises.first(where: { $0.exercise.id == exerciseId }) else { continue }
            let work = ex.loggedSets.filter { !$0.isWarmup && $0.reps > 0 }
            guard !work.isEmpty else { continue }
            return ExerciseLastSession(
                sessionId: workout.id,
                date: date,
                sets: work.map {
                    ExerciseLastSession.WorkSet(
                        id: $0.id,
                        weightKg: $0.weightKg,
                        reps: $0.reps,
                        rir: $0.rir
                    )
                }
            )
        }
        return nil
    }

    /// Sesiones de un ejercicio con desglose serie a serie (para la lista bajo el gráfico).
    public static func exerciseSessionSnapshots(
        exerciseId: UUID,
        workouts: [WorkoutSession],
        range: ProgressRange = .all,
        now: Date = Date()
    ) -> [ExerciseSessionSnapshot] {
        let start = range.startDate(from: now)
        var rows: [ExerciseSessionSnapshot] = []

        for workout in workouts.sorted(by: {
            ($0.finishedAt ?? $0.startedAt ?? .distantPast) > ($1.finishedAt ?? $1.startedAt ?? .distantPast)
        }) {
            guard workout.finishedAt != nil || workout.phase == .finished else { continue }
            guard let date = workout.finishedAt ?? workout.startedAt else { continue }
            if let start, date < start { continue }
            guard let ex = workout.exercises.first(where: { $0.exercise.id == exerciseId }) else { continue }
            let work = ex.loggedSets.filter { !$0.isWarmup && $0.reps > 0 }
            guard !work.isEmpty else { continue }

            let lines = work.map { set -> String in
                let w = set.weightKg.map { String(format: "%g", $0) } ?? "—"
                var line = "\(w)×\(set.reps)"
                if let rir = set.rir {
                    line += " (RIR \(String(format: "%g", rir)))"
                }
                return line
            }
            rows.append(
                ExerciseSessionSnapshot(
                    id: workout.id,
                    date: date,
                    setLines: lines,
                    topWeightKg: work.compactMap(\.weightKg).max()
                )
            )
        }
        return rows
    }

    /// Nº de PRs (mejor e1RM hasta esa fecha) logrados en una sesión.
    public static func personalRecordCount(in session: WorkoutSession, allWorkouts: [WorkoutSession]) -> Int {
        personalRecordCountsBySessionId(workouts: allWorkouts)[session.id] ?? 0
    }

    /// PRs por sesión en un solo pase cronológico (O(series) vs O(sesiones²) por fila).
    public static func personalRecordCountsBySessionId(workouts: [WorkoutSession]) -> [UUID: Int] {
        let dated = workouts.compactMap { session -> (WorkoutSession, Date)? in
            guard let date = session.finishedAt ?? session.startedAt else { return nil }
            return (session, date)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return lhs.0.id.uuidString < rhs.0.id.uuidString
        }

        var bestE1RM: [UUID: Double] = [:]
        var result: [UUID: Int] = [:]
        result.reserveCapacity(dated.count)

        for (session, _) in dated {
            var count = 0
            var sessionBests: [(UUID, Double)] = []
            for exercise in session.exercises {
                let work = exercise.loggedSets.filter { !$0.isWarmup && $0.reps > 0 && ($0.weightKg ?? 0) > 0 }
                guard !work.isEmpty else { continue }
                let sessionBest = work.map { $0.weightKg! * (1 + Double($0.reps) / 30.0) }.max() ?? 0
                guard sessionBest > 0 else { continue }
                let exerciseId = exercise.exercise.id
                let prior = bestE1RM[exerciseId] ?? 0
                if sessionBest > prior + 0.05 {
                    count += 1
                }
                sessionBests.append((exerciseId, sessionBest))
            }
            result[session.id] = count
            for (exerciseId, best) in sessionBests {
                bestE1RM[exerciseId] = max(bestE1RM[exerciseId] ?? 0, best)
            }
        }
        return result
    }

    public static func totalSets(in session: WorkoutSession) -> Int {
        session.exercises.reduce(0) { $0 + $1.loggedSets.filter { !$0.isWarmup }.count }
    }

    /// Actividad diaria (Gymbro + externas) para el heatmap de 12 meses.
    public static func dailyActivity(
        workouts: [WorkoutSession],
        external: [ExternalDaySample] = [],
        calendar: Calendar = .current
    ) -> [String: DayActivityContribution] {
        var agg: [String: DayActivityContribution] = [:]
        let df = Self.dayKeyFormatter(calendar: calendar)

        for workout in workouts {
            guard let date = workout.finishedAt ?? workout.startedAt else { continue }
            let day = calendar.startOfDay(for: date)
            let key = df.string(from: day)
            var row = agg[key] ?? DayActivityContribution(
                dayKey: key, date: day, minutes: 0, volumeKg: 0, sessionCount: 0
            )
            row.sessionCount += 1
            row.minutes += max(0, workout.durationMinutes)
            row.volumeKg += max(0, workout.totalVolumeKg)
            agg[key] = row
        }

        for sample in external {
            let day = calendar.startOfDay(for: sample.date)
            let key = df.string(from: day)
            var row = agg[key] ?? DayActivityContribution(
                dayKey: key, date: day, minutes: 0, volumeKg: 0, sessionCount: 0
            )
            row.sessionCount += 1
            row.minutes += max(0, sample.minutes)
            row.volumeKg += max(0, sample.volumeKg)
            agg[key] = row
        }
        return agg
    }

    /// Nivel 0…4 por cuartiles del valor (tiempo o volumen), como openGym Heatmap.
    public static func heatmapLevel(
        value: Double,
        hasActivity: Bool,
        thresholds: (t1: Double, t2: Double, t3: Double)
    ) -> Int {
        guard hasActivity else { return 0 }
        if value <= 0 { return 1 }
        if value >= thresholds.t3 { return 4 }
        if value >= thresholds.t2 { return 3 }
        if value >= thresholds.t1 { return 2 }
        return 1
    }

    public static func heatmapThresholds(values: [Double]) -> (t1: Double, t2: Double, t3: Double) {
        let sorted = values.filter { $0 > 0 }.sorted()
        guard !sorted.isEmpty else { return (0, 0, 0) }
        func q(_ p: Double) -> Double {
            sorted[min(sorted.count - 1, Int(floor(p * Double(sorted.count))))]
        }
        return (q(0.25), q(0.5), q(0.75))
    }

    /// Semanas consecutivas con ≥1 sesión (Gymbro o externa).
    public static func consecutiveWeekStreak(
        workoutDates: [Date],
        externalDates: [Date] = [],
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        var active = Set<String>()
        for date in workoutDates + externalDates {
            active.insert(weekKey(date, calendar: cal))
        }
        guard !active.isEmpty else { return 0 }

        var streak = 0
        var cursor = now
        for i in 0..<520 {
            let key = weekKey(cursor, calendar: cal)
            if active.contains(key) {
                streak += 1
            } else if i > 0 {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -7, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    public static func workoutsThisMonth(
        from workouts: [WorkoutSession],
        externalDates: [Date] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return 0 }
        let gym = workouts.filter {
            let d = $0.finishedAt ?? $0.startedAt ?? .distantPast
            return d >= start && d < end
        }.count
        let ext = externalDates.filter { $0 >= start && $0 < end }.count
        return gym + ext
    }

    /// Δ peso corporal últimos ~30 días (último − más cercano a hace 30d).
    public static func bodyWeightDelta30d(
        entries: [(date: Date, weightKg: Double)],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Double? {
        guard let latest = entries.max(by: { $0.date < $1.date }) else { return nil }
        let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let older = entries
            .filter { $0.date <= cutoff }
            .max(by: { $0.date < $1.date })
        guard let older else { return nil }
        return latest.weightKg - older.weightKg
    }

    private static func weekKey(_ date: Date, calendar: Calendar) -> String {
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-\(week)"
    }

    private static func dayKeyFormatter(calendar: Calendar) -> DateFormatter {
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = calendar.timeZone
        df.dateFormat = "yyyy-MM-dd"
        return df
    }
}

/// Muestra diaria externa (p. ej. Salud) para el heatmap y métricas.
public struct ExternalDaySample: Sendable, Equatable {
    public var date: Date
    public var minutes: Double
    public var volumeKg: Double
    public var activeEnergyKcal: Double
    /// Minutos de actividad cardio / no fuerza (carrera, bici…).
    public var cardioMinutes: Double

    public init(
        date: Date,
        minutes: Double,
        volumeKg: Double = 0,
        activeEnergyKcal: Double = 0,
        cardioMinutes: Double = 0
    ) {
        self.date = date
        self.minutes = minutes
        self.volumeKg = volumeKg
        self.activeEnergyKcal = activeEnergyKcal
        self.cardioMinutes = cardioMinutes
    }
}

/// Resumen 30 días para tiles de Progreso (Gymbro + Salud).
public enum ProgressTrendMetric: String, Sendable {
    case cardioMinutes
    case activeEnergyKcal
}

public struct ProgressHealthSummary: Sendable, Equatable {
    public var averageMinutes: Double?
    public var totalKcal: Double
    /// Media de minutos de sesiones cardio (no suma del periodo).
    public var averageCardioMinutes: Double?
    public var volumeKg: Double
    public var sessionCount: Int

    public init(
        averageMinutes: Double?,
        totalKcal: Double,
        averageCardioMinutes: Double?,
        volumeKg: Double,
        sessionCount: Int
    ) {
        self.averageMinutes = averageMinutes
        self.totalKcal = totalKcal
        self.averageCardioMinutes = averageCardioMinutes
        self.volumeKg = volumeKg
        self.sessionCount = sessionCount
    }
}

public struct ProgressDayPoint: Identifiable, Sendable, Equatable {
    public var id: String { dayKey }
    public var dayKey: String
    public var date: Date
    public var value: Double

    public init(dayKey: String, date: Date, value: Double) {
        self.dayKey = dayKey
        self.date = date
        self.value = value
    }
}

/// Granularidad de series en Progreso: rangos largos se promedian para reducir ruido.
public enum ProgressSeriesGranularity: String, Sendable, Equatable {
    case day
    case week
    case month

    /// Hoy/semana = día; mes/90/180 = semana; 360 = mes (Charts ≤ ~48 puntos).
    public static func forChart(
        range: ProgressTimeRange,
        firstDate: Date? = nil,
        lastDate: Date? = nil,
        calendar: Calendar = .current
    ) -> ProgressSeriesGranularity {
        _ = firstDate
        _ = lastDate
        _ = calendar
        switch range {
        case .today, .week:
            return .day
        case .month, .days90, .days180:
            return .week
        case .days360:
            return .month
        }
    }
}

extension StatsEngine {
    /// Promedia puntos diarios por semana o mes (eje X = inicio del bucket).
    public static func averagedSeries(
        _ points: [ProgressDayPoint],
        granularity: ProgressSeriesGranularity,
        weekStartsOnMonday: Bool = true,
        calendar: Calendar = .current
    ) -> [ProgressDayPoint] {
        guard granularity != .day, points.count > 1 else { return points }
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        let df = dayKeyFormatter(calendar: cal)

        struct Acc { var date: Date; var sum: Double; var count: Int }
        var groups: [String: Acc] = [:]

        for point in points {
            let day = cal.startOfDay(for: point.date)
            let key: String
            let bucketStart: Date
            switch granularity {
            case .day:
                key = df.string(from: day)
                bucketStart = day
            case .week:
                key = weekKey(day, calendar: cal)
                bucketStart = startOfWeek(containing: day, calendar: cal)
            case .month:
                let comps = cal.dateComponents([.year, .month], from: day)
                key = String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
                bucketStart = cal.date(from: comps) ?? day
            }
            var acc = groups[key] ?? Acc(date: bucketStart, sum: 0, count: 0)
            acc.sum += point.value
            acc.count += 1
            if bucketStart < acc.date { acc.date = bucketStart }
            groups[key] = acc
        }

        return groups.values
            .map { acc in
                let avg = acc.count > 0 ? acc.sum / Double(acc.count) : 0
                return ProgressDayPoint(dayKey: df.string(from: acc.date), date: acc.date, value: avg)
            }
            .sorted { $0.date < $1.date }
    }

    public static func startOfWeek(containing date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let delta = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -delta, to: day) ?? day
    }

    public static func filterWorkouts(
        _ workouts: [WorkoutSession],
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [WorkoutSession] {
        workouts.filter { workout in
            guard let day = workout.finishedAt ?? workout.startedAt else { return false }
            return range.contains(day, now: now, calendar: calendar, weekStartsOnMonday: weekStartsOnMonday)
        }
    }

    public static func filterWorkoutsInPreviousPeriod(
        _ workouts: [WorkoutSession],
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [WorkoutSession] {
        workouts.filter { workout in
            guard let day = workout.finishedAt ?? workout.startedAt else { return false }
            return range.containsInPreviousPeriod(
                day, now: now, calendar: calendar, weekStartsOnMonday: weekStartsOnMonday
            )
        }
    }

    public static func filterExternal(
        _ samples: [ExternalDaySample],
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ExternalDaySample] {
        samples.filter {
            range.contains($0.date, now: now, calendar: calendar, weekStartsOnMonday: weekStartsOnMonday)
        }
    }

    public static func filterStimuli(
        _ stimuli: [ExternalMuscleStimulus],
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ExternalMuscleStimulus] {
        stimuli.filter {
            range.contains($0.date, now: now, calendar: calendar, weekStartsOnMonday: weekStartsOnMonday)
        }
    }

    /// Serie diaria de cardio (min) o kcal para gráficas de Progreso.
    /// En 90d/Todo no rellena ceros día a día (solo días con dato) para no bloquear la UI.
    public static func dailyMetricSeries(
        workouts: [WorkoutSession],
        external: [ExternalDaySample] = [],
        metric: ProgressTrendMetric,
        range: ProgressTimeRange = .week,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ProgressDayPoint] {
        let days = range.chartDayCount
        let today = calendar.startOfDay(for: now)
        let start: Date = {
            if let s = range.startDate(now: now, calendar: calendar, weekStartsOnMonday: weekStartsOnMonday) {
                return s
            }
            return calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        }()
        let df = dayKeyFormatter(calendar: calendar)
        var buckets: [String: (date: Date, value: Double)] = [:]
        let fillZeros = ProgressSeriesGranularity.forChart(range: range) == .day

        if fillZeros {
            var cursor = start
            while cursor <= today {
                let key = df.string(from: cursor)
                buckets[key] = (cursor, 0)
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
                if buckets.count > 120 { break }
            }
        }

        for workout in workouts {
            guard let raw = workout.finishedAt ?? workout.startedAt else { continue }
            let day = calendar.startOfDay(for: raw)
            guard day >= start, day <= today else { continue }
            let key = df.string(from: day)
            let add: Double
            switch metric {
            case .cardioMinutes:
                let isCardioSession = workout.exercises.contains {
                    $0.exercise.muscleGroup == "Cardio"
                }
                add = isCardioSession ? max(0, workout.durationMinutes) : 0
            case .activeEnergyKcal:
                add = max(0, workout.appleActiveEnergyKcal ?? 0)
            }
            var row = buckets[key] ?? (day, 0)
            row.value += add
            buckets[key] = row
        }

        for sample in external {
            let day = calendar.startOfDay(for: sample.date)
            guard day >= start, day <= today else { continue }
            let key = df.string(from: day)
            let add: Double
            switch metric {
            case .cardioMinutes:
                add = max(0, sample.cardioMinutes)
            case .activeEnergyKcal:
                add = max(0, sample.activeEnergyKcal)
            }
            var row = buckets[key] ?? (day, 0)
            row.value += add
            buckets[key] = row
        }

        return buckets.values
            .map { ProgressDayPoint(dayKey: df.string(from: $0.date), date: $0.date, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    public static func progressHealthSummary(
        workouts: [WorkoutSession],
        external: [ExternalDaySample] = [],
        range: ProgressTimeRange = .week,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current,
        /// Si false, usa las listas tal cual (p. ej. ya filtradas al periodo anterior).
        applyRangeFilter: Bool = true
    ) -> ProgressHealthSummary {
        let filteredW = applyRangeFilter
            ? filterWorkouts(
                workouts, range: range, weekStartsOnMonday: weekStartsOnMonday, now: now, calendar: calendar
            )
            : workouts
        let filteredE = applyRangeFilter
            ? filterExternal(
                external, range: range, weekStartsOnMonday: weekStartsOnMonday, now: now, calendar: calendar
            )
            : external

        var minutes: [Double] = []
        var cardioMinutes: [Double] = []
        var kcal: Double = 0
        var volume: Double = 0

        for workout in filteredW {
            let m = workout.durationMinutes
            if m > 0 { minutes.append(m) }
            volume += max(0, workout.totalVolumeKg)
            if let k = workout.appleActiveEnergyKcal, k > 0 {
                kcal += k
            }
            let isCardioSession = workout.exercises.contains {
                $0.exercise.muscleGroup == "Cardio"
            }
            if isCardioSession, m > 0 {
                cardioMinutes.append(m)
            }
        }

        for sample in filteredE {
            if sample.minutes > 0 { minutes.append(sample.minutes) }
            volume += max(0, sample.volumeKg)
            kcal += max(0, sample.activeEnergyKcal)
            if sample.cardioMinutes > 0 {
                cardioMinutes.append(sample.cardioMinutes)
            }
        }

        let avg: Double? = minutes.isEmpty ? nil : minutes.reduce(0, +) / Double(minutes.count)
        let avgCardio: Double? = cardioMinutes.isEmpty
            ? nil
            : cardioMinutes.reduce(0, +) / Double(cardioMinutes.count)
        return ProgressHealthSummary(
            averageMinutes: avg,
            totalKcal: kcal,
            averageCardioMinutes: avgCardio,
            volumeKg: volume,
            sessionCount: filteredW.count + filteredE.count
        )
    }
}

public enum CalendarHelpers {
    /// ISO weekday: 1 Mon … 7 Sun
    public static func isoWeekday(for date: Date = Date(), calendar: Calendar = .current) -> Int {
        let wd = calendar.component(.weekday, from: date) // 1 Sun … 7 Sat
        return wd == 1 ? 7 : wd - 1
    }

    public static func weekdayName(_ iso: Int) -> String {
        switch iso {
        case 1: "Lunes"
        case 2: "Martes"
        case 3: "Miércoles"
        case 4: "Jueves"
        case 5: "Viernes"
        case 6: "Sábado"
        case 7: "Domingo"
        default: "Día \(iso)"
        }
    }

    /// Próxima fecha (incluido `from`) con ese weekday ISO.
    public static func nextDate(forISOWeekday iso: Int, from: Date = Date(), calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: from)
        for offset in 0..<7 {
            guard let d = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if isoWeekday(for: d, calendar: calendar) == iso { return d }
        }
        return start
    }
}
