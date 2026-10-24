import Foundation

/// SF Symbols compartidos por los filtros de Ejercicios y las etiquetas de su ficha.
/// Usar el mismo icono independientemente de la pantalla que muestra la disciplina.
enum ExerciseCategorySymbols {
    static let muscle = "lungs"
    static let equipment = "dumbbell"

    static func discipline(_ name: String) -> String {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased() {
        case "crossfit", "cross fit":
            return "figure.cross.training"
        case "gimnasia", "gimnasticos", "gymnastics", "gymnastic":
            return "figure.play"
        case "hyrox":
            return "figure.run"
        case "movilidad", "mobility":
            return "figure.flexibility"
        case "halterofilia", "weightlifting":
            return "figure.strengthtraining.traditional"
        case "cardio":
            return "heart"
        default:
            return "sportscourt"
        }
    }
}
