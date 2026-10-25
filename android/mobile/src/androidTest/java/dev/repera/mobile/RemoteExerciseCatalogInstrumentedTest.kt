package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID

/** Offline regression: corrections and tombstones may not rewrite past athlete IDs. */
@RunWith(AndroidJUnit4::class)
class RemoteExerciseCatalogInstrumentedTest {
    @Test
    fun spanishEditorialNamesReuseEnglishSeedUUIDs() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val file = File(context.filesDir, "exercise_catalog_remote_v1.json")
        val previous = if (file.exists()) file.readBytes() else null
        val account = "bilingual-catalog-${UUID.randomUUID()}"
        val id = UUID.randomUUID().toString()
        val local = LocalSnapshotStore(context, account)
        local.write(JSONObject()
            .put("exercises", JSONArray().put(JSONObject()
                .put("id", id).put("name", "Snatch")
                .put("muscleGroup", "Piernas").put("sportTag", "Halterofilia")
                .put("isFavorite", true).put("isCustom", false)))
            .put("workouts", JSONArray()).put("routines", JSONArray())
            .put("syncRevision", 1).toString().toByteArray())
        try {
            val cache = JSONObject()
                .put("revision", 1)
                .put("entries", JSONObject().put("catalog:Arrancada", JSONObject()
                    .put("name", "Arrancada")
                    .put("category", "Halterofilia")
                    .put("is_active", true)))
                .put("localIDs", JSONObject())
            file.writeText(cache.toString())
            assertTrue(RemoteExerciseCatalog(context).applyToAccount(account))
            val state = JSONObject(String(local.read()!!, Charsets.UTF_8))
            val entries = state.getJSONArray("exercises")
            assertEquals("Spanish name must not create an extra exercise", 1, entries.length())
            assertEquals(id, entries.getJSONObject(0).getString("id"))
            assertTrue(entries.getJSONObject(0).getBoolean("isFavorite"))
        } finally {
            if (previous == null) file.delete() else file.writeBytes(previous)
        }
    }

    @Test
    fun muscleGroupDerivesFromPrimariesWhenRemoteOmitsIt() {
        // Apple RemoteExerciseCatalogStore.merge: sin muscle_group remoto y
        // CON primarios, el grupo se deriva con MuscleTaxonomy; sin primarios
        // ni grupo anterior, "Custom".
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val file = File(context.filesDir, "exercise_catalog_remote_v1.json")
        val previous = if (file.exists()) file.readBytes() else null
        val account = "remote-musclegroup-${UUID.randomUUID()}"
        val local = LocalSnapshotStore(context, account)
        local.write(JSONObject()
            .put("exercises", JSONArray()).put("workouts", JSONArray())
            .put("routines", JSONArray()).put("syncRevision", 1)
            .toString().toByteArray())
        try {
            val cache = JSONObject()
                .put("revision", 1)
                .put("entries", JSONObject()
                    .put("catalog:Dominada estricta", JSONObject()
                        .put("name", "Dominada estricta")
                        .put("category", "Fuerza")
                        .put("primary_muscles", JSONArray().put("Espalda"))
                        .put("is_active", true))
                    .put("catalog:Movimiento raro", JSONObject()
                        .put("name", "Movimiento raro")
                        .put("category", "Fuerza")
                        .put("is_active", true)))
                .put("localIDs", JSONObject())
            file.writeText(cache.toString())
            assertTrue(RemoteExerciseCatalog(context).applyToAccount(account))
            val entries = JSONObject(String(local.read()!!, Charsets.UTF_8))
                .getJSONArray("exercises")
            var derived: String? = null
            var fallback: String? = null
            for (i in 0 until entries.length()) {
                val ex = entries.getJSONObject(i)
                when (ex.getString("name")) {
                    "Dominada estricta" -> derived = ex.getString("muscleGroup")
                    "Movimiento raro" -> fallback = ex.getString("muscleGroup")
                }
            }
            assertEquals("Espalda", derived)
            assertEquals("Custom", fallback)
        } finally {
            if (previous == null) file.delete() else file.writeBytes(previous)
        }
    }

    @Test
    fun remoteUpdateKeepsFavoriteIdentityAndArchivesWithoutDeletingHistory() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val file = File(context.filesDir, "exercise_catalog_remote_v1.json")
        val previous = if (file.exists()) file.readBytes() else null
        val account = "remote-catalog-test-${UUID.randomUUID()}"
        val id = UUID.randomUUID().toString()
        val key = "catalog:Press banca"
        val workout = JSONObject().put("id", "historic-session").put("title", "Historia")
        val original = JSONObject()
            .put("syncRevision", 1)
            .put("updatedAt", "2026-10-01T00:00:00Z")
            .put("lastWriterDeviceId", "test")
            .put("settings", JSONObject())
            .put("exercises", JSONArray().put(JSONObject()
                .put("id", id).put("name", "Press banca").put("catalogId", "0025")
                .put("isFavorite", true).put("isCustom", false).put("equipment", "Barra")))
            .put("routines", JSONArray())
            .put("workouts", JSONArray().put(workout))
            .put("bodyWeights", JSONArray())
        val store = LocalSnapshotStore(context, account)
        try {
            store.write(original.toString().toByteArray(Charsets.UTF_8))
            val remote = JSONObject()
                .put("name", "Press banca corregido").put("category", "Fuerza")
                .put("native_catalog_id", "0025")
                .put("equipment_override", "Barra y banco")
                .put("is_active", true)
            val cache = JSONObject()
                .put("revision", 1)
                .put("entries", JSONObject().put(key, remote))
                .put("localIDs", JSONObject())
            file.writeText(cache.toString())
            val feed = RemoteExerciseCatalog(context)
            assertTrue(feed.applyToAccount(account))
            val first = JSONObject(String(store.read()!!, Charsets.UTF_8))
            val ex = first.getJSONArray("exercises").getJSONObject(0)
            assertEquals(id, ex.getString("id"))
            assertEquals("Press banca corregido", ex.getString("name"))
            assertEquals("Barra y banco", ex.getString("equipment"))
            assertTrue(ex.getBoolean("isFavorite"))
            assertFalse(ex.getBoolean("isCatalogArchived"))
            assertEquals("historic-session",
                first.getJSONArray("workouts").getJSONObject(0).getString("id"))
            assertFalse(feed.applyToAccount(account))

            remote.put("is_active", false)
            file.writeText(cache.toString())
            assertTrue(feed.applyToAccount(account))
            val archived = JSONObject(String(store.read()!!, Charsets.UTF_8))
            val kept = archived.getJSONArray("exercises").getJSONObject(0)
            assertTrue(kept.getBoolean("isCatalogArchived"))
            assertEquals(id, kept.getString("id"))
            assertTrue(kept.getBoolean("isFavorite"))
            assertEquals(1, archived.getJSONArray("workouts").length())
        } finally {
            if (previous == null) file.delete() else file.writeBytes(previous)
        }
    }
}
