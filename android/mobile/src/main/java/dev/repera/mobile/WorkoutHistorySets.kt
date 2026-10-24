package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject

/**
 * Presentation-only effective training sets, matching StatsEngine.effectiveWorkSets on iOS.
 *
 * Never inserts synthetic LoggedSet into the workout JSON. A completed workout with no
 * positive work records displays every accepted prescribed work set; incomplete workouts
 * never do. Actual recorded sets (including warmups) take precedence.
 */
internal object WorkoutHistorySets {
    /** Effective positive working sets for statistics; never writes inferred sets to disk. */
    data class EffectiveSet(
        val reps: Int, val weightKg: Double?, val unit: String,
        val durationSeconds: Int? = null, val mobilityHold: Boolean = false
    )

    fun effectiveWorkSets(workout: JSONObject, exercise: JSONObject): List<EffectiveSet> {
        val logged = exercise.optJSONArray("loggedSets") ?: JSONArray()
        val actual = (0 until logged.length()).mapNotNull { n ->
            val set = logged.getJSONObject(n)
            val seconds = set.optInt("durationSeconds").takeIf {
                set.has("durationSeconds") && it > 0
            }
            // A time-only cardio entry is real work even if its distance or reps
            // are deliberately zero. Never replace it with planned strength sets.
            if (set.optString("phase", "work") == "warmup" ||
                (set.optInt("reps") <= 0 && seconds == null))
                null else EffectiveSet(set.optInt("reps"),
                    valueOrNull(set, "weightKg"), resolvedUnit(set, exercise),
                    seconds,
                    exercise.optJSONObject("exercise")?.optString("sportTag") == "Movilidad" &&
                        exercise.optJSONObject("exercise")?.optString("catalogId") in setOf(
                            "mobility-14","mobility-15","mobility-16","mobility-20",
                            "mobility-21","mobility-30","mobility-31","mobility-32",
                            "mobility-36","mobility-38","mobility-39","mobility-40",
                            "mobility-41","mobility-42","mobility-44","mobility-46",
                            "mobility-60","mobility-61","mobility-62","mobility-67",
                            "mobility-70","mobility-80"
                        ))
        }
        if (actual.isNotEmpty()) return actual
        // A score-only WOD has no work-set history. Its prescribed movement targets
        // must not become artificial confirmed sets after the global score is saved.
        if (exercise.optString("blockKind") == "wod" ||
            exercise.optJSONObject("exercise")?.optString("sportTag") == "Movilidad")
            return emptyList()
        val finished = workout.optString("phase") == "finished" ||
            (workout.has("finishedAt") && !workout.isNull("finishedAt") &&
                workout.optString("finishedAt").isNotBlank())
        if (!finished) return emptyList()
        val planned = exercise.optJSONArray("plannedSets") ?: return emptyList()
        return (0 until planned.length()).mapNotNull { n ->
            val set = planned.getJSONObject(n)
            if (set.optInt("targetReps") <= 0) null else EffectiveSet(
                set.optInt("targetReps"), valueOrNull(set, "targetWeightKg"),
                resolvedUnit(set, exercise))
        }
    }

    fun displayLines(workout: JSONObject, exercise: JSONObject): List<String> {
        val recorded = exercise.optJSONArray("loggedSets") ?: JSONArray()
        val actual = (0 until recorded.length()).map { recorded.getJSONObject(it) }
        val validWork = actual.any { set ->
            set.optString("phase", "work") != "warmup" &&
                (set.optInt("reps") > 0 || set.optInt("durationSeconds") > 0)
        }
        val actualLines = actual.map { set ->
            line(
                reps = set.optInt("reps"),
                quantityUnit = resolvedUnit(set, exercise),
                weight = valueOrNull(set, "weightKg"),
                deficitCm = set.optInt("deficitCm").takeIf {
                    set.has("deficitCm") && !set.isNull("deficitCm")
                },
                rir = valueOrNull(set, "rir"),
                durationSeconds = set.optInt("durationSeconds").takeIf {
                    set.has("durationSeconds") && it > 0
                },
                warmup = set.optString("phase", "work") == "warmup"
            )
        }
        val finished = workout.optString("phase") == "finished" ||
            (workout.has("finishedAt") && !workout.isNull("finishedAt") &&
                workout.optString("finishedAt").isNotBlank())
        if (validWork || !finished || exercise.optString("blockKind") == "wod" ||
            exercise.optJSONObject("exercise")?.optString("sportTag") == "Movilidad")
            return actualLines

        val planned = exercise.optJSONArray("plannedSets") ?: return actualLines
        val accepted = (0 until planned.length()).mapNotNull { n ->
            planned.getJSONObject(n).takeIf { it.optInt("targetReps") > 0 }
        }
        if (accepted.isEmpty()) return actualLines

        // Do not present zero-rep work placeholders as completed sets.
        val warmups = actualLines.filterIndexed { index, _ ->
            actual[index].optString("phase", "work") == "warmup"
        }
        return warmups + accepted.map { set ->
            line(
                reps = set.getInt("targetReps"),
                quantityUnit = resolvedUnit(set, exercise),
                weight = valueOrNull(set, "targetWeightKg"),
                deficitCm = null,
                rir = valueOrNull(set, "targetRir"),
                durationSeconds = null,
                warmup = false
            )
        }
    }

    /**
     * Series realmente registradas con su identidad: base de la edición de
     * entrenos terminados. Nunca incluye el fallback a series planificadas:
     * un objetivo pendiente no es una repetición realizada.
     */
    fun loggedSetsWithLines(exercise: JSONObject): List<Pair<String, String>> {
        val recorded = exercise.optJSONArray("loggedSets") ?: return emptyList()
        return (0 until recorded.length()).map { i ->
            val set = recorded.getJSONObject(i)
            set.optString("id") to line(
                reps = set.optInt("reps"),
                quantityUnit = resolvedUnit(set, exercise),
                weight = valueOrNull(set, "weightKg"),
                deficitCm = set.optInt("deficitCm").takeIf {
                    set.has("deficitCm") && !set.isNull("deficitCm")
                },
                rir = valueOrNull(set, "rir"),
                durationSeconds = set.optInt("durationSeconds").takeIf {
                    set.has("durationSeconds") && it > 0
                },
                warmup = set.optString("phase", "work") == "warmup"
            )
        }
    }

    private fun valueOrNull(json: JSONObject, key: String): Double? =
        if (json.has(key) && !json.isNull(key)) json.optDouble(key)
            .takeIf { it.isFinite() } else null

    private fun resolvedUnit(set: JSONObject, exercise: JSONObject): String {
        val raw = sequenceOf(
            set.optString("quantityUnit"),
            exercise.optString("quantityUnit"),
            exercise.optJSONObject("exercise")?.optString("defaultQuantityUnit").orEmpty()
        ).firstOrNull { it.isNotBlank() } ?: "reps"
        return when (raw) {
            "calories" -> "cal"
            "meters" -> "m"
            else -> "reps"
        }
    }

    private fun line(reps: Int, quantityUnit: String, weight: Double?, deficitCm: Int?,
                     rir: Double?, durationSeconds: Int?, warmup: Boolean): String = buildString {
        if (warmup) append("Calentamiento · ")
        append("$reps $quantityUnit")
        if (weight != null) append(" · $weight kg")
        if (deficitCm != null) append(" · $deficitCm cm déficit")
        if (rir != null) append(" · RIR $rir")
        if (durationSeconds != null)
            append(" · ${durationSeconds / 60}:${(durationSeconds % 60).toString().padStart(2, '0')}")
    }
}
