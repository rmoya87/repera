import Foundation
import ReperaDomain

/// Capa UI sobre `CatalogSpanish` del dominio.
/// Preferimos un solo texto de técnica (pasos o descripción), no ambos duplicados.
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
        CatalogSpanish.description(forName: exercise.name)
            ?? exercise.detailDescription.map(CatalogSpanish.translateSentence)
    }

    static func instructions(for exercise: Exercise) -> [String] {
        if let es = CatalogSpanish.instructions(forName: exercise.name), !es.isEmpty {
            return es
        }
        return exercise.instructions.map(CatalogSpanish.translateSentence)
    }
}
