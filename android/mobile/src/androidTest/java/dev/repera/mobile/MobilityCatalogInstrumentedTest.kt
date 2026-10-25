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
class MobilityCatalogInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun freshAccountGetsAll82CanonicalMobilityMovementsAndStableUuids() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val before = JSONObject(String(store.read()!!))
        // El catálogo nativo ya siembra las 288 entradas (196 base + 82 Movilidad
        // + 2 Hyrox + 8 halterofilia nuevas) con los mismos UUID v3 que la
        // migración genera para instalaciones antiguas, así ambas generaciones
        // comparten identidad.
        assertEquals(288, before.getJSONArray("exercises").length())
        assertFalse(MobilityCatalogMigration.ensure(context, account))
        val migrated = JSONObject(String(store.read()!!))
        val exercises = migrated.getJSONArray("exercises")
        assertEquals(288, exercises.length())
        val mobility = (0 until exercises.length()).map { exercises.getJSONObject(it) }
            .filter { it.optString("sportTag") == "Movilidad" }
        assertEquals(82, mobility.size)
        assertEquals(82, mobility.map { it.getString("catalogId") }.distinct().size)
        assertTrue(mobility.all { it.getJSONArray("instructions").length() >= 5 })
        assertTrue(mobility.all { it.optString("equipment").isNotBlank() })
        val ids = mobility.associate { it.getString("catalogId") to it.getString("id") }
        // Los ids del seed deben ser exactamente los UUID v3 que la migración
        // calcula con nameUUIDFromBytes, para que una instalación antigua y una
        // nueva referencien el mismo ejercicio.
        for ((catalogId, id) in ids) {
            val expected = UUID.nameUUIDFromBytes(
                ("repera:catalog:" + catalogId).toByteArray(Charsets.UTF_8)).toString()
            assertEquals("id distinto al esquema de la migración para " + catalogId, expected, id)
        }
        assertFalse(MobilityCatalogMigration.ensure(context, account))
        val after = JSONObject(String(store.read()!!))
        val returned = (0 until after.getJSONArray("exercises").length())
            .map { after.getJSONArray("exercises").getJSONObject(it) }
            .filter { it.optString("sportTag") == "Movilidad" }
            .associate { it.getString("catalogId") to it.getString("id") }
        assertEquals(ids, returned)
        // A virgin account must stay revision zero so it can download existing cloud history.
        assertEquals(0, migrated.getInt("syncRevision"))
        assertEquals("1970-01-01T00:00:00Z", migrated.getString("updatedAt"))
        val aliases = ExerciseSearchAssets.load(context)
        assertEquals("Flexión cervical suave",
            aliases[dev.repera.domain.ExerciseAliasSearch.normalize("Neck flexion stretch")])
        assertEquals(288, StateOverview.fromBytes(store.read())!!.exercises)
    }

    @Test fun importedIosHyroxStationWithoutCatalogIdDedupesByCanonicalName() {
        // Fixture: snapshot de una instalación que importó el catálogo iOS, donde
        // CatalogHyrox.sportRow lleva catalogId=nil. La migración NO debe crear
        // una segunda estación con UUID v3: deduplica por nombre canónico y
        // conserva el id importado (las referencias del historial quedan intactas).
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val existing = JSONObject(String(store.read()!!))
        val catalog = existing.getJSONArray("exercises")
        for (i in catalog.length() - 1 downTo 0) {
            val cid = catalog.getJSONObject(i).optString("catalogId")
            if (cid.startsWith("mobility-") || cid.startsWith("hyrox-")) catalog.remove(i)
        }
        assertEquals(204, catalog.length()) // seed actual: 288 - 84 mobility/hyrox
        val importedId = UUID.randomUUID().toString()
        catalog.put(JSONObject()
            .put("id", importedId).put("name", "Burpee Broad Jump")
            .put("isCustom", false).put("muscleGroup", "Piernas")
            .put("sportTag", "HYROX").put("equipment", "Peso corporal")
            .put("instructions", JSONArray()))
        store.write(existing.toString().toByteArray())
        assertTrue(MobilityCatalogMigration.ensure(context, account))
        val migrated = JSONObject(String(store.read()!!))
        val exercises = migrated.getJSONArray("exercises")
        val broad = (0 until exercises.length()).map { exercises.getJSONObject(it) }
            .filter { it.optString("name") == "Burpee Broad Jump" }
        assertEquals("la estación importada no debe duplicarse", 1, broad.size)
        assertEquals(importedId, broad[0].getString("id"))
        assertEquals(204 + 83 + 1, exercises.length()) // seed 288: base 204 + 1 importada + 83 migradas (la importada deduplica)
        val sandbag = (0 until exercises.length()).map { exercises.getJSONObject(it) }
            .first { it.optString("name") == "Sandbag Lunges" }
        assertEquals(UUID.nameUUIDFromBytes(
            "repera:catalog:hyrox-sandbag-lunges".toByteArray(Charsets.UTF_8)).toString(),
            sandbag.getString("id"))
    }

    @Test fun migrationOfExistingWorkoutsNeverRewritesAthleteHistoryOrCustomExercises() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val existing = JSONObject(String(store.read()!!))
        // Rebobinar al catálogo de 196 entradas: sin Movilidad, sin Hyrox extra
        // y sin las 8 de halterofilia añadidas en esta sincronización.
        val catalog = existing.getJSONArray("exercises")
        val newHaltero = setOf("Snatch High Pull", "Clean High Pull", "Clean Deadlift",
            "Squat Jerk", "Jerk Dip and Drive", "Block Power Snatch", "Block Power Clean",
            "Snatch-Grip Push Press")
        for (i in catalog.length() - 1 downTo 0) {
            val item = catalog.getJSONObject(i)
            val cid = item.optString("catalogId")
            if (cid.startsWith("mobility-") || cid.startsWith("hyrox-") ||
                item.optString("name") in newHaltero) catalog.remove(i)
        }
        assertEquals(196, catalog.length()) // 288 del seed - 84 mobility/hyrox - 8 haltero nuevas
        existing.getJSONArray("exercises").put(JSONObject()
            .put("id", UUID.randomUUID().toString()).put("name", "Mi ejercicio")
            .put("isCustom", true).put("muscleGroup", "Core"))
        val workout = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Registrado").put("phase", "finished")
            .put("startedAt", "2026-10-22T08:00:00Z").put("exercises", JSONArray())
        existing.getJSONArray("workouts").put(workout)
        existing.put("syncRevision", 12).put("updatedAt", "2026-10-22T08:00:00Z")
        store.write(existing.toString().toByteArray())
        val originalWorkout = existing.getJSONArray("workouts").toString()
        assertTrue(MobilityCatalogMigration.ensure(context, account))
        val migrated = JSONObject(String(store.read()!!))
        assertEquals(281, migrated.getJSONArray("exercises").length())
        assertEquals(originalWorkout, migrated.getJSONArray("workouts").toString())
        assertEquals(13, migrated.getInt("syncRevision"))
        assertTrue((0 until migrated.getJSONArray("exercises").length()).any {
            migrated.getJSONArray("exercises").getJSONObject(it).optString("name") == "Mi ejercicio"
        })
    }
}
