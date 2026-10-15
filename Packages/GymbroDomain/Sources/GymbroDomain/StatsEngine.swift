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
        guard let sessionDate = session.finishedAt ?? session.startedAt else { return 0 }
        var count = 0
        for exercise in session.exercises {
            let work = exercise.loggedSets.filter { !$0.isWarmup && $0.reps > 0 && ($0.weightKg ?? 0) > 0 }
            guard !work.isEmpty else { continue }
            let sessionBest = work.map { $0.weightKg! * (1 + Double($0.reps) / 30.0) }.max() ?? 0
            guard sessionBest > 0 else { continue }

            var priorBest: Double = 0
            for other in allWorkouts {
                guard let d = other.finishedAt ?? other.startedAt, d < sessionDate else { continue }
                guard let ex = other.exercises.first(where: { $0.exercise.id == exercise.exercise.id }) else { continue }
                for set in ex.loggedSets where !set.isWarmup && set.reps > 0 {
                    guard let w = set.weightKg, w > 0 else { continue }
                    priorBest = max(priorBest, w * (1 + Double(set.reps) / 30.0))
                }
            }
            if sessionBest > priorBest + 0.05 {
                count += 1
            }
        }
        return count
    }

    public static func totalSets(in session: WorkoutSession) -> Int {
        session.exercises.reduce(0) { $0 + $1.loggedSets.filter { !$0.isWarmup }.count }
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
