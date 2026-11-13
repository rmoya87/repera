package dev.repera.mobile

import dev.repera.domain.WorkoutCollaboration
import dev.repera.domain.WorkoutPhase
import dev.repera.domain.WorkoutPhaseKind
import dev.repera.domain.WorkoutResultMetric
import dev.repera.domain.WorkoutSection
import dev.repera.domain.WorkoutStructure
import dev.repera.domain.WorkoutStrengthTechnique
import dev.repera.domain.WorkoutSetMethod
import dev.repera.domain.WorkoutPhaseResult
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

/** Stable wire keys shared with Swift Codable. Optional: all legacy blocks
 * without structure remain valid and readable. */
internal object WorkoutStructureWire {
    fun encode(value: WorkoutStructure): JSONObject = JSONObject()
        .put("version", value.version)
        .apply {
            value.section?.let { put("section", it.name) }
            value.collaboration?.let { put("collaboration", it.name) }
            value.resultMetric?.let { put("resultMetric", it.name) }
            put("phases", JSONArray().apply { value.phases.forEach { put(phaseJson(it)) } })
        }

    private fun phaseJson(value: WorkoutPhase): JSONObject = JSONObject()
        .put("id", value.id)
        .put("kind", value.kind.name)
        .put("title", value.title)
        .put("movementIDs", JSONArray(value.movementIDs))
        .apply {
            value.repeatCount?.let { put("repeatCount", it) }
            value.workSeconds?.let { put("workSeconds", it) }
            value.restSeconds?.let { put("restSeconds", it) }
            value.notes?.let { put("notes", it) }
            value.technique?.let { put("technique", encodeTechnique(it)) }
            put("children", JSONArray().apply { value.children.forEach { put(phaseJson(it)) } })
        }

    fun encodeTechnique(value: WorkoutStrengthTechnique): JSONObject = JSONObject()
        .put("method", value.method.name)
        .apply {
            value.tempo?.let { put("tempo", it) }
            value.pauseSeconds?.let { put("pauseSeconds", it) }
            value.intraSetRestSeconds?.let { put("intraSetRestSeconds", it) }
            value.clusterReps?.let { put("clusterReps", it) }
            put("dropPercentages", JSONArray(value.dropPercentages))
        }

    private fun decodeTechnique(raw: JSONObject?): WorkoutStrengthTechnique? = runCatching {
        val data = raw ?: return null
        val drops = data.optJSONArray("dropPercentages") ?: JSONArray()
        val technique = WorkoutStrengthTechnique(
            method = WorkoutSetMethod.valueOf(data.getString("method")),
            tempo = data.optString("tempo").takeIf { it.isNotBlank() },
            pauseSeconds = data.optInt("pauseSeconds").takeIf { data.has("pauseSeconds") },
            intraSetRestSeconds = data.optInt("intraSetRestSeconds").takeIf { data.has("intraSetRestSeconds") },
            clusterReps = data.optInt("clusterReps").takeIf { data.has("clusterReps") },
            dropPercentages = (0 until drops.length()).map { drops.getDouble(it) }
        )
        technique.takeIf { it.isValid }
    }.getOrNull()

    fun encodePhaseResult(value: WorkoutPhaseResult): JSONObject {
        require(value.isValid)
        return JSONObject().put("id", value.id).put("phaseID", value.phaseID)
            .put("iteration", value.iteration).apply {
                value.participantIndex?.let { put("participantIndex", it) }
                value.movementID?.let { put("movementID", it) }
                value.completedReps?.let { put("completedReps", it) }
                value.roundsCompleted?.let { put("roundsCompleted", it) }
                value.elapsedSeconds?.let { put("elapsedSeconds", it) }
                value.measuredValue?.let { put("measuredValue", it) }
                value.measuredMetric?.let { put("measuredMetric", it.name) }
                value.notes?.let { put("notes", it) }
            }
    }

    fun decodePhaseResult(raw: JSONObject): WorkoutPhaseResult? = runCatching {
        val result = WorkoutPhaseResult(
            id = raw.optString("id").takeIf { it.isNotBlank() } ?: UUID.randomUUID().toString(),
            phaseID = raw.getString("phaseID"),
            iteration = raw.getInt("iteration"),
            participantIndex = raw.optInt("participantIndex").takeIf { raw.has("participantIndex") },
            movementID = raw.optString("movementID").takeIf { it.isNotBlank() },
            completedReps = raw.optInt("completedReps").takeIf { raw.has("completedReps") },
            roundsCompleted = raw.optInt("roundsCompleted").takeIf { raw.has("roundsCompleted") },
            elapsedSeconds = raw.optInt("elapsedSeconds").takeIf { raw.has("elapsedSeconds") },
            measuredValue = raw.optDouble("measuredValue").takeIf { raw.has("measuredValue") },
            measuredMetric = raw.optString("measuredMetric").takeIf { it.isNotBlank() }
                ?.let { dev.repera.domain.WorkoutResultMetric.valueOf(it) },
            notes = raw.optString("notes").takeIf { it.isNotBlank() }
        )
        result.takeIf { it.isValid }
    }.getOrNull()

    fun decode(raw: JSONObject?): WorkoutStructure? = runCatching {
        val source = raw ?: return null
        val version = source.optInt("version", 1)
        if (version != 1) return null
        val phases = source.optJSONArray("phases") ?: JSONArray()
        if (phases.length() > 40) return null
        WorkoutStructure(
            version = version,
            section = source.optString("section").takeIf { it.isNotEmpty() }
                ?.let { WorkoutSection.valueOf(it) },
            collaboration = source.optString("collaboration").takeIf { it.isNotEmpty() }
                ?.let { WorkoutCollaboration.valueOf(it) },
            resultMetric = source.optString("resultMetric").takeIf { it.isNotEmpty() }
                ?.let { WorkoutResultMetric.valueOf(it) },
            phases = (0 until phases.length()).map { decodePhase(phases.getJSONObject(it), 0) }
        )
    }.getOrNull()

    private fun decodePhase(raw: JSONObject, depth: Int): WorkoutPhase {
        require(depth < 4) { "Nested workout phases exceed the safety limit" }
        val children = raw.optJSONArray("children") ?: JSONArray()
        require(children.length() <= 40)
        val ids = raw.optJSONArray("movementIDs") ?: JSONArray()
        require(ids.length() <= 50)
        return WorkoutPhase(
            id = raw.getString("id"),
            kind = WorkoutPhaseKind.valueOf(raw.getString("kind")),
            title = raw.getString("title"),
            movementIDs = (0 until ids.length()).map { ids.getString(it) },
            repeatCount = raw.optInt("repeatCount").takeIf { raw.has("repeatCount") && it in 1..200 },
            workSeconds = raw.optInt("workSeconds").takeIf { raw.has("workSeconds") && it in 1..86400 },
            restSeconds = raw.optInt("restSeconds").takeIf { raw.has("restSeconds") && it in 0..86400 },
            notes = raw.optString("notes").takeIf { it.isNotEmpty() },
            technique = decodeTechnique(raw.optJSONObject("technique")),
            children = (0 until children.length()).map { decodePhase(children.getJSONObject(it), depth + 1) }
        )
    }
}
