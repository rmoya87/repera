package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Técnicas de fuerza: dropset y rest-pause con la fidelidad del modelo iOS. */
@RunWith(AndroidJUnit4::class)
class TechniquesInstrumentedTest {
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

    private fun startAndFinish(repo: WorkoutRepository, local: LocalSnapshotStore,
                               log: () -> Unit): JSONObject {
        val exerciseId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        repo.startQuickLog(exerciseId)
        log()
        repo.finish()
        return JSONObject(String(local.read()!!)).getJSONArray("workouts")
            .getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
    }

    @Test fun dropSetPersistsSegmentsAndCountsAllReps() {
        val (repo, local) = repo()
        val entry = startAndFinish(repo, local) {
            repo.logDropSet(10, 60.0, listOf(8 to 50.0, 6 to 40.0))
        }
        val set = entry.getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("dropset", set.getString("kind"))
        assertEquals(10, set.getInt("reps"))
        val drops = set.getJSONArray("drops")
        assertEquals(2, drops.length())
        assertEquals(8, drops.getJSONObject(0).getInt("reps"))
        assertEquals(50.0, drops.getJSONObject(0).getDouble("weightKg"), 0.001)
        assertEquals(24, entry.getInt("completedReps"))
        // La línea de historial muestra las caídas.
        val line = WorkoutHistorySets.loggedSetsWithLines(entry).single().second
        assertTrue(line.contains("+ 8"))
        assertTrue(line.contains("50.0"))
    }

    @Test fun restPauseSumsClusterRepsIntoMotherSet() {
        val (repo, local) = repo()
        val entry = startAndFinish(repo, local) {
            repo.logRestPauseSet(listOf(8 to 15, 5 to 15, 3 to 15), 80.0)
        }
        val set = entry.getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("restpause", set.getString("kind"))
        // Espejo de iOS: las reps de la serie madre son la suma de clusters.
        assertEquals(16, set.getInt("reps"))
        assertEquals(3, set.getJSONArray("clusters").length())
        assertEquals(15, set.getJSONArray("clusters").getJSONObject(1).getInt("restSeconds"))
        assertEquals(16, entry.getInt("completedReps"))
        assertTrue(WorkoutHistorySets.loggedSetsWithLines(entry).single().second
            .contains("rest-pause 8+5+3"))
    }

    @Test fun effortAndFailurePersistForEveryStrengthTechniqueWithoutLeakingIntoWarmup() {
        val (repo, local) = repo()
        val id=JSONObject(String(local.read()!!)).getJSONArray("exercises").getJSONObject(0).getString("id")
        repo.startQuickLog(id)
        repo.logCurrentSet(5,60.0,rir=3.0,toFailure=true)
        assertTrue(repo.active()!!.sets.single().toFailure)
        assertEquals(0.0,repo.active()!!.sets.single().rir!!,0.0)
        repo.logCurrentSet(3,40.0,rir=2.0,warmup=true,toFailure=true)
        repo.logDropSet(6,60.0,listOf(4 to 50.0),rir=2.0,toFailure=true)
        repo.logRestPauseSet(listOf(4 to 15,2 to 15),60.0,rir=1.0,toFailure=true)
        repo.logDropSet(5,55.0,listOf(3 to 45.0),rir=2.5)
        repo.logRestPauseSet(listOf(3 to 15,2 to 15),55.0,rir=1.5)
        repo.finish()
        val sets=JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
        for (i in listOf(0,2,3)) {
            assertTrue(sets.getJSONObject(i).getBoolean("toFailure"))
            assertEquals(0.0,sets.getJSONObject(i).getDouble("rir"),0.0)
        }
        assertFalse(sets.getJSONObject(1).getBoolean("toFailure"))
        assertFalse(sets.getJSONObject(1).has("rir"))
        assertEquals(2.5,sets.getJSONObject(4).getDouble("rir"),0.0)
        assertEquals(1.5,sets.getJSONObject(5).getDouble("rir"),0.0)
        assertFalse(sets.getJSONObject(4).getBoolean("toFailure"))
    }

    @Test fun techniquesRejectCardioAndBadInput() {
        val (repo, local) = repo()
        val exerciseId = JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        repo.startQuickLog(exerciseId)
        assertThrows(IllegalArgumentException::class.java) {
            repo.logDropSet(10, null, emptyList())
        }
        assertThrows(IllegalArgumentException::class.java) {
            repo.logRestPauseSet(listOf(8 to 15))
        }
        assertThrows(IllegalArgumentException::class.java) {
            repo.logRestPauseSet(listOf(8 to 0, 5 to 15))
        }
        assertNull(JSONObject(String(local.read()!!)).optJSONArray("workouts")
            ?.takeIf { it.length() > 0 })
    }
}
