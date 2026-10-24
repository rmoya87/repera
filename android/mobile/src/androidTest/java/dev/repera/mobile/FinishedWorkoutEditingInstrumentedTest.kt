package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Edición de entrenos terminados: corregir y borrar series registradas. */
@RunWith(AndroidJUnit4::class)
class FinishedWorkoutEditingInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val press = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Press banca").put("muscleGroup", "Pecho")
            .put("equipment", "Barra")
        val state = JSONObject().put("exercises", JSONArray().put(press))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    private fun finishedWorkout(repo: WorkoutRepository, local: LocalSnapshotStore): JSONObject {
        val exerciseId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val active = repo.startQuickLog(exerciseId)
        repo.logCurrentSet(10, 60.0)
        repo.logCurrentSet(8, 62.5)
        repo.finish()
        assertNull(repo.active())
        return JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0)
    }

    @Test fun reviseFinishedSetCorrectsQuantitiesAndRecomputes() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        val entry = workout.getJSONArray("exercises").getJSONObject(0)
        val setId = entry.getJSONArray("loggedSets").getJSONObject(1).getString("id")
        repo.reviseFinishedSet(workout.getString("id"), entry.getString("id"), setId,
            9, 65.0)
        val updated = JSONObject(String(local.read()!!)).getJSONArray("workouts")
            .getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
        val set = updated.getJSONArray("loggedSets").getJSONObject(1)
        assertEquals(9, set.getInt("reps"))
        assertEquals(65.0, set.getDouble("weightKg"), 0.001)
        assertEquals(19, updated.getInt("completedReps"))
    }

    @Test fun deleteFinishedSetRemovesOnlyThatSet() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        val entry = workout.getJSONArray("exercises").getJSONObject(0)
        val setId = entry.getJSONArray("loggedSets").getJSONObject(0).getString("id")
        repo.deleteFinishedSet(workout.getString("id"), entry.getString("id"), setId)
        val updated = JSONObject(String(local.read()!!)).getJSONArray("workouts")
            .getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
        assertEquals(1, updated.getJSONArray("loggedSets").length())
        assertEquals(8, updated.getInt("completedReps"))
    }

    @Test fun editingRejectsUnknownIdsAndBadValues() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        val entry = workout.getJSONArray("exercises").getJSONObject(0)
        val setId = entry.getJSONArray("loggedSets").getJSONObject(0).getString("id")
        assertThrows(IllegalArgumentException::class.java) {
            repo.reviseFinishedSet(workout.getString("id"), entry.getString("id"), setId,
                -1, null)
        }
        assertThrows(IllegalStateException::class.java) {
            repo.reviseFinishedSet("no-existe", entry.getString("id"), setId, 5, null)
        }
        // La serie original sigue intacta tras los rechazos.
        val intact = JSONObject(String(local.read()!!)).getJSONArray("workouts")
            .getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertEquals(10, intact.getInt("reps"))
    }
}
