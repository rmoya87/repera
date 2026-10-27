package dev.repera.domain

/**
 * Port 1:1 de MuscleLoadEngine (iOS, MuscleTaxonomy.swift): series efectivas
 * por músculo en la ventana (entrenos Repera + estímulos Salud). El caller ya
 * filtra la ventana (equivale a window .all sobre datos filtrados por periodo,
 * misma semántica que los preparedLoad* de ProgressSnapshot en iOS).
 */
object MuscleLoadEngine {

    /** Series efectivas por músculo: reps>0, no calentamiento; hardOnly exige RIR duro. */
    fun load(
        workouts: List<MuscleStimulusWorkout>,
        external: List<ExternalMuscleStimulus> = emptyList(),
        hardOnly: Boolean = false
    ): Map<String, Double> {
        val load = mutableMapOf<String, Double>()
        for (workout in workouts) {
            for (entry in workout.exercises) {
                val sets = entry.sets.count { set ->
                    if (set.reps <= 0 || set.isWarmup) return@count false
                    if (hardOnly) Effort.isHard(set.rir) else true
                }
                // Apple (live main) MuscleLoadEngine.load: un WOD completado sin series
                // desglosadas aporta el equivalente estimado solo en modo fatiga; en
                // hardOnly nunca se inventa esfuerzo alto.
                val estimated = if (hardOnly) 0.0 else entry.completedWodSetEquivalent
                val effectiveSets = if (sets > 0) sets.toDouble() else estimated
                if (effectiveSets <= 0) continue
                for ((slug, w) in entry.weights) {
                    load[slug] = (load[slug] ?: 0.0) + w * effectiveSets
                }
            }
        }
        for (stimulus in external) {
            for ((slug, w) in stimulus.load) {
                load[slug] = (load[slug] ?: 0.0) + w
            }
        }
        return load
    }

    /** Niveles relativos 0..4 contra el máximo del periodo (modo sin fatiga). */
    fun levels(load: Map<String, Double>): Map<String, Int> {
        val maxLoad = MuscleTaxonomy.muscles.maxOfOrNull { load[it] ?: 0.0 } ?: 0.0
        val out = mutableMapOf<String, Int>()
        for (slug in MuscleTaxonomy.muscles) {
            val v = load[slug] ?: 0.0
            out[slug] = if (v <= 0 || maxLoad <= 0) 0
            else maxOf(1, minOf(4, kotlin.math.ceil(v / maxLoad * 4).toInt()))
        }
        return out
    }

    /** Trabajados (ordenados por carga desc) y omitidos del periodo. */
    fun ranked(load: Map<String, Double>): Pair<List<String>, List<String>> {
        val worked = MuscleTaxonomy.muscles
            .filter { (load[it] ?: 0.0) > 0 }
            .sortedByDescending { load[it] ?: 0.0 }
        val missed = MuscleTaxonomy.muscles.filter { (load[it] ?: 0.0) <= 0 }
        return worked to missed
    }
}
