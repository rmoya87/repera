package dev.repera.domain

/**
 * Traduce actividades externas de salud a estímulo muscular y muestras
 * diarias. Port 1:1 de HealthMuscleMapper.swift (iOS) con el tipo de
 * actividad como clave de texto normalizada (la capa Health Connect
 * mapea sus EXERCISE_TYPE_* a estas claves).
 */
object HealthMuscleMapper {

    /** Muestra externa para la actividad diaria. */
    data class ExternalActivity(
        val epochMillis: Long,
        val type: String,
        val durationMinutes: Double,
        val activeEnergyKcal: Double? = null
    )

    fun stimuli(from: List<ExternalActivity>): List<ExternalMuscleStimulus> =
        from.mapNotNull { activity ->
            val load = muscleLoad(activity.type, activity.durationMinutes)
            if (load.isEmpty()) null
            else ExternalMuscleStimulus(activity.epochMillis, load)
        }

    fun daySamples(from: List<ExternalActivity>): List<ExternalDaySample> =
        from.map { activity ->
            val mins = maxOf(0.0, activity.durationMinutes)
            ExternalDaySample(
                epochMillis = activity.epochMillis,
                minutes = mins,
                cardioMinutes = if (isCardio(activity.type)) mins else 0.0,
                activeEnergyKcal = maxOf(0.0, activity.activeEnergyKcal ?: 0.0),
                volumeKg = 0.0
            )
        }

    fun isCardio(type: String): Boolean = when (type) {
        "running", "walking", "hiking", "cycling", "handCycling",
        "swimming", "elliptical", "rowing", "stairClimbing",
        "highIntensityIntervalTraining", "mixedCardio", "crossTraining",
        "dance", "wheelchairRunPace", "paddleSports" -> true
        "traditionalStrengthTraining", "functionalStrengthTraining" -> false
        // Deportes y resto: cuentan como cardio para minutos de Progreso.
        else -> true
    }

    fun muscleLoad(type: String, durationMinutes: Double): Map<String, Double> {
        val sets = setUnits(durationMinutes, type)
        val template = template(type)
        if (template.isEmpty()) return emptyMap()
        return template.mapValues { it.value * sets }
    }

    /** Minutos por «serie efectiva»: deportes/HIIT pesan más que paseo. */
    private fun setUnits(durationMinutes: Double, type: String): Double {
        val minutesPerSet = when (type) {
            "highIntensityIntervalTraining", "mixedCardio", "crossTraining" -> 10.0
            "traditionalStrengthTraining", "functionalStrengthTraining",
            "coreTraining", "martialArts",
            "tennis", "pickleball", "racquetball", "squash", "badminton",
            "soccer", "basketball", "volleyball", "americanFootball",
            "baseball", "softball", "hockey", "lacrosse", "rugby",
            "boxing", "kickboxing", "wrestling" -> 12.0
            "running", "stairClimbing", "elliptical", "rowing", "swimming",
            "paddleSports", "cycling", "handCycling" -> 15.0
            "walking", "hiking", "wheelchairRunPace", "yoga", "pilates",
            "flexibility", "cooldown", "dance", "golf" -> 22.0
            else -> 16.0
        }
        return maxOf(0.5, durationMinutes / minutesPerSet)
    }

