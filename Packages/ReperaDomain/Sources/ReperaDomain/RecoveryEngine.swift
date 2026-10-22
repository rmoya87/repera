import Foundation

/// Cálculo orientativo y determinista. No diagnostica, confirma ovulación,
/// predice fertilidad ni altera resultados deportivos.
public enum RecoveryEngine {
    public enum CyclePhase: String, Sendable, Equatable {
        case menstrual
        case follicular
        case ovulatory
        case luteal
        case unknown
    }

    /// Observed daily Apple Health signals. A nil value means unavailable,
    /// NOT zero or healthy. Kept on device, never added to workout mirrors.
    public struct DailyVitals: Sendable, Equatable {
        public let date: Date
        public let hrvMilliseconds: Double?
        public let restingHeartRateBpm: Double?
        public let respiratoryRateBpm: Double?
        public let oxygenSaturationPercent: Double?
        public let wristTemperatureCelsius: Double?
        public let heartRateRecoveryBpm: Double?

        public init(
            date: Date, hrvMilliseconds: Double? = nil,
            restingHeartRateBpm: Double? = nil,
            respiratoryRateBpm: Double? = nil,
            oxygenSaturationPercent: Double? = nil,
            wristTemperatureCelsius: Double? = nil,
            heartRateRecoveryBpm: Double? = nil
        ) {
            self.date = date
            self.hrvMilliseconds = hrvMilliseconds
            self.restingHeartRateBpm = restingHeartRateBpm
            self.respiratoryRateBpm = respiratoryRateBpm
            self.oxygenSaturationPercent = oxygenSaturationPercent
            self.wristTemperatureCelsius = wristTemperatureCelsius
            self.heartRateRecoveryBpm = heartRateRecoveryBpm
        }
    }

    public struct VitalContext: Sendable, Equatable {
        /// Conservative reduction in readiness, never a performance bonus.
        public let penalty: Double
        public let calibratedSignals: Int
        public let notes: [String]
    }

    /// Calibrate each accepted signal against >=7 distinct, prior days in the
    /// preceding 28 days. Ignore absent or invalid samples; never extrapolate
    /// or treat missing readings as normal physiological values.
    public static func vitalContext(
        at date: Date, history: [DailyVitals],
        calendar: Calendar = .current
    ) -> VitalContext {
        let day = calendar.startOfDay(for: date)
        let previous = history.filter {
            let sampleDay = calendar.startOfDay(for: $0.date)
            return sampleDay < day && sampleDay >= day.addingTimeInterval(-28 * 86_400)
        }
        guard let today = history.last(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return VitalContext(penalty: 0, calibratedSignals: 0, notes: []) }

        func baseline(_ key: KeyPath<DailyVitals, Double?>, valid: ClosedRange<Double>) -> Double? {
            let values = previous.compactMap { row -> (Date, Double)? in
                guard let v = row[keyPath: key], v.isFinite, valid.contains(v) else { return nil }
                return (calendar.startOfDay(for: row.date), v)
            }
            // Seven different calendar days, not seven watch measurements.
            guard Set(values.map(\.0)).count >= 7 else { return nil }
            let sorted = values.map(\.1).sorted()
            let n = sorted.count
            return n.isMultiple(of: 2) ? (sorted[n/2 - 1] + sorted[n/2]) / 2 : sorted[n/2]
        }

        var penalty = 0.0
        var calibrated = 0
        var notes: [String] = []
        if let v = today.hrvMilliseconds, (5...300).contains(v),
           let base = baseline(\.hrvMilliseconds, valid: 5...300), base > 0 {
            calibrated += 1
            if v < base * 0.70 { penalty += 0.9; notes.append("VFC considerablemente inferior a tu referencia") }
            else if v < base * 0.85 { penalty += 0.45; notes.append("VFC inferior a tu referencia") }
        }
        if let v = today.restingHeartRateBpm, (30...130).contains(v),
           let base = baseline(\.restingHeartRateBpm, valid: 30...130) {
            calibrated += 1
            if v - base >= 10 { penalty += 0.85; notes.append("Pulso en reposo claramente elevado") }
            else if v - base >= 5 { penalty += 0.45; notes.append("Pulso en reposo elevado") }
        }
        if let v = today.respiratoryRateBpm, (6...40).contains(v),
           let base = baseline(\.respiratoryRateBpm, valid: 6...40), base > 0 {
            calibrated += 1
            if v > base * 1.20 { penalty += 0.4; notes.append("Respiración superior a tu referencia") }
        }
        // SpO2, wrist temperature and 1-minute HR recovery are presented as
        // context only: different devices/conditions can confound them.
        return VitalContext(
            penalty: min(1.8, penalty),
            calibratedSignals: calibrated,
            notes: notes
        )
    }

