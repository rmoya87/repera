package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.util.UUID

/**
 * Ejecución autónoma offline del reloj: plan del día, adopción de la sesión
 * iniciada en el reloj y registro reconciliado después.
 */
@RunWith(AndroidJUnit4::class)
class WearAutonomousSessionInstrumentedTest {

    private fun seedRoutine(ctx: android.content.Context, user: String,
                            exerciseId: String, weekday: Int) {
        val exercise = JSONObject().put("id", exerciseId).put("name", "Sentadilla")
            .put("equipment", "Barra").put("muscleGroup", "Piernas")
        val plannedSets = JSONArray().put(
            JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 5))
        val entry = JSONObject().put("id", UUID.randomUUID().toString())
            .put("exerciseId", exerciseId).put("plannedSets", plannedSets)
            .put("restSeconds", 90)
        val block = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Fuerza").put("kind", "strength")
            .put("exercises", JSONArray().put(entry))
        val routine = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Pierna pesada").put("weekday", weekday)
            .put("blocks", JSONArray().put(block))
        val state = JSONObject().put("exercises", JSONArray().put(exercise))
            .put("workouts", JSONArray())
            .put("routines", JSONArray().put(routine))
            .put("syncRevision", 0)
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray(Charsets.UTF_8))
    }

    @Test fun todayPlanSeMontaSinPersistirYSeAdoptaIdempotentemente() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val today = LocalDate.now()
        seedRoutine(ctx, user, exerciseId, today.dayOfWeek.value)
        val repo = WorkoutRepository(ctx, user)
        val plan = repo.todayPlanSession(today)
        assertNotNull(plan)
        assertEquals("Pierna pesada", plan!!.getString("title"))
        // No se ha persistido: sigue sin haber sesión activa.
        assertNull(repo.active())
        assertTrue(repo.adoptWearSession(plan))
        assertEquals(plan.getString("id"), repo.active()!!.id)
        // Segunda adopción del mismo plan: idempotente.
        assertTrue(repo.adoptWearSession(plan))
    }

    @Test fun serieDelRelojAdoptaLaSesionDelPlanAntesDeAplicar() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val today = LocalDate.now()
        seedRoutine(ctx, user, exerciseId, today.dayOfWeek.value)
        val repo = WorkoutRepository(ctx, user)
        val plan = repo.todayPlanSession(today)!!
        assertNull(repo.active())
        val setId = UUID.randomUUID().toString()
        assertTrue(repo.logWearSet(plan.getString("id"), 0, setId, 5, 60.0,
            sessionPayload = plan))
        val active = WorkoutRepository(ctx, user).active()!!
        assertEquals(1, active.sets.size)
        assertEquals(setId, active.sets.single().id)
        assertEquals(60.0, active.sets.single().weightKg!!, 0.001)
    }

    @Test fun sinPlanCuandoLaRutinaEsDeOtroDia() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val today = LocalDate.now()
        // Rutina programada para otro día de la semana: hoy no hay plan.
        seedRoutine(ctx, user, UUID.randomUUID().toString(),
            today.plusDays(1).dayOfWeek.value)
        assertNull(WorkoutRepository(ctx, user).todayPlanSession(today))
    }

    @Test fun adopcionRechazadaConOtraSesionActiva() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val today = LocalDate.now()
        seedRoutine(ctx, user, exerciseId, today.dayOfWeek.value)
        val repo = WorkoutRepository(ctx, user)
        val plan = repo.todayPlanSession(today)!!
        val other = JSONObject(plan.toString()).put("id", UUID.randomUUID().toString())
        repo.adoptWearSession(plan)
        assertFalse(repo.adoptWearSession(other))
    }
    @Test fun finishRetryIsIdempotentAndNeverFinishesADifferentActiveSession() {
        val c=InstrumentationRegistry.getInstrumentation().targetContext
        val user="test-wear-finish-${UUID.randomUUID()}"
        seedRoutine(c,user,"a",LocalDate.now().dayOfWeek.value)
        val repo=WorkoutRepository(c,user)
        val plan=repo.todayPlanSession()!!
        assertTrue(repo.adoptWearSession(plan))
        val id=plan.getString("id")
        assertFalse(repo.finishWearSession("other"))
        assertEquals(id,repo.active()!!.id)
        assertTrue(repo.finishWearSession(id))
        assertTrue(repo.finishWearSession(id))
        assertNull(repo.active())
        assertEquals(1,JSONObject(String(LocalSnapshotStore(c,user).read()!!)).getJSONArray("workouts").length())
    }
    @Test fun staleSessionPayloadCannotResurrectFinishedOrDeletedWorkout() {
        val c=InstrumentationRegistry.getInstrumentation().targetContext
        val user="test-wear-resurrection-${UUID.randomUUID()}"
        seedRoutine(c,user,"a",LocalDate.now().dayOfWeek.value)
        val repo=WorkoutRepository(c,user);val plan=repo.todayPlanSession()!!;val id=plan.getString("id")
        assertTrue(repo.adoptWearSession(plan));assertTrue(repo.finishWearSession(id))
        assertFalse(repo.adoptWearSession(plan));assertNull(repo.active())
        assertTrue(runCatching {repo.logWearSet(id,0,UUID.randomUUID().toString(),5,20.0,sessionPayload=plan)}.isFailure)
        assertNull(repo.active())
        repo.deleteWorkout(id)
        assertFalse(repo.adoptWearSession(plan));assertNull(repo.active())
        val mirror=WorkoutMirrorStore(c,user)
        mirror.acknowledgeDeletes(setOf(id))
        assertTrue(mirror.pendingDeletes().isEmpty())
        assertFalse(repo.adoptWearSession(plan));assertNull(repo.active())
        val finished=org.json.JSONObject(plan.toString()).put("finishedAt",java.time.Instant.now().toString())
        assertEquals(0,repo.mergeRecoveredWorkoutsFromSupabase(listOf(finished)))
    }
}
