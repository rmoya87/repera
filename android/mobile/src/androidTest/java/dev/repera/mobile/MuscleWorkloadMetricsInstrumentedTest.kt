package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.time.ZoneId

@RunWith(AndroidJUnit4::class)
class MuscleWorkloadMetricsInstrumentedTest {
    private val today = LocalDate.parse("2026-10-23")
    private val zone = ZoneId.of("Europe/Madrid")

    private fun entry(name: String, group: String, plans: Int, completed: Boolean = false,
                      warmups: Int = 0): JSONObject {
        val prescribed = JSONArray()
        repeat(plans) { prescribed.put(JSONObject().put("targetReps", 8).put("targetWeightKg", 30)) }
        val logs = JSONArray()
        repeat(warmups) { logs.put(JSONObject().put("phase", "warmup").put("reps", 5)) }
        return JSONObject().put("exercise", JSONObject().put("name", name)
            .put("muscleGroup", group).put("equipment", "Barra"))
            .put("plannedSets", prescribed).put("loggedSets", logs)
            .put("blockKind", if (completed) "wod" else "strength")
    }

    @Test fun usesFinishedPrescriptionsButIgnoresCardioWodAndUnfinished() {
        val strength = entry("Sentadilla", "Piernas", 3)
        val warming = entry("Press banca", "Pecho", 2, warmups = 1)
        val wod = entry("Sentadilla", "Piernas", 21, completed = true)
        val cardio = entry("SkiErg", "Cardio", 1)
        val monday = JSONObject().put("phase", "finished")
            .put("finishedAt", "2026-10-19T12:00:00Z")
            .put("exercises", JSONArray().put(strength).put(warming).put(wod).put(cardio))
        val draft = JSONObject().put("phase", "ready")
            .put("startedAt", "2026-10-23T08:00:00Z")
            .put("exercises", JSONArray().put(entry("Sentadilla", "Piernas", 9)))
        val lastWeek = JSONObject().put("phase", "finished")
            .put("finishedAt", "2026-10-11T12:00:00Z")
            .put("exercises", JSONArray().put(entry("Sentadilla", "Piernas", 9)))
        val archive = JSONArray().put(monday).put(draft).put(lastWeek)
        val original = archive.toString()
        assertEquals(listOf(
            MuscleWorkloadMetrics.GroupCount("Piernas", 3),
            MuscleWorkloadMetrics.GroupCount("Pecho", 2)
        ), MuscleWorkloadMetrics.weekly(archive, today, zone))
        assertEquals(original, archive.toString())
    }

    @Test fun excludesWarmupsAndCountsOnlyPositiveActualWork() {
        val e = entry("Sentadilla", "Piernas", 4, warmups = 1)
        e.getJSONArray("loggedSets")
            .put(JSONObject().put("phase", "work").put("reps", 5))
            .put(JSONObject().put("phase", "work").put("reps", 0))
        val archive = JSONArray().put(JSONObject().put("phase", "finished")
            .put("finishedAt", "2026-10-22T12:00:00Z")
            .put("exercises", JSONArray().put(e)))
        assertEquals(1, MuscleWorkloadMetrics.weekly(archive, today, zone).single().sets)
    }
}
