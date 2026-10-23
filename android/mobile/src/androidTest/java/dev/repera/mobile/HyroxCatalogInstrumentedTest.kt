package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class HyroxCatalogInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun seedIncludesOfficialStationsWithSharedCrossfitIdsAndNoDuplicateNames() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val local = LocalSnapshotStore(context, account)
        val original = JSONObject(String(local.read()!!)).getJSONArray("exercises")
        val before = (0 until original.length()).associate {
            original.getJSONObject(it).getString("name") to original.getJSONObject(it).getString("id")
        }
        assertTrue(MobilityCatalogMigration.ensure(context, account))
        val catalog = JSONObject(String(local.read()!!)).getJSONArray("exercises")
        assertEquals(280, catalog.length())
        val rows = (0 until catalog.length()).map { catalog.getJSONObject(it) }
        val stationNames = setOf("Carrera", "SkiErg", "Sled push", "Sled pull",
            "Burpee Broad Jump", "Remo máquina", "Farmer carry", "Sandbag Lunges",
            "Wall ball")
        assertTrue(stationNames.all { name -> rows.any { it.optString("name") == name } })
        for (name in setOf("SkiErg","Sled push","Sled pull","Remo máquina","Wall ball")) {
            val found = rows.first { it.optString("name") == name }
            assertEquals(before[name], found.getString("id"))
        }
        assertEquals(2, rows.count { it.optString("sportTag") == "HYROX" })
        val sports = StateOverview.fromBytes(local.read())!!.exerciseEntries
        assertEquals(11, sports.count { ExerciseCatalogFilters.matches(it, "Hyrox") })
        assertFalse(MobilityCatalogMigration.ensure(context, account))
    }

    @Test fun importingAppleStationWithoutCatalogIdNeverDuplicatesItsIdentity() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        val local = LocalSnapshotStore(context, account)
        val state = JSONObject(String(local.read()!!))
        val appleId = UUID.randomUUID().toString()
        state.getJSONArray("exercises").put(JSONObject()
            .put("id", appleId).put("name", "Burpee Broad Jump")
            .put("sportTag", "HYROX").put("muscleGroup", "Cardio")
            .put("isCustom", false))
        state.put("syncRevision", 4).put("updatedAt", "2026-10-23T12:00:00Z")
        local.write(state.toString().toByteArray())
        assertTrue(MobilityCatalogMigration.ensure(context, account))
        val catalog = JSONObject(String(local.read()!!)).getJSONArray("exercises")
        assertEquals(280, catalog.length())
        val same = (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .filter { it.optString("name") == "Burpee Broad Jump" }
        assertEquals(1, same.size)
        assertEquals(appleId, same.single().getString("id"))
    }

    @Test fun sandbagMetersAndLoadAreRecordedWithoutFalseEstimatedOneRm() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        MobilityCatalogMigration.ensure(context, account)
        val local = LocalSnapshotStore(context, account)
        val snapshot = JSONObject(String(local.read()!!))
        val ids = snapshot.getJSONArray("exercises")
        val entry = (0 until ids.length()).map { ids.getJSONObject(it) }
            .first { it.optString("name") == "Sandbag Lunges" }
        val repo = WorkoutRepository(context, account)
        val active = repo.startQuickLog(entry.getString("id"))
        assertEquals("meters", active.quantityUnit)
        assertTrue(active.allowsWeight)
        assertFalse(active.cardioToggle)
        val recorded = repo.logCurrentSet(100, 20.0, quantityUnit = "meters", durationSeconds = 180)
        assertEquals("meters", recorded.sets.single().unit)
        repo.finish()
        val archive = JSONObject(String(local.read()!!)).getJSONArray("workouts")
        val stats = ExerciseProgressMetrics.fromWorkouts(archive)[entry.getString("id")]!!
        assertEquals(100, stats.bestMeters)
        assertEquals(20.0, stats.maxWeightKg!!, 0.01)
        assertNull(stats.estimatedOneRM)
        assertNull(stats.repsAtMaxWeight)
        assertNull(stats.bestReps)
    }
}
