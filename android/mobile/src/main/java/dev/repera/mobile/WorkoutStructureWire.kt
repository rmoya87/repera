package dev.repera.mobile

import dev.repera.domain.WorkoutCollaboration
import dev.repera.domain.WorkoutPhase
import dev.repera.domain.WorkoutPhaseKind
import dev.repera.domain.WorkoutResultMetric
import dev.repera.domain.WorkoutSection
import dev.repera.domain.WorkoutStructure
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
            put("children", JSONArray().apply { value.children.forEach { put(phaseJson(it)) } })
        }

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
            children = (0 until children.length()).map { decodePhase(children.getJSONObject(it), depth + 1) }
        )
    }
}
