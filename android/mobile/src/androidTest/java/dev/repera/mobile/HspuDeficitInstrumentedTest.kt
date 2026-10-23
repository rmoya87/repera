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
class HspuDeficitInstrumentedTest {
    @Test fun hspuStoresAndRevisesCentimeterDeficitNotKilograms() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val exercise = JSONObject().put("id", id).put("name", "HSPU")
            .put("muscleGroup", "Hombros").put("equipment", "Peso corporal")
        val snapshot = JSONObject().put("exercises", JSONArray().put(exercise))
            .put("routines", JSONArray()).put("workouts", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(snapshot.toString().toByteArray(Charsets.UTF_8))
        val repo = WorkoutRepository(ctx, user)
        assertTrue(repo.startQuickLog(id).allowsDeficit)
        val saved = repo.logCurrentSet(7, null, rir = 2.0, deficitCm = 15)
        val set = saved.sets.single()
        assertNull(set.weightKg)
        assertEquals(15, set.deficitCm)
        assertEquals(2.0, set.rir!!, 0.001)
        assertTrue(WorkoutHistorySets.displayLines(
            JSONObject().put("phase", "counting"),
            JSONObject(String(local.read()!!)).getJSONObject("activeSession")
                .getJSONArray("exercises").getJSONObject(0)).single().contains("15 cm déficit"))
        repo.reviseCurrentSet(set.id, 5, null, deficitCm = 10)
        assertEquals(10, repo.active()!!.sets.single().deficitCm)
        repo.finish()
        val archived = JSONObject(String(local.read()!!)).getJSONArray("workouts")
            .getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertEquals(10, archived.getInt("deficitCm"))
        assertFalse(archived.has("weightKg"))
    }

    @Test fun nonHspuCannotRecordDeficit() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val exercise = JSONObject().put("id", id).put("name", "Sentadilla")
            .put("muscleGroup", "Piernas").put("equipment", "Barra")
        LocalSnapshotStore(ctx, user).write(JSONObject()
            .put("exercises", JSONArray().put(exercise))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0).toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        repo.startQuickLog(id)
        assertThrows(IllegalStateException::class.java) {
            repo.logCurrentSet(8, 40.0, deficitCm = 5)
        }
    }
}
