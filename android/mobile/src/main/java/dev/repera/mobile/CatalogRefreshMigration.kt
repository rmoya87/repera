package dev.repera.mobile

import android.content.Context
import org.json.JSONObject
import java.time.Instant

/**
 * Refresco no destructivo del catálogo nativo frente al seed actual (288 entradas,
 * paridad con iOS). Para snapshots de instalaciones anteriores:
 * - actualiza los campos de catálogo de las entradas existentes casadas por `id`
 *   (incluidos los 43 renombrados canónicos, p.ej. "Arrancada" → "Snatch"),
 *   preservando `id`, `isFavorite` y cualquier entrada `isCustom`;
 * - añade las entradas del seed ausentes (p.ej. las 8 nuevas de halterofilia).
 * Nunca toca workouts, routines ni sets: las referencias son por `id`, que se
 * conserva, por lo que el historial del atleta queda intacto. Idempotente: una
 * segunda ejecución no modifica nada y devuelve false.
 */
internal object CatalogRefreshMigration {
    private const val EXPECTED_CATALOG = 288
    private val CATALOG_FIELDS = listOf(
        "name", "muscleGroup", "catalogId", "detailDescription", "equipment",
        "instructions", "primaryRegions", "secondaryMuscles", "secondaryRegions",
        "targetMuscle", "bodyPart", "sportTag"
    )

    fun ensure(context: Context, accountId: String): Boolean {
        val store = LocalSnapshotStore(context, accountId)
        val bytes = store.read() ?: return false
        LocalSnapshotStore.validate(bytes)
        val state = JSONObject(String(bytes, Charsets.UTF_8))
        val catalog = state.getJSONArray("exercises")
        val seed = context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { org.json.JSONArray(it.readText()) }
        check(seed.length() == EXPECTED_CATALOG) { "Catálogo semilla incompleto" }

        val byId = mutableMapOf<String, JSONObject>()
        for (i in 0 until catalog.length()) {
            val item = catalog.getJSONObject(i)
            byId[item.getString("id")] = item
        }
        var changed = false
        for (i in 0 until seed.length()) {
            val seedEntry = seed.getJSONObject(i)
            val existing = byId[seedEntry.getString("id")]
            if (existing == null) {
                catalog.put(JSONObject(seedEntry.toString()))
                changed = true
                continue
            }
            if (existing.optBoolean("isCustom")) continue
            for (field in CATALOG_FIELDS) {
                val seedValue = seedEntry.opt(field)
                if (seedValue == null || seedValue == JSONObject.NULL) continue
                val current = existing.opt(field)
                val equal = when {
                    current == null || current == JSONObject.NULL -> false
                    current is org.json.JSONArray && seedValue is org.json.JSONArray ->
                        current.toString() == seedValue.toString()
                    else -> current.toString() == seedValue.toString()
                }
                if (!equal) {
                    existing.put(field, seedValue)
                    changed = true
                }
            }
        }
        if (!changed) return false

        val untouched = state.optInt("syncRevision", -1) == 0 &&
            state.optString("updatedAt") == "1970-01-01T00:00:00Z" &&
            state.optString("lastWriterDeviceId") == "" &&
            listOf("workouts", "routines", "bodyWeights", "favoriteTimers")
                .all { state.optJSONArray(it)?.length() == 0 } &&
            state.optJSONObject("activeSession") == null &&
            state.optJSONObject("settings")?.length() == 0 &&
            state.optJSONObject("exerciseLoadPrefs")?.length() == 0 &&
            (0 until catalog.length()).none { catalog.getJSONObject(it).optBoolean("isCustom") }
        if (!untouched) {
            state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
            state.put("updatedAt", Instant.now().toString())
            state.put("lastWriterDeviceId", "android-catalog-refresh")
        }
        store.write(state.toString().toByteArray(Charsets.UTF_8))
        return true
    }
}
