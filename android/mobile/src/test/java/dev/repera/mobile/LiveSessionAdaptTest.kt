package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Port del contrato de LiveActivityModelTests.swift (Apple 5890215d) sobre el
 * adaptador JSON→StatsWorkout: la duración de una sesión En vivo es la ACTIVA
 * medida por Repera y su día es el de INICIO, sin inventar ruta ni energía.
 */
class LiveSessionAdaptTest {
    private val zone: ZoneId = ZoneId.of("UTC")

    private fun stateWith(session: JSONObject): JSONObject =
        JSONObject()
            .put("workouts", JSONArray().put(session))
            .put("exercises", JSONArray())
            .put("routines", JSONArray())

    @Test fun liveActivityUsesActiveDurationAndStartDay() {
        // Carrera que empieza 2 min antes de medianoche y acaba 2 después:
        // el día es el de INICIO y la duración la activa (240s = 4 min).
        val session = JSONObject()
            .put("id", "s1")
            .put("title", "Carrera antes de medianoche")
            .put("phase", "finished")
            .put("startedAt", "2026-09-12T23:58:00Z")
            .put("finishedAt", "2026-09-13T00:02:00Z")
            .put("liveSportID", "running")
            .put("activeDurationSeconds", 240.0)
            .put("recordedDistanceMeters", 800.0)
            .put("exercises", JSONArray())
        val workouts = ProgressSnapshotBuilder.statsWorkouts(stateWith(session), zone)
        assertEquals(1, workouts.size)
        val w = workouts[0]
        assertEquals("running", w.liveSportID)
        assertEquals(4.0, w.durationMinutes, 0.001)
        // Día de inicio (12), no el de fin (13).
        assertEquals(LocalDate.of(2026, 9, 12),
            Instant.ofEpochMilli(w.epochMillis).atZone(zone).toLocalDate())
    }

    @Test fun indoorLiveActivityDoesNotInventRouteOrEnergy() {
        val session = JSONObject()
            .put("id", "s2")
            .put("title", "Pádel")
            .put("phase", "finished")
            .put("startedAt", "2026-09-13T10:00:00Z")
            .put("finishedAt", "2026-09-13T11:00:00Z")
            .put("liveSportID", "padel")
            .put("activeDurationSeconds", 3000.0)
            .put("exercises", JSONArray())
        val w = ProgressSnapshotBuilder.statsWorkouts(stateWith(session), zone)[0]
        assertEquals("padel", w.liveSportID)
        assertEquals(50.0, w.durationMinutes, 0.001)
        assertNull(w.activeEnergyKcal)
    }

    @Test fun classicWorkoutKeepsFinishDayAndWallDuration() {
        val session = JSONObject()
            .put("id", "s3")
            .put("title", "Fuerza")
            .put("phase", "finished")
            .put("startedAt", "2026-09-12T23:30:00Z")
            .put("finishedAt", "2026-09-13T00:30:00Z")
            .put("exercises", JSONArray())
        val w = ProgressSnapshotBuilder.statsWorkouts(stateWith(session), zone)[0]
        assertNull(w.liveSportID)
        assertEquals(60.0, w.durationMinutes, 0.001)
        assertEquals(LocalDate.of(2026, 9, 13),
            Instant.ofEpochMilli(w.epochMillis).atZone(zone).toLocalDate())
    }

    @Test fun liveWithoutActiveFieldStillUsesWallEndNotStartDayAsEnd() {
        val session=JSONObject().put("id","fallback").put("phase","finished")
            .put("liveSportID","running").put("startedAt","2026-09-12T23:30:00Z")
            .put("finishedAt","2026-09-13T00:30:00Z").put("exercises",JSONArray())
        assertEquals(60.0,ProgressSnapshotBuilder.statsWorkouts(stateWith(session),zone).single().durationMinutes,0.0)
        session.put("activeDurationSeconds",0.0)
        assertEquals(0.0,ProgressSnapshotBuilder.statsWorkouts(stateWith(session),zone).single().durationMinutes,0.0)
    }
    @Test fun olderWorkoutsWithoutLiveFieldsAdaptUnchanged() {
        // Sin campos live (registros anteriores): nada cambia.
        val session = JSONObject()
            .put("id", "s4")
            .put("title", "Fuerza")
            .put("phase", "finished")
            .put("startedAt", "2026-09-13T10:00:00Z")
            .put("finishedAt", "2026-09-13T11:00:00Z")
            .put("exercises", JSONArray())
        val w = ProgressSnapshotBuilder.statsWorkouts(stateWith(session), zone)[0]
        assertNull(w.liveSportID)
        assertEquals(60.0, w.durationMinutes, 0.001)
    }
}
