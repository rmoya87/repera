package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/** Serie de progreso por ejercicio (StatsEngine.exerciseProgressSeries de iOS). */
@RunWith(AndroidJUnit4::class)
class ExerciseProgressSeriesInstrumentedTest {

    private val exerciseId = "ex-1"
    private val zone: ZoneId = ZoneId.systemDefault()

    private fun session(daysAgo: Long, sets: JSONArray): JSONObject {
        val day = LocalDate.now().minusDays(daysAgo)
        val finished = day.atTime(LocalTime.of(11, 0)).atZone(zone)
            .toInstant().toString()
        return JSONObject()
            .put("id", "w-$daysAgo")
            .put("phase", "finished")
            .put("finishedAt", finished)
            .put("exercises", JSONArray().put(JSONObject()
                .put("exercise", JSONObject().put("id", exerciseId)
                    .put("name", "Press de banca").put("muscleGroup", "Pecho"))
                .put("loggedSets", sets)))
    }

    private fun strengthSet(reps: Int, kg: Double, rir: Double? = null) =
        JSONObject().put("reps", reps).put("weightKg", kg).apply {
            if (rir != null) put("rir", rir)
        }

    @Test
    fun topSetTomaElMejorPesoDeCadaSesion() {
        val archive = JSONArray()
            .put(session(5, JSONArray()
                .put(strengthSet(8, 80.0)).put(strengthSet(6, 90.0))))
            .put(session(2, JSONArray().put(strengthSet(5, 95.0))))
        val points = ExerciseProgressSeries.compute(archive, exerciseId,
            ExerciseProgressMetric.TOP_SET, ExerciseProgressRange.ALL)
        assertEquals(2, points.size)
        assertEquals(90.0, points[0].value, 1e-9)
        assertEquals(95.0, points[1].value, 1e-9)
        // Orden cronológico.
        assertTrue(points[0].epochMillis < points[1].epochMillis)
    }

    @Test
    fun oneRMEstimadoUsaEpleyConLaMejorSerie() {
        val archive = JSONArray().put(session(3, JSONArray()
            .put(strengthSet(10, 60.0))   // 60 * (1+10/30) = 80
            .put(strengthSet(5, 100.0)))) // 100 * (1+5/30) ≈ 116.67
        val points = ExerciseProgressSeries.compute(archive, exerciseId,
            ExerciseProgressMetric.ESTIMATED_ONE_RM, ExerciseProgressRange.ALL)
        assertEquals(1, points.size)
        assertEquals(100.0 * (1 + 5.0 / 30.0), points[0].value, 1e-6)
        assertEquals(5, points[0].reps)
    }

    @Test
    fun esfuerzoPromediaElRirDeLasSeries() {
        val archive = JSONArray().put(session(1, JSONArray()
            .put(strengthSet(8, 80.0, 2.0)).put(strengthSet(8, 80.0, 1.0))))
        val points = ExerciseProgressSeries.compute(archive, exerciseId,
            ExerciseProgressMetric.EFFORT, ExerciseProgressRange.ALL)
        assertEquals(1, points.size)
        assertEquals(1.5, points[0].value, 1e-9)
    }

    @Test
    fun rangoFiltraSesionesAntiguas() {
        val archive = JSONArray()
            .put(session(200, JSONArray().put(strengthSet(5, 100.0))))
            .put(session(10, JSONArray().put(strengthSet(5, 110.0))))
        val points = ExerciseProgressSeries.compute(archive, exerciseId,
            ExerciseProgressMetric.TOP_SET, ExerciseProgressRange.ONE_MONTH)
        assertEquals(1, points.size)
        assertEquals(110.0, points[0].value, 1e-9)
    }

    @Test
    fun sesionesSinTerminarNoCuentan() {
        val unfinished = JSONObject()
            .put("id", "w-open").put("phase", "active")
            .put("startedAt", LocalDate.now().atTime(10, 0).atZone(zone)
                .toInstant().toString())
            .put("exercises", JSONArray().put(JSONObject()
                .put("exercise", JSONObject().put("id", exerciseId))
                .put("loggedSets", JSONArray().put(strengthSet(5, 100.0)))))
        val points = ExerciseProgressSeries.compute(
            JSONArray().put(unfinished), exerciseId,
            ExerciseProgressMetric.TOP_SET, ExerciseProgressRange.ALL)
        assertTrue(points.isEmpty())
    }

    @Test
    fun metricasDisponiblesPorEstiloComoIOS() {
        assertEquals(listOf(ExerciseProgressMetric.TOP_SET,
            ExerciseProgressMetric.ESTIMATED_ONE_RM, ExerciseProgressMetric.EFFORT),
            ExerciseProgressMetric.available("loadAndReps"))
        assertEquals(listOf(ExerciseProgressMetric.BEST_METERS,
            ExerciseProgressMetric.BEST_CALORIES, ExerciseProgressMetric.TOTAL_METERS,
            ExerciseProgressMetric.TOTAL_CALORIES, ExerciseProgressMetric.DURATION),
            ExerciseProgressMetric.available("machineWork"))
    }
}
