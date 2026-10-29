package dev.repera.domain

import java.text.Normalizer
import java.util.Locale

/** Port 1:1 de SportExerciseNames.swift (ReperaDomain). */
object SportExerciseNames {

    private val legacySpanishToEnglish: Map<String, String> = mapOf(
        "Arrancada" to "Snatch",
        "Tirón alto de arrancada" to "Snatch High Pull",
        "Tirón alto de cargada" to "Clean High Pull",
        "Peso muerto de cargada" to "Clean Deadlift",
        "Envión en sentadilla" to "Squat Jerk",
        "Dip y drive de envión" to "Jerk Dip and Drive",
        "Arrancada de potencia desde bloques" to "Block Power Snatch",
        "Cargada de potencia desde bloques" to "Block Power Clean",
        "Push press con agarre de arrancada" to "Snatch-Grip Push Press",
        "Arrancada colgante" to "Hang Snatch",
        "Arrancada colgante completa" to "Hang Squat Snatch",
        "Arrancada con pausa" to "Pause Snatch",
        "Arrancada de potencia" to "Power Snatch",
        "Arrancada desde bloques" to "Block Snatch",
        "Arrancada en split" to "Split Snatch",
        "Arrancada muscular" to "Muscle Snatch",
        "Balance de arrancada" to "Snatch Balance",
        "Balance de envión" to "Jerk Balance",
        "Burpee al cajón" to "Burpee Box Jump",
        "Cargada" to "Clean",
        "Cargada colgante" to "Hang Clean",
        "Cargada colgante completa" to "Hang Squat Clean",
        "Cargada con pausa" to "Pause Clean",
        "Cargada de potencia" to "Power Clean",
        "Cargada desde bloques" to "Block Clean",
        "Cargada muscular" to "Muscle Clean",
        "Cargada y envión" to "Clean and Jerk",
        "Cargada y envión con mancuerna" to "Dumbbell Clean and Jerk",
        "Cargada y press" to "Clean and Press",
        "Carrera" to "Run",
        "Clean kettlebell" to "Kettlebell Clean",
        "Clean mancuerna" to "Dumbbell Clean",
        "Dobles de comba" to "Double-Under",
        "Envión detrás de nuca" to "Behind-the-Neck Jerk",
        "Peso muerto agarre arrancada" to "Snatch-Grip Deadlift",
        "Press detrás de nuca" to "Behind-the-Neck Press",
        "Salto al cajón" to "Box Jump",
        "Sentadilla frontal con pausa" to "Pause Front Squat",
        "Simples de comba" to "Single-Under",
        "Snatch kettlebell" to "Kettlebell Snatch",
        "Snatch mancuerna" to "Dumbbell Snatch",
        "Step-up al cajón" to "Box Step-Up",
        "Step-up al cajón con kettlebell goblet" to "Kettlebell Goblet Box Step-Up",
        "Swing americano" to "American Kettlebell Swing",
        "Swing kettlebell" to "Kettlebell Swing",
        "Thruster kettlebell" to "Kettlebell Thruster",
        "Thruster mancuernas" to "Dumbbell Thruster",
        "Tirón de arrancada" to "Snatch Pull",
        "Tirón de cargada" to "Clean Pull",
        "Triples de comba" to "Triple-Under",
        "Zancadas inversas con barra" to "Back rack reverse lunge",
    )

