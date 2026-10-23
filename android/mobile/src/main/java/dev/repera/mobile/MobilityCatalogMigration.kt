package dev.repera.mobile

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

/**
 * Non-destructive Android catalog migration. Adds the 82 canonical mobility and two HYROX
 * seeds from the current iOS catalog without altering pre-existing exercises,
 * routines or logged sets. UUIDs remain deterministic between Android devices.
 */
internal object MobilityCatalogMigration {
    private const val EXPECTED_MOBILITY = 82
    private const val EXPECTED_HYROX = 2

    fun ensure(context: Context, accountId: String): Boolean {
        val store = LocalSnapshotStore(context, accountId)
        val bytes = store.read() ?: return false
        LocalSnapshotStore.validate(bytes)
        val state = JSONObject(String(bytes, Charsets.UTF_8))
        val catalog = state.getJSONArray("exercises")
        val mobility = context.assets.open("mobility_seed.json")
            .bufferedReader(Charsets.UTF_8).use { JSONArray(it.readText()) }
        val hyrox = context.assets.open("hyrox_seed.json")
            .bufferedReader(Charsets.UTF_8).use { JSONArray(it.readText()) }
        check(mobility.length() == EXPECTED_MOBILITY && hyrox.length() == EXPECTED_HYROX) {
            "Catálogo deportivo incompleto"
        }
        val seeds = JSONArray()
        for (i in 0 until mobility.length()) seeds.put(mobility.getJSONObject(i))
        for (i in 0 until hyrox.length()) seeds.put(hyrox.getJSONObject(i))
        val originalCount = catalog.length()
        val existingCatalogIds = mutableSetOf<String>()
        val existingExerciseIds = mutableSetOf<String>()
        for (i in 0 until catalog.length()) {
            val item = catalog.getJSONObject(i)
            item.optString("catalogId").takeIf { it.isNotBlank() }?.let(existingCatalogIds::add)
            existingExerciseIds.add(item.getString("id"))
        }
        val usedSeedIds = mutableSetOf<String>()
        for (i in 0 until seeds.length()) {
            val seed = seeds.getJSONObject(i)
            val catalogId = seed.getString("catalogId")
            require((catalogId.startsWith("mobility-") ||
                catalogId.startsWith("hyrox-")) && usedSeedIds.add(catalogId))
            if (catalogId in existingCatalogIds) continue
            val id = UUID.nameUUIDFromBytes(
                ("repera:catalog:" + catalogId).toByteArray(Charsets.UTF_8)
            ).toString()
            check(existingExerciseIds.add(id)) { "Colisión de UUID en el catálogo" }
            catalog.put(JSONObject(seed.toString()).put("id", id))
            existingCatalogIds.add(catalogId)
        }
        if (catalog.length() == originalCount) return false

        val untouched = state.optInt("syncRevision", -1) == 0 &&
            state.optString("updatedAt") == "1970-01-01T00:00:00Z" &&
            state.optString("lastWriterDeviceId") == "" &&
            listOf("workouts", "routines", "bodyWeights", "favoriteTimers")
                .all { state.optJSONArray(it)?.length() == 0 } &&
            state.optJSONObject("activeSession") == null &&
            state.optJSONObject("settings")?.length() == 0 &&
            state.optJSONObject("exerciseLoadPrefs")?.length() == 0 &&
            (0 until originalCount).none { catalog.getJSONObject(it).optBoolean("isCustom") }

        // The untouched seed remains virgin for Drive first-sync conflict resolution.
        // For real user histories, increment revision to make the catalog change
        // recoverable and syncable rather than silently dropping it.
        if (!untouched) {
            state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
            state.put("updatedAt", Instant.now().toString())
            state.put("lastWriterDeviceId", "android-mobility-catalog")
        }
        store.write(state.toString().toByteArray(Charsets.UTF_8))
        return true
    }
}
