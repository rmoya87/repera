package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject

/** RemoteExerciseCatalogStore.merge assigns remote.aliases ?? [] (Apple 0a640da8). */
internal object PublishedCatalogAliases {
    fun merge(exercise: JSONObject, remote: JSONObject) {
        exercise.put("searchAliases", JSONArray(strings(remote.optJSONArray("aliases"))))
    }
    fun read(exercise: JSONObject): List<String> = strings(exercise.optJSONArray("searchAliases"))
    private fun strings(array: JSONArray?): List<String> = if (array == null) emptyList() else
        (0 until array.length()).mapNotNull { array.opt(it) as? String }
}
