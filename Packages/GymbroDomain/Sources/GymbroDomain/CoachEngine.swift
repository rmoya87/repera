import Foundation

public struct CoachInsight: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var detail: String
    public var priority: Int

    public init(id: UUID = UUID(), title: String, detail: String, priority: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.priority = priority
    }
}

/// Rule-based local coach (no network / no API keys).
public enum CoachEngine {
    public static func insights(
        state: AppState,
        now: Date = Date()
    ) -> [CoachInsight] {
        var items: [CoachInsight] = []

        let workouts = state.workouts
        let weekCount = StatsEngine.workoutCount(from: workouts, days: 7, now: now)
        let monthCount = StatsEngine.workoutCount(from: workouts, days: 30, now: now)
        let volume = StatsEngine.weeklyVolume(from: workouts, now: now)
        let muscles = MuscleMapEngine.statuses(from: workouts, now: now)
        let fatigued = muscles.filter { $0.state == .fatigued }
        let neglected = muscles.filter { $0.setsLast7Days == 0 && halfLifeTracked($0.name) }

        if workouts.isEmpty {
            items.append(CoachInsight(
                title: "Empieza hoy",
                detail: state.routines.isEmpty
                    ? "Aún no hay entrenos. Crea un plan o importa una pizarra, y registra al menos unas series de trabajo."
                    : "No hay historial. Empieza la rutina de hoy y registra al menos 3 series de trabajo.",
                priority: 100
            ))
            return items
        }

        if weekCount == 0 {
            items.append(CoachInsight(
                title: "Llevas 7 días sin entrenar",
                detail: "Retoma con la rutina de hoy al 90% del último peso (deload suave) y sube la próxima sesión.",
                priority: 95
            ))
        } else if weekCount >= 5 {
            items.append(CoachInsight(
                title: "Alta frecuencia esta semana",
                detail: "Llevas \(weekCount) sesiones en 7 días. Prioriza sueño y deja 1 día fácil si algún grupo está fatigado.",
                priority: 70
            ))
        } else {
            items.append(CoachInsight(
                title: "Ritmo semanal",
                detail: "\(weekCount) sesiones esta semana · \(Int(volume)) kg de volumen. Objetivo sano: 3–5 sesiones.",
                priority: 40
            ))
        }

        if let top = fatigued.first {
            items.append(CoachInsight(
                title: "\(top.name) fatigado",
                detail: "Score \(top.score.formatted(.number.precision(.fractionLength(2)))). Evita otro estímulo duro ahí hoy; prioriza otro grupo o reduce series.",
                priority: 85
            ))
        }

        if neglected.count >= 2 {
            let names = neglected.prefix(3).map(\.name).joined(separator: ", ")
            items.append(CoachInsight(
                title: "Grupos sin tocar",
                detail: "En 7 días no has entrenado: \(names). Enrota o añade 2–3 series ligeras.",
                priority: 75
            ))
        }

        if let last = workouts.first,
           let when = last.finishedAt ?? last.startedAt,
           now.timeIntervalSince(when) < 36 * 3600 {
            items.append(CoachInsight(
                title: "Última sesión: \(last.title)",
                detail: "Volumen \(Int(last.totalVolumeKg)) kg. Si repites los mismos ejercicios mañana, baja 1 RIR o 1 serie.",
                priority: 55
            ))
        }

        if monthCount < 4 {
            items.append(CoachInsight(
                title: "Constancia",
                detail: "Solo \(monthCount) sesiones en 30 días. La progresión lineal funciona mejor con ≥3 sesiones/semana.",
                priority: 60
            ))
        }

        if let bw = state.bodyWeights.first, let goal = state.settings.bodyWeightGoalKg {
            let delta = bw.weightKg - goal
            if abs(delta) < 0.3 {
                items.append(CoachInsight(
                    title: "Peso en objetivo",
                    detail: "Estás en \(bw.weightKg.formatted(.number.precision(.fractionLength(1)))) kg (meta \(goal)). Mantén calorías y sigue fuerza.",
                    priority: 35
                ))
            } else if delta > 0 {
                items.append(CoachInsight(
                    title: "Por encima del peso meta",
                    detail: "+\(delta.formatted(.number.precision(.fractionLength(1)))) kg vs objetivo. Déficit suave y mantén proteinas/pesas.",
                    priority: 50
                ))
            } else {
                items.append(CoachInsight(
                    title: "Por debajo del peso meta",
                    detail: "\(abs(delta).formatted(.number.precision(.fractionLength(1)))) kg bajo el objetivo. Revisa calorías si buscas ganar masa.",
                    priority: 50
                ))
            }
        } else if state.bodyWeights.isEmpty {
            items.append(CoachInsight(
                title: "Registra tu peso",
                detail: "Un weigh-in semanal mejora el contexto del coach y las gráficas.",
                priority: 30
            ))
        }

        let hardRatio = hardSetRatio(workouts: Array(workouts.prefix(8)))
        if hardRatio > 0.7 {
            items.append(CoachInsight(
                title: "Muchas series al límite",
                detail: ">\(Int(hardRatio * 100))% de series recientes con RIR≤2. Deja 1–2 series técnicas más holgadas.",
                priority: 65
            ))
        }

        return items.sorted { $0.priority > $1.priority }
    }

    private static func halfLifeTracked(_ name: String) -> Bool {
        ["Pecho", "Espalda", "Piernas", "Hombros", "Bíceps", "Tríceps", "Isquios", "Glúteos"].contains(name)
    }

    private static func hardSetRatio(workouts: [WorkoutSession]) -> Double {
        var total = 0
        var hard = 0
        for w in workouts {
            for e in w.exercises {
                for s in e.loggedSets where s.countsForProgression {
                    total += 1
                    if Effort.isHard(rir: s.rir) || s.toFailure { hard += 1 }
                }
            }
        }
        guard total > 0 else { return 0 }
        return Double(hard) / Double(total)
    }
}
