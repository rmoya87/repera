import Foundation

/// Nombre canónico EN de CrossFit/halterofilia y alias ES de búsqueda.
/// Las equivalencias se aplican en la hidratación sin reemplazar los UUID existentes.
public enum SportExerciseNames {
    private static let legacySpanishToEnglish: [String: String] = [
        "Arrancada": "Snatch",
        "Arrancada colgante": "Hang Snatch",
        "Arrancada colgante completa": "Hang Squat Snatch",
        "Arrancada con pausa": "Pause Snatch",
        "Arrancada de potencia": "Power Snatch",
        "Arrancada desde bloques": "Block Snatch",
        "Arrancada en split": "Split Snatch",
        "Arrancada muscular": "Muscle Snatch",
        "Balance de arrancada": "Snatch Balance",
        "Balance de envión": "Jerk Balance",
        "Burpee al cajón": "Burpee Box Jump",
        "Cargada": "Clean",
        "Cargada colgante": "Hang Clean",
        "Cargada colgante completa": "Hang Squat Clean",
        "Cargada con pausa": "Pause Clean",
        "Cargada de potencia": "Power Clean",
        "Cargada desde bloques": "Block Clean",
        "Cargada muscular": "Muscle Clean",
        "Cargada y envión": "Clean and Jerk",
        "Cargada y envión con mancuerna": "Dumbbell Clean and Jerk",
        "Cargada y press": "Clean and Press",
        "Carrera": "Run",
        "Clean kettlebell": "Kettlebell Clean",
        "Clean mancuerna": "Dumbbell Clean",
        "Dobles de comba": "Double-Under",
        "Envión detrás de nuca": "Behind-the-Neck Jerk",
        "Peso muerto agarre arrancada": "Snatch-Grip Deadlift",
        "Press detrás de nuca": "Behind-the-Neck Press",
        "Salto al cajón": "Box Jump",
        "Sentadilla frontal con pausa": "Pause Front Squat",
        "Simples de comba": "Single-Under",
        "Snatch kettlebell": "Kettlebell Snatch",
        "Snatch mancuerna": "Dumbbell Snatch",
        "Step-up al cajón": "Box Step-Up",
        "Step-up al cajón con kettlebell goblet": "Kettlebell Goblet Box Step-Up",
        "Swing americano": "American Kettlebell Swing",
        "Swing kettlebell": "Kettlebell Swing",
        "Thruster kettlebell": "Kettlebell Thruster",
        "Thruster mancuernas": "Dumbbell Thruster",
        "Tirón de arrancada": "Snatch Pull",
        "Tirón de cargada": "Clean Pull",
        "Triples de comba": "Triple-Under",
        "Zancadas inversas con barra": "Back rack reverse lunge",
    ]

    private static let originalEnglishAliases: [String: String] = [
        "Air bike": "Bicicleta de aire",
        "Ball slam": "Golpeo de balón al suelo",
        "Bar facing burpee": "Burpee frente a la barra",
        "Bear crawl": "Gateo del oso",
        "Box jump over": "Salto sobre cajón",
        "Broad jump": "Salto de longitud",
        "Burpee": "Burpi",
        "Burpee box jump over": "Burpee con salto sobre cajón",
        "Burpee pull-up": "Burpee con dominada",
        "Cluster": "Cargada y thruster",
        "Devil press": "Press del diablo",
        "Drop snatch": "Arrancada bajo la barra",
        "Echo bike": "Bicicleta Echo",
        "Farmer carry": "Paseo del granjero",
        "Front rack lunge": "Zancada con barra en rack frontal",
        "Goblet squat": "Sentadilla goblet",
        "Ground to overhead": "Del suelo a encima de la cabeza",
        "Hang power clean": "Cargada de potencia desde colgado",
        "Hang power snatch": "Arrancada de potencia desde colgado",
        "Man maker": "Hombre máquina",
        "Medball clean": "Cargada con balón medicinal",
        "Overhead squat": "Sentadilla por encima de la cabeza",
        "Plate ground to overhead": "Disco del suelo a encima de la cabeza",
        "Power jerk": "Envión de potencia",
        "Push jerk": "Envión de fuerza",
        "Push press": "Press con impulso",
        "Sandbag clean": "Cargada con saco",
        "Sandbag over shoulder": "Saco sobre el hombro",
        "Shuttle run": "Carrera de ida y vuelta",
        "SkiErg": "Esquí ergómetro",
        "Sled pull": "Arrastre de trineo",
        "Sled push": "Empuje de trineo",
        "Sots press": "Press Sots",
        "Split jerk": "Envión en tijera",
        "Strict press": "Press estricto",
        "Sumo high pull": "Tirón alto sumo",
        "Tall clean": "Cargada desde extensión",
        "Tall snatch": "Arrancada desde extensión",
        "Thruster": "Sentadilla frontal con press",
        "Turkish get-up": "Levantamiento turco",
        "Walking lunge": "Zancadas caminando",
        "Wall ball": "Lanzamiento de balón a pared",
        "Yoke carry": "Paseo con yugo",
    ]

    private static let englishToSpanish: [String: String] = {
        var aliases = originalEnglishAliases
        for (spanish, english) in legacySpanishToEnglish {
            aliases[english] = spanish
        }
        return aliases
    }()

    private static func key(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
    }

    private static let normalizedSpanishToEnglish: [String: String] =
        Dictionary(uniqueKeysWithValues: legacySpanishToEnglish.map { (key($0.key), $0.value) })

    private static let normalizedEnglishToSpanish: [String: String] =
        Dictionary(uniqueKeysWithValues: englishToSpanish.map { (key($0.key), $0.value) })

    /// No modificar el catálogo general de musculación ni gimnasia.
    public static func displayName(_ name: String, sport: String?) -> String {
        guard sport == "CrossFit" || sport == "Halterofilia" else { return name }
        return canonicalName(name)
    }

    /// Puente de nombres antiguos en entrenos locales/cloud y en buscadores.
    public static func canonicalName(_ name: String) -> String {
        legacySpanishToEnglish[name] ?? normalizedSpanishToEnglish[key(name)] ?? name
    }

    /// Nombre español conservado como alias, sin alterar la identidad del ejercicio.
    public static func spanishAlias(for name: String) -> String? {
        normalizedEnglishToSpanish[key(name)] ?? (normalizedSpanishToEnglish[key(name)] == nil ? nil : name)
    }

    /// Alias técnicos EN->ES para indexación o resolución inversa de la pizarra.
    public static func englishAlias(forSpanish name: String) -> String? {
        normalizedSpanishToEnglish[key(name)]
    }
}
