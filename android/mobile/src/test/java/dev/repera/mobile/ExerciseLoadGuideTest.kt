package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExerciseLoadGuideTest {

    private fun set(reps: Int, weight: Double? = null, rir: Double? = null): JSONObject {
        val s = JSONObject().put("id", "s" + reps + (weight ?: 0)).put("reps", reps)
        if (weight != null) s.put("weightKg", weight)
        if (rir != null) s.put("rir", rir)
        return s
    }

    private fun workout(id: String, exerciseId: String, name: String,
                        sets: JSONArray, finishedAt: String): JSONObject =
        JSONObject().put("id", id).put("title", "W").put("phase", "finished")
            .put("finishedAt", finishedAt)
            .put("exercises", JSONArray().put(JSONObject()
                .put("exercise", JSONObject().put("id", exerciseId).put("name", name))
                .put("loggedSets", sets)))

    private fun root(workouts: JSONArray, settings: JSONObject? = null,
                     prefs: JSONObject? = null): JSONObject {
        val r = JSONObject().put("workouts", workouts)
        if (settings != null) r.put("settings", settings)
        if (prefs != null) r.put("exerciseLoadPrefs", prefs)
        return r
    }

    @Test fun lastWorkingSessionPicksMostRecentWithWorkSets() {
        val older = workout("w1", "e1", "Press banca",
            JSONArray().put(set(8, 50.0)), "2026-10-10T10:00:00Z")
        val newer = workout("w2", "e1", "Press banca",
            JSONArray().put(set(6, 55.0)).put(set(4, 60.0)), "2026-10-20T10:00:00Z")
        val last = ExerciseLoadGuide.lastWorkingSession("e1", listOf(older, newer))!!
        assertEquals("w2", last.sessionId)
        assertEquals(2, last.sets.size)
        assertEquals(60.0, last.topSet!!.weightKg!!, 0.001)
    }

    @Test fun suggestionFromTestedOneRM() {
        val w = workout("w1", "e1", "Press banca",
            JSONArray().put(set(5, 100.0)), "2026-10-20T10:00:00Z")
        val prefs = JSONObject().put("e1",
            JSONObject().put("testedOneRMKg", 120.0))
        val g = ExerciseLoadGuide.guide(root(JSONArray().put(w), prefs = prefs),
            "e1", targetReps = 8, targetRir = 2.0)
        // 120 / (1 + 10/30) = 90 → redondeo a 2.5 = 90.0
        assertEquals(90.0, g.suggestedKg!!, 0.001)
        assertEquals("1RM", g.suggestionSource)
    }

    @Test fun suggestionFromEstimatedOneRMWhenNoTested() {
        // 100×5 → e1RM = 100*(1+5/30) = 116.67 → 8@RIR2: 116.67/1.333=87.5
        val w = workout("w1", "e1", "Press banca",
            JSONArray().put(set(5, 100.0)), "2026-10-20T10:00:00Z")
        val g = ExerciseLoadGuide.guide(root(JSONArray().put(w)),
            "e1", targetReps = 8, targetRir = 2.0)
        assertEquals(87.5, g.suggestedKg!!, 0.001)
        assertEquals("e1RM", g.suggestionSource)
    }

    @Test fun suggestionFallsBackToLastSet() {
        // Sin peso histórico válido para e1RM (reps sin peso no cuentan) pero
        // la última serie tiene peso: usa weightKgFromLastSet.
        // 80×10 @RIR2 → 1RM = 80*(1+12/30)=112 → 6@RIR2: 112/(1+8/30)=88.42→87.5
        // (e1RM existe aquí, así que fuerza el caso: unit calories no da e1RM
        //  pero tampoco weightKgFromLastSet válido → cubrimos topSet de reps)
        val w = workout("w1", "e1", "Remo",
            JSONArray().put(set(10, 80.0, 2.0)), "2026-10-20T10:00:00Z")
        val g = ExerciseLoadGuide.guide(root(JSONArray().put(w)),
            "e1", targetReps = 10, targetRir = 2.0)
        assertTrue(g.suggestedKg!! > 0)
        // Con historial con peso la fuente es e1RM (nunca "última").
        assertEquals("e1RM", g.suggestionSource)
    }

    @Test fun weightIncrementFromSettingsRespected() {
        val w = workout("w1", "e1", "Press banca",
            JSONArray().put(set(5, 100.0)), "2026-10-20T10:00:00Z")
        val settings = JSONObject().put("weightIncrementKg", 1.0)
        val g = ExerciseLoadGuide.guide(root(JSONArray().put(w), settings = settings),
            "e1", targetReps = 8, targetRir = 2.0)
        // e1RM 116.67 → 87.5 con step 2.5; con step 1.0 → 87.5 también:
        // 116.67/1.3333 = 87.5 exacto. Usamos reps 7 → 116.67/(1+9/30)=89.74→90 con 2.5; 90 con 1.0? 89.74→90.0
        val g7 = ExerciseLoadGuide.guide(root(JSONArray().put(w), settings = settings),
            "e1", targetReps = 7, targetRir = 2.0)
        assertEquals(90.0, g7.suggestedKg!!, 0.001)
        val g7def = ExerciseLoadGuide.guide(root(JSONArray().put(w)),
            "e1", targetReps = 7, targetRir = 2.0)
        assertEquals(90.0, g7def.suggestedKg!!, 0.001)
        // Caso que distingue: reps 9 → 116.67/(1+11/30)=85.36 → 85 con 2.5, 85 con 1? 85.36→85.0
        // reps 12 → 116.67/(1+14/30)=79.54 → 80 con 2.5; con 1.0 → 80? 79.54→80.0
        // reps 4 → 116.67/(1+6/30)=97.22 → 97.5 con 2.5; con 1.0 → 97.0
        val g4custom = ExerciseLoadGuide.guide(root(JSONArray().put(w), settings = settings),
            "e1", targetReps = 4, targetRir = 2.0)
        assertEquals(97.0, g4custom.suggestedKg!!, 0.001)
        val g4def = ExerciseLoadGuide.guide(root(JSONArray().put(w)),
            "e1", targetReps = 4, targetRir = 2.0)
        assertEquals(97.5, g4def.suggestedKg!!, 0.001)
    }

    @Test fun assumedRirWhenTargetMissing() {
        val w = workout("w1", "e1", "Press banca",
            JSONArray().put(set(5, 100.0)), "2026-10-20T10:00:00Z")
        val g = ExerciseLoadGuide.guide(root(JSONArray().put(w)),
            "e1", targetReps = 8, targetRir = null)
        assertTrue(g.assumedRir)
        assertEquals(2.0, g.effectiveRir, 0.001)
    }

    @Test fun emptyHistoryGivesNoSuggestion() {
        val g = ExerciseLoadGuide.guide(root(JSONArray()),
            "e1", targetReps = 8, targetRir = 2.0)
        assertNull(g.lastSession)
        assertNull(g.suggestedKg)
        assertNull(g.suggestionSource)
    }
}