    private fun template(type: String): Map<String, Double> = when (type) {
        "running", "wheelchairRunPace" -> mapOf(
            "quadriceps" to 0.3, "hamstring" to 0.25, "gluteal" to 0.2,
            "calves" to 0.15, "tibialis" to 0.05, "abs" to 0.05)
        "walking", "hiking" -> mapOf(
            "quadriceps" to 0.3, "gluteal" to 0.25, "hamstring" to 0.2,
            "calves" to 0.15, "tibialis" to 0.1)
        "cycling", "handCycling" -> mapOf(
            "quadriceps" to 0.4, "hamstring" to 0.25, "gluteal" to 0.2,
            "calves" to 0.15)
        "swimming", "paddleSports" -> mapOf(
            "upper-back" to 0.2, "deltoids" to 0.15, "chest" to 0.1,
            "triceps" to 0.1, "biceps" to 0.1, "abs" to 0.1,
            "quadriceps" to 0.1, "hamstring" to 0.075, "gluteal" to 0.075)
        "rowing" -> mapOf(
            "upper-back" to 0.25, "biceps" to 0.15, "forearm" to 0.1,
            "abs" to 0.1, "quadriceps" to 0.15, "hamstring" to 0.1,
            "gluteal" to 0.1, "deltoids" to 0.05)
        "yoga", "pilates", "flexibility", "cooldown" -> mapOf(
            "abs" to 0.25, "obliques" to 0.15, "lower-back" to 0.15,
            "gluteal" to 0.15, "hip-flexors" to 0.15, "hamstring" to 0.15)
        "coreTraining" -> mapOf("abs" to 0.5, "obliques" to 0.3, "lower-back" to 0.2)
        "stairClimbing", "elliptical" -> mapOf(
            "quadriceps" to 0.35, "gluteal" to 0.3, "hamstring" to 0.2,
            "calves" to 0.15)
        "highIntensityIntervalTraining", "crossTraining", "mixedCardio" -> mapOf(
            "quadriceps" to 0.15, "hamstring" to 0.1, "gluteal" to 0.1,
            "chest" to 0.1, "upper-back" to 0.1, "deltoids" to 0.1,
            "abs" to 0.1, "biceps" to 0.075, "triceps" to 0.075, "calves" to 0.1)
        "traditionalStrengthTraining", "functionalStrengthTraining" -> mapOf(
            "chest" to 0.12, "upper-back" to 0.12, "deltoids" to 0.1,
            "quadriceps" to 0.12, "hamstring" to 0.1, "gluteal" to 0.1,
            "biceps" to 0.08, "triceps" to 0.08, "abs" to 0.08, "calves" to 0.1)
        "dance" -> mapOf(
            "gluteal" to 0.25, "quadriceps" to 0.2, "calves" to 0.2,
            "abs" to 0.15, "hip-flexors" to 0.2)
        "martialArts", "boxing", "kickboxing", "wrestling" -> mapOf(
            "deltoids" to 0.2, "abs" to 0.2, "obliques" to 0.15,
            "quadriceps" to 0.15, "calves" to 0.1, "upper-back" to 0.1,
            "triceps" to 0.1)
        "tennis", "pickleball", "racquetball", "squash", "badminton" -> mapOf(
            "quadriceps" to 0.2, "hamstring" to 0.12, "gluteal" to 0.12,
            "calves" to 0.12, "deltoids" to 0.15, "forearm" to 0.12,
            "obliques" to 0.1, "abs" to 0.07)
        "soccer", "basketball", "volleyball", "americanFootball",
        "baseball", "softball", "hockey", "lacrosse", "rugby" -> mapOf(
            "quadriceps" to 0.25, "hamstring" to 0.18, "gluteal" to 0.15,
            "calves" to 0.15, "abs" to 0.1, "deltoids" to 0.1, "obliques" to 0.07)
        "golf" -> mapOf(
            "obliques" to 0.3, "lower-back" to 0.2, "forearm" to 0.2,
            "deltoids" to 0.15, "abs" to 0.15)
        "downhillSkiing", "snowboarding", "skatingSports",
        "crossCountrySkiing", "snowSports" -> mapOf(
            "quadriceps" to 0.35, "gluteal" to 0.25, "hamstring" to 0.2,
            "calves" to 0.2)
        "climbing", "equestrianSports", "surfingSports", "waterFitness" -> mapOf(
            "forearm" to 0.2, "upper-back" to 0.2, "biceps" to 0.15,
            "deltoids" to 0.15, "abs" to 0.1, "quadriceps" to 0.1,
            "calves" to 0.1)
        // Cualquier otro workout de Salud aporta fatiga genérica.
        else -> mapOf(
            "quadriceps" to 0.2, "gluteal" to 0.15, "hamstring" to 0.15,
            "abs" to 0.15, "upper-back" to 0.15, "deltoids" to 0.1,
            "calves" to 0.1)
    }
}
