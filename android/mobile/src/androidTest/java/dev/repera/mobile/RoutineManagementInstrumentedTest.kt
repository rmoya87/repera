package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Gestión de rutinas existentes: renombrar, reprogramar y borrar. */
@RunWith(AndroidJUnit4::class)
class RoutineManagementInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val press = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Press banca").put("muscleGroup", "Pecho")
        val state = JSONObject().put("exercises", JSONArray().put(press))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    private fun routines(local: LocalSnapshotStore): JSONArray =
        JSONObject(String(local.read()!!)).getJSONArray("routines")

    @Test fun renameAndRescheduleKeepBlocksUntouched() {
        val (repo, local) = repo()
        val exerciseId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val id = repo.createRoutine("Original", "strength",
            listOf(RoutineDraftEntry(exerciseId, 10)))
        val blocksBefore = routines(local).getJSONObject(0).getJSONArray("blocks").toString()
        repo.updateRoutineDetails(id, "  Renombrada  ",
            RoutineSchedule(weekday = 3, timeMinutes = 930))
        val updated = routines(local).getJSONObject(0)
        assertEquals("Renombrada", updated.getString("title"))
        assertEquals(3, updated.getInt("weekday"))
        assertEquals(930, updated.getInt("scheduledTimeMinutes"))
        assertFalse(updated.has("scheduledDate"))
        assertEquals(blocksBefore, updated.getJSONArray("blocks").toString())
    }

    @Test fun rescheduleRejectsWeeklyPlusConcreteDate() {
        val (repo, local) = repo()
        val exerciseId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val id = repo.createRoutine("R", "strength",
            listOf(RoutineDraftEntry(exerciseId, 10)))
        assertThrows(IllegalArgumentException::class.java) {
            repo.updateRoutineDetails(id, "R",
                RoutineSchedule(scheduledDate = "2026-11-02", weekday = 1))
        }
        assertThrows(IllegalArgumentException::class.java) {
            repo.updateRoutineDetails(id, "R", RoutineSchedule(timeMinutes = 1440))
        }
    }

    @Test fun deleteRoutineDropsItAndItsRotationEntryOnly() {
        val (repo, local) = repo()
        val exerciseId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val id = repo.createRoutine("A borrar", "strength",
            listOf(RoutineDraftEntry(exerciseId, 10)))
        val rotationState = JSONObject(String(local.read()!!))
            .put("rotation", JSONObject().put("routineIds", JSONArray().put(id)))
        local.write(rotationState.toString().toByteArray(Charsets.UTF_8))
        repo.deleteRoutine(id)
        val after = JSONObject(String(local.read()!!))
        assertEquals(0, after.getJSONArray("routines").length())
        assertFalse(after.has("rotation"))
        assertThrows(IllegalStateException::class.java) { repo.deleteRoutine(id) }
    }
}
