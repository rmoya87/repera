package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class CatalogRefreshInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    private fun exercises(store: LocalSnapshotStore): JSONArray =
        JSONObject(String(store.read()!!)).getJSONArray("exercises")

    private fun byName(catalog: JSONArray, name: String): JSONObject? =
        (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .firstOrNull { it.optString("name") == name }

    private fun byId(catalog: JSONArray, id: String): JSONObject? =
        (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id }

    /** Rebobina una cuenta al catálogo de 196 entradas anterior a la unificación. */
    private fun rewindToLegacyCatalog(state: JSONObject) {
        val catalog = state.getJSONArray("exercises")
        val newHaltero = setOf("Snatch High Pull", "Clean High Pull", "Clean Deadlift",
            "Squat Jerk", "Jerk Dip and Drive", "Block Power Snatch", "Block Power Clean",
            "Snatch-Grip Push Press")
        for (i in catalog.length() - 1 downTo 0) {
            val item = catalog.getJSONObject(i)
            val cid = item.optString("catalogId")
            if (cid.startsWith("mobility-") || cid.startsWith("hyrox-") ||
                item.optString("name") in newHaltero) catalog.remove(i)
        }
        assertEquals(196, catalog.length())
    }

    @Test fun legacySnapshotRefreshesFieldsAndNamesWithoutBreakingReferences() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val state = JSONObject(String(store.read()!!))
        rewindToLegacyCatalog(state)
        val catalog = state.getJSONArray("exercises")

        // Simular valores antiguos: nombre heredado y equipment previo a iOS.
        val snatch = byName(catalog, "Snatch")!!
        val snatchId = snatch.getString("id")
        snatch.put("name", "Arrancada")
        val bench = byName(catalog, "Press banca")!!
        val benchId = bench.getString("id")
        bench.put("equipment", "Barra")
        bench.put("isFavorite", true)
        // Historial del atleta que referencia esos ids.
        val routine = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Rutina").put("entries", JSONArray().put(JSONObject()
                .put("exerciseId", snatchId).put("reps", 3)))
        val workout = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Sesión").put("phase", "finished")
            .put("exercises", JSONArray().put(JSONObject().put("exerciseId", benchId)))
        state.put("routines", JSONArray().put(routine))
        state.put("workouts", JSONArray().put(workout))
        state.put("syncRevision", 7).put("updatedAt", "2026-10-20T10:00:00Z")
        store.write(state.toString().toByteArray())
        val routinesBefore = state.getJSONArray("routines").toString()
        val workoutsBefore = state.getJSONArray("workouts").toString()

        assertTrue(CatalogRefreshMigration.ensure(context, account))
        val after = exercises(store)
        // Identidad preservada: mismo id, nombre canonicalizado y campos iOS.
        val snatchAfter = byId(after, snatchId)!!
        assertEquals("Snatch", snatchAfter.getString("name"))
        assertNull(byName(after, "Arrancada"))
        val benchAfter = byId(after, benchId)!!
        assertEquals("Barra, Banco", benchAfter.getString("equipment"))
        assertTrue(benchAfter.getBoolean("isFavorite"))
        // Altas ausentes añadidas: 8 halterofilia nuevas + 84 de migración no las toca esta migración.
        assertNotNull(byName(after, "Snatch High Pull"))
        // Historial intacto byte a byte; referencias por id siguen resolviendo.
        val migrated = JSONObject(String(store.read()!!))
        assertEquals(routinesBefore, migrated.getJSONArray("routines").toString())
        assertEquals(workoutsBefore, migrated.getJSONArray("workouts").toString())
        assertEquals(8, migrated.getInt("syncRevision"))
    }

    @Test fun refreshIsIdempotentAndNoOpOnCurrentCatalog() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        // Catálogo ya al día (288 del seed): no-op.
        assertFalse(CatalogRefreshMigration.ensure(context, account))
        // Catálogo antiguo: primera ejecución cambia, segunda no.
        val state = JSONObject(String(store.read()!!))
        rewindToLegacyCatalog(state)
        state.put("syncRevision", 3).put("updatedAt", "2026-10-20T10:00:00Z")
        store.write(state.toString().toByteArray())
        assertTrue(CatalogRefreshMigration.ensure(context, account))
        val once = String(store.read()!!)
        assertFalse(CatalogRefreshMigration.ensure(context, account))
        assertEquals(once, String(store.read()!!))
    }

    @Test fun refreshNeverTouchesCustomExercises() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val state = JSONObject(String(store.read()!!))
        // Entrada de catálogo convertida en custom por el usuario: no se renombra.
        val catalog = state.getJSONArray("exercises")
        val snatch = byName(catalog, "Snatch")!!
        snatch.put("name", "Mi arrancada").put("isCustom", true)
        val custom = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Mi ejercicio").put("isCustom", true).put("muscleGroup", "Core")
        catalog.put(custom)
        state.put("syncRevision", 2).put("updatedAt", "2026-10-20T10:00:00Z")
        store.write(state.toString().toByteArray())

        CatalogRefreshMigration.ensure(context, account)
        val after = exercises(store)
        val customSnatch = byName(after, "Mi arrancada")!!
        assertTrue(customSnatch.getBoolean("isCustom"))
        assertNotNull(byName(after, "Mi ejercicio"))
        // La entrada de catálogo original reaparece con su nombre canónico por id:
        // el refresh actualiza por id, y como el usuario la marcó custom, se respeta.
    }

    @Test fun dedupeTransfersFavoritesAndLoadPrefsAndNeverDropsReferencedIds() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val state = JSONObject(String(store.read()!!))
        val catalog = state.getJSONArray("exercises")
        val seedEntry = byName(catalog, "Burpee Broad Jump")!!
        val seedId = seedEntry.getString("id")
        // Entrada importada con otro id, favorita y con prefs de carga.
        val importedId = UUID.randomUUID().toString()
        catalog.put(JSONObject(seedEntry.toString())
            .put("id", importedId).put("isFavorite", true).put("catalogId", JSONObject.NULL))
        state.put("exerciseLoadPrefs", JSONObject().put(importedId, JSONObject().put("lastKg", 24)))
        state.put("syncRevision", 5).put("updatedAt", "2026-10-22T08:00:00Z")
        store.write(state.toString().toByteArray())

        assertTrue(CatalogRefreshMigration.ensure(context, account))
        val after = exercises(store)
        val survivors = (0 until after.length()).map { after.getJSONObject(it) }
            .filter { it.optString("name") == "Burpee Broad Jump" }
        assertEquals(1, survivors.size)
        assertEquals(importedId, survivors.single().getString("id"))
        assertTrue(survivors.single().getBoolean("isFavorite"))
        val prefs = JSONObject(String(store.read()!!)).getJSONObject("exerciseLoadPrefs")
        assertTrue(prefs.has(importedId))
        assertFalse(prefs.has(seedId))

        // Caso ambos referenciados: se conservan ambos ids, sin reconciliar a la fuerza.
        val account2 = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account2)
        val store2 = LocalSnapshotStore(context, account2)
        val state2 = JSONObject(String(store2.read()!!))
        val catalog2 = state2.getJSONArray("exercises")
        val seedEntry2 = byName(catalog2, "Sandbag Lunges")!!
        val seedId2 = seedEntry2.getString("id")
        val importedId2 = UUID.randomUUID().toString()
        catalog2.put(JSONObject(seedEntry2.toString())
            .put("id", importedId2).put("catalogId", JSONObject.NULL))
        val workout = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Sesión").put("phase", "finished")
            .put("exercises", JSONArray().put(JSONObject().put("exerciseId", seedId2))
                .put(JSONObject().put("exerciseId", importedId2)))
        state2.put("workouts", JSONArray().put(workout))
        state2.put("syncRevision", 9).put("updatedAt", "2026-10-22T08:00:00Z")
        store2.write(state2.toString().toByteArray())

        CatalogRefreshMigration.ensure(context, account2)
        val after2 = exercises(store2)
        val both = (0 until after2.length()).map { after2.getJSONObject(it) }
            .filter { it.optString("name") == "Sandbag Lunges" }
        assertEquals(2, both.size)  // ambos referenciados: no se toca nada
        val keptIds = both.map { it.getString("id") }.toSet()
        assertEquals(setOf(seedId2, importedId2), keptIds)
    }
}
