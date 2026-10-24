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

    /// Símbolos individuales por aparato. Se usan tanto para elementos únicos
    /// como para montajes con varios materiales (p. ej. cajón + kettlebell).
    static func equipmentSymbol(for material: String) -> String {
        let e = material.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es_ES"))
            .lowercased()
        if e.contains("cajon") || e.contains("step") || e.contains("plataforma") { return "cube" }
        if e.contains("anillas") || e.contains("rings") { return "circle" }
        if e.contains("barra de dominadas") || e.contains("barra fija") { return "figure.climbing" }
        if e.contains("barra") || e.contains("barbell") { return "figure.strengthtraining.traditional" }
        if e.contains("mancuerna") || e.contains("dumbbell") { return "dumbbell" }
        if e.contains("kettlebell") || e.contains("pesa rusa") { return "scalemass" }
        if e.contains("lastre") || e.contains("chaleco") { return "scalemass" }
        if e.contains("comba") { return "figure.jumprope" }
        if e.contains("cuerda de trepa") { return "figure.climbing" }
        if e.contains("paralela") || e.contains("parallete") { return "figure.dip" }
        if e.contains("rueda abdominal") || e.contains("ab wheel") { return "circle.circle" }
        if e.contains("rodillo") { return "circle" }
        if e.contains("banco") { return "chair.lounge" }
        if e.contains("pared") || e.contains("muro") { return "square.grid.3x3" }
        if e.contains("puerta") { return "door.left.hand.closed" }
        if e.contains("banda") || e.contains("goma") { return "circle.dashed" }
        if e.contains("pica") { return "line.diagonal" }
        if e.contains("disco") { return "circle.dotted.circle" }
        if e.contains("balon") || e.contains("ball") { return "basketball" }
        if e.contains("ski") || e.contains("esqui") { return "figure.skiing.crosscountry" }
        if e.contains("remo") || e.contains("rowerg") { return "figure.rower" }
        if e.contains("bicicleta") || e.contains("bike") { return "bicycle" }
        if e.contains("ghd") { return "figure.core.training" }
        if e.contains("pegboard") { return "circle.grid.3x3" }
        if e.contains("polea") { return "gearshape.2" }
        if e.contains("saco") || e.contains("sandbag") { return "bag" }
        if e.contains("trineo") || e.contains("sled") { return "shippingbox" }
        if e.contains("yoke") { return "figure.strengthtraining.traditional" }
        if e.contains("maquina") || e.contains("machine") { return "gearshape" }
        if e.contains("peso corporal") || e.contains("sin material") { return "figure.stand" }
        return equipment
    }
}
