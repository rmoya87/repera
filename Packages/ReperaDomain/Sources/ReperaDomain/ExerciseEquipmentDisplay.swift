import Foundation

/// Etiquetas cortas de material para chips de ficha / biblioteca.
/// El feed remoto o ExerciseDB a veces trae frases largas
/// («Colchoneta o superficie acolchada estable», «…para la variante C»).
public enum ExerciseEquipmentDisplay {
    /// Chips listos para UI, ya canónicos y sin ruido de variante.
    public static func chips(from equipment: String?) -> [String] {
        guard let equipment else { return [] }
        var seen = Set<String>()
        var result: [String] = []
        for raw in splitTokens(equipment) {
            let label = canonicalize(raw)
            guard !label.isEmpty else { continue }
            let key = normalized(label)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(label)
        }
        return result
    }

    /// Una sola etiqueta canónica (primer chip) o nil.
    public static func primary(from equipment: String?) -> String? {
        chips(from: equipment).first
    }

    public static func canonicalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let key = normalized(trimmed)

        // Frases de variante / nota editorial: no son material.
        if key.contains("variante") || key.contains("variant")
            || key.contains("para la ") || key.hasPrefix("for the ") {
            // Si el token es solo la nota («para la variante c»), descartar.
            // Si mezcla material + nota, seguir con el resto del texto.
            let stripped = key
                .replacingOccurrences(
                    of: #"\b(para la |for the )?variante?\b.*$"#,
                    with: "",
                    options: .regularExpression
                )
                .replacingOccurrences(
                    of: #"\bfor the .+ variant\b.*$"#,
                    with: "",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if stripped.isEmpty { return "" }
            return canonicalize(stripped)
        }

        if looksLikeMat(key) { return "Colchoneta" }
        if key == "body weight" || key == "bodyweight" || key == "body only"
            || key == "peso corporal" || key == "sin material" {
            return "Peso corporal"
        }
        if key.contains("barra de dominadas") || key == "pull-up bar" || key == "pullup bar"
            || key == "barra fija" {
            return "Barra de dominadas"
        }
        if key == "abmat" || key == "ab mat" { return "AbMat" }
        if key.contains("rueda abdominal") || key.contains("ab wheel") {
            return "Rueda abdominal"
        }
        if key == "barbell" || key == "barra" { return "Barra" }
        if key.contains("dumbbell") || key.contains("mancuerna") { return "Mancuernas" }
        if key.contains("kettlebell") || key.contains("pesa rusa") { return "Kettlebell" }
        if key.contains("anilla") || key == "rings" { return "Anillas" }
        if key.contains("cajon") || key == "box" || key == "plyo box" { return "Cajón" }
        if key.contains("banda") || key == "band" || key == "bands" { return "Banda" }
        if key.contains("medicine ball") || key == "medball" || key.contains("balon medicinal") {
            return "Balón medicinal"
        }
        if key.contains("stability ball") || key.contains("fitball") { return "Fitball" }
        if key.contains("smith") { return "Máquina Smith" }
        if key == "cable" || key.contains("polea") { return "Polea" }
        if key.contains("machine") || key.contains("maquina") { return "Máquina" }

        // Evitar Title Case palabra a palabra: conservar capitalización corta razonable.
        if trimmed.count <= 28, !trimmed.contains(" o "), !trimmed.contains(" or ") {
            return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        }
        // Frases largas desconocidas: quedarse con el primer tramo antes de « o » / « or ».
        if let short = firstClause(key) {
            return canonicalize(short)
        }
        return trimmed
    }

    private static func splitTokens(_ equipment: String) -> [String] {
        equipment
            .replacingOccurrences(of: ";", with: ",")
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func looksLikeMat(_ key: String) -> Bool {
        if key.contains("colchoneta") || key.contains("superficie acolchada") {
            return true
        }
        if key.contains("padded surface") || key.contains("exercise mat") {
            return true
        }
        // «mat» suelto / «mat or …», sin medicine/slam/wall ball.
        if key == "mat" || key.hasPrefix("mat ") || key.contains(" mat ")
            || key.contains("yoga mat") {
            return !key.contains("medball") && !key.contains("medicine")
                && !key.contains("wall ball") && !key.contains("slam")
        }
        return false
    }

    private static func firstClause(_ key: String) -> String? {
        for separator in [" o ", " or ", " / "] {
            if let range = key.range(of: separator) {
                let head = String(key[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !head.isEmpty { return head }
            }
        }
        return nil
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "es_ES"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
