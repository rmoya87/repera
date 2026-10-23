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
        check(catalog.length() == 278) { "El catálogo no está completo" }
        val ids = (0 until catalog.length()).map { catalog.getJSONObject(it).getString("id") }
        require(ids.distinct().size == ids.size) { "IDs de catálogo repetidos" }
        val state = JSONObject()
            .put("settings", JSONObject())
            .put("exercises", catalog)
            .put("routines", JSONArray())
            .put("workouts", JSONArray())
            .put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray())
            .put("exerciseLoadPrefs", JSONObject())
            .put("updatedAt", "1970-01-01T00:00:00Z")
            .put("syncRevision", 0)
            .put("lastWriterDeviceId", "")
        local.write(state.toString().toByteArray(Charsets.UTF_8))
    }

    /**
     * Merge idempotente tras actualizar o importar una copia desde Drive.
     * No modifica ejercicios existentes, históricos ni favoritos.
     */
    fun appendMissingMobility(context: Context, googleAccountId: String): Int {
        val local = LocalSnapshotStore(context, googleAccountId)
        val bytes = local.read() ?: return 0
        val state = JSONObject(String(bytes, Charsets.UTF_8))
        val exercises = state.getJSONArray("exercises")
        val existingIds = (0 until exercises.length()).map {
            exercises.getJSONObject(it).optString("catalogId")
        }.toHashSet()
        val existingNames = (0 until exercises.length()).map {
            exercises.getJSONObject(it).optString("name").trim().lowercase()
        }.toHashSet()
        val catalog = context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { JSONArray(it.readText()) }
        var appended = 0
        for (index in 0 until catalog.length()) {
            val row = catalog.getJSONObject(index)
            if (row.optString("sportTag") != "Movilidad") continue
            val key = row.optString("catalogId")
            val name = row.getString("name").trim().lowercase()
            if (key in existingIds || name in existingNames) continue
            exercises.put(JSONObject(row.toString()))
            existingIds.add(key)
            existingNames.add(name)
            appended++
        }
        if (appended == 0) return 0
        state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
        state.put("updatedAt", java.time.Instant.now().toString())
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return appended
    }
}
