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
        assertEquals(196, before.getJSONArray("exercises").length())
        assertTrue(MobilityCatalogMigration.ensure(context, account))
        val migrated = JSONObject(String(store.read()!!))
        val exercises = migrated.getJSONArray("exercises")
        assertEquals(280, exercises.length())
        val mobility = (0 until exercises.length()).map { exercises.getJSONObject(it) }
            .filter { it.optString("sportTag") == "Movilidad" }
        assertEquals(82, mobility.size)
        assertEquals(82, mobility.map { it.getString("catalogId") }.distinct().size)
        assertTrue(mobility.all { it.getJSONArray("instructions").length() >= 5 })
        assertTrue(mobility.all { it.optString("equipment").isNotBlank() })
        val ids = mobility.associate { it.getString("catalogId") to it.getString("id") }
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
        assertEquals(280, StateOverview.fromBytes(store.read())!!.exercises)
    }

    @Test fun migrationOfExistingWorkoutsNeverRewritesAthleteHistoryOrCustomExercises() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val store = LocalSnapshotStore(context, account)
        val existing = JSONObject(String(store.read()!!))
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
