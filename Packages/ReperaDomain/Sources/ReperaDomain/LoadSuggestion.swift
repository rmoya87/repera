import Foundation

/// Sugiere kg a partir de % de 1RM (pizarra `#70%` / notas) y e1RM del historial.
public enum LoadSuggestion {
    /// Extrae porcentaje (70, 80…) desde notas u OCR (`#70%`, `#>80%`, `70%`).
    public static func percentOfOneRM(from text: String?) -> (value: Double, isMinimum: Bool)? {
        guard let text, !text.isEmpty else { return nil }
        guard let match = text.range(
            of: #"[#@]?\s*(>?)(\d{1,3})\s*%"#,
            options: .regularExpression
        ) else { return nil }
        let token = String(text[match])
        let isMin = token.contains(">")
        let digits = token.filter(\.isNumber)
        guard let pct = Double(digits), pct > 0, pct <= 100 else { return nil }
        return (pct, isMin)
    }

    public static func weightKg(
        oneRM: Double,
        percent: Double,
        roundTo incrementKg: Double = 2.5
    ) -> Double {
        guard oneRM > 0, percent > 0 else { return 0 }
        let raw = oneRM * (percent / 100)
        let step = max(incrementKg, 0.5)
        return (raw / step).rounded() * step
    }

    /// Peso para `reps` dejando `targetRir` en reserva (Epley inverso: RTF = reps + RIR).
    /// Ejemplo: 8 reps @ RIR 2 → carga ≈ 1RM / (1 + 10/30).
    public static func weightKg(
        oneRM: Double,
        reps: Int,
        targetRir: Double,
        roundTo incrementKg: Double = 2.5
    ) -> Double {
        guard oneRM > 0, reps > 0 else { return 0 }
        let rir = max(0, targetRir)
        let repsToFailure = Double(reps) + rir
        let raw = oneRM / (1 + repsToFailure / 30.0)
        let step = max(incrementKg, 0.5)
        return (raw / step).rounded() * step
    }

    /// Si no hay 1RM, estima desde la última serie de trabajo (mismo Epley).
    public static func weightKgFromLastSet(
        lastWeightKg: Double,
        lastReps: Int,
        lastRir: Double?,
        targetReps: Int,
        targetRir: Double,
        roundTo incrementKg: Double = 2.5
    ) -> Double {
        guard lastWeightKg > 0, lastReps > 0, targetReps > 0 else { return 0 }
        let lastRTF = Double(lastReps) + max(0, lastRir ?? 2)
        let oneRM = lastWeightKg * (1 + lastRTF / 30.0)
        return weightKg(
            oneRM: oneRM,
            reps: targetReps,
            targetRir: targetRir,
            roundTo: incrementKg
        )
    }

    /// Rellena `weightMaleKg` en movimientos que solo traen % y tienen 1RM conocido (tested o e1RM).
    public static func applyPercentLoads(
        to blocks: [RoutineBlock],
        workouts: [WorkoutSession],
        catalog: [Exercise],
        incrementKg: Double = 2.5,
        testedOneRMByExerciseId: [UUID: Double] = [:]
    ) -> [RoutineBlock] {
        blocks.map { block in
            var b = block
            b.movements = block.movements.map { move in
                guard !move.isRest else { return move }
                guard move.weightMaleKg == nil else { return move }
                guard let pct = percentOfOneRM(from: move.notes)?.value
                        ?? percentOfOneRM(from: move.name)?.value
                else { return move }

                let exerciseId = move.exerciseId
                    ?? catalog.first {
                        CrossFitGlossary.normalize($0.name) == CrossFitGlossary.normalize(move.name)
                    }?.id
                guard let exerciseId else { return move }
                let tested = testedOneRMByExerciseId[exerciseId]
                let hist = StatsEngine.history(for: exerciseId, workouts: workouts)
                guard let oneRM = tested ?? hist.estimatedOneRM, oneRM > 0 else { return move }
                let sourceLabel = tested != nil ? "1RM" : "e1RM"

                var m = move
                let kg = weightKg(oneRM: oneRM, percent: pct, roundTo: incrementKg)
                m.weightMaleKg = kg
                let note = "~\(Int(pct))% \(sourceLabel) → \(kg.formatted(.number.precision(.fractionLength(0...1)))) kg"
                if let existing = m.notes, !existing.isEmpty {
                    if !existing.contains("% e1RM"), !existing.contains("% 1RM") {
                        m.notes = existing + " · " + note
                    }
                } else {
                    m.notes = note
                }
                return m
            }
            return b
        }
    }
}
