package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Contract tests for Swift-compatible machine work: cal/m/time, never fake reps. */
@RunWith(AndroidJUnit4::class)
class CardioRecordInstrumentedTest {
    private fun prepare(name: String): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val exercise = JSONObject().put("id", id).put("name", name)
            .put("muscleGroup", "Cardio").put("equipment", "Máquina")
        val state = JSONObject().put("exercises", JSONArray().put(exercise))
            .put("workouts", JSONArray()).put("routines", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    @Test fun skiErgRecordsAndRevisesCaloriesMetersAndDuration() {
        val (repo, local) = prepare("SkiErg")
        val id = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val first = repo.startQuickLog(id)
        assertEquals("calories", first.quantityUnit)
        assertTrue(first.durationInput)
        assertTrue(first.cardioToggle)
        assertFalse(first.allowsWeight)
        val saved = repo.logCurrentSet(35, null, null, false,
            quantityUnit = "calories", durationSeconds = 480)
        assertEquals("calories", saved.sets.single().unit)
        repo.reviseCurrentSet(saved.sets.single().id, 40, null, "calories", 475)
        assertNull(repo.next())
        val second = repo.startQuickLog(id)
        assertEquals("calories", second.quantityUnit)
        repo.logCurrentSet(1000, null, null, false,
            quantityUnit = "meters", durationSeconds = 300)
        repo.finish()
        val workouts = JSONObject(String(local.read()!!)).getJSONArray("workouts")
        assertEquals(2, workouts.length())
        val firstSet = workouts.getJSONObject(0).getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("calories", firstSet.getString("quantityUnit"))
        assertEquals(40, firstSet.getInt("reps"))
        assertEquals(475, firstSet.getInt("durationSeconds"))
        val secondSet = workouts.getJSONObject(1).getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("meters", secondSet.getString("quantityUnit"))
        assertEquals(1000, secondSet.getInt("reps"))
        assertEquals(300, secondSet.getInt("durationSeconds"))
        val stats = ExerciseProgressMetrics.fromWorkouts(workouts)[id]!!
        assertEquals(2, stats.timesPerformed)
        assertEquals(40, stats.bestCalories)
        assertEquals(1000, stats.bestMeters)
        assertNull(stats.bestReps)
        assertEquals(475, stats.bestDurationSeconds)
    }

    @Test fun runRejectsCaloriesAndDoesNotPersistInvalidWork() {
        val (repo, local) = prepare("Carrera")
        val id = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val active = repo.startQuickLog(id)
        assertEquals("meters", active.quantityUnit)
        assertFalse(active.cardioToggle)
        assertThrows(IllegalStateException::class.java) {
            repo.logCurrentSet(250, null, quantityUnit = "calories", durationSeconds = 120)
        }
        assertTrue(repo.active()!!.sets.isEmpty())
        assertEquals(0, JSONObject(String(local.read()!!)).getJSONArray("workouts").length())
    }

    @Test fun emptyDurationEditRemovesOldCardioDuration() {
        val (repo, local) = prepare("SkiErg")
        val id = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        repo.startQuickLog(id)
        val recorded = repo.logCurrentSet(50, null, quantityUnit = "calories", durationSeconds = 180)
        val setId = recorded.sets.single().id
        repo.reviseCurrentSet(setId, 50, null, "calories", durationSeconds = null)
        assertNull(repo.active()!!.sets.single().durationSeconds)
        val saved = JSONObject(String(local.read()!!)).getJSONObject("activeSession")
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertFalse(saved.has("durationSeconds"))
    }

    @Test fun jumpRopeStoresCountAndDurationAsRepsAndTime() {
        val (repo, local) = prepare("Double under")
        val id = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val active = repo.startQuickLog(id)
        assertEquals("reps", active.quantityUnit)
        assertTrue(active.durationInput)
        val saved = repo.logCurrentSet(60, null, durationSeconds = 35)
        assertEquals(35, saved.sets.single().durationSeconds)
        assertEquals("reps", saved.sets.single().unit)
    }
}