    private val originalEnglishAliases: Map<String, String> = mapOf(
        "Burpee Broad Jump" to "Burpee con salto de longitud",
        "Sandbag Lunges" to "Zancadas con saco",
        "Air bike" to "Bicicleta de aire",
        "Ball slam" to "Golpeo de balón al suelo",
        "Bar facing burpee" to "Burpee frente a la barra",
        "Bear crawl" to "Gateo del oso",
        "Box jump over" to "Salto sobre cajón",
        "Broad jump" to "Salto de longitud",
        "Burpee" to "Burpi",
        "Burpee box jump over" to "Burpee con salto sobre cajón",
        "Burpee pull-up" to "Burpee con dominada",
        "Cluster" to "Cargada y thruster",
        "Devil press" to "Press del diablo",
        "Drop snatch" to "Arrancada bajo la barra",
        "Echo bike" to "Bicicleta Echo",
        "Farmer carry" to "Paseo del granjero",
        "Front rack lunge" to "Zancada con barra en rack frontal",
        "Goblet squat" to "Sentadilla goblet",
        "Ground to overhead" to "Del suelo a encima de la cabeza",
        "Hang power clean" to "Cargada de potencia desde colgado",
        "Hang power snatch" to "Arrancada de potencia desde colgado",
        "Man maker" to "Hombre máquina",
        "Medball clean" to "Cargada con balón medicinal",
        "Overhead squat" to "Sentadilla por encima de la cabeza",
        "Plate ground to overhead" to "Disco del suelo a encima de la cabeza",
        "Power jerk" to "Envión de potencia",
        "Push jerk" to "Envión de fuerza",
        "Push press" to "Press con impulso",
        "Sandbag clean" to "Cargada con saco",
        "Sandbag over shoulder" to "Saco sobre el hombro",
        "Shuttle run" to "Carrera de ida y vuelta",
        "SkiErg" to "Esquí ergómetro",
        "Sled pull" to "Arrastre de trineo",
        "Sled push" to "Empuje de trineo",
        "Sots press" to "Press Sots",
        "Split jerk" to "Envión en tijera",
        "Strict press" to "Press estricto",
        "Sumo high pull" to "Tirón alto sumo",
        "Tall clean" to "Cargada desde extensión",
        "Tall snatch" to "Arrancada desde extensión",
        "Thruster" to "Sentadilla frontal con press",
        "Turkish get-up" to "Levantamiento turco",
        "Walking lunge" to "Zancadas caminando",
        "Wall ball" to "Lanzamiento de balón a pared",
        "Yoke carry" to "Paseo con yugo",
    )

