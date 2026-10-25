package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** Casos de CompletedWorkoutEditingTests.swift sobre fixtures JSON (sin dispositivo). */
class CompletedWorkoutEditingTest {
    private fun ex(id: String, name: String) = JSONObject().put("id", id).put("name", name)
        .put("muscleGroup", "X").put("isCustom", true)

    private fun planned(id: String, reps: Int, kg: Double? = null) =
        JSONObject().put("id", id).put("targetReps", reps).apply { kg?.let { put("targetWeightKg", it) } }

    private fun logged(id: String, reps: Int, kg: Double, rir: Double) = JSONObject()
        .put("id", id).put("reps", reps).put("weightKg", kg).put("rir", rir)
        .put("completedAt", "2026-10-20T10:30:00Z").put("phase", "work").put("kind", "straight")
        .put("toFailure", false).put("drops", JSONArray()).put("clusters", JSONArray())

    private fun entry(id: String, e: JSONObject, blockId: String, p: JSONObject, l: JSONObject?) = JSONObject()
        .put("id", id).put("exercise", e).put("plannedSets", JSONArray().put(p))
        .put("loggedSets", JSONArray().apply { l?.let { put(it) } })
        .put("completedReps", l?.optInt("reps") ?: 0).put("isCompleted", l != null)
        .put("blockId", blockId).put("blockKind", "strength").put("blockHeader", "Bloque A")

    private val squat = ex("sq", "Sentadilla")
    private val press = ex("pr", "Press banca")
    private val catalog = JSONArray().put(squat).put(press)

    private fun strengthSession(): JSONObject {
        val block = JSONObject().put("id", "b1").put("title", "Bloque A").put("kind", "strength")
            .put("exercises", JSONArray()
                .put(JSONObject().put("id", "re1").put("exerciseId", "sq").put("plannedSets", JSONArray().put(planned("p1", 8, 40.0))))
                .put(JSONObject().put("id", "re2").put("exerciseId", "pr").put("plannedSets", JSONArray().put(planned("p2", 8, 30.0)))))
        return JSONObject().put("id", "s1").put("title", "Fuerza").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z")
            .put("currentIndex", 1).put("routeId", "r").put("routePoints", JSONArray())
            .put("routineBlocks", JSONArray().put(block))
            .put("wodResults", JSONArray())
            .put("exercises", JSONArray()
                .put(entry("e1", squat, "b1", planned("p1", 8, 40.0), logged("l1", 5, 60.0, 2.0)))
                .put(entry("e2", press, "b1", planned("p2", 8, 30.0), logged("l2", 6, 35.0, 1.0))))
    }