    /// Puntuación SOLO del sueño observado; nunca se añade/resta al score del entreno.
    public static func sleepIndex(hours: Double?, recentAverage: Double?) -> Int? {
        guard let hours, hours.isFinite, hours > 0 else { return nil }
        let baseline = (recentAverage?.isFinite == true && (recentAverage ?? 0) > 0)
            ? recentAverage! : 8
        let target = max(7, min(9, baseline))
        return Int((100 * min(max(0, hours / target), 1)).rounded())
    }

    /// Orientación de carga del día, NO diagnóstico ni medición fisiológica
    /// directa (sin HRV, dolor muscular, percepción de fatiga, etc.).
    public enum TrainingReadinessAdvice: String, Sendable, Equatable {
        case usual = "Entreno habitual según sensaciones"
        case moderate = "Modera carga e intensidad"
        case rest = "Prioriza descanso o actividad suave"
    }

    public struct TrainingReadiness: Sendable, Equatable {
        /// Índice orientativo independiente del índice de sueño y de la
        /// puntuación de rendimiento del WOD (0…10).
        public let score: Double
        public let advice: TrainingReadinessAdvice
        public let sleepContribution: Double
        public let fatiguePenalty: Double
        public let trainingCount: Int
        public let physiologicalPenalty: Double
        public let calibratedVitalSignals: Int
        public let vitalNotes: [String]

        public init(
            score: Double,
            advice: TrainingReadinessAdvice,
            sleepContribution: Double,
            fatiguePenalty: Double,
            trainingCount: Int,
            physiologicalPenalty: Double = 0,
            calibratedVitalSignals: Int = 0,
            vitalNotes: [String] = []
        ) {
            self.score = score
            self.advice = advice
            self.sleepContribution = sleepContribution
            self.fatiguePenalty = fatiguePenalty
            self.trainingCount = trainingCount
            self.physiologicalPenalty = physiologicalPenalty
            self.calibratedVitalSignals = calibratedVitalSignals
            self.vitalNotes = vitalNotes
        }
    }

