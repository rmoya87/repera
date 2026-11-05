import Foundation
import ReperaDomain

/// Capa UI sobre la resolución editorial del dominio.
/// Preferimos un solo texto de técnica (pasos o descripción), no ambos duplicados.
/// Autoridad: campos del `Exercise` (Supabase mergeado) → fallback `CatalogSpanish`.
enum ExerciseCopy {
    /// Pasos de técnica si existen; si no, la descripción como un único párrafo.
    static func techniqueSteps(for exercise: Exercise) -> [String] {
        let steps = instructions(for: exercise)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !steps.isEmpty { return steps }
        if let desc = description(for: exercise)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !desc.isEmpty {
            return [desc]
        }
        return []
    }

    static func description(for exercise: Exercise) -> String? {
        CatalogSpanish.resolvedDescription(for: exercise)
    }

    static func instructions(for exercise: Exercise) -> [String] {
        CatalogSpanish.resolvedInstructions(for: exercise)
    }
}
