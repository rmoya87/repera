package dev.repera.mobile

import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.WorkoutLocationPin
import dev.repera.domain.WorkoutRoutePoint
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

/** Pin de gym + ruta GPS persistidos en la sesión (WorkoutLocationCodableTests iOS). */
class WorkoutLocationInstrumentedTest {

    @Test
    fun pinYRutaSePersistenYSobrevivenAlFinish() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val exercise = JSONObject()
            .put("id", exerciseId).put("name", "Carrera suave")
            .put("muscleGroup", "Cardio").put("isCustom", true)
            .put("secondaryMuscles", JSONArray()).put("instructions", JSONArray())
            .put("primaryRegions", JSONArray()).put("secondaryRegions", JSONArray())
            .put("isFavorite", false)
        val sets = JSONArray().put(
            JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 8))
        val block = JSONObject().put("id", UUID.randomUUID().toString())
            .put("kind", "strength").put("title", "Bloque")
            .put("exercises", JSONArray().put(
                JSONObject().put("id", UUID.randomUUID().toString())
                    .put("exerciseId", exerciseId).put("plannedSets", sets)))
        val routine = JSONObject().put("id", routineId).put("title", "Running del domingo")
            .put("blocks", JSONArray().put(block)).put("progression", "off")
            .put("isFavorite", false)
        val state = JSONObject()
            .put("settings", JSONObject())
            .put("exercises", JSONArray().put(exercise))
            .put("routines", JSONArray().put(routine))
            .put("workouts", JSONArray()).put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray()).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 0).put("lastWriterDeviceId", "")
            .put("updatedAt", "2026-10-24T00:00:00Z")
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())

        val repo = WorkoutRepository(ctx, user)
        val active = repo.startStrengthRoutine(routineId)

        // Pin al empezar (capturePin iOS).
        repo.attachLocationPin(active.id, WorkoutLocationPin(
            latitude = 40.4168, longitude = -3.7038, recordedAtEpochMs = 1_700_000_000_000L,
            name = "Retiro"))

        // Heurística outdoor con título real.
        val info = repo.activeSessionOutdoorInfo()
        assertNotNull(info)
        assertTrue(dev.repera.domain.WorkoutLocationLogic
            .shouldTrackRoute(info!!.title, info.exerciseNames))

        // Ruta al terminar (stopRouteTracking → sesión ya archivada).
        val puntos = (0 until 5).map {
            WorkoutRoutePoint(id = it, latitude = 40.4168 + it * 0.0001,
                longitude = -3.7038, recordedAtEpochMs = 1_700_000_000_000L + it * 30_000L,
                speedMps = 2.8, altitudeMeters = 650.0)
        }
        repo.finish()
        repo.attachRoutePoints(active.id, puntos)

        // Round-trip: releer del disco y comprobar pin + ruta íntegros.
        val raw = String(LocalSnapshotStore(ctx, user).read()!!)
        val archived = JSONObject(raw).getJSONArray("workouts").getJSONObject(0)
        val pin = archived.getJSONObject("locationPin")
        assertEquals(40.4168, pin.getDouble("latitude"), 1e-9)
        assertEquals("Retiro", pin.getString("name"))
        val ruta = archived.getJSONArray("routePoints")
        assertEquals(5, ruta.length())
        assertEquals(2.8, ruta.getJSONObject(2).getDouble("speedMps"), 1e-9)
        assertEquals(650.0, ruta.getJSONObject(4).getDouble("altitudeMeters"), 1e-9)

        // El espejo Supabase sigue sin recibir ubicación (privacidad 1:1 iOS).
        val limpio = WorkoutMirrorStore.privatize(archived)
        assertTrue(limpio.isNull("locationPin"))
        assertTrue(limpio.isNull("routePoints"))
    }
}