    /// Estimación de disposición para entrenar a una hora determinada. Usa:
    /// - sueño observado (o supuesto explícito para una proyección),
    /// - fatiga residual por músculos (mismo motor del mapa corporal),
    /// - minutos de entrenamiento de las últimas 48 h.
    ///
    /// Requiere ambos tipos de datos y al menos un entrenamiento finalizado
    /// en los últimos siete días. Jamás inventa cero esfuerzo sin registros.
    /// No incluye entrenamientos futuros ni cambia la nota deportiva.
    public static func trainingReadiness(
        at date: Date,
        sleepHours: Double?,
        recentAverageSleepHours: Double?,
        workouts: [WorkoutSession],
        vitalHistory: [DailyVitals] = []
    ) -> TrainingReadiness? {
        guard let hours = sleepHours,
              hours.isFinite,
              hours > 0,
              let sleep = sleepIndex(hours: hours, recentAverage: recentAverageSleepHours)
        else { return nil }

        let sevenDays: TimeInterval = 7 * 24 * 3600
        let twoDays: TimeInterval = 48 * 3600
        let fourDays: TimeInterval = 96 * 3600
        let recent = workouts.filter { workout in
            guard let finished = workout.finishedAt else { return false }
            let age = date.timeIntervalSince(finished)
            return age >= 0 && age <= sevenDays
        }
        guard !recent.isEmpty else { return nil }

        // Solo sesiones ya acabadas. MuscleMapEngine respeta los grupos
        // musculares y la vida media propia de cada uno.
        let retained = MuscleMapEngine.retainedLoad(workouts: recent, now: date)
        let mainGroups = retained.values.sorted(by: >).prefix(3)
        let musclePressure = mainGroups.isEmpty
            ? 0.0
            : mainGroups.reduce(0, +) / Double(mainGroups.count)
        var minutes48h = 0.0
        var minutes96h = 0.0
        for workout in recent {
            guard let finished = workout.finishedAt else { continue }
            let age = date.timeIntervalSince(finished)
            let minutes = min(180.0, max(0.0, workout.durationMinutes))
            if age <= fourDays { minutes96h += minutes }
            if age <= twoDays { minutes48h += minutes }
        }
        // Si un WOD solo tiene duración y no series mapeadas, la densidad
        // temporal sigue representando esfuerzo real: no asumir fatiga nula.
        let durationPressure = 0.55 * min(1.0, minutes48h / 120.0)
            + 0.45 * min(1.0, minutes96h / 240.0)
        let muscleLoad = min(1.0, musclePressure / 0.95)
        let hasMeasuredLoad = musclePressure > 0 || minutes96h > 0
        guard hasMeasuredLoad else { return nil }
        let load = musclePressure > 0
            ? 0.7 * muscleLoad + 0.3 * durationPressure
            : durationPressure
        let sleepContribution = (Double(sleep) / 10.0 - 7.0) * 0.45
        let penalty = 3.5 * load
        let vitals = vitalContext(at: date, history: vitalHistory)
        var score = max(0, min(10, 7.5 + sleepContribution - penalty - vitals.penalty))
        // Una noche corta no debe catalogarse «lista» aunque el cálculo
        // muscular sea favorable.
        if hours < 6 { score = min(score, 5.0) }
        // Los índices de Repera se publican como enteros de 0 a 10.
        // Redondear antes de elegir la banda mantiene el consejo coherente
        // con el número que ve el usuario.
        score = score.rounded()
        let advice: TrainingReadinessAdvice = score >= 7.5
            ? .usual : (score >= 5.5 ? .moderate : .rest)
        return TrainingReadiness(
            score: score,
            advice: advice,
            sleepContribution: sleepContribution,
            fatiguePenalty: penalty,
            trainingCount: recent.count,
            physiologicalPenalty: vitals.penalty,
            calibratedVitalSignals: vitals.calibratedSignals,
            vitalNotes: vitals.notes
        )
    }

    /// Estima una fase únicamente a partir del historial de menstruaciones.
    /// Requiere al menos tres comienzos de ciclo, dos intervalos válidos y
    /// una regularidad razonable; no usa la fecha para inferir fertilidad.
    public static func cyclePhase(
        flowDays: [Date],
        on date: Date,
        calendar: Calendar = .current
    ) -> CyclePhase {
        let today = calendar.startOfDay(for: date)
        let days = Array(Set(flowDays.map { calendar.startOfDay(for: $0) })).sorted()
        guard let latest = days.last, latest <= today else { return .unknown }
        if days.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            return .menstrual
        }
        var starts: [Date] = []
        for day in days {
            if let last = starts.last {
                let elapsed = calendar.dateComponents([.day], from: last, to: day).day ?? 0
                if elapsed <= 10 { continue }
            }
            starts.append(day)
        }
        guard starts.count >= 3, let current = starts.last else { return .unknown }
        let intervals = zip(starts.dropFirst(), starts).map {
            calendar.dateComponents([.day], from: $1, to: $0).day ?? 0
        }
        guard intervals.count >= 2,
              intervals.allSatisfy({ (21...40).contains($0) }),
              (intervals.max() ?? 0) - (intervals.min() ?? 0) <= 7 else { return .unknown }
        let elapsed = calendar.dateComponents([.day], from: current, to: today).day ?? -1
        let meanLength = Double(intervals.reduce(0,+)) / Double(intervals.count)
        guard elapsed >= 0, elapsed < Int(meanLength.rounded()) else { return .unknown }
        let midpoint = Int(meanLength.rounded()) - 14
        if abs(elapsed - midpoint) <= 1 { return .ovulatory }
        return elapsed < midpoint ? .follicular : .luteal
    }
}
