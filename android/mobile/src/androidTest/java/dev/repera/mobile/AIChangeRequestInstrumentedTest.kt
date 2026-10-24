package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Cambios propuestos por la IA y consentidos: patch de entrenos y CRUD de
 * ejercicios personalizados (port de AIChangeRequestStore.decide). */
@RunWith(AndroidJUnit4::class)
class AIChangeRequestInstrumentedTest {
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
        repo.startQuickLog(exerciseId)
        repo.logCurrentSet(10, 60.0)
        repo.logCurrentSet(8, 62.5)
        repo.finish()
        return JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0)
    }

    private fun readWorkouts(local: LocalSnapshotStore): JSONArray =
        JSONObject(String(local.read()!!)).getJSONArray("workouts")

    @Test fun patchUpdatesTitleSetsAndRecomputes() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        val entry = workout.getJSONArray("exercises").getJSONObject(0)
        val setId = entry.getJSONArray("loggedSets").getJSONObject(0).getString("id")
        repo.applyAIWorkoutPatch(workout.getString("id"), "Empuje corregido",
            listOf(WorkoutRepository.AISetPatch(
                exerciseEntryId = entry.getString("id"),
                loggedSetId = setId, reps = 12, weightKg = 57.5, rir = 1.5)))
        val updated = readWorkouts(local).getJSONObject(0)
        assertEquals("Empuje corregido", updated.getString("title"))
        val set = updated.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertEquals(12, set.getInt("reps"))
        assertEquals(57.5, set.getDouble("weightKg"), 0.001)
        assertEquals(1.5, set.getDouble("rir"), 0.001)
        assertFalse(set.optBoolean("toFailure"))
        assertEquals(20, updated.getJSONArray("exercises").getJSONObject(0)
            .getInt("completedReps"))
    }

    @Test fun patchClearsWeightAndRir() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        val entry = workout.getJSONArray("exercises").getJSONObject(0)
        val setId = entry.getJSONArray("loggedSets").getJSONObject(1).getString("id")
        repo.applyAIWorkoutPatch(workout.getString("id"), null,
            listOf(WorkoutRepository.AISetPatch(
                exerciseEntryId = entry.getString("id"),
                loggedSetId = setId, clearWeight = true, clearRir = true)))
        val set = readWorkouts(local).getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(1)
        assertFalse(set.has("weightKg"))
        assertFalse(set.has("rir"))
        assertEquals(8, set.getInt("reps"))
    }

    @Test fun patchRejectsUnknownSet() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        val entry = workout.getJSONArray("exercises").getJSONObject(0)
        assertThrows(IllegalStateException::class.java) {
            repo.applyAIWorkoutPatch(workout.getString("id"), null,
                listOf(WorkoutRepository.AISetPatch(
                    exerciseEntryId = entry.getString("id"),
                    loggedSetId = "no-existe", reps = 5)))
        }
    }

    @Test fun deleteWorkoutRemovesIt() {
        val (repo, local) = repo()
        val workout = finishedWorkout(repo, local)
        repo.deleteWorkout(workout.getString("id"))
        assertEquals(0, readWorkouts(local).length())
    }

    @Test fun customExerciseCrudRoundtrip() {
        val (repo, local) = repo()
        val id = UUID.randomUUID().toString()
        assertTrue(repo.addCustomExercise(id, "Sentadilla búlgara", "Pierna",
            equipment = "Mancuernas", targetMuscle = "Cuádriceps",
            secondaryMuscles = listOf("Glúteo")))
        assertFalse(repo.addCustomExercise(id, "Duplicado", "Pierna"))
        var custom = repo.customExercisesSnapshot()
        assertEquals(1, custom.size)
        assertEquals("Sentadilla búlgara", custom[0].getString("name"))
        assertEquals("Glúteo", custom[0].getJSONArray("secondaryMuscles").getString(0))
        assertTrue(repo.updateCustomExercise(id, "Búlgara trasera", "Pierna",
            equipment = "Barra"))
        custom = repo.customExercisesSnapshot()
        assertEquals("Búlgara trasera", custom[0].getString("name"))
        assertEquals("Barra", custom[0].getString("equipment"))
        assertTrue(repo.deleteCustomExercise(id))
        assertEquals(0, repo.customExercisesSnapshot().size)
        assertFalse(repo.deleteCustomExercise(id))
    }

    @Test fun catalogExerciseIsNotCustomEditable() {
        val (repo, local) = repo()
        val catalogId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        assertFalse(repo.updateCustomExercise(catalogId, "X", "Pecho"))
        assertFalse(repo.deleteCustomExercise(catalogId))
        assertEquals(0, repo.customExercisesSnapshot().size)
    }

    @Test fun finishedWorkoutsSnapshotOnlyFinished() {
        val (repo, local) = repo()
        finishedWorkout(repo, local)
        val finished = repo.finishedWorkoutsSnapshot()
        assertEquals(1, finished.size)
        assertFalse(finished[0].isNull("finishedAt"))
    }
}
