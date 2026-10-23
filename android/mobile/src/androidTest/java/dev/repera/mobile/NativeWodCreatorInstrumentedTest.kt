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
class NativeWodCreatorInstrumentedTest {
    private fun repo(): Triple<WorkoutRepository, LocalSnapshotStore, String> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val ski = JSONObject().put("id", id).put("name", "SkiErg")
            .put("muscleGroup", "Cardio").put("equipment", "Máquina")
        val state = JSONObject().put("exercises", JSONArray().put(ski))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return Triple(WorkoutRepository(ctx, user), local, id)
    }

    @Test fun emomPrescribesCaloriesWithExactIntervalAndDoesNotFabricateWork() {
        val (repo, local, id) = repo()
        val routine = repo.createRoutine("EMOM Ski", "emom",
            listOf(RoutineDraftEntry(id, 15)), rounds = 6,
            emomIntervalSeconds = 120)
        val created = JSONObject(String(local.read()!!)).getJSONArray("routines")
            .getJSONObject(0).getJSONArray("blocks").getJSONObject(0)
        assertEquals(6, created.getInt("rounds"))
        assertEquals(120, created.getInt("emomIntervalSeconds"))
        assertEquals(12, created.getInt("timeCapMinutes"))
        assertEquals(15, created.getJSONArray("movements").getJSONObject(0).getInt("calories"))
        assertFalse(created.getJSONArray("movements").getJSONObject(0).has("reps"))
        val active = repo.startRoutine(routine)
        assertEquals("emom", active.wod!!.format)
        assertEquals("PER_MOVEMENT_SETS", active.wod!!.capture)
        assertTrue(active.wod!!.recorded.isEmpty())
        assertThrows(IllegalArgumentException::class.java) {
            repo.recordWodMovement(0, 6, 15, null)
        }
        val logged = repo.recordWodMovement(0, 0, 16, null)
        assertEquals(1, logged.wod!!.recorded.size)
        assertEquals("calories", logged.wod!!.recorded.single().quantityUnit)
        repo.completeWodMovementBlock()
        val history = JSONObject(String(local.read()!!)).getJSONArray("workouts")
        assertEquals(1, history.length())
        val set = history.getJSONObject(0).getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
        assertEquals(16, set.getInt("reps"))
        assertEquals("calories", set.getString("quantityUnit"))
    }

    @Test fun tabataAndCircuitRetainRealTimingAndRejectOutOfRangeIntervals() {
        for (kind in listOf("tabata", "circuit")) {
            val (repo, local, id) = repo()
            val routine = repo.createRoutine("Tempo", kind,
                listOf(RoutineDraftEntry(id, 12)), rounds = 8,
                workSeconds = 20, restSeconds = 10)
            val block = JSONObject(String(local.read()!!)).getJSONArray("routines")
                .getJSONObject(0).getJSONArray("blocks").getJSONObject(0)
            assertEquals(8, block.getInt("rounds"))
            if (kind == "tabata") {
                assertEquals(20, block.getInt("workSeconds"))
                assertEquals(10, block.getInt("restSeconds"))
                assertEquals(4, block.getInt("timeCapMinutes"))
            } else assertEquals(10, block.getInt("restBetweenRoundsSeconds"))
            repo.startRoutine(routine)
            assertThrows(IllegalArgumentException::class.java) {
                repo.recordWodMovement(0, 8, 12, null)
            }
            repo.recordWodMovement(0, 7, 12, null)
            repo.completeWodMovementBlock()
            assertEquals(1, JSONObject(String(local.read()!!)).getJSONArray("workouts").length())
        }
    }
}
