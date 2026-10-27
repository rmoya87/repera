package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import dev.repera.mobile.CompletedWorkoutEditing.ScoreField as SF

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

    @Test fun addedUnconfirmedSetIsNotTurnedIntoLoggedSet() {
        val s = strengthSession()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets")
            .put(planned("extra", 3, 20.0))
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, s, catalog)
        val sets = u.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
        // Apple live main: solo los UUID ya registrados son resultados; la serie nueva queda prescrita.
        assertEquals(1, sets.length())
        assertTrue((0 until sets.length()).none { sets.getJSONObject(it).getString("id") == "extra" })
        val planned = u.getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets")
        assertTrue((0 until planned.length()).any { planned.getJSONObject(it).getString("id") == "extra" })
        assertEquals(5, u.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
    }

    /** Apple testRemovingRecordedSetFromCompletedEditorDoesNotTurnPendingIntoPerformed. */
    @Test fun removingRecordedSetDoesNotTurnPendingIntoPerformed() {
        val s = strengthSession()
        val e1 = s.getJSONArray("exercises").getJSONObject(0)
        e1.put("plannedSets", JSONArray().put(planned("p1", 5)).put(planned("p1b", 5)))
        e1.put("loggedSets", JSONArray().put(logged("p1", 5, 30.0, 2.0)))
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        val sets = blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets")
        assertEquals(2, sets.length())
        val kept = JSONArray().put(sets.getJSONObject(1))
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0).put("plannedSets", kept)
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, s, catalog)
        val ue = u.getJSONArray("exercises").getJSONObject(0)
        assertEquals(0, ue.getJSONArray("loggedSets").length())
        assertEquals(1, ue.getJSONArray("plannedSets").length())
        assertEquals(5, ue.getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
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

    @Test fun changingWodFormatKeepsRealResultWithItsOwnFormat() {
        val s = wodSession(true)
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        blocks.getJSONObject(0).put("wodFormat", "amrap")
        val u = CompletedWorkoutEditing.applying("Circuito", blocks, s, JSONArray().put(ex("bu", "Burpees")))
        // Apple live main: cambiar de formato NO borra un resultado real; conserva su formato/unidades.
        assertEquals(1, u.getJSONArray("wodResults").length())
        assertEquals("forTime", u.getJSONArray("wodResults").getJSONObject(0).getString("format"))
        assertEquals(250, u.getJSONArray("wodResults").getJSONObject(0).getInt("elapsedSeconds"))
    }

    @Test fun deletingTheBlockDeletesItsResult() {
        val s = wodSession(true)
        val u = CompletedWorkoutEditing.applying("Circuito", JSONArray(), s, JSONArray())
        assertEquals(0, u.getJSONArray("wodResults").length())
    }

    @Test fun missingBlockFormatIsRecoveredFromRecordedResult() {
        val s = wodSession(true)
        s.getJSONArray("routineBlocks").getJSONObject(0).remove("wodFormat")
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        assertEquals("forTime", blocks.getJSONObject(0).getString("wodFormat"))
        val u = CompletedWorkoutEditing.applying("Circuito", blocks, s, JSONArray().put(ex("bu", "Burpees")))
        assertEquals(250, u.getJSONArray("wodResults").getJSONObject(0).getInt("elapsedSeconds"))
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
        // Apple live main: los ids derivados son nuevos, por tanto NO se convierten en LoggedSet.
        assertEquals(0, e.getJSONArray("loggedSets").length())
    }

    @Test fun scoreEditUpdatesRftTimeWithLimitsAndKeepsOtherFormatResult() {
        val s = wodSession(true)
        s.getJSONArray("wodResults").put(JSONObject().put("id", "w1").put("format", "amrap").put("totalReps", 99))
        val block = CompletedWorkoutEditing.blocksFrom(s, null).getJSONObject(0)
        assertEquals(4, CompletedWorkoutEditing.scoreValue(block, s, CompletedWorkoutEditing.ScoreField.MINUTES))
        assertEquals(10, CompletedWorkoutEditing.scoreValue(block, s, CompletedWorkoutEditing.ScoreField.SECONDS))
        var u = CompletedWorkoutEditing.changingScore(s, block, CompletedWorkoutEditing.ScoreField.MINUTES, 999)
        assertEquals(180 * 60 + 10, u.getJSONArray("wodResults").let { a -> (0 until a.length()).map { a.getJSONObject(it) }.first { it.optString("format") == "forTime" }.getInt("elapsedSeconds") })
        u = CompletedWorkoutEditing.changingScore(u, block, CompletedWorkoutEditing.ScoreField.SECONDS, 75)
        val rs = u.getJSONArray("wodResults")
        assertEquals(2, rs.length())
        assertEquals(180 * 60 + 59, (0 until 2).map { rs.getJSONObject(it) }.first { it.optString("format") == "forTime" }.getInt("elapsedSeconds"))
        assertEquals(99, (0 until 2).map { rs.getJSONObject(it) }.first { it.optString("format") == "amrap" }.getInt("totalReps"))
        // El original no se muta; reps sobre un formato por tiempo se ignoran.
        assertEquals(250, s.getJSONArray("wodResults").getJSONObject(0).getInt("elapsedSeconds"))
        assertEquals(u.toString(), CompletedWorkoutEditing.changingScore(u, block, CompletedWorkoutEditing.ScoreField.REPS, 5).toString())
    }

    @Test fun legacyAmrapSingleSetScoreIsInferredForDisplayOnly() {
        val s = wodSession(false)
        s.getJSONArray("routineBlocks").getJSONObject(0).put("wodFormat", "amrap")
        s.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
            .put(JSONObject().put("id", "l1").put("reps", 87))
        val block = CompletedWorkoutEditing.blocksFrom(s, null).getJSONObject(0)
        assertEquals(87, CompletedWorkoutEditing.scoreValue(block, s, CompletedWorkoutEditing.ScoreField.REPS))
        assertEquals(0, s.getJSONArray("wodResults").length())
        val u = CompletedWorkoutEditing.changingScore(s, block, CompletedWorkoutEditing.ScoreField.ROUNDS, 12)
        assertEquals(12, u.getJSONArray("wodResults").getJSONObject(0).getInt("roundsCompleted"))
        assertEquals(87, u.getJSONArray("wodResults").getJSONObject(0).getInt("totalReps"))
        assertEquals(1, u.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").length())
    }

    /** Apple testUntypedLegacyRepsSurviveChangingToElapsedTime. */
    @Test fun untypedLegacyRepsSurviveChangingToElapsedTime() {
        val s = wodSession(false)
        s.getJSONArray("routineBlocks").getJSONObject(0).put("wodFormat", "amrap")
        s.put("wodResults", JSONArray().put(JSONObject().put("id", "w1").put("totalReps", 8).put("roundsCompleted", 4)))
        val block = CompletedWorkoutEditing.blocksFrom(s, null).getJSONObject(0).put("wodFormat", "forTime")
        assertNull(CompletedWorkoutEditing.editableScore(block, s))
        val u = CompletedWorkoutEditing.changingScore(s, block, CompletedWorkoutEditing.ScoreField.MINUTES, 6)
        val rs = u.getJSONArray("wodResults")
        assertEquals(2, rs.length())
        val all = (0 until 2).map { rs.getJSONObject(it) }
        assertEquals(8, all.first { !it.has("format") || it.optString("format").isBlank() }.getInt("totalReps"))
        assertEquals(360, all.first { it.optString("format") == "forTime" }.getInt("elapsedSeconds"))
    }

    /** Apple testAllGlobalWODFormatsAllowEditingAndPersistingResultWithNoPriorScore (sin ida y vuelta Codable). */
    @Test fun allGlobalWodFormatsAllowEditingAndPersistingResultWithNoPriorScore() {
        listOf("amrap", "deathBy", "maxEffort", "forTime", "chipper", "afap", "ladder", "buyInCashOut").forEach { fmt ->
            val s = wodSession(false)
            s.getJSONArray("routineBlocks").getJSONObject(0).put("wodFormat", fmt)
            assertEquals(fmt, 0, s.getJSONArray("wodResults").length())
            val block = CompletedWorkoutEditing.blocksFrom(s, null).getJSONObject(0)
            val totalReps = dev.repera.domain.WodFormat.fromWire(fmt)!!.capture == dev.repera.domain.ResultCapture.TOTAL_REPS
            var edited = s
            if (totalReps) {
                edited = CompletedWorkoutEditing.changingScore(edited, block, SF.REPS, 11)
                assertEquals(fmt, 11, CompletedWorkoutEditing.scoreValue(block, edited, SF.REPS))
                if (fmt == "amrap" || fmt == "deathBy") edited = CompletedWorkoutEditing.changingScore(edited, block, SF.ROUNDS, 5)
            } else {
                edited = CompletedWorkoutEditing.changingScore(edited, block, SF.MINUTES, 12)
                edited = CompletedWorkoutEditing.changingScore(edited, block, SF.SECONDS, 37)
                assertEquals(fmt, 12, CompletedWorkoutEditing.scoreValue(block, edited, SF.MINUTES))
                assertEquals(fmt, 37, CompletedWorkoutEditing.scoreValue(block, edited, SF.SECONDS))
            }
            val blocks = CompletedWorkoutEditing.blocksFrom(edited, null)
            val saved = CompletedWorkoutEditing.applying("Registrado", blocks, edited, JSONArray().put(ex("bu", "Burpees")))
            val rs = saved.getJSONArray("wodResults")
            assertEquals(fmt, 1, rs.length())
            val r = rs.getJSONObject(0)
            assertEquals(fmt, fmt, r.optString("format"))
            assertEquals(fmt, if (totalReps) 11 else null, if (r.has("totalReps")) r.getInt("totalReps") else null)
            assertEquals(fmt, if (fmt == "amrap" || fmt == "deathBy") 5 else null, if (r.has("roundsCompleted")) r.getInt("roundsCompleted") else null)
            assertEquals(fmt, if (!totalReps) 757 else null, if (r.has("elapsedSeconds")) r.getInt("elapsedSeconds") else null)
            val exs = saved.getJSONArray("exercises")
            assertTrue((0 until exs.length()).all { exs.getJSONObject(it).getJSONArray("loggedSets").length() == 0 })
            assertEquals(edited.getString("id"), saved.getString("id"))
        }
    }

    /** Apple testMixedScannedBlocksKeepRFTAMRAPScoresAndEMOMDraftSeriesAfterEditing (JSON, sin Codable). */
    @Test fun mixedScannedBlocksKeepRftAmrapScoresAndEmomExplicitSeriesAfterEditing() {
        val burpee = ex("bu", "Burpees")
        fun blk(id: String, fmt: String) = JSONObject().put("id", id).put("title", id).put("kind", "wod").put("wodFormat", fmt)
            .put("movements", JSONArray().put(JSONObject().put("id", "m$id").put("exerciseId", "bu").put("name", "Burpees").put("reps", 8)))
        val rft = blk("rft", "forTime").put("rounds", 3)
        val amrap = blk("amrap", "amrap").put("timeCapMinutes", 10)
        val emom = blk("emom", "emom").put("emomIntervalSeconds", 120).put("rounds", 4)
        fun entry(id: String, b: String, fmt: String, sets: JSONArray) = JSONObject().put("id", id).put("exercise", burpee)
            .put("plannedSets", sets).put("loggedSets", JSONArray()).put("completedReps", 0).put("isCompleted", false)
            .put("blockId", b).put("blockKind", "wod").put("wodFormat", fmt).put("blockHeader", b)
        val emomSets = JSONArray().put(planned("e1", 6)).put(planned("e2", 6)).put(planned("e3", 6)).put(planned("e4", 6))
            .put(planned("e5", 9, 12.0))
        val s = JSONObject().put("id", "mix").put("title", "Pizarra").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z").put("currentIndex", 0)
            .put("routineBlocks", JSONArray().put(rft).put(amrap).put(emom))
            .put("wodResults", JSONArray()
                .put(JSONObject().put("id", "rft").put("format", "forTime").put("elapsedSeconds", 533))
                .put(JSONObject().put("id", "amrap").put("format", "amrap").put("totalReps", 4).put("roundsCompleted", 6)))
            .put("exercises", JSONArray().put(entry("x1", "rft", "forTime", JSONArray().put(planned("r1", 8))))
                .put(entry("x2", "amrap", "amrap", JSONArray().put(planned("a1", 8))))
                .put(entry("x3", "emom", "emom", emomSets)))
        val rftBlock = CompletedWorkoutEditing.blocksFrom(s, null).getJSONObject(0)
        val corrected = CompletedWorkoutEditing.changingScore(s, rftBlock, SF.SECONDS, 21)
        val stored = CompletedWorkoutEditing.applying("Pizarra", CompletedWorkoutEditing.blocksFrom(corrected, null), corrected, JSONArray().put(burpee))
        val rs = stored.getJSONArray("wodResults")
        fun res(id: String) = (0 until rs.length()).map { rs.getJSONObject(it) }.first { it.getString("id") == id }
        assertEquals(501, res("rft").getInt("elapsedSeconds"))
        assertEquals(6, res("amrap").getInt("roundsCompleted"))
        assertEquals(4, res("amrap").getInt("totalReps"))
        val ex2 = stored.getJSONArray("exercises").getJSONObject(2)
        assertEquals(5, ex2.getJSONArray("plannedSets").length())
        assertEquals(0, ex2.getJSONArray("loggedSets").length())
        val blocks = stored.getJSONArray("routineBlocks")
        assertEquals(3, blocks.getJSONObject(0).getInt("rounds"))
        assertEquals(10, blocks.getJSONObject(1).getInt("timeCapMinutes"))
        assertEquals(5, blocks.getJSONObject(2).getJSONArray("movements").getJSONObject(0).optJSONArray("explicitPlannedSets")?.length() ?: -1)
    }

    @Test fun perSetQuantityUnitEditWinsOverExerciseAndPrevious() {
        // Apple f7109bd7 (editableSetRow): la unidad editada por serie manda;
        // sin edicion explicita se conserva la registrada (nunca conversion).
        val lunge = ex("wl", "Walking lunge")
        val cat = JSONArray().put(lunge)
        val block = JSONObject().put("id", "b1").put("title", "Bloque A").put("kind", "strength")
            .put("exercises", JSONArray().put(JSONObject().put("id", "re1")
                .put("exerciseId", "wl")
                .put("plannedSets", JSONArray().put(planned("p1", 12, 16.0)))))
        val ls = logged("l1", 12, 16.0, 2.0).put("quantityUnit", "reps")
        val session = JSONObject().put("id", "s1").put("title", "Fuerza").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z")
            .put("currentIndex", 0).put("routePoints", JSONArray())
            .put("routineBlocks", JSONArray().put(block)).put("wodResults", JSONArray())
            .put("exercises", JSONArray().put(entry("e1", lunge, "b1", planned("p1", 12, 16.0), ls)))

        // Sin edicion: se conserva "reps".
        val untouched = CompletedWorkoutEditing.applying("Fuerza",
            CompletedWorkoutEditing.blocksFrom(session, null), session, cat)
        assertEquals("reps", untouched.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0).getString("quantityUnit"))

        // Edicion explicita de la serie: pasa a "meters".
        val blocks = CompletedWorkoutEditing.blocksFrom(session, null)
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").getJSONObject(0).put("targetQuantityUnit", "meters")
        val edited = CompletedWorkoutEditing.applying("Fuerza", blocks, session, cat)
        val editedSet = edited.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("meters", editedSet.getString("quantityUnit"))
        // Identidad preservada: mismo LoggedSet, mismos kg/reps.
        assertEquals("l1", editedSet.getString("id"))
        assertEquals(16.0, editedSet.getDouble("weightKg"), 0.0)
        assertEquals(12, editedSet.getInt("reps"))
    }

    @Test fun prescribedMetersLoggedRepsNotRelabeledByUnrelatedEdit() {
        // Caso mixto (revision): ejercicio prescrito en metros, serie REGISTRADA
        // en reps; editar SOLO el kg no debe reetiquetar la unidad.
        val lunge = ex("wl", "Walking lunge")
        val cat = JSONArray().put(lunge)
        val block = JSONObject().put("id", "b1").put("title", "Bloque A").put("kind", "strength")
            .put("exercises", JSONArray().put(JSONObject().put("id", "re1")
                .put("exerciseId", "wl").put("quantityUnit", "meters")
                .put("plannedSets", JSONArray().put(planned("p1", 20, 16.0)))))
        val ls = logged("l1", 12, 16.0, 2.0).put("quantityUnit", "reps")
        val session = JSONObject().put("id", "s1").put("title", "Fuerza").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z")
            .put("currentIndex", 0).put("routePoints", JSONArray())
            .put("routineBlocks", JSONArray().put(block)).put("wodResults", JSONArray())
            .put("exercises", JSONArray().put(entry("e1", lunge, "b1", planned("p1", 20, 16.0), ls)))

        val blocks = CompletedWorkoutEditing.blocksFrom(session, null)
        // Edicion SOLO de kg (sin tocar unidad).
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").getJSONObject(0).put("targetWeightKg", 24.0)
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, session, cat)
        val set = u.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("reps", set.getString("quantityUnit"))
        assertEquals(24.0, set.getDouble("weightKg"), 0.0)
    }

    @Test fun mixedRepsAndMetersSetsKeepTheirOwnUnit() {
        // Varias series del mismo ejercicio con unidades distintas: cada una
        // conserva la suya al guardar una edicion ajena.
        val lunge = ex("wl", "Walking lunge")
        val cat = JSONArray().put(lunge)
        val block = JSONObject().put("id", "b1").put("title", "Bloque A").put("kind", "strength")
            .put("exercises", JSONArray().put(JSONObject().put("id", "re1")
                .put("exerciseId", "wl")
                .put("plannedSets", JSONArray().put(planned("p1", 12)).put(planned("p2", 20)))))
        val l1 = logged("l1", 12, 16.0, 2.0).put("quantityUnit", "reps")
        val l2 = logged("l2", 20, 16.0, 1.0).put("quantityUnit", "meters")
        val ent = entry("e1", lunge, "b1", planned("p1", 12), l1)
        ent.getJSONArray("plannedSets").put(planned("p2", 20))
        ent.getJSONArray("loggedSets").put(l2)
        val session = JSONObject().put("id", "s1").put("title", "Fuerza").put("phase", "finished")
            .put("startedAt", "2026-10-20T10:00:00Z").put("finishedAt", "2026-10-20T11:00:00Z")
            .put("currentIndex", 0).put("routePoints", JSONArray())
            .put("routineBlocks", JSONArray().put(block)).put("wodResults", JSONArray())
            .put("exercises", JSONArray().put(ent))

        val blocks = CompletedWorkoutEditing.blocksFrom(session, null)
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").getJSONObject(0).put("targetRir", 3.0)
        val u = CompletedWorkoutEditing.applying("Fuerza", blocks, session, cat)
        val sets = u.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets")
        assertEquals(2, sets.length())
        assertEquals("reps", sets.getJSONObject(0).getString("quantityUnit"))
        assertEquals("meters", sets.getJSONObject(1).getString("quantityUnit"))
    }

    @Test fun draftMutationNeverTouchesStoredSession() {
        // Cancelar = descartar borrador: mutar el draft no altera la sesion.
        val s = strengthSession()
        val before = s.toString()
        val blocks = CompletedWorkoutEditing.blocksFrom(s, null)
        blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").getJSONObject(0)
            .put("targetWeightKg", 999.0).put("targetQuantityUnit", "meters")
        assertEquals(before, s.toString())
    }
}
