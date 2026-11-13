package dev.repera.mobile

import dev.repera.domain.ComparableWodResult
import dev.repera.domain.WODComparisonEngine
import org.json.JSONArray
import org.json.JSONObject

/**
 * Only compares a completed session with the newest earlier *equivalent* WOD.
 * A title, template ID or score alone does not establish equivalence.
 */
internal object CompletedWODComparator {
    private val blockFields = listOf(
        "kind", "wodFormat", "timeCapMinutes", "timeCapSeconds", "structure",
        "emomIntervalSeconds",
        "rounds", "workSeconds", "restSeconds", "restBetweenRoundsSeconds",
        "wodNotes", "wodTemplateId", "movements"
    )

    fun comparisonLabel(
        currentSession: JSONObject, history: List<JSONObject>, instanceId: String?
    ): String? {
        val finished = ExerciseSessionAppearances.epochOf(currentSession)
        if (finished <= 0L || currentSession.optString("finishedAt").isBlank()) return null
        val scores = currentSession.optJSONArray("wodResults") ?: return null
        val blockId = if (!instanceId.isNullOrBlank()) {
            val exercises = currentSession.optJSONArray("exercises") ?: return null
            (0 until exercises.length()).map { exercises.getJSONObject(it) }
                .firstOrNull { it.optString("id") == instanceId }
                ?.optString("blockId")?.takeIf { it.isNotBlank() }
        } else if (scores.length() == 1) {
            scores.getJSONObject(0).optString("id").takeIf { it.isNotBlank() }
        } else null
        if (blockId == null) return null
        val currentResult = (0 until scores.length()).map { scores.getJSONObject(it) }
            .firstOrNull { it.optString("id") == blockId } ?: return null
        val currentBlock = block(currentSession, blockId) ?: return null
        val currentAttempt = toComparable(currentSession, currentBlock, currentResult) ?: return null

        val eligibleHistory = history
            .filter { it.optString("id") != currentSession.optString("id") &&
                it.optString("finishedAt").isNotBlank() &&
                ExerciseSessionAppearances.epochOf(it) in 1 until finished }
            .sortedByDescending { ExerciseSessionAppearances.epochOf(it) }
        for (session in eligibleHistory) {
            val results = session.optJSONArray("wodResults") ?: continue
            for (i in 0 until results.length()) {
                val priorResult = results.getJSONObject(i)
                val priorBlock = block(session, priorResult.optString("id")) ?: continue
                val priorAttempt = toComparable(session, priorBlock, priorResult) ?: continue
                val precise = WODComparisonEngine.compareMeasurement(priorAttempt, currentAttempt)
                if (precise != null) {
                    val change = precise.improvement
                    val display = dev.repera.domain.ReperaNumberFormat.decimal(change)
                    return if (change == 0.0) "Misma marca en WOD comparable"
                        else (if (change > 0) "+" else "") + display + " " +
                            precise.unit + " frente al WOD comparable anterior"
                }
                val result = WODComparisonEngine.compare(priorAttempt, currentAttempt) ?: continue
                val prefix = if (result.improvement > 0) "+" else ""
                return if (result.improvement == 0) "Misma marca en WOD comparable"
                    else "$prefix${result.improvement} ${result.unit} frente al WOD comparable anterior"
            }
        }
        return null
    }

    private fun block(session: JSONObject, id: String): JSONObject? {
        val blocks = session.optJSONArray("routineBlocks") ?: session.optJSONArray("blocks")
            ?: return null
        return (0 until blocks.length()).map { blocks.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id && it.optString("kind") == "wod" }
    }

    private fun toComparable(
        session: JSONObject, block: JSONObject, result: JSONObject
    ): ComparableWodResult? {
        val rx = result.opt("isRx")
        val isRx = if (rx is Boolean) rx else return null
        val format = block.optString("wodFormat")
        if (format != result.optString("format")) return null
        val movements = block.optJSONArray("movements") ?: return null
        if (movements.length() == 0) return null
        val repsPerRound = if (format == "amrap") {
            var reps = 0
            for (i in 0 until movements.length()) {
                val movement = movements.getJSONObject(i)
                if (movement.optBoolean("isRest", false) ||
                    !movement.has("reps") || movement.isNull("reps") ||
                    movement.optInt("reps") <= 0 ||
                    movement.has("repScheme") && !movement.isNull("repScheme") ||
                    movement.has("distanceMeters") && !movement.isNull("distanceMeters") ||
                    movement.has("calories") && !movement.isNull("calories")) return null
                reps += movement.optInt("reps")
            }
            reps
        } else null
        val scale = scalingSignature(session, result.optString("id"))
        if (isRx && scale.isNotBlank()) return null
        if (!isRx && scale.isBlank()) return null
        val signature = blockFields.joinToString("|") { key -> canonical(block.opt(key)) }
        fun intOrNull(key: String): Int? =
            if (result.has(key) && !result.isNull(key)) result.optInt(key) else null
        val timeCap = block.optInt("timeCapSeconds").takeIf {
            block.has("timeCapSeconds") && !block.isNull("timeCapSeconds") && it > 0
        } ?: block.optInt("timeCapMinutes").takeIf {
            block.has("timeCapMinutes") && !block.isNull("timeCapMinutes") && it > 0
        }?.times(60)
        return ComparableWodResult(
            format = format,
            prescriptionFingerprint = signature,
            isRx = isRx,
            scalingFingerprint = scale,
            roundsCompleted = intOrNull("roundsCompleted"),
            extraReps = intOrNull("totalReps"),
            elapsedSeconds = intOrNull("elapsedSeconds"),
            repsPerRound = repsPerRound,
            timeCapSeconds = timeCap,
            measuredMetric = result.optString("measuredMetric").takeIf { it.isNotBlank() },
            measuredValue = result.optDouble("measuredValue").takeIf {
                result.has("measuredValue") && !result.isNull("measuredValue")
            }
        )
    }

    private fun scalingSignature(session: JSONObject, blockId: String): String {
        val exercises = session.optJSONArray("exercises") ?: return ""
        val modified = mutableListOf<String>()
        for (index in 0 until exercises.length()) {
            val item = exercises.getJSONObject(index)
            if (item.optString("blockId") != blockId) continue
            val reps = item.opt("adaptedReps")
            val kg = item.opt("adaptedWeightKg")
            if ((reps == null || reps == JSONObject.NULL) &&
                (kg == null || kg == JSONObject.NULL)) continue
            modified += canonical(listOf(
                item.optJSONObject("exercise")?.optString("name") ?: "",
                reps, kg
            ))
        }
        return modified.joinToString(";");
    }

    private fun canonical(value: Any?): String {
        return when (value) {
            null, JSONObject.NULL -> "null"
            is JSONObject -> value.keys().asSequence()
                .filter { it != "id" && it != "title" }
                .sorted().joinToString(",", "{", "}") { key -> key + ":" + canonical(value.opt(key)) }
            is JSONArray -> (0 until value.length()).joinToString(",", "[", "]") {
                canonical(value.opt(it))
            }
            is List<*> -> value.joinToString(",", "[", "]") { canonical(it) }
            else -> value.toString()
        }
    }
}
