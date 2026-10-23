package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Device-only integration tests for the exact Repera JSON contract and atomic writes. */
@RunWith(AndroidJUnit4::class)
class WorkoutRepositoryInstrumentedTest {
    @Test fun realSeriesArePersistedExactlyOnceAndContinueAfterReload() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val exercise = JSONObject()
            .put("id", exerciseId)
            .put("name", "Sentadilla")
            .put("muscleGroup", "Piernas")
            .put("isCustom", true)
            .put("secondaryMuscles", JSONArray())
            .put("instructions", JSONArray())
            .put("primaryRegions", JSONArray())
            .put("secondaryRegions", JSONArray())
            .put("isFavorite", false)
        val sets = JSONArray().put(
            JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 8)
                .put("targetWeightKg", 50.0)
        )
        val block = JSONObject().put("id", UUID.randomUUID().toString()).put("kind", "strength")
            .put("title", "Fuerza").put("exercises", JSONArray().put(
                JSONObject().put("id", UUID.randomUUID().toString())
                    .put("exerciseId", exerciseId).put("plannedSets", sets)
            ))
        val routine = JSONObject().put("id", routineId).put("title", "Piernas")
            .put("blocks", JSONArray().put(block)).put("progression", "linear")
            .put("isFavorite", false)
        val state = JSONObject().put("settings", JSONObject())
            .put("exercises", JSONArray().put(exercise))
            .put("routines", JSONArray().put(routine))
            .put("workouts", JSONArray()).put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray()).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 0).put("lastWriterDeviceId", "")
            .put("updatedAt", "2026-10-23T00:00:00Z")
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        val active = repo.startStrengthRoutine(routineId)
        assertEquals(8, active.prescribedQuantity)
        assertEquals(50.0, active.prescribedWeightKg!!, 0.001)
        repo.logCurrentSet(7, 52.5)
        val fresh = WorkoutRepository(ctx, user).active()!!
        assertEquals(1, fresh.completedSets)
        assertEquals(7, fresh.sets.single().reps)
        val id = fresh.sets.single().id
        repo.reviseCurrentSet(id, 8, 52.5)
        assertEquals(id, repo.active()!!.sets.single().id)
        assertNull(repo.next())
        val saved = JSONObject(String(LocalSnapshotStore(ctx, user).read()!!))
        assertFalse(saved.has("activeSession"))
        assertEquals(1, saved.getJSONArray("workouts").length())
        assertEquals(1, saved.getJSONArray("workouts").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").length())
    }

    @Test fun noWodIsSilentlyCoercedToStrength() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val state = JSONObject()
            .put("exercises", JSONArray())
            .put("workouts", JSONArray())
            .put("routines", JSONArray().put(JSONObject().put("id", id)
                .put("title", "AMRAP").put("blocks", JSONArray().put(
                    JSONObject().put("id", UUID.randomUUID().toString())
                        .put("kind", "wod")
                )))).put("syncRevision", 0)
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())
        assertThrows(IllegalStateException::class.java) {
            WorkoutRepository(ctx, user).startStrengthRoutine(id)
        }
        assertNull(WorkoutRepository(ctx, user).active())
    }
}
