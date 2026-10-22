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

        public init(
            score: Double,
            advice: TrainingReadinessAdvice,
            sleepContribution: Double,
            fatiguePenalty: Double,
            trainingCount: Int
        ) {
            self.score = score
            self.advice = advice
            self.sleepContribution = sleepContribution
            self.fatiguePenalty = fatiguePenalty
            self.trainingCount = trainingCount
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
        workouts: [WorkoutSession]
    ) -> TrainingReadiness? {
        guard let hours = sleepHours,
              hours.isFinite,
              hours > 0,
              let sleep = sleepIndex(hours: hours, recentAverage: recentAverageSleepHours)
        else { return nil }

        let sevenDays: TimeInterval = 7 * 24 * 3600
        let twoDays: TimeInterval = 48 * 3600
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
        let minutes48h = recent.reduce(0.0) { sum, workout in
            guard let finished = workout.finishedAt,
                  date.timeIntervalSince(finished) <= twoDays else { return sum }
            // Tope defensivo para sesiones olvidadas abiertas o duraciones erróneas.
            return sum + min(180.0, max(0.0, workout.durationMinutes))
        }
        let effortPressure = min(1.0, minutes48h / 180.0)
        // La ausencia de series mapeables no elimina la penalización si hay
        // duración válida; sin duración ni series no se presupone buena recuperación.
        let hasMeasuredLoad = musclePressure > 0 || minutes48h > 0
        guard hasMeasuredLoad else { return nil }
        let load = 0.75 * min(1.0, musclePressure / 0.95) + 0.25 * effortPressure
        let sleepContribution = (Double(sleep) / 10.0 - 7.0) * 0.45
        let penalty = 3.0 * load
        var score = max(0, min(10, 7.5 + sleepContribution - penalty))
        // Una noche corta no debe catalogarse «lista» aunque el cálculo
        // muscular sea favorable.
        if hours < 6 { score = min(score, 5.0) }
        let advice: TrainingReadinessAdvice = score >= 7.5
            ? .usual : (score >= 5.5 ? .moderate : .rest)
        return TrainingReadiness(
            score: (score * 10).rounded() / 10,
            advice: advice,
            sleepContribution: sleepContribution,
            fatiguePenalty: penalty,
            trainingCount: recent.count
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
