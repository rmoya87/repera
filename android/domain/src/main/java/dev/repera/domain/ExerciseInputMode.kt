package dev.repera.domain

/** Exercise.loggingStyle / loadField conventions from ReperaDomain.Models.swift. */
enum class ExerciseInputMode(val basicRecorderAvailable: Boolean, val showsWeight: Boolean) {
    LOAD_REPS(true, true),
    REPS_ONLY(true, false),
    REPS_AND_TIME(true, false),
    MACHINE_WORK(true, false),
    LOAD_DISTANCE(true, true),
    HSPU_DEFICIT(true, false)
}

object ExerciseInput {
    /** Apple Models.swift normalizeExerciseToken: minusculas + plegado de
     *  diacriticos, SIN colapsar puntuacion (las apostrofes cuentan). */
    fun normalizeExerciseToken(raw: String): String =
        java.text.Normalizer.normalize(raw.lowercase(), java.text.Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")

    /** Apple Models.swift supportsWeightedRepsOrMeters: distancia o repeticiones
     *  prescribibles junto con carga REAL en kg. No implica convertir historicos. */
    fun supportsWeightedRepsOrMeters(name: String): Boolean {
        val key = normalizeExerciseToken(name)
        val loadedDistancePatterns = listOf(
            "walking lunge", "zancada caminando", "zancadas caminando",
            "zancadas andando", "sandbag lunge", "zancadas con saco",
            "farmer carry", "farmer walk", "farmers carry", "farmer's carry",
            "paseo del granjero", "paseo granjero",
            "yoke carry", "yoke walk", "paseo con yugo",
            "sled push", "sled pull", "sled drag",
            "empuje de trineo", "arrastre de trineo",
            "suitcase carry", "overhead carry", "front rack carry",
            "bear hug carry", "sandbag carry")
        return key == "walking lung" || loadedDistancePatterns.any { key.contains(it) }
    }

    /** Apple Models.swift supportsRepsOrMeters: recorridos sin lastre nunca activan kg. */
    fun supportsRepsOrMeters(name: String): Boolean {
        val key = normalizeExerciseToken(name)
        return supportsWeightedRepsOrMeters(name) ||
            key.startsWith("burpee broad jump") ||
            key.startsWith("burpee con salto de longitud") ||
            key.startsWith("bear crawl") || key.startsWith("gateo del oso")
    }

    /** Mirrors Swift Exercise.defaultQuantityUnit; never use reps for machine-work by default. */
    fun defaultQuantityUnit(name: String, equipment: String?): String {
        val n = normalizeExerciseToken(name)
        // Apple: solo Walking lunge empieza en reps por retrocompatibilidad; los
        // transportes, empujes y saltos de longitud suelen prescribirse en m.
        if (supportsRepsOrMeters(name)) {
            if (n == "walking lung" || n.contains("walking lunge")
                || n.contains("zancada caminando") || n.contains("zancadas caminando")
                || n.contains("zancadas andando")) return "reps"
            return "meters"
        }
        val style = mode(name, equipment, null, null)
        if (style != ExerciseInputMode.MACHINE_WORK) return "reps"
        val rower = n.contains("rower") || n.contains("remoerg") ||
            n.contains("concept2") || (n.contains("remo") &&
            (n.contains("maquina") || n.contains("erg")))
        val run = listOf("carrera", "running", "run", "shuttle", "treadmill", "cinta")
            .any { n.contains(it) }
        return if (rower || run) "meters" else "calories"
    }

    fun supportsCaloriesAndMeters(name: String, equipment: String?): Boolean {
        if (mode(name, equipment, null, null) != ExerciseInputMode.MACHINE_WORK) return false
        val n = ExerciseAliasSearch.normalize(name)
        if (n == "burpee broad jump") return false
        return listOf("carrera", "running", "run", "shuttle", "treadmill", "cinta")
            .none { n.contains(it) }
    }

    fun mode(
        name: String, equipment: String?, target: String?, group: String?,
        sportTag: String? = null
    ): ExerciseInputMode {
        if (sportTag == "Movilidad") return ExerciseInputMode.REPS_AND_TIME
        val n = ExerciseAliasSearch.normalize(name)
        val eq = ExerciseAliasSearch.normalize(equipment ?: "")
        if (n in setOf("sled push", "sled pull", "farmer carry",
                "farmer walk", "sandbag lunges"))
            return ExerciseInputMode.LOAD_DISTANCE
        // Apple 1d1edc8b (cut Models.swift:380): TODOS los supportsWeightedRepsOrMeters
        // son loadAndReps (kg + reps/m); Android conserva LOAD_DISTANCE para los 5
        // Hyrox anteriores y deriva el resto (walking lunge, yoke, suitcase...)
        // a LOAD_REPS. Antes, "Walking lunge" peso corporal caia en REPS_ONLY
        // y no admitia carga.
        if (supportsWeightedRepsOrMeters(name)) return ExerciseInputMode.LOAD_REPS
        if (n == "burpee broad jump") return ExerciseInputMode.MACHINE_WORK
        // Apple (live main) Models.isJumpRope: su normalización conserva guiones; la nuestra
        // los convierte en espacios, así que "double under" ya cubre "double-under".
        if (eq.contains("comba") || n.contains("double under") ||
            n.contains("single under") || n.contains("triple under") ||
            (n.contains("doble") && n.contains("comba")) ||
            (n.contains("simple") && n.contains("comba")) ||
            (n.contains("triple") && n.contains("comba")) ||
            n == "du" || n.startsWith("du ") || n.startsWith("su ")) {
            return ExerciseInputMode.REPS_AND_TIME
        }
        val strengthRow = listOf("barra", "mancuerna", "sentado", "menton", "invert",
            "anilla", "polea", "landmine", "seal", "pendlay", "t bar")
            .any { n.contains(it) }
        val rowing = (n.contains("rower") || n.contains("concept2") ||
            n.contains("remoerg") || (n.contains("remo") && !strengthRow &&
                (n == "remo" || n.contains("maquina") || n.contains("erg"))))
        val cardio = listOf("air bike", "echo bike", "assault", "fan bike", "skierg",
            "ski erg", "wattbike", "carrera", "cinta", "shuttle", "running", "treadmill")
            .any { n.contains(it) }
        if (rowing || cardio || (eq.contains("trineo") && n.contains("sled")))
            return ExerciseInputMode.MACHINE_WORK
        // Burpee variants and bands never imply an external load in kilograms.
        if (n.contains("burpee")) return ExerciseInputMode.REPS_ONLY
        if ((eq.contains("banda") || eq.contains("goma")) &&
            !eq.contains("mancuerna") && !eq.contains("barra")) return ExerciseInputMode.REPS_ONLY
        val isHspu = n.contains("hspu") || n.contains("fondos en pino") ||
            n.contains("pino flex") || (n.contains("handstand") &&
            listOf("push", "press", "fond").any { n.contains(it) })
        if (isHspu) return ExerciseInputMode.HSPU_DEFICIT
        val isPull = listOf("dominad", "pull up", "pullup", "chin up", "muscle up")
            .any { n.contains(it) } || n == "mu" || n.startsWith("mu ")
        if (isPull) return ExerciseInputMode.LOAD_REPS
        val externalLoad = listOf("kettlebell", "mancuerna", "dumbbell", "barbell", "barra,", "disco",
            "saco", "lastre", "trineo", "yoke", "polea").any {eq.contains(it)}
        val support = listOf("cajon", "step", "anillas", "barra de dominadas", "barra fija",
            "cuerda de trepa", "pegboard", "paralelas", "pared", "banco", "rueda abdominal",
            "ghd", "plataforma elevada").any {eq.contains(it)}
        if (support && !externalLoad) return ExerciseInputMode.REPS_ONLY
        if (eq.contains("peso corporal") || (eq.isEmpty() &&
            ((target ?: "").lowercase().contains("cardiovascular") || group.equals("cardio", ignoreCase = true))) ||
            listOf("toes to", "burpee", "box jump", "salto al caj", "sit up", "air squat",
                "pistol", "hollow", "l sit", "handstand")
                .any { n.contains(it) }) return ExerciseInputMode.REPS_ONLY
        return ExerciseInputMode.LOAD_REPS
    }
}
