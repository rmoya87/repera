package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import dev.repera.domain.ProgressTimeRange
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.time.ZoneId

/** Adaptación JSON → motores de dominio para el snapshot de Progreso. */
@RunWith(AndroidJUnit4::class)
class ProgressSnapshotInstrumentedTest {
    private val zone: ZoneId = ZoneId.of("Europe/Madrid")
    private val now = LocalDate.of(2026, 10, 24)

    private fun session(day: LocalDate, minutes: Long, block: JSONObject.() -> Unit = {}): JSONObject {
        val start = day.atTime(10, 0).atZone(zone).toInstant().toString()
        val end = day.atTime(10, 0).plusSeconds(minutes * 60).atZone(zone).toInstant().toString()
        return JSONObject()
            .put("id", "w-$day")
            .put("title", "Sesión $day")
            .put("phase", "finished")
            .put("startedAt", start)
            .put("finishedAt", end)
            .apply(block)
    }

    private fun strengthEntry(weight: Double, reps: Int, rir: Double? = null): JSONObject {
        val set = JSONObject().put("reps", reps).put("weightKg", weight)
        if (rir != null) set.put("rir", rir)
        return JSONObject()
            .put("exercise", JSONObject()
                .put("id", "press").put("name", "Press banca")
                .put("muscleGroup", "Pecho").put("targetMuscle", "pectorals")
                .put("sportTag", "Gimnasio")
                .put("secondaryMuscles", JSONArray().put("triceps")))
            .put("loggedSets", JSONArray().put(set))
    }

    @Test fun fullArchiveFeedsRecordsStreakAndSummary() {
        val state = JSONObject()
            .put("workouts", JSONArray()
                .put(session(now, 50) { put("exercises", JSONArray().put(strengthEntry(100.0, 5, 1.0))) })
                .put(session(now.minusDays(7), 45) { put("exercises", JSONArray().put(strengthEntry(90.0, 10))) }))
            .put("bodyWeights", JSONArray())
        val snap = ProgressSnapshotBuilder.build(state, ProgressTimeRange.WEEK,
            now = now, zone = zone)
        assertEquals(1, snap.filteredWorkouts)
        assertEquals(1, snap.summary.sessionCount)
        assertEquals(1, snap.records.size)
        assertEquals("Press banca", snap.records[0].exerciseName)
        // Racha: esta semana + la anterior.
        assertEquals(2, snap.streak)
        // El periodo anterior tuvo una sesión.
        assertEquals(1, snap.previousSummary?.sessionCount)
        assertTrue(snap.hasHardSets)
        // Fatiga en pecho con serie dura reciente.
        assertTrue(snap.muscleStatuses.any { it.name == "chest" && it.score > 0 })
        // Heatmap: 6 días (lunes..sábado), hoy con actividad.
        assertEquals(6, snap.heatmapTime.size)
        assertTrue(snap.heatmapTime.last().second >= 1)
    }

    @Test fun previousMonthRangeExcludesThisMonth() {
        val state = JSONObject().put("workouts", JSONArray()
            .put(session(now, 50) { put("exercises", JSONArray().put(strengthEntry(80.0, 5))) }))
            .put("bodyWeights", JSONArray())
        val snap = ProgressSnapshotBuilder.build(state, ProgressTimeRange.MONTH,
            now = now, zone = zone)
        assertEquals(1, snap.filteredWorkouts)
        assertEquals(0, snap.previousSummary?.sessionCount)
    }

    @Test fun weightPointsFilterAndDelta() {
        val state = JSONObject().put("workouts", JSONArray())
            .put("bodyWeights", JSONArray()
                .put(JSONObject().put("date", now.minusDays(40).toString()).put("weightKg", 80.0))
                .put(JSONObject().put("date", now.minusDays(2).toString()).put("weightKg", 78.5))
                .put(JSONObject().put("date", now.toString()).put("weightKg", 78.0)))
        val snap = ProgressSnapshotBuilder.build(state, ProgressTimeRange.WEEK,
            now = now, zone = zone)
        assertEquals(2, snap.weightPoints.size) // la de hace 40d queda fuera
        assertEquals(78.0, snap.weightPoints.last().value, 0.0001)
        assertEquals(-2.0, snap.weightDelta30d!!, 0.0001)
    }

    @Test fun mobilityCountsRegisteredDurationOnly() {
        val mobility = JSONObject()
            .put("exercise", JSONObject().put("id", "mob-1").put("name", "Respiración")
                .put("sportTag", "Movilidad").put("muscleGroup", "Core"))
            .put("loggedSets", JSONArray()
                .put(JSONObject().put("reps", 1).put("durationSeconds", 300))
                .put(JSONObject().put("reps", 0).put("durationSeconds", 999)))
        val state = JSONObject().put("workouts", JSONArray()
            .put(session(now, 50) { put("exercises", JSONArray().put(mobility)) }))
            .put("bodyWeights", JSONArray())
        val snap = ProgressSnapshotBuilder.build(state, ProgressTimeRange.WEEK,
            now = now, zone = zone)
        assertEquals(1, snap.mobilitySessions)
        assertEquals(300, snap.mobilitySeconds)
        // Movilidad no genera fatiga muscular ni records.
        assertTrue(snap.records.isEmpty())
        assertTrue(snap.muscleStatuses.none { it.name == "abs" && it.score > 0 })
    }
}
