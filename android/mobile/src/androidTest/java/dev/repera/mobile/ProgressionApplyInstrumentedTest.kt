package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.util.UUID

/** La progresión de la rutina recalcula los objetivos al iniciar sesión,
 *  como iOS (ProgressionEngine.applySuggestions). */
@RunWith(AndroidJUnit4::class)
class ProgressionApplyInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val squat = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Sentadilla").put("muscleGroup", "Piernas")
        val state = JSONObject()
            .put("exercises", JSONArray().put(squat))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    private fun exerciseId(local: LocalSnapshotStore): String =
        JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")

    private fun finishedSession(exerciseId: String, reps: Int, weight: Double,
                                daysAgo: Long): JSONObject {
        val day = LocalDate.now().minusDays(daysAgo)
        val start = day.atTime(LocalTime.of(10, 0)).atZone(ZoneId.systemDefault())
        val set = JSONObject().put("id", UUID.randomUUID().toString())
            .put("reps", reps).put("weightKg", weight).put("phase", "work")
        return JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", "Anterior")
            .put("phase", "finished")
            .put("startedAt", start.toInstant().toString())
            .put("finishedAt", start.plusMinutes(50).toInstant().toString())
            .put("exercises", JSONArray().put(JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("exercise", JSONObject().put("id", exerciseId)
                    .put("name", "Sentadilla").put("muscleGroup", "Piernas"))
                .put("plannedSets", JSONArray()
                    .put(JSONObject().put("targetReps", 8))
                    .put(JSONObject().put("targetReps", 8))
                    .put(JSONObject().put("targetReps", 8)))
                .put("loggedSets", JSONArray()
                    .put(set).put(JSONObject(set.toString()))
                    .put(JSONObject(set.toString())))))
    }

    @Test fun linearProgressionRaisesTargetsAtSessionStart() {
        val (repo, local) = repo()
        val id = exerciseId(local)
        repo.createRoutine("Fuerza", "strength",
            listOf(RoutineDraftEntry(id, 8, sets = 3, weightKg = 100.0)))
        val routineId = JSONObject(String(local.read()!!)).getJSONArray("routines")
            .getJSONObject(0).getString("id")
        repo.setRoutineProgression(routineId, "linear")
        // Historial con hit completo a 100 kg x 8.
        val state = JSONObject(String(local.read()!!))
        state.getJSONArray("workouts").put(finishedSession(id, 8, 100.0, 2))
        local.write(state.toString().toByteArray(Charsets.UTF_8))

        val active = repo.startRoutine(routineId)
        val snapshot = JSONObject(String(local.read()!!))
        val session = snapshot.getJSONObject("activeSession")
        val planned = session.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets")
        assertEquals(3, planned.length())
        assertEquals(8, planned.getJSONObject(0).getInt("targetReps"))
        assertEquals(102.5, planned.getJSONObject(0).getDouble("targetWeightKg"), 0.001)
        assertNotNull(active)
        // La rutina guardada NO se reescribe: solo los objetivos de la sesión.
        val routine = snapshot.getJSONArray("routines").getJSONObject(0)
        assertEquals(100.0, routine.getJSONArray("blocks").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").getJSONObject(0)
            .getDouble("targetWeightKg"), 0.001)
        assertEquals("linear", routine.getString("progression"))
    }

    @Test fun offKeepsPlanTargetsUntouched() {
        val (repo, local) = repo()
        val id = exerciseId(local)
        repo.createRoutine("Fuerza", "strength",
            listOf(RoutineDraftEntry(id, 8, sets = 3, weightKg = 100.0)))
        val routineId = JSONObject(String(local.read()!!)).getJSONArray("routines")
            .getJSONObject(0).getString("id")
        val state = JSONObject(String(local.read()!!))
        // La política por defecto de ajustes también es off: solo así la rutina off no progresa (Apple: off -> defaultProgression).
        state.put("settings", JSONObject().put("defaultProgression", "off"))
        state.getJSONArray("workouts").put(finishedSession(id, 8, 100.0, 2))
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        repo.startRoutine(routineId)
        val planned = JSONObject(String(local.read()!!))
            .getJSONObject("activeSession").getJSONArray("exercises")
            .getJSONObject(0).getJSONArray("plannedSets")
        assertEquals(100.0, planned.getJSONObject(0).getDouble("targetWeightKg"), 0.001)
    }

    /** Apple: routine.progression == off usa settings.defaultProgression (lineal si falta). */
    @Test fun offRoutineUsesDefaultPolicyAndFreeTierKeepsPlan() {
        for (allow in listOf(true, false)) {
            val (repo, local) = repo()
            val id = exerciseId(local)
            repo.createRoutine("Fuerza", "strength", listOf(RoutineDraftEntry(id, 8, sets = 3, weightKg = 100.0)))
            val routineId = JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getString("id")
            val state = JSONObject(String(local.read()!!))
            state.getJSONArray("workouts").put(finishedSession(id, 8, 100.0, 2))
            local.write(state.toString().toByteArray(Charsets.UTF_8))
            repo.startRoutine(routineId, allowAdvancedProgression = allow)
            val w = JSONObject(String(local.read()!!)).getJSONObject("activeSession").getJSONArray("exercises")
                .getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getDouble("targetWeightKg")
            assertEquals(if (allow) 102.5 else 100.0, w, 0.001)
        }
    }
}
