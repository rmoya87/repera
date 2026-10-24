import Foundation

/// Grupo de material para la ordenación de la biblioteca.
/// La fuente original de equipo puede ser genérica («Máquina», «Peso corporal»):
/// usar también el movimiento permite distinguir SkiErg, RowErg, GHD, cajones, etc.
/// Solo afecta a la presentación; nunca altera un Exercise ni su identificador.
public enum ExerciseEquipmentGroup {
    public static func category(for exercise: Exercise?) -> String {
        guard let exercise else { return "Sin material" }
        return category(name: exercise.name, equipment: exercise.equipment)
    }

    public static func category(name: String, equipment: String?) -> String {
        let n = normalized(name)
        // Para varios aparatos simultáneos, agrupar por el principal (primer chip)
        // y mostrar todos en la ficha. Evita que «Barra, Banco» se ordene como Banco.
        let primary = (equipment ?? "").split(separator: ",", maxSplits: 1).first
            .map(String.init) ?? ""
        let e = normalized(primary)
        func named(_ parts: [String]) -> Bool { parts.contains { n.contains($0) } }
        func equipped(_ parts: [String]) -> Bool { parts.contains { e.contains($0) } }

        // Máquinas concretas: el seed puede registrar solo «Máquina» o nil.
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
            equipped(["air bike", "echo bike", "assault bike", "bikeerg"]) {
            return "Bicicletas y Air Bikes"
        }

        if named(["cinta / carrera", "treadmill"]) || equipped(["cinta de correr", "treadmill"]) {
            return "Cintas de correr"
        }

        // Balones distintos: Wall Ball ≠ Slam Ball ≠ balón medicinal genérico.
        if named(["wall ball", "wallball", "wall-ball", "lanzamiento de balon a pared"]) ||
            equipped(["wall ball", "wallball"]) {
            return "Wall Balls"
        }
        if named(["ball slam", "slam ball", "slamball", "golpeo de balon al suelo"]) ||
            equipped(["slam ball", "slamball"]) {
            return "Slam Balls"
        }
        if named(["sandbag", "saco de arena", "zancadas con saco"]) ||
            equipped(["saco", "sandbag"]) {
            return "Sacos de arena"
        }
        if named(["sled push", "sled pull", "trineo", "sled drag"]) ||
            equipped(["trineo", "sled"]) {
            return "Trineos"
        }
        if named(["yoke"]) || equipped(["yoke", "yugo"]) { return "Yugos" }

        // Cajones, cuerdas y anillas aparecen a veces etiquetados «Peso corporal».
        if named(["box jump", "box step", "box squat", "box step-up",
                  "burpee box", "salto al cajon", "step-up al cajon",
                  "burpee al cajon", "box jump over"]) ||
            equipped(["cajon", "plyo box", "jump box"]) || e == "box" || e == "step" {
            return "Cajones"
        }
        if named(["double-under", "single-under", "triple-under", "jump rope",
                  "dobles de comba", "simples de comba", "triples de comba"]) ||
            equipped(["comba", "jump rope", "skipping rope"]) {
            return "Combas"
        }
        if named(["rope climb", "pegboard rope", "trepa cuerda"]) ||
            equipped(["cuerda de trepa", "climbing rope"]) {
            return "Cuerdas de trepa"
        }
        if named(["anilla", "rings", "ring dip", "ring muscle", "ring row",
                  "skin the cat", "false grip hang"]) ||
            equipped(["anilla", "gymnastic rings"]) {
            return "Anillas"
        }
        if named(["pegboard"]) || equipped(["pegboard"]) { return "Pegboards" }
        if named(["paralela", "parallel bars"]) || equipped(["paralela"]) {
            return "Paralelas"
        }
        if named(["dominada", "pull-up", "pull up", "chin-up", "chin up",
                  "chest to bar", "toes to bar", "knees to elbows",
                  "toes to rings", "muscle-up barra", "bar muscle up",
                  "hip to bar", "pull-over barra"]) ||
            equipped(["barra de dominadas", "barra fija", "pull-up bar", "pullup bar"]) {
            return "Barras de dominadas"
        }

        // Material principal declarado para fuerza, movilidad y técnica.
        if equipped(["mancuerna", "dumbbell"]) { return "Mancuernas" }
        if equipped(["kettlebell", "pesa rusa"]) { return "Kettlebells" }
        if equipped(["banda", "goma", "resistance band", "miniband"]) {
            return "Bandas y gomas"
        }
        if equipped(["polea", "cable machine"]) { return "Poleas" }
        if equipped(["disco", "weight plate"]) { return "Discos" }
        if equipped(["barra", "barbell"]) || named(["bar facing burpee"]) {
            return "Barras"
        }
        if equipped(["balon", "medicine ball", "medball"]) { return "Balones medicinales" }
        if named(["fondos en banco"]) || equipped(["banco", "bench"]) { return "Bancos" }
        if equipped(["rueda abdominal", "ab wheel"]) { return "Ruedas abdominales" }
        if equipped(["plataforma elevada"]) { return "Plataformas de apoyo" }
        if equipped(["pica", "pvc pipe"]) { return "Picas" }
        if equipped(["rodillo", "foam roller"]) { return "Rodillos" }
        if equipped(["marco de puerta", "door frame"]) { return "Marcos de puerta" }
        if named(["wall walk", "wall handstand"]) || equipped(["pared", "wall"]) {
            return "Paredes"
        }
        if equipped(["maquina", "machine", "ergometro"]) { return "Máquinas" }
        if equipped(["peso corporal", "bodyweight", "sin material"]) {
            return "Peso corporal"
        }
        if e.isEmpty { return "Sin material" }
        // Material añadido por el usuario: preservar la etiqueta, nunca descartarlo.
        return equipment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Sin material"
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "es_ES")).lowercased()
    }
}