class LoadGuideApplyActionsTest {

    private fun ls(reps: Int, weight: Double? = null, rir: Double? = null) =
        LoadGuideSet(weightKg = weight, reps = reps, rir = rir,
            durationSeconds = null, unit = "reps")

    @Test fun applyScalesLastSessionToSuggestedKg() {
        // iOS: ratio = kg / anchor (top set); cada serie se escala y redondea
        // al paso; reps y RIR se conservan de la última sesión.
        val last = listOf(ls(8, 50.0, 1.0), ls(6, 60.0, null))
        val out = ExerciseLoadGuide.scaledPlannedSets(90.0, last, 2.5, 2.0)!!
        assertEquals(2, out.size)
        assertEquals(8, out[0].targetReps)
        assertEquals(75.0, out[0].targetWeightKg!!, 0.001) // 50*1.5=75
        assertEquals(1.0, out[0].targetRir!!, 0.001)
        assertEquals(6, out[1].targetReps)
        assertEquals(90.0, out[1].targetWeightKg!!, 0.001) // 60*1.5=90
        assertEquals(2.0, out[1].targetRir!!, 0.001) // fallbackRir
    }

    @Test fun applyWithoutAnchorWeightsUsesSuggestedKgEverywhere() {
        val last = listOf(ls(10, null, 3.0), ls(10, null, null))
        val out = ExerciseLoadGuide.scaledPlannedSets(40.0, last, 2.5, 2.0)!!
        assertEquals(40.0, out[0].targetWeightKg!!, 0.001)
        assertEquals(3.0, out[0].targetRir!!, 0.001)
        assertEquals(2.0, out[1].targetRir!!, 0.001)
    }

    @Test fun applyWithEmptyHistoryReturnsNull() {
        assertNull(ExerciseLoadGuide.scaledPlannedSets(90.0, emptyList(), 2.5, 2.0))
    }

    @Test fun copyLastSessionPreservesRepsWeightAndRir() {
        val last = listOf(ls(5, 100.0, 1.5), ls(5, 100.0, null))
        val out = ExerciseLoadGuide.copyLastSession(last)
        assertEquals(5, out[0].targetReps)
        assertEquals(100.0, out[0].targetWeightKg!!, 0.001)
        assertEquals(1.5, out[0].targetRir!!, 0.001)
        assertNull(out[1].targetRir) // ausente se conserva ausente (asumido)
    }

    @Test fun guideCarriesIncrementFromSettings() {
        val w = JSONObject().put("id", "w1").put("title", "W")
            .put("phase", "finished").put("finishedAt", "2026-10-20T10:00:00Z")
            .put("exercises", JSONArray().put(JSONObject()
                .put("exercise", JSONObject().put("id", "e1").put("name", "Press"))
                .put("loggedSets", JSONArray().put(JSONObject()
                    .put("id", "s1").put("reps", 5).put("weightKg", 100.0)))))
        val root = JSONObject().put("workouts", JSONArray().put(w))
            .put("settings", JSONObject().put("weightIncrementKg", 1.25))
        val g = ExerciseLoadGuide.guide(root, "e1", 8, null)
        assertEquals(1.25, g.incrementKg, 0.001)
    }
}
