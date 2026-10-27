package dev.repera.mobile

import dev.repera.domain.ResultCapture
import dev.repera.domain.WodFormat
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Builds WOD session movements from actual RoutineBlock.movements.
 * Ports the source-of-truth block/movement layout, not artificial logged sets.
 * Per-movement formats remain gated until their recorder is functional.
 */
object WodSessionAssembler {
    fun supports(block: JSONObject): Boolean {
        if (block.optString("kind") != "wod") return false
        val format = WodFormat.fromWire(block.optString("wodFormat")) ?: return false
        val moves = block.optJSONArray("movements") ?: return false
        return (0 until moves.length()).any { !moves.getJSONObject(it).optBoolean("isRest") }
    }

    fun append(block: JSONObject, catalog: JSONArray, result: JSONArray) {
        require(supports(block)) { "Bloque WOD no válido" }
        val format = WodFormat.fromWire(block.getString("wodFormat"))!!
        val movements = block.getJSONArray("movements")
        for (n in 0 until movements.length()) {
            val move = movements.getJSONObject(n)
            if (move.optBoolean("isRest")) continue
            val name = move.getString("name")
            val preferredId = move.optString("exerciseId").takeIf { it.isNotBlank() }
            val fromCatalog = (0 until catalog.length())
                .map { catalog.getJSONObject(it) }
                .firstOrNull {
                    (preferredId != null && it.optString("id") == preferredId) ||
                        (it.optString("name").equals(name, ignoreCase = true))
                }
            // Swift SessionController.from can resolve an unrecognized WOD name
            // as a custom movement, but that must never imply it was performed.
            val exercise = fromCatalog?.let { JSONObject(it.toString()) } ?: JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("name", name)
                .put("muscleGroup", "WOD")
                .put("isCustom", true)
            // Apple SessionController.from: SessionExercise.id = id del movimiento de la rutina.
            val sessionMovement = JSONObject()
                .put("id", move.optString("id").ifBlank { UUID.randomUUID().toString() })
                .put("exercise", exercise)
                .put("plannedSets", plannedSets(move))
                .put("loggedSets", JSONArray())
                .put("completedReps", 0)
                .put("isCompleted", false)
                .put("blockId", block.getString("id"))
                .put("blockKind", "wod")
                .put("wodFormat", format.wireName)
                .put("blockHeader", block.optString("title"))
            if (block.has("timeCapMinutes") && !block.isNull("timeCapMinutes"))
                sessionMovement.put("blockTimeCapMinutes", block.getInt("timeCapMinutes"))
            if (block.has("emomIntervalSeconds") && !block.isNull("emomIntervalSeconds"))
                sessionMovement.put("blockIntervalSeconds", block.getInt("emomIntervalSeconds"))
            if (block.has("rounds") && !block.isNull("rounds"))
                sessionMovement.put("blockRounds", block.getInt("rounds"))
            if (block.has("workSeconds") && !block.isNull("workSeconds"))
                sessionMovement.put("blockWorkSeconds", block.getInt("workSeconds"))
            if (block.has("restSeconds") && !block.isNull("restSeconds"))
                sessionMovement.put("blockRestSeconds", block.getInt("restSeconds"))
            if (block.has("restBetweenRoundsSeconds") && !block.isNull("restBetweenRoundsSeconds"))
                sessionMovement.put("blockRestBetweenRoundsSeconds", block.getInt("restBetweenRoundsSeconds"))
            // Preserve the actual amount and unit from the board for previews;
            // WOD block scoring never creates individual movement logs.
            if (move.has("calories") && !move.isNull("calories"))
                sessionMovement.put("quantityUnit", "calories")
            else if (move.has("distanceMeters") && !move.isNull("distanceMeters"))
                sessionMovement.put("quantityUnit", "meters")
            result.put(sessionMovement)
        }
    }

    /** WODMovement.plannedSetsFromReps, never counted as confirmed performance. */
    private fun plannedSets(move: JSONObject): JSONArray {
        val explicit = move.optJSONArray("explicitPlannedSets")
        if (explicit != null && explicit.length() > 0)
            return JSONArray(explicit.toString())
        val scheme = move.optJSONArray("repScheme")
        val values = scheme?.let { (0 until it.length()).map { index -> it.getInt(index) } }
            ?: emptyList()
        val range = values.size == 2 && values[0] < values[1] &&
            values[1] - values[0] <= 20
        val reps = if (values.isNotEmpty() && !range) values
            else listOf(if (range) values[1] else move.optInt(
                if (move.has("calories")) "calories"
                else if (move.has("distanceMeters")) "distanceMeters" else "reps", 10
            ))
        return JSONArray().apply {
            for (rep in reps) {
                val planned = JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("targetReps", rep.coerceAtLeast(1))
                if (move.has("weightMaleKg") && !move.isNull("weightMaleKg"))
                    planned.put("targetWeightKg", move.getDouble("weightMaleKg"))
                put(planned)
            }
        }
    }
}
