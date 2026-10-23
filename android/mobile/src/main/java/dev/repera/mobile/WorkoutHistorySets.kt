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
    fun displayLines(workout: JSONObject, exercise: JSONObject): List<String> {
        val recorded = exercise.optJSONArray("loggedSets") ?: JSONArray()
        val actual = (0 until recorded.length()).map { recorded.getJSONObject(it) }
        val validWork = actual.any { set ->
            set.optString("phase", "work") != "warmup" && set.optInt("reps") > 0
        }
        val actualLines = actual.map { set ->
            line(
                reps = set.optInt("reps"),
                quantityUnit = resolvedUnit(set, exercise),
                weight = valueOrNull(set, "weightKg"),
                rir = valueOrNull(set, "rir"),
                warmup = set.optString("phase", "work") == "warmup"
            )
        }
        val finished = workout.optString("phase") == "finished" ||
            (workout.has("finishedAt") && !workout.isNull("finishedAt") &&
                workout.optString("finishedAt").isNotBlank())
        if (validWork || !finished) return actualLines

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
                rir = valueOrNull(set, "targetRir"),
                warmup = false
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

    private fun line(reps: Int, quantityUnit: String, weight: Double?, rir: Double?,
                     warmup: Boolean): String = buildString {
        if (warmup) append("Calentamiento · ")
        append("$reps $quantityUnit")
        if (weight != null) append(" · $weight kg")
        if (rir != null) append(" · RIR $rir")
    }
}
