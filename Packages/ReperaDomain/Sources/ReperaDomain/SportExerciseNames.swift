import Foundation

/// Nombre canónico EN de CrossFit/halterofilia y alias ES de búsqueda.
/// Las equivalencias se aplican en la hidratación sin reemplazar los UUID existentes.
public enum SportExerciseNames {
    private static let legacySpanishToEnglish: [String: String] = [
        "Arrancada": "Snatch",
        "Tirón alto de arrancada": "Snatch High Pull",
        "Tirón alto de cargada": "Clean High Pull",
        "Peso muerto de cargada": "Clean Deadlift",
        "Envión en sentadilla": "Squat Jerk",
        "Dip y drive de envión": "Jerk Dip and Drive",
        "Arrancada de potencia desde bloques": "Block Power Snatch",
        "Cargada de potencia desde bloques": "Block Power Clean",
        "Push press con agarre de arrancada": "Snatch-Grip Push Press",
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
        "Burpee Broad Jump": "Burpee con salto de longitud",
        "Sandbag Lunges": "Zancadas con saco",
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

    /// Aliases habituales de boxes y halterofilia. No cambian el nombre visible ni el UUID.
    /// Las siglas ambiguas (p. ej. «PS») se evitan deliberadamente.
    private static let supplementalAliases: [String: [String]] = [
        "Snatch": ["full snatch", "squat snatch", "arrancada completa", "sn"],
        "Power Snatch": ["p snatch", "psn", "arrancada alta"],
        "Hang Snatch": ["hang sn", "arrancada desde colgado", "hsn"],
        "Hang Squat Snatch": ["hang full snatch", "hs snatch", "hssn", "arrancada colgante profunda"],
        "Hang Power Snatch": ["hpsn", "hang p snatch", "power snatch from hang", "arrancada potencia colgante"],
        "Muscle Snatch": ["m snatch", "muscle sn", "arrancada sin recepción profunda"],
        "Block Snatch": ["snatch from blocks", "block squat snatch", "arrancada desde tacos"],
        "Pause Snatch": ["paused snatch", "snatch with pause", "arrancada pausada"],
        "Snatch Balance": ["sb snatch", "snatch balance behind neck", "recepcion arrancada con impulso"],
        "Drop Snatch": ["snatch drop", "drop into snatch", "caida de arrancada"],
        "Tall Snatch": ["tall sn", "arrancada de extensión", "tall squat snatch"],
        "Split Snatch": ["split sn", "arrancada en tijera"],
        "Snatch Pull": ["sn pull", "tiron de arrancada completo"],
        "Snatch High Pull": ["shp", "snatch highpull", "high pull de arrancada"],
        "Snatch-Grip Deadlift": ["snatch grip dl", "sgdl", "deadlift snatch grip", "peso muerto agarre ancho"],
        "Block Power Snatch": ["bpsn", "power snatch off blocks", "arrancada potencia desde tacos"],
        "Clean": ["full clean", "squat clean", "cargada completa"],
        "Power Clean": ["pc", "p clean", "cargada alta"],
        "Hang Clean": ["hang squat clean", "cargada desde colgado", "hc"],
        "Hang Squat Clean": ["hsc", "hang full clean", "cargada colgante profunda"],
        "Hang Power Clean": ["hpc", "hang p clean", "power clean from hang", "cargada potencia colgante"],
        "Muscle Clean": ["m clean", "cargada sin sentadilla"],
        "Block Clean": ["clean from blocks", "block squat clean", "cargada desde tacos"],
        "Pause Clean": ["paused clean", "clean with pause", "cargada pausada"],
        "Tall Clean": ["tall c", "cargada desde extension"],
        "Clean Pull": ["clean pull from floor", "tiron de cargada completo"],
        "Clean High Pull": ["chp", "clean highpull", "high pull de cargada"],
        "Clean Deadlift": ["clean grip deadlift", "cgdl", "peso muerto agarre cargada"],
        "Block Power Clean": ["bpc", "power clean off blocks", "cargada potencia desde tacos"],
        "Clean and Jerk": ["c&j", "cj", "c+j", "clean & jerk", "dos tiempos", "dos tiempos olimpicos", "cargada y envion olimpico"],
        "Clean and Press": ["c&p", "clean & press", "cargada y press estricto"],
        "Push Press": ["pp", "press de impulso", "press con piernas"],
        "Push Jerk": ["pj", "jerk en paralelo", "envion con pies paralelos"],
        "Split Jerk": ["sj", "jerk en split", "jerk en tijera", "envion split"],
        "Power Jerk": ["power j", "jerk de potencia", "envion potencia"],
        "Squat Jerk": ["squat j", "sj squat", "jerk en sentadilla"],
        "Jerk Balance": ["jerk balance drill", "balance de jerk"],
        "Jerk Dip and Drive": ["jerk dip drive", "dip & drive", "dip drive", "jerk dip + drive", "impulso de envion"],
        "Behind-the-Neck Jerk": ["btn jerk", "jerk btn", "jerk desde nuca"],
        "Strict Press": ["sp", "strict overhead press", "press estricto de pie"],
        "Behind-the-Neck Press": ["btn press", "press tras nuca"],
        "Sots Press": ["sots", "sots overhead press"],
        "Snatch-Grip Push Press": ["sgpp", "snatch grip pp", "push press ancho"],
        "Overhead Squat": ["ohs", "ohsq", "sentadilla overhead", "sentadilla sobre cabeza"],
        "Pause Front Squat": ["paused fs", "pause fs", "pfs", "sentadilla frontal pausada"],
        "Front Rack Lunge": ["fr lunge", "fr lunges", "zancada rack frontal"],
        "Sumo High Pull": ["sdhp", "sumo deadlift high pull", "tiron alto sumo deadlift"],
        "Run": ["running", "jogging", "correr", "carrera"],
        "SkiErg": ["ski erg", "ski ergometer", "esqui nordico ergometro"],
        "Remo máquina": ["rowerg", "row erg", "rowing erg", "ergometro remo"],
        "Burpee Broad Jump": ["bbj", "burpee broad jumps", "burpee long jump", "burpee salto longitud"],
        "Sandbag Lunges": ["sandbag walking lunges", "sb lunges", "zancadas con saco"],
        "Wall ball": ["wb", "wbs", "wall balls", "wallball", "lanzamientos a diana"],
        "Bar facing burpee": ["bfb", "bar-facing burpees", "burpee facing bar"],
        "Burpee box jump over": ["bbjo", "burpee box jumps over", "burpee sobre cajon"],
        "Double-Under": ["du", "dus", "double unders", "dobles"],
        "Single-Under": ["su", "single unders", "simples"],
        "Triple-Under": ["tu", "triple unders", "triples"],
        "Toes to bar": ["t2b", "ttb", "toes-to-bar", "pies a barra"],
        "Chest to bar": ["c2b", "ctb", "chest-to-bar", "dominadas al pecho"],
        "Muscle-up barra": ["bmu", "bar mu", "bar muscle up", "muscle up de barra"],
        "Muscle-up anillas": ["rmu", "ring mu", "ring muscle up", "muscle up de anillas"],
        "HSPU": ["handstand push up", "handstand push-up", "flexiones en pino"],
        "HSPU deficit": ["deficit hspu", "def hspu", "pino con deficit"],
        "GHD sit-up": ["ghd su", "ghdsu", "situp ghd"],
        "Knees to elbows": ["k2e", "knees-to-elbows", "rodillas a codos"],
        "Farmer carry": ["farmers carry", "farmer walk", "paseo granjero"],
        "Ground to overhead": ["gtoh", "ground 2 overhead", "suelo a overhead"],
        "Dumbbell Snatch": ["db snatch", "db sn", "snatch con mancuerna"],
        "Dumbbell Clean and Jerk": ["db c&j", "db cj", "dumbbell clean & jerk", "cargada y envion mancuerna"],
        "Kettlebell Swing": ["kb swing", "kbs", "swing de pesa rusa"],
        "Air bike": ["assault bike", "abike", "bicicleta de aire"],
        "Echo bike": ["echo", "echo erg", "bicicleta echo"],
        "Sled push": ["sledpush", "empujar trineo"],
        "Sled pull": ["sledpull", "tirar de trineo"],
    ]

    private static func aliasKey(_ raw: String) -> String {
        let folded = key(raw)
        var result = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
            } else if !result.hasSuffix(" ") {
                result.append(" ")
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    private static let normalizedSupplementalAliases: [String: String] = {
        var values: [String: String] = [:]
        for (canonical, aliases) in supplementalAliases {
            for alias in aliases {
                let normalized = aliasKey(alias)
                guard !normalized.isEmpty else { continue }
                if values[normalized] == nil {
                    values[normalized] = canonical
                }
            }
        }
        return values
    }()

    public static func searchAliases(for name: String) -> [String] {
        let canonical = canonicalName(name)
        let direct = supplementalAliases[canonical] ?? []
        let spanish = spanishAlias(for: canonical).map { [$0] } ?? []
        return Array(Set(direct + spanish)).sorted()
    }

    /// Permite al buscador y al lector de pizarra resolver siglas sin modificar IDs.
    public static func canonicalName(forSearchAlias raw: String) -> String? {
        normalizedSupplementalAliases[aliasKey(raw)]
    }

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
