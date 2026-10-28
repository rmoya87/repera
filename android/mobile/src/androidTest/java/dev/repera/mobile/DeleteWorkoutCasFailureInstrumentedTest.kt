package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/**
 * COMPILADO, NO EJECUTADO (sin dispositivo). Caracteriza el riesgo de WorkoutRepository.deleteWorkout:
 * el tombstone del espejo se escribe ANTES de save(); si save() falla por CAS (otro escritor, p. ej. una
 * descarga de Drive, toco el snapshot entre la lectura y el guardado), el entreno sigue en local pero su
 * id queda como borrado pendiente. El espejo omite los ids de deletedIds() y el siguiente sync borraria el remoto.
 * El hook usa stillAuthorized: llamada 1 = loadOrNull, llamada 2 = comprobacion de deleteWorkout (tras leer), llamada 3 = save.
 */
@RunWith(AndroidJUnit4::class)
class DeleteWorkoutCasFailureInstrumentedTest {
    @Test fun casFailureLeavesPendingTombstoneWhileWorkoutRemainsLocal() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val press = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Press banca").put("muscleGroup", "Pecho").put("equipment", "Barra")
        val local = LocalSnapshotStore(ctx, user)
        local.write(JSONObject().put("exercises", JSONArray().put(press))
            .put("routines", JSONArray()).put("workouts", JSONArray()).put("syncRevision", 0)
            .toString().toByteArray(Charsets.UTF_8))
        var armed = false
        var calls = 0
        val repo = WorkoutRepository(ctx, user) {
            if (armed && ++calls == 2) {
                val s = JSONObject(String(local.read()!!, Charsets.UTF_8))
                s.put("syncRevision", s.optInt("syncRevision", 0) + 1)
                local.write(s.toString().toByteArray(Charsets.UTF_8))
            }
            true
        }
        repo.startQuickLog(press.getString("id"))
        repo.logCurrentSet(10, 60.0)
        repo.finish()
        val id = JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0).getString("id")
        armed = true
        val failed = runCatching { repo.deleteWorkout(id) }.isFailure
        armed = false
        assertTrue("el CAS debia fallar", failed)
        val stillLocal = JSONObject(String(local.read()!!)).getJSONArray("workouts").length() == 1
        val pending = WorkoutMirrorStore(ctx, user).pendingDeletes().contains(id)
        // Estado inseguro caracterizado: ambos true. Una correccion futura debe hacer que no se cumplan a la vez.
        assertTrue(stillLocal)
        assertTrue(pending)
    }
}
