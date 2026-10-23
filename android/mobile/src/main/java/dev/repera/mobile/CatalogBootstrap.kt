package dev.repera.mobile

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.UUID

/** Initial local-first state built only from catalog definitions present in Apple's source. */
object CatalogBootstrap {
    fun initializeEmptyAccount(context: Context, googleAccountId: String) {
        val local = LocalSnapshotStore(context, googleAccountId)
        check(local.read() == null) { "Ya existe un historial; no se sobrescribirá" }
        val catalogText = context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { it.readText() }
        val catalog = JSONArray(catalogText)
        check(catalog.length() == 196) { "El catálogo no está completo" }
        val ids = (0 until catalog.length()).map { catalog.getJSONObject(it).getString("id") }
        require(ids.distinct().size == ids.size) { "IDs de catálogo repetidos" }
        val iso = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")
            .withZone(ZoneOffset.UTC).format(Instant.now())
        val state = JSONObject()
            .put("settings", JSONObject())
            .put("exercises", catalog)
            .put("routines", JSONArray())
            .put("workouts", JSONArray())
            .put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray())
            .put("exerciseLoadPrefs", JSONObject())
            .put("updatedAt", iso)
            .put("syncRevision", 1)
            .put("lastWriterDeviceId", UUID.randomUUID().toString())
        local.write(state.toString().toByteArray(Charsets.UTF_8))
    }
}
