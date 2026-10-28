package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Device integration tests for at-least-once Wear OS actions. */
@RunWith(AndroidJUnit4::class)
class WearSetReconciliationInstrumentedTest {
    @Test fun lostAckCanReplayAfterRestartWithoutDuplicatingSets() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val exercise = JSONObject().put("id", exerciseId).put("name", "Sentadilla")
            .put("equipment", "Barra").put("muscleGroup", "Piernas")
        val state = JSONObject().put("exercises", JSONArray().put(exercise))
            .put("workouts", JSONArray()).put("routines", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        val repo = WorkoutRepository(ctx, user)
        val active = repo.startQuickLog(exerciseId)
        val messageId = UUID.randomUUID().toString()
        var newSetEffects=0
        assertTrue(repo.logWearSet(active.id, active.index, messageId, 8, 40.0,onNewSet={newSetEffects++}))
        assertTrue(WorkoutRepository(ctx, user).logWearSet(
            active.id, active.index, messageId, 8, 40.0,onNewSet={newSetEffects++}
        ))
        val restored = WorkoutRepository(ctx, user).active()!!
        assertEquals(1, restored.sets.size)
        assertEquals(messageId, restored.sets.single().id)
        assertEquals(8, restored.sets.single().reps)
        assertEquals(40.0, restored.sets.single().weightKg!!, 0.001)
        repo.finish()
        // A delayed acknowledgement is also valid after the session is archived.
        assertTrue(WorkoutRepository(ctx, user).logWearSet(
            active.id, active.index, messageId, 8, 40.0,onNewSet={newSetEffects++}
        ))
        assertEquals(1,newSetEffects)
        val archived = JSONObject(String(local.read()!!)).getJSONArray("workouts")
        assertEquals(1, archived.length())
        assertEquals(1, archived.getJSONObject(0).getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("loggedSets").length())
    }

    @Test fun wearSetCarriesRirFromTheWatch() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val exercise = JSONObject().put("id", exerciseId).put("name", "Peso muerto")
            .put("equipment", "Barra").put("muscleGroup", "Espalda")
        val state = JSONObject().put("exercises", JSONArray().put(exercise))
            .put("workouts", JSONArray()).put("routines", JSONArray())
            .put("syncRevision", 0)
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray(Charsets.UTF_8))
        val repo = WorkoutRepository(ctx, user)
        val active = repo.startQuickLog(exerciseId)
        assertTrue(repo.logWearSet(active.id, active.index,
            UUID.randomUUID().toString(), 5, 140.0, rir = 1.5))
        val saved = WorkoutRepository(ctx, user).active()!!.sets.single()
        assertEquals(1.5, saved.rir!!, 0.001)
        repo.finish()
    }

    @Test fun staleWatchSessionCannotWriteToAnotherActiveWorkout() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val state = JSONObject().put("exercises",
                JSONArray().put(JSONObject().put("id", id).put("name", "Sentadilla")
                    .put("equipment", "Barra").put("muscleGroup", "Piernas")))
            .put("workouts", JSONArray()).put("routines", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        val repo = WorkoutRepository(ctx, user)
        val active = repo.startQuickLog(id)
        assertThrows(IllegalStateException::class.java) {
            repo.logWearSet(UUID.randomUUID().toString(), active.index,
                UUID.randomUUID().toString(), 8, 40.0)
        }
        assertTrue(WorkoutRepository(ctx, user).active()!!.sets.isEmpty())
    }
    @Test fun wearWarmupAndFailureUseTheSameStoredSemanticsAsPhone() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext;val user="test-wear-phase-${UUID.randomUUID()}"
        val state=JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
            .put("workouts",JSONArray()).put("routines",JSONArray())
        val local=LocalSnapshotStore(ctx,user);local.write(state.toString().toByteArray())
        val repo=WorkoutRepository(ctx,user);val active=repo.startQuickLog("a")
        repo.logWearSet(active.id,active.index,UUID.randomUUID().toString(),5,20.0,rir=2.0,warmup=true,toFailure=true)
        repo.logWearSet(active.id,active.index,UUID.randomUUID().toString(),5,40.0,toFailure=true)
        val entry=JSONObject(String(local.read()!!)).getJSONObject("activeSession").getJSONArray("exercises").getJSONObject(0)
        val warm=entry.getJSONArray("loggedSets").getJSONObject(0);val work=entry.getJSONArray("loggedSets").getJSONObject(1)
        assertEquals("warmup",warm.getString("phase"));assertFalse(warm.getBoolean("toFailure"));assertFalse(warm.has("rir"))
        assertTrue(work.getBoolean("toFailure"));assertEquals(0.0,work.getDouble("rir"),0.001);assertEquals(5,entry.getInt("completedReps"))
    }
}