    /** Aliases habituales de boxes y halterofilia. Las siglas ambiguas se evitan. */
    private val supplementalAliases: Map<String, List<String>> = mapOf(
        "Snatch" to listOf("full snatch", "squat snatch", "arrancada completa", "sn"),
        "Power Snatch" to listOf("p snatch", "psn", "arrancada alta"),
        "Hang Snatch" to listOf("hang sn", "arrancada desde colgado", "hsn"),
        "Hang Squat Snatch" to listOf("hang full snatch", "hs snatch", "hssn", "arrancada colgante profunda"),
        "Hang power snatch" to listOf("hpsn", "hang p snatch", "power snatch from hang", "arrancada potencia colgante"),
        "Muscle Snatch" to listOf("m snatch", "muscle sn", "arrancada sin recepción profunda"),
        "Block Snatch" to listOf("snatch from blocks", "block squat snatch", "arrancada desde tacos"),
        "Pause Snatch" to listOf("paused snatch", "snatch with pause", "arrancada pausada"),
        "Snatch Balance" to listOf("sb snatch", "snatch balance behind neck", "recepcion arrancada con impulso"),
        "Drop snatch" to listOf("snatch drop", "drop into snatch", "caida de arrancada"),
        "Tall snatch" to listOf("tall sn", "arrancada de extensión", "tall squat snatch"),
        "Split Snatch" to listOf("split sn", "arrancada en tijera"),
        "Snatch Pull" to listOf("sn pull", "tiron de arrancada completo"),
        "Snatch High Pull" to listOf("shp", "snatch highpull", "high pull de arrancada"),
        "Snatch-Grip Deadlift" to listOf("snatch grip dl", "sgdl", "deadlift snatch grip", "peso muerto agarre ancho"),
        "Block Power Snatch" to listOf("bpsn", "power snatch off blocks", "arrancada potencia desde tacos"),
        "Clean" to listOf("full clean", "squat clean", "cargada completa"),
        "Power Clean" to listOf("pc", "p clean", "cargada alta"),
        "Hang Clean" to listOf("hang squat clean", "cargada desde colgado", "hc"),
        "Hang Squat Clean" to listOf("hsc", "hang full clean", "cargada colgante profunda"),
        "Hang power clean" to listOf("hpc", "hang p clean", "power clean from hang", "cargada potencia colgante"),
        "Muscle Clean" to listOf("m clean", "cargada sin sentadilla"),
        "Block Clean" to listOf("clean from blocks", "block squat clean", "cargada desde tacos"),
        "Pause Clean" to listOf("paused clean", "clean with pause", "cargada pausada"),
        "Tall clean" to listOf("tall c", "cargada desde extension"),
        "Clean Pull" to listOf("clean pull from floor", "tiron de cargada completo"),
        "Clean High Pull" to listOf("chp", "clean highpull", "high pull de cargada"),
        "Clean Deadlift" to listOf("clean grip deadlift", "cgdl", "peso muerto agarre cargada"),
        "Block Power Clean" to listOf("bpc", "power clean off blocks", "cargada potencia desde tacos"),
        "Clean and Jerk" to listOf("c&j", "cj", "c+j", "clean & jerk", "dos tiempos", "dos tiempos olimpicos", "cargada y envion olimpico"),
        "Clean and Press" to listOf("c&p", "clean & press", "cargada y press estricto"),
        "Push Press" to listOf("pp", "press de impulso", "press con piernas"),
        "Push jerk" to listOf("pj", "jerk en paralelo", "envion con pies paralelos"),
        "Split jerk" to listOf("sj", "jerk en split", "jerk en tijera", "envion split"),
        "Power jerk" to listOf("power j", "jerk de potencia", "envion potencia"),
        "Squat Jerk" to listOf("squat j", "sj squat", "jerk en sentadilla"),
        "Jerk Balance" to listOf("jerk balance drill", "balance de jerk"),
        "Jerk Dip and Drive" to listOf("jerk dip drive", "dip & drive", "dip drive", "jerk dip + drive", "impulso de envion"),
        "Behind-the-Neck Jerk" to listOf("btn jerk", "jerk btn", "jerk desde nuca"),
        "Strict press" to listOf("sp", "strict overhead press", "press estricto de pie"),
        "Behind-the-Neck Press" to listOf("btn press", "press tras nuca"),
        "Sots press" to listOf("sots", "sots overhead press"),
        "Snatch-Grip Push Press" to listOf("sgpp", "snatch grip pp", "push press ancho"),
        "Overhead squat" to listOf("ohs", "ohsq", "sentadilla overhead", "sentadilla sobre cabeza"),
        "Pause Front Squat" to listOf("paused fs", "pause fs", "pfs", "sentadilla frontal pausada"),
        "Front Rack Lunge" to listOf("fr lunge", "fr lunges", "zancada rack frontal"),
        "Sumo high pull" to listOf("sdhp", "sumo deadlift high pull", "tiron alto sumo deadlift"),
        "Run" to listOf("running", "jogging", "correr", "carrera"),
        "SkiErg" to listOf("ski erg", "ski ergometer", "esqui nordico ergometro"),
        "Remo máquina" to listOf("rowerg", "row erg", "rowing erg", "ergometro remo"),
        "Burpee Broad Jump" to listOf("bbj", "burpee broad jumps", "burpee long jump", "burpee salto longitud"),
        "Sandbag Lunges" to listOf("sandbag walking lunges", "sb lunges", "zancadas con saco"),
        "Wall ball" to listOf("wb", "wbs", "wall balls", "wallball", "lanzamientos a diana"),
        "Bar facing burpee" to listOf("bfb", "bar-facing burpees", "burpee facing bar"),
        "Burpee box jump over" to listOf("bbjo", "burpee box jumps over", "burpee sobre cajon"),
        "Double-Under" to listOf("du", "dus", "double unders", "dobles"),
        "Single-Under" to listOf("su", "single unders", "simples"),
        "Triple-Under" to listOf("tu", "triple unders", "triples"),
        "Toes to bar" to listOf("t2b", "ttb", "t2bs", "t 2 b", "toes-to-bar", "pies a barra"),
        "Burpee to target" to listOf("btt", "burpee to target", "burpees to target", "burpee a diana"),
        "Chest to bar" to listOf("c2b", "ctb", "chest-to-bar", "dominadas al pecho"),
        "Muscle-up barra" to listOf("bmu", "bar mu", "bar muscle up", "muscle up de barra"),
        "Muscle-up anillas" to listOf("rmu", "ring mu", "ring muscle up", "muscle up de anillas"),
        "HSPU" to listOf("handstand push up", "handstand push-up", "flexiones en pino"),
        "HSPU deficit" to listOf("deficit hspu", "def hspu", "pino con deficit"),
        "GHD sit-up" to listOf("ghd su", "ghdsu", "situp ghd"),
        "Knees to elbows" to listOf("k2e", "knees-to-elbows", "rodillas a codos"),
        "Farmer carry" to listOf("farmers carry", "farmer walk", "paseo granjero"),
        "Ground to overhead" to listOf("gtoh", "ground 2 overhead", "suelo a overhead"),
        "Dumbbell Snatch" to listOf("db snatch", "db sn", "snatch con mancuerna"),
        "Dumbbell Clean and Jerk" to listOf("db c&j", "db cj", "dumbbell clean & jerk", "cargada y envion mancuerna"),
        "Kettlebell Swing" to listOf("kb swing", "kbs", "swing de pesa rusa"),
        "Air bike" to listOf("assault bike", "abike", "bicicleta de aire"),
        "Echo bike" to listOf("echo", "echo erg", "bicicleta echo"),
        "Sled push" to listOf("sledpush", "empujar trineo"),
        "Sled pull" to listOf("sledpull", "tirar de trineo"),
    )

