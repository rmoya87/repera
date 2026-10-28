package dev.repera.mobile

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Initial local-first state built only from catalog definitions present in Apple's source. */
object CatalogBootstrap {
    fun initializeEmptyAccount(context: Context, googleAccountId: String) {
        val local = LocalSnapshotStore(context, googleAccountId)
        check(local.read() == null) { "Ya existe un historial; no se sobrescribirá" }
        val catalogText = context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { it.readText() }
        val catalog = JSONArray(catalogText)
        check(catalog.length() == 288) { "El catálogo no está completo" }
        val ids = (0 until catalog.length()).map { catalog.getJSONObject(it).getString("id") }
        require(ids.distinct().size == ids.size) { "IDs de catálogo repetidos" }
        val state = JSONObject()
            .put("settings", JSONObject())
            .put("exercises", catalog)
            .put("routines", JSONArray())
            .put("workouts", JSONArray())
            .put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray())
            .put("favoriteSportActivities", JSONArray())
            .put("exerciseLoadPrefs", JSONObject())
            .put("updatedAt", "1970-01-01T00:00:00Z")
            .put("syncRevision", 0)
            .put("lastWriterDeviceId", "")
        check(local.replaceIfUnchanged(null,state.toString().toByteArray(Charsets.UTF_8))) {
            "Ya existe un historial; no se sobrescribirá"
        }
    }
}
