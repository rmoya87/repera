package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExerciseSessionAppearanceTest {

    private fun ex(id: String, name: String) = JSONObject()
        .put("id", id).put("name", name)

    private fun entry(id: String, name: String, sets: JSONArray,
                      planned: JSONArray? = null): JSONObject {
        val e = JSONObject().put("exercise", ex(id, name)).put("loggedSets", sets)
        if (planned != null) e.put("plannedSets", planned)
        return e
    }

    private fun set(reps: Int, weight: Double? = null): JSONObject {
        val s = JSONObject().put("reps", reps)
        if (weight != null) s.put("weightKg", weight)
        return s
    }

    private fun session(id: String, title: String, entries: JSONArray,
                        results: JSONArray? = null,
                        finished: Boolean = true): JSONObject {
        val s = JSONObject().put("id", id).put("title", title)
            .put("exercises", entries)
        if (finished) s.put("phase", "finished")
            .put("finishedAt", "2026-10-20T10:00:00Z")
        if (results != null) s.put("wodResults", results)
        return s
    }

    @Test fun strengthSessionShowsCompactSetLines() {
        val sets = JSONArray().put(set(8, 50.0)).put(set(6, 55.0))
        val s = session("w1", "Fuerza lunes",
            JSONArray().put(entry("e1", "Press banca", sets)))
        val a = ExerciseSessionAppearances.appearance("e1", s)!!
        assertEquals(listOf("50×8", "55×6"), a.setLines)
        assertEquals("Fuerza lunes", a.sessionTitle)
        assertNull(a.wodScoreLabel)
    }

    @Test fun benchmarkWodShowsGlobalScoreLabel() {
        val results = JSONArray().put(JSONObject()
            .put("id", "b1").put("format", "forTime")
            .put("elapsedSeconds", 754).put("wodTemplateId", "fran"))
        val entry = entry("e1", "Thruster", JSONArray()).put("blockId", "b1")
        val s = session("w2", "Fran", JSONArray().put(entry), results)
        val a = ExerciseSessionAppearances.appearance("e1", s)!!
        assertTrue(a.isGlobalWodScore)
        assertEquals("12:34", a.wodScoreLabel)
        assertEquals("For Time / RFT", a.wodFormatName)
        assertEquals("fran", a.wodTemplateId)
    }

    @Test fun emptyScoreIsNotAnAppearance() {
        val results = JSONArray().put(JSONObject()
            .put("id", "b1").put("wodTemplateId", "fran"))
        val entry = entry("e1", "Thruster", JSONArray()).put("blockId", "b1")
        val s = session("w3", "Fran", JSONArray().put(entry), results)
        assertNull(ExerciseSessionAppearances.appearance("e1", s))
    }

    @Test fun unfinishedSessionFallsBackToPrescriptionLine() {
        val planned = JSONArray().put(JSONObject()
            .put("targetReps", 8).put("targetWeightKg", 50.0))
        val s = session("w4", "Fuerza", JSONArray().put(
            entry("e1", "Press banca", JSONArray(), planned)), finished = false)
        val a = ExerciseSessionAppearances.appearance("e1", s)!!
        assertEquals("8 @ 50 kg", a.prescriptionLine)
        assertTrue(a.setLines.isEmpty())
    }

    @Test fun priorAppearancesSkipUnfinishedAndTheExcludedSession() {
        val old = session("w-old", "Día 1", JSONArray().put(
            entry("e1", "Press banca", JSONArray().put(set(5, 40.0)))))
        val excluded = session("w-new", "Día 2", JSONArray().put(
            entry("e1", "Press banca", JSONArray().put(set(5, 50.0)))))
        val unfinished = session("w-mid", "Día 3", JSONArray().put(
            entry("e1", "Press banca", JSONArray().put(set(5, 45.0)))),
            finished = false)
        val rows = ExerciseSessionAppearances.priorAppearances("e1",
            listOf(old, excluded, unfinished), excludingSessionId = "w-new")
        assertEquals(1, rows.size)
        assertEquals("w-old", rows.single().sessionId)
    }

    @Test fun matchesByEquivalentNameWhenIdsDiffer() {
        val sets = JSONArray().put(set(5, 60.0))
        val s = session("w5", "Fuerza", JSONArray().put(
            entry("otro-id", "Press banca", sets)))
        val catalog = JSONArray().put(ex("id-catalogo", "press banca"))
        val a = ExerciseSessionAppearances.appearance("id-catalogo", s, catalog)
        assertEquals(listOf("60×5"), a?.setLines)
    }

    @Test fun templateComparisonOnlyReturnsThatWodScores() {
        val results = JSONArray().put(JSONObject()
            .put("id", "b1").put("roundsCompleted", 5).put("totalReps", 30)
            .put("wodTemplateId", "cindy"))
        val benchmark = session("w-c1", "Cindy", JSONArray().put(
            entry("e1", "Dominadas", JSONArray()).put("blockId", "b1")), results)
        val plain = session("w-p1", "Fuerza", JSONArray().put(
            entry("e1", "Dominadas", JSONArray().put(set(5)))))
        val rows = ExerciseSessionAppearances.priorAppearances("e1",
            listOf(benchmark, plain), excludingSessionId = "w-c1")
        // La destacada es benchmark: solo cuentan marcas del mismo WOD.
        assertTrue(rows.isEmpty())
    }
}
