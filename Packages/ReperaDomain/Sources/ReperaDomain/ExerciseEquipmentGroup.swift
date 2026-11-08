import Foundation

/// Grupo de material para la ordenación de la biblioteca.
///
/// Prioridad:
/// 1. Aparato **declarado** en `equipment` (primer chip).
/// 2. Inferencia por **nombre** solo si el equipo es genérico
///    (`nil`, vacío, «Peso corporal», «Máquina», «Sin material»).
///
/// Así «Box Squat» con `Barra` no cae en Cajones, «Neumático» no cae en
/// Colchonetas por el substring `mat`, y Couch stretch con `Pared` va a Paredes.
/// Solo afecta a la presentación; nunca altera un Exercise ni su identificador.
public enum ExerciseEquipmentGroup {
    public static func category(for exercise: Exercise?) -> String {
        guard let exercise else { return "Sin material" }
        return category(name: exercise.name, equipment: exercise.equipment)
    }

    public static func category(name: String, equipment: String?) -> String {
        let n = normalized(name)
        // Varios aparatos: agrupar por el principal (primer chip).
        let primary = (equipment ?? "").split(separator: ",", maxSplits: 1).first
            .map(String.init) ?? ""
        let e = normalized(primary)
        func named(_ parts: [String]) -> Bool { parts.contains { n.contains($0) } }
        func equipped(_ parts: [String]) -> Bool { parts.contains { e.contains($0) } }
        let genericEquipment = e.isEmpty
            || equipped(["peso corporal", "bodyweight", "sin material", "maquina", "machine"])

        // Máquinas concretas: el seed puede registrar solo «Máquina».
        if named(["skierg", "ski erg", "ski-erg", "esqui de aire", "esquis de aire", "esqui ergometro"]) ||
            equipped(["skierg", "ski erg", "esqui de aire", "esquis de aire"]) {
            return "SkiErg / esquí de aire"
        }
        if named(["rowerg", "row erg", "remo maquina", "remoergometro", "rowing erg", "rowing machine"])
            || equipped(["rowerg", "row erg", "remoergometro"]) || e == "remo"
            || (e == "maquina" && named(["remo"])) {
            return "Remoergómetros"
        }
        if named(["ghd", "glute ham developer", "glute-ham developer"]) ||
            equipped(["ghd", "glute ham developer"]) {
            return "GHD"
        }
        if named(["air bike", "echo bike", "assault bike", "bikeerg", "bike erg",
                  "bici estatica", "bicicleta de aire"]) ||
            equipped(["air bike", "echo bike", "assault bike", "bikeerg", "bicicleta estatica"]) {
            return "Bicicletas y Air Bikes"
        }
        if named(["cinta / carrera", "treadmill"]) || equipped(["cinta de correr", "treadmill"]) {
            return "Cintas de correr"
        }

        // —— Material declarado (gana sobre heurísticas de nombre) ——
        // Wall/Slam a veces vienen etiquetados solo como «Balón medicinal».
        if equipped(["wall ball", "wallball"])
            || (equipped(["balon", "medicine ball", "medball"])
                && named(["wall ball", "wallball", "wall-ball", "lanzamiento de balon a pared"])) {
            return "Wall Balls"
        }
        if equipped(["slam ball", "slamball"])
            || (equipped(["balon", "medicine ball", "medball"])
                && named(["ball slam", "slam ball", "slamball", "golpeo de balon al suelo"])) {
            return "Slam Balls"
        }
        if equipped(["saco", "sandbag"]) { return "Sacos de arena" }
        if equipped(["trineo", "sled"]) { return "Trineos" }
        if equipped(["yoke", "yugo"]) { return "Yugos" }
        if equipped(["cajon", "plyo box", "jump box"]) || e == "box" || e == "step" {
            return "Cajones"
        }
        if equipped(["comba", "jump rope", "skipping rope"]) { return "Combas" }
        if equipped(["cuerda de trepa", "climbing rope"]) { return "Cuerdas de trepa" }
        if equipped(["cuerda de batalla", "battle rope"]) { return "Cuerdas de batalla" }
        if equipped(["anilla", "gymnastic rings"]) { return "Anillas" }
        if equipped(["pegboard"]) { return "Pegboards" }
        if equipped(["paralela", "parallette"]) { return "Paralelas" }
        if equipped(["abmat", "ab mat"]) { return "AbMats" }
        if isMatEquipment(e) { return "Colchonetas" }
        if equipped(["barra de dominadas", "barra fija", "pull-up bar", "pullup bar"]) {
            return "Barras de dominadas"
        }
        if equipped(["mancuerna", "dumbbell"]) { return "Mancuernas" }
        if equipped(["kettlebell", "pesa rusa"]) { return "Kettlebells" }
        if equipped(["banda", "goma", "resistance band", "miniband"]) {
            return "Bandas y gomas"
        }
        if equipped(["polea", "cable machine"]) { return "Poleas" }
        if equipped(["disco", "weight plate"]) { return "Discos" }
        // «Barra de dominadas» ya se resolvió arriba; «barra» corta = olímpica/obstáculo.
        if equipped(["barra", "barbell", "axle", "landmine", "hex", "trap"]) {
            return "Barras"
        }
        if equipped(["balon", "medicine ball", "medball", "d-ball", "dball"]) {
            return "Balones medicinales"
        }
        if equipped(["banco", "bench"]) { return "Bancos" }
        if equipped(["rueda abdominal", "ab wheel"]) { return "Ruedas abdominales" }
        if equipped(["plataforma elevada"]) { return "Plataformas de apoyo" }
        if equipped(["pica", "pvc pipe"]) { return "Picas" }
        if equipped(["rodillo", "foam roller"]) { return "Rodillos" }
        if equipped(["marco de puerta", "door frame"]) { return "Marcos de puerta" }
        if equipped(["pared", "wall"]) { return "Paredes" }
        if equipped(["neumatico", "tire", "tyre"]) { return "Neumáticos" }
        if equipped(["maza", "sledgehammer", "hammer"]) { return "Mazas" }
        if equipped(["husafell"]) { return "Husafell" }
        if equipped(["atlas", "piedra"]) { return "Piedras Atlas" }
        if equipped(["smith"]) { return "Máquinas" }
        if equipped(["trx"]) { return "TRX" }

        // —— Inferencia por nombre solo con equipo genérico / vacío ——
        if genericEquipment {
            if named(["wall ball", "wallball", "wall-ball", "lanzamiento de balon a pared"]) {
                return "Wall Balls"
            }
            if named(["ball slam", "slam ball", "slamball", "golpeo de balon al suelo"]) {
                return "Slam Balls"
            }
            if named(["sandbag", "saco de arena", "zancadas con saco"]) {
                return "Sacos de arena"
            }
            if named(["sled push", "sled pull", "trineo", "sled drag"]) {
                return "Trineos"
            }
            if named(["yoke"]) { return "Yugos" }
            if named(["box jump", "box step", "box squat", "box step-up",
                      "burpee box", "salto al cajon", "step-up al cajon",
                      "burpee al cajon", "box jump over"]) {
                return "Cajones"
            }
            if named(["double-under", "single-under", "triple-under", "jump rope",
                      "dobles de comba", "simples de comba", "triples de comba"]) {
                return "Combas"
            }
            if named(["rope climb", "pegboard rope", "trepa cuerda"]) {
                return "Cuerdas de trepa"
            }
            if named(["anilla", "rings", "ring dip", "ring muscle", "ring row",
                      "skin the cat", "false grip hang", "german hang",
                      "back lever", "toes to rings"]) {
                return "Anillas"
            }
            if named(["pegboard"]) { return "Pegboards" }
            if named(["paralela", "parallel bars", "parallette"]) {
                return "Paralelas"
            }
            if named(["ab mat", "abmat"]) { return "AbMats" }
            if named(["arch hold", "hollow hold", "hollow rock", "candlestick"]) {
                return "Colchonetas"
            }
            if named(["dominada", "pull-up", "pull up", "chin-up", "chin up",
                      "chest to bar", "toes to bar", "knees to elbows",
                      "muscle-up barra", "bar muscle up", "hip to bar",
                      "pull-over barra", "dead hang", "hanging knee",
                      "hanging hip", "negative pull"]) {
                return "Barras de dominadas"
            }
            if named(["fondos en banco"]) { return "Bancos" }
            if named(["bar facing burpee"]) { return "Barras" }
            if named(["wall walk", "wall handstand", "couch stretch",
                      "gemelo en pared", "soleo en pared", "rodilla a pared"]) {
                return "Paredes"
            }
            if named(["tire flip", "vuelco de neumatico"]) { return "Neumáticos" }
        }

        if equipped(["maquina", "machine", "ergometro"]) { return "Máquinas" }
        if equipped(["peso corporal", "bodyweight", "sin material"]) {
            return "Peso corporal"
        }
        if e.isEmpty { return "Sin material" }
        // Material añadido por el usuario: preservar la etiqueta.
        return equipment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Sin material"
    }

    /// `mat` suelto / yoga mat — nunca el substring dentro de «neumático» o «abmat».
    private static func isMatEquipment(_ e: String) -> Bool {
        if e.contains("colchoneta") || e.contains("yoga mat") || e.contains("exercise mat") {
            return true
        }
        if e == "mat" { return true }
        if e.hasPrefix("mat ") || e.hasSuffix(" mat") || e.contains(" mat ") {
            return true
        }
        return false
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "es_ES")).lowercased()
    }
}