    @Test fun reorderAndEditKeepHistoryIdentity() {
        val s = strengthSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        val exs = blocks.getJSONObject(0).getJSONArray("exercises")
        // Las series visibles son las REGISTRADAS (60 kg x 5), no las planificadas.
        assertEquals(60.0, exs.getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getDouble("targetWeightKg"), 0.0)
        assertEquals(5, exs.getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
        val first = exs.getJSONObject(0); val second = exs.getJSONObject(1)
        second.getJSONArray("plannedSets").getJSONObject(0).put("targetWeightKg", 70.0).put("targetReps", 4)
        blocks.getJSONObject(0).put("exercises", JSONArray().put(second).put(first))
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, s, catalog)
        val ue = u.getJSONArray("exercises")
        assertEquals("e2", ue.getJSONObject(0).getString("id"))
        assertEquals("e1", ue.getJSONObject(1).getString("id"))
        val l = ue.getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("l2", l.getString("id"))
        assertEquals(70.0, l.getDouble("weightKg"), 0.0)
        assertEquals(4, l.getInt("reps"))
        assertEquals(5, ue.getJSONObject(1).getJSONArray("loggedSets").getJSONObject(0).getInt("reps"))
        assertEquals(4, ue.getJSONObject(0).getInt("completedReps"))
        assertEquals("2026-10-20T11:00:00Z", u.getString("finishedAt"))
        assertEquals("finished", u.getString("phase"))
        assertTrue(u.has("routineBlocks"))
        // El original no se muta (Cancelar = sin escritura).
        assertEquals("e1", s.getJSONArray("exercises").getJSONObject(0).getString("id"))
        assertEquals(5, s.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0).getInt("reps"))
    }

    @Test fun newUnloggedExerciseDoesNotInventCompletedSets() {
        val s = strengthSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        blocks.getJSONObject(0).getJSONArray("exercises").put(JSONObject()
            .put("id", "new1").put("exerciseId", "pr").put("plannedSets", JSONArray().put(planned("pn", 8))))
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, s, catalog)
        val last = u.getJSONArray("exercises").getJSONObject(2)
        assertEquals(3, u.getJSONArray("exercises").length())
        assertEquals(0, last.getJSONArray("loggedSets").length())
        assertFalse(last.getBoolean("isCompleted"))
    }

    @Test fun removingExerciseDropsItsLoggedSetsOnly() {
        val s = strengthSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        val exs = blocks.getJSONObject(0).getJSONArray("exercises")
        blocks.getJSONObject(0).put("exercises", JSONArray().put(exs.getJSONObject(1)))
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, s, catalog)
        assertEquals(1, u.getJSONArray("exercises").length())
        assertEquals("e2", u.getJSONArray("exercises").getJSONObject(0).getString("id"))
        assertEquals(0, u.getInt("currentIndex"))
    }

    @Test fun addedSetOnLoggedExerciseGetsFinishedAtAsCompletedAt() {
        val s = strengthSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets")
            .put(planned("extra", 3, 20.0))
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, s, catalog)
        val sets = u.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
        assertEquals(2, sets.length())
        assertEquals("extra", sets.getJSONObject(1).getString("id"))
        assertEquals("2026-10-20T11:00:00Z", sets.getJSONObject(1).getString("completedAt"))
        assertEquals(5 + 3, u.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
    }

    private fun wodSession(withScore: Boolean): JSONObject {
        val burpee = ex("bu", "Burpees")
        val block = JSONObject().put("id", "w1").put("title", "RFT").put("kind", "wod")
            .put("wodFormat", "forTime").put("rounds", 3)
            .put("movements", JSONArray()
                .put(JSONObject().put("id", "m1").put("exerciseId", "bu").put("name", "Burpees").put("reps", 10))
                .put(JSONObject().put("id", "m2").put("name", "REST").put("isRest", true).put("restSeconds", 45)))
        return JSONObject().put("id", "s2").put("title", "Circuito").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z")
            .put("currentIndex", 0).put("routineBlocks", JSONArray().put(block))
            .put("wodResults", JSONArray().apply {
                if (withScore) put(JSONObject().put("id", "w1").put("format", "forTime").put("elapsedSeconds", 250))
            })
            .put("exercises", JSONArray().put(JSONObject().put("id", "e9").put("exercise", burpee)
                .put("plannedSets", JSONArray().put(planned("pw", 10))).put("loggedSets", JSONArray())
                .put("completedReps", 0).put("isCompleted", false).put("blockId", "w1").put("blockKind", "wod")
                .put("wodFormat", "forTime").put("blockHeader", "RFT").put("blockRounds", 3)))
    }

    @Test fun wodRestAndGlobalScoreSurviveEditing() {
        val s = wodSession(true)
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        assertEquals(2, blocks.getJSONObject(0).getJSONArray("movements").length())
        assertTrue(blocks.getJSONObject(0).getJSONArray("movements").getJSONObject(1).getBoolean("isRest"))
        blocks.getJSONObject(0).getJSONArray("movements").getJSONObject(1).put("restSeconds", 60)
        val u = CompletedWorkoutEditing.applying("Circuito", blocks, s, JSONArray().put(ex("bu", "Burpees")))
        assertEquals(60, u.getJSONArray("routineBlocks").getJSONObject(0).getJSONArray("movements").getJSONObject(1).getInt("restSeconds"))
        assertEquals(250, u.getJSONArray("wodResults").getJSONObject(0).getInt("elapsedSeconds"))
        assertEquals(0, u.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").length())
    }

    @Test fun changingWodFormatDropsIncompatibleStoredScore() {
        val s = wodSession(true)
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        blocks.getJSONObject(0).put("wodFormat", "amrap")
        val u = CompletedWorkoutEditing.applying("Circuito", blocks, s, JSONArray().put(ex("bu", "Burpees")))
        assertEquals(0, u.getJSONArray("wodResults").length())
    }

    @Test fun exerciseWithoutBlockInSnapshotGetsOwnBlock() {
        val s = strengthSession()
        s.remove("routineBlocks")
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        assertEquals(1, blocks.length())
        assertEquals(2, blocks.getJSONObject(0).getJSONArray("exercises").length())
    }

    private fun emomSession(): JSONObject {
        val block = JSONObject().put("id", "w2").put("title", "EMOM").put("kind", "wod")
            .put("wodFormat", "emom").put("rounds", 3).put("emomIntervalSeconds", 60)
            .put("movements", JSONArray().put(JSONObject().put("id", "m1").put("exerciseId", "bu")
                .put("name", "Burpees").put("reps", 10)))
        return JSONObject().put("id", "s3").put("title", "EMOM").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z")
            .put("currentIndex", 0).put("routineBlocks", JSONArray().put(block)).put("wodResults", JSONArray())
            .put("exercises", JSONArray().put(JSONObject().put("id", "m1").put("exercise", ex("bu", "Burpees"))
                .put("plannedSets", JSONArray().put(planned("a", 10)).put(planned("b", 10)).put(planned("c", 10)))
                .put("loggedSets", JSONArray().put(logged("a", 10, 0.0, 2.0)).put(logged("b", 9, 0.0, 2.0)).put(logged("c", 8, 0.0, 2.0)))
                .put("completedReps", 27).put("isCompleted", true).put("blockId", "w2").put("blockKind", "wod")
                .put("wodFormat", "emom").put("blockHeader", "EMOM").put("blockRounds", 3)))
    }

    @Test fun wodPerMovementRebuildKeepsLoggedSetIdsViaExplicitSets() {
        val s = emomSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        val mv = blocks.getJSONObject(0).getJSONArray("movements").getJSONObject(0)
        assertEquals(3, mv.getJSONArray("explicitPlannedSets").length())
        assertEquals("b", mv.getJSONArray("explicitPlannedSets").getJSONObject(1).getString("id"))
        mv.getJSONArray("explicitPlannedSets").getJSONObject(1).put("targetReps", 7)
        val u = CompletedWorkoutEditing.applying("EMOM", blocks, s, JSONArray().put(ex("bu", "Burpees")))
        val ls = u.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
        assertEquals(listOf("a", "b", "c"), (0 until 3).map { ls.getJSONObject(it).getString("id") })
        assertEquals(7, ls.getJSONObject(1).getInt("reps"))
        assertEquals(10 + 7 + 8, u.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
    }

    @Test fun clearingExplicitSetsDerivesFromBlockRulesWithoutInventingLoggedReps() {
        val s = emomSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        val b = blocks.getJSONObject(0)
        b.put("rounds", 5)
        b.getJSONArray("movements").getJSONObject(0).remove("explicitPlannedSets")
        val u = CompletedWorkoutEditing.applying("EMOM", blocks, s, JSONArray().put(ex("bu", "Burpees")))
        val e = u.getJSONArray("exercises").getJSONObject(0)
        // Apple: routine(from:) deja repScheme [10,9,8] (ola registrada); con EMOM de 5 rondas se
        // rellena repitiendo la última => [10,9,8,8,8]. Los ids derivados son nuevos.
        assertEquals(listOf(10, 9, 8, 8, 8), (0 until 5).map { e.getJSONArray("plannedSets").getJSONObject(it).getInt("targetReps") })
        assertEquals(5, e.getInt("blockRounds"))
        // Las series registradas se reconstruyen con las prescritas (Apple), con completedAt = finishedAt.
        assertEquals(5, e.getJSONArray("loggedSets").length())
        assertEquals("2026-10-20T11:00:00Z", e.getJSONArray("loggedSets").getJSONObject(4).getString("completedAt"))
    }
}
