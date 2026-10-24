package dev.repera.domain

import kotlin.math.min
import kotlin.math.pow

enum class FatigueState(val wire: String, val label: String) {
    READY("ready", "Listo"),
    RECOVERING("recovering", "Recuperando"),
    FATIGUED("fatigued", "Fatigado")
}

data class MuscleStatus(
    val name: String,
    val score: Double,
    val state: FatigueState,
    val setsLast7Days: Double
)

/** Serie registrada reducida a lo que la fatiga necesita. */
data class MuscleStimulusSet(
    val reps: Int,
    val isWarmup: Boolean = false,
    val rir: Double? = null,
    val weightKg: Double? = null,
    val durationSeconds: Int? = null,
    val isMachineQuantity: Boolean = false
) {
    /** Port 1:1 de LoggedSet.fatigueSetEquivalent (Models.swift:774). */
    val fatigueSetEquivalent: Double
        get() {
            if (isWarmup) return 0.25
            if (isMachineQuantity || (durationSeconds != null && weightKg == null)) {
                val minutes = maxOf(durationSeconds ?: 60, 30) / 60.0
                return min(3.0, maxOf(0.5, minutes))
            }
            if (Effort.isHard(rir)) return 1.0
            return 0.7
        }
}

/** Ejercicio de sesión con sus campos de estímulo. */
data class MuscleStimulusExercise(
    val sportTag: String? = null,
    val targetMuscle: String? = null,
    val primaryRegions: List<String> = emptyList(),
    val secondaryMuscles: List<String> = emptyList(),
    val secondaryRegions: List<String> = emptyList(),
    val bodyPart: String? = null,
    val muscleGroup: String? = null,
    val sets: List<MuscleStimulusSet> = emptyList()
) {
    val weights: Map<String, Double>
        get() = MuscleTaxonomy.muscleWeights(
            targetMuscle, primaryRegions, secondaryMuscles, secondaryRegions,
            bodyPart, muscleGroup)
}

data class MuscleStimulusWorkout(
    val epochMillis: Long,
    val exercises: List<MuscleStimulusExercise>
)

/** Estímulo externo (p. ej. Salud) ya resuelto a carga por músculo. */
data class ExternalMuscleStimulus(
    val epochMillis: Long,
    val load: Map<String, Double>
)

/** Fatiga / recuperación por músculo (BodyMap slugs): el estímulo decae
 *  con vida media. Port 1:1 de MuscleMapEngine.swift (iOS). */
object MuscleMapEngine {
    private val halfLifeHours: Map<String, Double> = mapOf(
        "chest" to 30.0,
        "upper-back" to 30.0,
        "trapezius" to 28.0,
        "lower-back" to 36.0,
        "deltoids" to 24.0,
        "serratus" to 24.0,
        "biceps" to 24.0,
        "triceps" to 24.0,
        "forearm" to 20.0,
        "abs" to 24.0,
        "obliques" to 24.0,
        "gluteal" to 48.0,
        "quadriceps" to 48.0,
        "hamstring" to 48.0,
        "adductors" to 40.0,
        "hip-flexors" to 36.0,
        "calves" to 36.0,
        "tibialis" to 24.0
    )

    /** Estímulo retenido ahora (0…~1.5+). Más alto = más fatiga residual. */
    fun retainedLoad(
        workouts: List<MuscleStimulusWorkout>,
        external: List<ExternalMuscleStimulus> = emptyList(),
        hardOnly: Boolean = false,
        nowMillis: Long = System.currentTimeMillis()
    ): Map<String, Double> {
        val stimulus = mutableMapOf<String, Double>()

        for (workout in workouts) {
            val ageHours = (nowMillis - workout.epochMillis) / 3_600_000.0
            if (ageHours < 0 || ageHours >= 30 * 24) continue

            for (entry in workout.exercises) {
                // La movilidad no representa volumen de fuerza ni fatiga muscular.
                if (entry.sportTag == "Movilidad") continue
                var hardSets = 0.0
                for (set in entry.sets) {
                    if (set.reps <= 0) continue
                    if (hardOnly) {
                        // Solo fuerza «dura» (RIR); cardio/máquina no entra.
                        if (set.isWarmup || set.isMachineQuantity) continue
                        if (set.weightKg == null && set.durationSeconds != null) continue
                        if (Effort.isHard(set.rir)) hardSets += 1.0
                    } else {
                        hardSets += set.fatigueSetEquivalent
                    }
                }
                if (hardSets <= 0) continue
                val capped = min(hardSets, 12.0)
                for ((slug, w) in entry.weights) {
                    val hl = halfLifeHours[slug] ?: 30.0
                    val retained = capped * w * 0.5.pow(ageHours / hl)
                    stimulus[slug] = (stimulus[slug] ?: 0.0) + retained
                }
            }
        }

        for (sample in external) {
            val ageHours = (nowMillis - sample.epochMillis) / 3_600_000.0
            if (ageHours < 0 || ageHours >= 30 * 24) continue
            for ((slug, w) in sample.load) {
                if (w <= 0) continue
                val hl = halfLifeHours[slug] ?: 30.0
                stimulus[slug] = (stimulus[slug] ?: 0.0) + w * 0.5.pow(ageHours / hl)
            }
        }

        // Normaliza: ~8 unidades serie-dura·peso ≈ score 1.0
        val scores = mutableMapOf<String, Double>()
        for (slug in MuscleTaxonomy.muscles) {
            val raw = (stimulus[slug] ?: 0.0) / 8.0
            if (raw > 0) scores[slug] = min(1.5, raw)
        }
        return scores
    }

    /** Niveles absolutos para el mapa (misma leyenda siempre):
     *  0 sin estímulo · 1 listo · 2 suave · 3 recuperando · 4 fatigado. */
    fun levels(scores: Map<String, Double>): Map<String, Int> =
        MuscleTaxonomy.muscles.associateWith { level(scores[it] ?: 0.0) }

    fun level(score: Double): Int = when {
        score <= 0 -> 0
        score < 0.25 -> 1
        score < 0.5 -> 2
        score < 0.85 -> 3
        else -> 4
    }

    fun state(score: Double): FatigueState = when {
        score < 0.25 -> FatigueState.READY
        score <= 0.5 -> FatigueState.RECOVERING
        else -> FatigueState.FATIGUED
    }

    /** Un `MuscleStatus` por slug con estímulo (para listados). */
    fun statuses(
        workouts: List<MuscleStimulusWorkout>,
        external: List<ExternalMuscleStimulus> = emptyList(),
        hardOnly: Boolean = false,
        nowMillis: Long = System.currentTimeMillis()
    ): List<MuscleStatus> {
        val scores = retainedLoad(workouts, external, hardOnly, nowMillis)
        val weekAgo = nowMillis - 7L * 24 * 3_600_000
        val weekly = mutableMapOf<String, Double>()
        for (workout in workouts) {
            if (workout.epochMillis < weekAgo) continue
            for (entry in workout.exercises) {
                if (entry.sportTag == "Movilidad") continue
                val sets = entry.sets.count { !it.isWarmup && it.reps > 0 }
                if (sets <= 0) continue
                for ((slug, w) in entry.weights) {
                    weekly[slug] = (weekly[slug] ?: 0.0) + w * sets
                }
            }
        }
        return MuscleTaxonomy.muscles.mapNotNull { slug ->
            val score = scores[slug] ?: 0.0
            if (score <= 0 && (weekly[slug] ?: 0.0) <= 0) return@mapNotNull null
            MuscleStatus(slug, score, state(score), weekly[slug] ?: 0.0)
        }.sortedByDescending { it.score }
    }
}