    private fun key(value: String): String = Normalizer.normalize(value, Normalizer.Form.NFD)
        .replace(Regex("\\p{Mn}+"), "")
        .lowercase(Locale("es", "ES"))

    private fun aliasKey(raw: String): String {
        val folded = key(raw)
        val sb = StringBuilder()
        for (ch in folded) {
            if (ch.isLetterOrDigit()) sb.append(ch)
            else if (!sb.endsWith(" ")) sb.append(" ")
        }
        return sb.toString().trim()
    }

    private val normalizedSupplementalAliases: Map<String, String> by lazy {
        val values = mutableMapOf<String, String>()
        for ((canonical, aliases) in supplementalAliases) {
            for (alias in aliases) {
                val normalized = aliasKey(alias)
                if (normalized.isEmpty()) continue
                values.putIfAbsent(normalized, canonical)
            }
        }
        values
    }

    fun searchAliases(name: String): List<String> {
        val canonical = canonicalName(name)
        val direct = supplementalAliases[canonical]
            ?: supplementalAliases.entries.firstOrNull { key(it.key) == key(canonical) }?.value
            ?: emptyList()
        val spanish = spanishAlias(canonical)?.let { listOf(it) } ?: emptyList()
        return (direct + spanish).toSet().sorted()
    }

    /** Permite al buscador y al lector de pizarra resolver siglas sin modificar IDs. */
    fun canonicalNameForSearchAlias(raw: String): String? = normalizedSupplementalAliases[aliasKey(raw)]

    private val englishToSpanish: Map<String, String> by lazy {
        val aliases = originalEnglishAliases.toMutableMap()
        for ((spanish, english) in legacySpanishToEnglish) aliases[english] = spanish
        aliases
    }

    private val normalizedSpanishToEnglish: Map<String, String> by lazy {
        legacySpanishToEnglish.mapKeys { (k, _) -> key(k) }
    }

    private val normalizedEnglishToSpanish: Map<String, String> by lazy {
        englishToSpanish.mapKeys { (k, _) -> key(k) }
    }

    /**
     * Nombre unificado por locale de la app (extra Ramón):
     * es → «Cargada y envión»; en → «Clean and Jerk». Misma cadena en
     * detalle, Reordenar, Inicio y Wear.
     */
    fun displayName(
        name: String,
        sport: String?,
        locale: java.util.Locale = java.util.Locale.getDefault()
    ): String {
        if (sport != "CrossFit" && sport != "Halterofilia") return name
        val preferSpanish = locale.language.startsWith("es", ignoreCase = true)
        return if (preferSpanish) {
            spanishAlias(name) ?: name
        } else {
            canonicalName(name)
        }
    }

    /**
     * Nombre para UI en es-ES (Wear / pantallas localizadas): CrossFit y
     * Halterofilia muestran el alias español («Cargada y envión»), no el
     * canónico EN («Clean and Jerk»). Ramón 2026-10-29.
     */
    fun localizedSpanishName(name: String, sport: String?): String {
        if (sport != "CrossFit" && sport != "Halterofilia") return name
        return spanishAlias(name) ?: spanishAlias(canonicalName(name)) ?: name
    }

    /** Puente de nombres antiguos en entrenos locales/cloud y en buscadores. */
    fun canonicalName(name: String): String =
        legacySpanishToEnglish[name] ?: normalizedSpanishToEnglish[key(name)] ?: name

    /** Nombre español conservado como alias, sin alterar la identidad del ejercicio. */
    fun spanishAlias(name: String): String? =
        normalizedEnglishToSpanish[key(name)]
            ?: if (normalizedSpanishToEnglish[key(name)] == null) null else name

    /** Alias técnicos EN->ES para indexación o resolución inversa de la pizarra. */
    fun englishAliasForSpanish(name: String): String? = normalizedSpanishToEnglish[key(name)]
}
