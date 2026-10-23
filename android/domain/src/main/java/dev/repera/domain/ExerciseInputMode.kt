package dev.repera.domain

/** Exercise.loggingStyle / loadField conventions from ReperaDomain.Models.swift. */
enum class ExerciseInputMode(val basicRecorderAvailable: Boolean, val showsWeight: Boolean) {
    LOAD_REPS(true, true),
    REPS_ONLY(true, false),
    REPS_AND_TIME(false, false),
    MACHINE_WORK(false, false),
    HSPU_DEFICIT(false, false)
}

object ExerciseInput {
    fun mode(name: String, equipment: String?, target: String?, group: String?): ExerciseInputMode {
        val n = ExerciseAliasSearch.normalize(name)
        val eq = ExerciseAliasSearch.normalize(equipment ?: "")
        if (eq.contains("comba") || n.contains("double under") ||
            n.contains("single under") || n.contains("triple under") ||
            (n.contains("doble") && n.contains("comba")) ||
            (n.contains("simple") && n.contains("comba")) || n == "du" || n.startsWith("du ")) {
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
        val isHspu = n.contains("hspu") || n.contains("fondos en pino") ||
            n.contains("pino flex") || (n.contains("handstand") &&
            listOf("push", "press", "fond").any { n.contains(it) })
        if (isHspu) return ExerciseInputMode.HSPU_DEFICIT
        val isPull = listOf("dominad", "pull up", "pullup", "chin up", "muscle up")
            .any { n.contains(it) } || n == "mu" || n.startsWith("mu ")
        if (isPull) return ExerciseInputMode.LOAD_REPS
        if (eq.contains("peso corporal") || (eq.isEmpty() &&
            ((target ?: "").lowercase().contains("cardiovascular") || group == "Cardio")) ||
            listOf("toes to", "burpee", "box jump", "salto al caj", "sit up", "air squat",
                "pistol", "hollow", "l sit", "handstand")
                .any { n.contains(it) }) return ExerciseInputMode.REPS_ONLY
        return ExerciseInputMode.LOAD_REPS
    }
}
