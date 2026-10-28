package dev.repera.mobile

import dev.repera.domain.CrossFitGlossary
import dev.repera.domain.WODHistoryPresentation
import org.json.JSONArray
import org.json.JSONObject

/**
 * Inactive, pure preview of catalog-reference repair. No store, network, clock,
 * caller or persistence. Apple owning sources: ReperaStore.relinkOrphanSessionExercisesToCatalog
 * and relinkScheduledWODMovementsToCatalog (0a640da8), plus ff097bf3 applyAndRelink.
 * Safety differences: never changes activeSession or private/custom exercises;
 * duplicate identities/aliases are reported, never resolved by first-match;
 * no seed insertion, fuzzy match or replacement of an existing non-WOD choice.
 */
internal object HistoricalCatalogRelink {
    data class Change(val path: String, val previousId: String, val nextId: String)
    data class Preview(val state: JSONObject, val changes: List<Change>, val ambiguous: List<String>)

    fun preview(source: JSONObject): Preview {
        val output = JSONObject(source.toString())
        val changes = mutableListOf<Change>()
        val ambiguous = mutableListOf<String>()
        val all = objects(output.optJSONArray("exercises"))
        val official = all.filter {
            !it.optBoolean("isCustom") && !it.optBoolean("isCatalogArchived") &&
                it.optString("id").isNotBlank() && it.optString("name").isNotBlank()
        }
        fun norm(s: String) = CrossFitGlossary.normalize(s)
        fun unique(candidates: List<JSONObject>, path: String): JSONObject? {
            if (candidates.size > 1) ambiguous.add(path)
            val hit = candidates.singleOrNull() ?: return null
            if (all.count { it.optString("id") == hit.optString("id") } != 1) {
                ambiguous.add(path)
                return null
            }
            return hit
        }
        fun target(id: String, name: String, catalogId: String, path: String): JSONObject? {
            if (all.any { it.optString("id") == id && it.optBoolean("isCustom") }) return null
            val canonical = WODHistoryPresentation.officialName(name)
            if (canonical != null) {
                return unique(official.filter { norm(it.optString("name")) == norm(canonical) }, path)
            }
            // Existing catalog IDs remain chosen by the user; repair orphans only.
            if (id.isNotBlank() && all.any { it.optString("id") == id }) return null
            if (catalogId.isNotBlank()) {
                val sameIdentity = official.filter { it.optString("catalogId") == catalogId }
                if (sameIdentity.isNotEmpty()) return unique(sameIdentity, path)
            }
            // Exact published name or alias only, with no fuzzy/canonical inference.
            if (name.isBlank()) return null
            val exact = official.filter { norm(it.optString("name")) == norm(name) }
            if (exact.isNotEmpty()) return unique(exact, path)
            return unique(official.filter { entry ->
                objectsStrings(entry.optJSONArray("searchAliases")).any { norm(it) == norm(name) }
            }, path)
        }
        for ((wi, workout) in objects(output.optJSONArray("workouts")).withIndex()) {
            for ((ei, item) in objects(workout.optJSONArray("exercises")).withIndex()) {
                val snapshot = item.optJSONObject("exercise") ?: continue
                if (snapshot.optBoolean("isCustom")) continue
                val path = "workouts[$wi].exercises[$ei].exercise"
                val oldId = snapshot.optString("id")
                val match = target(oldId, snapshot.optString("name"), snapshot.optString("catalogId"), path)
                    ?: continue
                if (snapshot.toString() != match.toString()) {
                    item.put("exercise", JSONObject(match.toString()))
                    changes.add(Change(path, oldId, match.optString("id")))
                }
            }
        }
        for ((ri, routine) in objects(output.optJSONArray("routines")).withIndex()) {
            for ((bi, block) in objects(routine.optJSONArray("blocks")).withIndex()) {
                if (block.optString("kind") != "wod") continue
                for ((mi, move) in objects(block.optJSONArray("movements")).withIndex()) {
                    if (move.optBoolean("isRest")) continue
                    val path = "routines[$ri].blocks[$bi].movements[$mi]"
                    val oldId = move.optString("exerciseId")
                    val match = target(oldId, move.optString("name"), "", path) ?: continue
                    val canonical = WODHistoryPresentation.officialName(move.optString("name"))
                    val nameChanged = canonical != null && move.optString("name") != match.optString("name")
                    if (oldId != match.optString("id") || nameChanged) {
                        move.put("exerciseId", match.optString("id"))
                        if (nameChanged) move.put("name", match.optString("name"))
                        changes.add(Change(path, oldId, match.optString("id")))
                    }
                }
            }
        }
        return Preview(output, changes, ambiguous.distinct())
    }

    private fun objects(a: JSONArray?): List<JSONObject> =
        if (a == null) emptyList() else (0 until a.length()).mapNotNull { a.optJSONObject(it) }
    private fun objectsStrings(a: JSONArray?): List<String> =
        if (a == null) emptyList() else (0 until a.length()).mapNotNull {
            (a.opt(it) as? String)?.takeIf { s -> s.isNotBlank() }
        }
}
