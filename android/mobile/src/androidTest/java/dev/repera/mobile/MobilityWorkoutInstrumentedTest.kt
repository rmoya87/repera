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
class MobilityWorkoutInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    private fun startCatalogExercise(catalogId: String): Triple<WorkoutRepository, LocalSnapshotStore, String> {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        MobilityCatalogMigration.ensure(context, account)
        val store = LocalSnapshotStore(context, account)
        val snapshot = JSONObject(String(store.read()!!))
        val catalog = snapshot.getJSONArray("exercises")
        val exercise = (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .first { it.optString("catalogId") == catalogId }
        return Triple(WorkoutRepository(context, account), store, exercise.getString("id"))
    }

    @Test fun holdUsesPrescribedSecondsWithNoFakeLoadOrRepRecord() {
        val (repo, store, id) = startCatalogExercise("mobility-46")
        val active = repo.startQuickLog(id)
        assertTrue(active.mobility)
        assertTrue(active.mobilityHold)
        assertTrue(active.durationInput)
        assertFalse(active.allowsWeight)
        assertEquals(1, active.prescribedQuantity)
        assertEquals(30, active.prescribedDurationSeconds)
        val saved = repo.logCurrentSet(1, null, durationSeconds = 45)
        assertEquals(45, saved.sets.single().durationSeconds)
        repo.finish()
        val archive = JSONObject(String(store.read()!!)).getJSONArray("workouts")
        val progress = ExerciseProgressMetrics.fromWorkouts(archive)[id]!!
        assertEquals(1, progress.timesPerformed)
        assertEquals(45, progress.bestDurationSeconds)
        assertNull(progress.bestReps)
        assertNull(progress.estimatedOneRM)
        val effective = WorkoutHistorySets.effectiveWorkSets(
            archive.getJSONObject(0), archive.getJSONObject(0)
                .getJSONArray("exercises").getJSONObject(0))
        assertTrue(effective.single().mobilityHold)
    }

    @Test fun finishingUnrecordedHoldMustNotManufactureThirtySecondsOfTraining() {
        val (repo, store, id) = startCatalogExercise("mobility-46")
        repo.startQuickLog(id)
        repo.finish()
        val session = JSONObject(String(store.read()!!))
            .getJSONArray("workouts").getJSONObject(0)
        val movement = session.getJSONArray("exercises").getJSONObject(0)
        assertTrue(WorkoutHistorySets.effectiveWorkSets(session, movement).isEmpty())
        assertTrue(WorkoutHistorySets.displayLines(session, movement).isEmpty())
        assertFalse(ExerciseProgressMetrics.fromWorkouts(JSONArray().put(session)).containsKey(id))
    }

    @Test fun dynamicMobilityRecordsRepsAndTimeButNeverRequiresWeight() {
        val (repo, _, id) = startCatalogExercise("mobility-1")
        val active = repo.startQuickLog(id)
        assertTrue(active.mobility)
        assertFalse(active.mobilityHold)
        assertTrue(active.durationInput)
        assertFalse(active.allowsWeight)
        val saved = repo.logCurrentSet(8, null, durationSeconds = 25)
        assertEquals("reps", saved.sets.single().unit)
        assertEquals(25, saved.sets.single().durationSeconds)
    }
}
