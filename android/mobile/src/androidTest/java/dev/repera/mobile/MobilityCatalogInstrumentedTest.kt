package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.ExerciseAliasSearch
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class MobilityCatalogInstrumentedTest {
    @Test fun bilingualCatalogIsCompleteAndUnique() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val catalog = JSONArray(context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { it.readText() })
        val entries = (0 until catalog.length()).map(catalog::getJSONObject)
        val mobility = entries.filter { it.optString("sportTag") == "Movilidad" }
        assertEquals(278, entries.size)
        assertEquals(82, mobility.size)
        assertEquals(82, mobility.map { it.getString("catalogId") }.toSet().size)
        assertEquals(82, mobility.map { it.getString("name") }.toSet().size)
        assertTrue(mobility.all {
            it.getJSONArray("instructions").length() >= 2 &&
                it.optString("detailDescription").isNotBlank()
        })

        val aliases = ExerciseSearchAssets.load(context)
        val exerciseNames = mobility.map { it.getString("name") }
        for ((english, expected) in mapOf(
            "cat cow" to "Gato-vaca",
            "knee to wall ankle mobility" to "Rodilla a pared para tobillo",
            "wrist circles" to "Círculos de muñecas",
            "90/90 hip mobility" to "90/90 de cadera"
        )) {
            assertTrue("$english debería encontrar $expected", exerciseNames
                .filter { ExerciseAliasSearch.score(english, it, aliases) >= 0 }
                .contains(expected))
        }
    }

    @Test fun existingAccountReceivesMovementsOnceWithoutLosingWorkouts() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val account = "mobility-test-" + UUID.randomUUID()
        val store = LocalSnapshotStore(context, account)
        val legacy = JSONObject()
            .put("settings", JSONObject())
            .put("exercises", JSONArray().put(JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("name", "Press banca")))
            .put("routines", JSONArray())
            .put("workouts", JSONArray().put(JSONObject().put("id", "historical-workout")))
            .put("syncRevision", 4)
        store.write(legacy.toString().toByteArray(Charsets.UTF_8))

        assertEquals(82, CatalogBootstrap.appendMissingMobility(context, account))
        assertEquals(0, CatalogBootstrap.appendMissingMobility(context, account))
        val state = JSONObject(String(store.read()!!, Charsets.UTF_8))
        assertEquals(83, state.getJSONArray("exercises").length())
        assertEquals("historical-workout",
            state.getJSONArray("workouts").getJSONObject(0).getString("id"))
        assertEquals(5, state.getInt("syncRevision"))
    }

    @Test fun actualMobilitySecondsAppearInProgressWithoutInventingPrescriptionTime() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val catalog = JSONArray(context.assets.open("catalog_seed.json")
            .bufferedReader(Charsets.UTF_8).use { it.readText() })
        val posture = (0 until catalog.length()).map(catalog::getJSONObject)
            .first { it.optString("catalogId") == "mobility-31" }
        val sets = JSONArray()
            .put(JSONObject().put("id", UUID.randomUUID().toString())
                .put("reps", 1).put("phase", "work").put("durationSeconds", 25))
            .put(JSONObject().put("id", UUID.randomUUID().toString())
                .put("reps", 1).put("phase", "work").put("durationSeconds", 45))
        val move = JSONObject()
            .put("exercise", posture)
            .put("plannedSets", JSONArray().put(JSONObject().put("targetReps", 1)
                .put("targetDurationSeconds", 60)))
            .put("loggedSets", sets)
        val workout = JSONObject().put("phase", "finished")
            .put("finishedAt", "2026-10-23T12:00:00Z")
            .put("exercises", JSONArray().put(move))
        val metrics = ExerciseProgressMetrics.fromWorkouts(JSONArray().put(workout))
            .getValue(posture.getString("id"))
        assertEquals(45, metrics.bestDurationSeconds)
        assertEquals(70, metrics.totalDurationSeconds)
        assertEquals(1, metrics.timesPerformed)

        move.put("loggedSets", JSONArray())
        val absent = ExerciseProgressMetrics.fromWorkouts(JSONArray().put(workout))
        assertFalse(absent.containsKey(posture.getString("id")))
    }
}
