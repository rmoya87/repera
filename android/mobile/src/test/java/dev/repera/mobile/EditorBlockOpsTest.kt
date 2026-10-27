package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** Reglas de conversión/orden de PlanView.applyReorder sobre fixtures JSON (JVM, sin dispositivo). */
class EditorBlockOpsTest {
    private fun set(id: String, reps: Int, kg: Double? = null, rir: Double? = null) =
        JSONObject().put("id", id).put("targetReps", reps)
            .apply { kg?.let { put("targetWeightKg", it) }; rir?.let { put("targetRir", it) } }

    private fun strength() = JSONObject().put("id", "b1").put("kind", "strength").put("exercises", JSONArray()
        .put(JSONObject().put("id", "i1").put("exerciseId", "sq")
            .put("plannedSets", JSONArray().put(set("s1", 5, 100.0, 2.0)).put(set("s2", 5, 100.0))))
        .put(JSONObject().put("id", "i2").put("exerciseId", "pr").put("plannedSets", JSONArray().put(set("s3", 8)))))
    private fun wod() = JSONObject().put("id", "b2").put("kind", "wod").put("wodFormat", "amrap").put("movements", JSONArray()
        .put(JSONObject().put("id", "m1").put("exerciseId", "sq").put("name", "Thruster").put("reps", 10)
            .put("weightMaleKg", 43.0).put("weightFemaleKg", 30.0).put("scaleAlternative", "30 kg").put("notes", "rápido")
            .put("repScheme", JSONArray(listOf(10, 8))))
        .put(JSONObject().put("id", "m2").put("name", "REST").put("isRest", true).put("restSeconds", 90)))
    private fun blocks() = JSONArray().put(strength()).put(wod())

    @Test fun strengthToWod_keepsSetsIdsUnitAndWeight() {
        val b = blocks()
        assertTrue(EditorBlockOps.moveItem(b, 0, "i1", 1, "m2", { "Sentadilla" }, { null }))
        val mv = b.getJSONObject(1).getJSONArray("movements")
        assertEquals(listOf("m1", "i1", "m2"), (0 until 3).map { mv.getJSONObject(it).getString("id") })
        val m = mv.getJSONObject(1)
        assertEquals("Sentadilla", m.getString("name")); assertEquals(5, m.getInt("reps"))
        assertEquals(100.0, m.getDouble("weightMaleKg"), 0.0)
        assertEquals(listOf("s1", "s2"), (0 until 2).map { m.getJSONArray("explicitPlannedSets").getJSONObject(it).getString("id") })
        assertEquals(1, b.getJSONObject(0).getJSONArray("exercises").length())
    }

    @Test fun wodToStrength_appleLosesScaleNotesFemaleAndScheme_andRestIsRefused() {
        val b = blocks()
        assertFalse("REST no se convierte", EditorBlockOps.moveItem(b, 1, "m2", 0, null, { "" }, { "sq" }))
        assertEquals(2, b.getJSONObject(1).getJSONArray("movements").length())
        assertTrue(EditorBlockOps.moveItem(b, 1, "m1", 0, null, { "" }, { "sq" }))
        val ex = b.getJSONObject(0).getJSONArray("exercises").getJSONObject(2)
        assertEquals("m1", ex.getString("id")); assertEquals("sq", ex.getString("exerciseId"))
        EditorBlockOps.lostFieldsOnToStrength.forEach { assertFalse(it, ex.has(it)) }
        assertEquals(43.0, ex.getJSONArray("plannedSets").getJSONObject(0).getDouble("targetWeightKg"), 0.0)
    }

    @Test fun unresolvedCatalogIdAbortsWithoutRemoving() {
        val b = blocks()
        assertFalse(EditorBlockOps.moveItem(b, 1, "m1", 0, null, { "" }, { null }))
        assertEquals(2, b.getJSONObject(1).getJSONArray("movements").length())
    }

    @Test fun dropOnOwnSlotIsNoop_andReorderWithinBlock() {
        val b = blocks()
        assertFalse(EditorBlockOps.moveItem(b, 0, "i1", 0, "i1", { "" }, { null }))
        assertTrue(EditorBlockOps.moveItem(b, 0, "i2", 0, "i1", { "" }, { null }))
        val ex = b.getJSONObject(0).getJSONArray("exercises")
        assertEquals("i2", ex.getJSONObject(0).getString("id")); assertEquals("i1", ex.getJSONObject(1).getString("id"))
    }

    @Test fun moveBlockKeepsIds() {
        val b = blocks()
        assertTrue(EditorBlockOps.moveBlock(b, 0, 1))
        assertEquals("b2", b.getJSONObject(0).getString("id")); assertEquals("b1", b.getJSONObject(1).getString("id"))
        assertFalse(EditorBlockOps.moveBlock(b, 0, 5))
    }

    @Test fun writeSets_multiSetsBecomeSchemeAndSingleBecomesReps() {
        val m = JSONObject().put("id", "m").put("name", "x").put("reps", 3)
        EditorBlockOps.writeSetsToMovement(m, JSONArray().put(set("a", 10, 40.0)).put(set("b", 8)), false)
        assertEquals(listOf(10, 8), (0 until 2).map { m.getJSONArray("repScheme").getInt(it) })
        assertFalse(m.has("reps")); assertEquals(40.0, m.getDouble("weightMaleKg"), 0.0)
        EditorBlockOps.writeSetsToMovement(m, JSONArray().put(set("a", 12)), false)
        assertFalse(m.has("repScheme")); assertEquals(12, m.getInt("reps"))
    }

    @Test fun writeSets_machineWorkFeedsCaloriesAndDropsReps() {
        val m = JSONObject().put("id", "m").put("name", "Row").put("calories", 20).put("reps", 20)
        EditorBlockOps.writeSetsToMovement(m, JSONArray().put(set("a", 30)), true)
        assertEquals(30, m.getInt("calories")); assertFalse(m.has("reps"))
    }

    @Test fun roundTrip_wodFieldsSurviveSaveApplying() {
        val original = JSONObject().put("id", "w").put("title", "t").put("exercises", JSONArray())
        val updated = CompletedWorkoutEditing.applying("t", blocks(), original, JSONArray())
        val kept = updated.getJSONArray("routineBlocks").getJSONObject(1).getJSONArray("movements")
        val m = kept.getJSONObject(0)
        assertEquals(30.0, m.getDouble("weightFemaleKg"), 0.0); assertEquals("30 kg", m.getString("scaleAlternative"))
        assertEquals("rápido", m.getString("notes")); assertEquals(2, m.getJSONArray("repScheme").length())
        assertTrue(kept.getJSONObject(1).getBoolean("isRest")); assertEquals(90, kept.getJSONObject(1).getInt("restSeconds"))
    }

    @Test fun unknownCatalogMovementBecomesPendingDraftOnly_thenResolves() {
        val b = blocks()
        assertTrue(EditorBlockOps.moveItem(b, 1, "m1", 0, null, { "" }, { "pending:Thruster" }))
        assertEquals(listOf("Thruster"), EditorBlockOps.pendingCustomNames(b))
        val resolved = EditorBlockOps.resolvePending(b, mapOf("Thruster" to "new-id"))
        assertEquals("new-id", resolved.getJSONObject(0).getJSONArray("exercises").getJSONObject(2).getString("exerciseId"))
        // el borrador original sigue con el marcador (nada se persiste hasta Guardar)
        assertEquals(listOf("Thruster"), EditorBlockOps.pendingCustomNames(b))
        assertTrue(EditorBlockOps.pendingCustomNames(resolved).isEmpty())
    }

    @Test fun reorderKeepsIdsAndIsSinglePass() {
        val arr = JSONArray().put(JSONObject().put("id", "a")).put(JSONObject().put("id", "b")).put(JSONObject().put("id", "c"))
        assertTrue(EditorBlockOps.reorder(arr, 0, 2))
        assertEquals(listOf("b", "c", "a"), (0 until 3).map { arr.getJSONObject(it).getString("id") })
        assertFalse(EditorBlockOps.reorder(arr, 1, 1)); assertFalse(EditorBlockOps.reorder(arr, 0, 9))
    }

    @Test fun dragTargetUsesMidpointOverRealHeights() {
        val h = listOf(100, 300, 100)
        assertEquals(0, dragTargetIndex(0, 100f, h))     // < mitad del siguiente (150)
        assertEquals(1, dragTargetIndex(0, 150f, h))
        assertEquals(2, dragTargetIndex(0, 350f, h))     // 300 + 50
        assertEquals(1, dragTargetIndex(2, -150f, h))
        assertEquals(0, dragTargetIndex(2, -500f, h))
        assertEquals(1, dragTargetIndex(1, 0f, h))
    }

    @Test fun dropTargetsResolveByGeometry() {
        val bounds = listOf(0f to 100f, 120f to 300f, null)
        assertEquals(0, EditorBlockOps.dropBlockIndex(50f, bounds))
        assertEquals(1, EditorBlockOps.dropBlockIndex(200f, bounds))
        assertNull("hueco entre bloques = inválido", EditorBlockOps.dropBlockIndex(110f, bounds))
        assertNull(EditorBlockOps.dropBlockIndex(999f, bounds))
        val items = listOf("a" to (120f to 160f), "b" to (160f to 200f))
        assertEquals("a", EditorBlockOps.dropBeforeId(130f, items))
        assertEquals("b", EditorBlockOps.dropBeforeId(170f, items))
        assertNull("bloque vacío o debajo de todos = al final", EditorBlockOps.dropBeforeId(250f, items))
        assertNull(EditorBlockOps.dropBeforeId(10f, emptyList()))
    }

    @Test fun handleItemDrop_invalidDropAndRejectedConversionLeaveDraftUntouched() {
        val b = blocks(); val snapshot = b.toString()
        val geo = EditorGeometry().apply { blocks[0] = 0f to 100f; blocks[1] = 120f to 300f }
        var changed = 0
        val arr0 = b.getJSONObject(0).getJSONArray("exercises")
        handleItemDrop(b, geo, 0, "i1", 0, arr0, 110f, 1, { "" }, { null }) { changed++ }   // hueco
        assertEquals(0, changed); assertEquals(snapshot, b.toString())
        val mv = b.getJSONObject(1).getJSONArray("movements")
        handleItemDrop(b, geo, 1, "m2", 1, mv, 50f, 1, { "" }, { "sq" }) { changed++ }       // REST a fuerza
        assertEquals(0, changed); assertEquals(snapshot, b.toString())
        handleItemDrop(b, geo, 0, "i1", 0, arr0, 200f, 0, { "Sentadilla" }, { null }) { changed++ } // fuerza→WOD
        assertEquals(1, changed)
        assertEquals(3, b.getJSONObject(1).getJSONArray("movements").length())
        assertEquals(1, arr0.length())
    }

    @Test fun autoScrollSpeedIsZeroInMiddleRampedAndClamped() {
        assertEquals(0f, autoScrollSpeed(500f, 0f, 1000f, 100f, 20f), 0f)
        assertEquals(10f, autoScrollSpeed(950f, 0f, 1000f, 100f, 20f), 1e-4f)   // mitad de la zona inferior
        assertEquals(20f, autoScrollSpeed(1500f, 0f, 1000f, 100f, 20f), 1e-4f)  // fuera: tope
        assertEquals(-10f, autoScrollSpeed(50f, 0f, 1000f, 100f, 20f), 1e-4f)
        assertEquals(-20f, autoScrollSpeed(-300f, 0f, 1000f, 100f, 20f), 1e-4f)
        assertEquals(0f, autoScrollSpeed(10f, 0f, 1000f, 0f, 20f), 0f)
    }

    @Test fun planConversionKeepsSetIdsAndReportsLostFields() {
        val sets = listOf(PlannedSetDraft(5, 100.0, 2.0, "s1"), PlannedSetDraft(3, 110.0, null, "s2"))
        val mv = EditorBlockOps.planStrengthToMovement("it1", "sq", "Sentadilla", sets, "")
        assertEquals("it1", mv.getString("id")); assertEquals(5, mv.getInt("reps")); assertEquals(100.0, mv.getDouble("weightMaleKg"), 0.0)
        assertEquals("s2", mv.getJSONArray("explicitPlannedSets").getJSONObject(1).getString("id"))
        mv.put("weightFemaleKg", 60.0).put("scaleAlternative", "banda").put("notes", "n")
        val (item, lost) = EditorBlockOps.planMovementToStrength(mv, "sq")
        assertEquals(setOf("weightFemaleKg", "scaleAlternative", "notes"), lost.toSet())
        val back = EditorBlockOps.jsonToDraftSets(item.getJSONArray("plannedSets"))
        assertEquals(sets, back)
        assertTrue(EditorBlockOps.planMovementToStrength(JSONObject().put("id", "m").put("name", "x").put("reps", 7), "sq").second.isEmpty())
    }
}

class PlanPendingCustomsTest {
    private fun state() = org.json.JSONObject().put("exercises", org.json.JSONArray()
        .put(org.json.JSONObject().put("id", "ex-1").put("name", "Dominadas").put("isCustom", false)))
    private fun draft(vararg ids: String) = listOf(RoutineBlockDraft(format = "strength",
        entries = ids.map { RoutineDraftEntry(exerciseId = it, quantity = 5) }))

    @org.junit.Test fun createsOnceAndReusesNormalizedName() {
        val st = state()
        val out = materializePendingCustoms(draft("pending:Thruster", "pending:thruster ", "pending:DOMINADAS"), st) { true }
        val cat = st.getJSONArray("exercises")
        org.junit.Assert.assertEquals(2, cat.length())
        org.junit.Assert.assertEquals(out[0].entries[0].exerciseId, out[0].entries[1].exerciseId.let { out[0].entries[0].exerciseId })
        org.junit.Assert.assertEquals("ex-1", out[0].entries[2].exerciseId)
        org.junit.Assert.assertTrue(out.all { b -> b.entries.none { it.exerciseId.startsWith("pending:") } })
    }
    @org.junit.Test fun quotaDeniedThrowsBeforeWriting() {
        val st = state()
        try { materializePendingCustoms(draft("pending:A", "pending:B"), st) { n -> n < 1 }; org.junit.Assert.fail() }
        catch (e: IllegalStateException) {}
        org.junit.Assert.assertEquals(1, st.getJSONArray("exercises").length())
    }
}

class CardioUnitTest {
    @org.junit.Test fun keepsOriginalUnitWithoutChoiceAndHonorsChoice() {
        val orig = org.json.JSONObject().put("distanceMeters", 500)
        org.junit.Assert.assertEquals("meters", EditorBlockOps.resolveQuantityUnit("Air Bike", null, null, orig))
        org.junit.Assert.assertEquals("calories", EditorBlockOps.resolveQuantityUnit("Air Bike", null, "calories", orig))
        org.junit.Assert.assertEquals("calories", EditorBlockOps.resolveQuantityUnit("Air Bike", null, null, null))
    }
    @org.junit.Test fun runLikeOrStrengthIgnoreChoice() {
        org.junit.Assert.assertEquals("meters", EditorBlockOps.resolveQuantityUnit("Carrera", null, "calories", null))
        org.junit.Assert.assertEquals("reps", EditorBlockOps.resolveQuantityUnit("Sentadilla", null, "meters", null))
    }
}

class DayEditorImportTest {
    @org.junit.Test fun freshIdsReplacesEveryIdAndDropsSuperset() {
        val j = """{"id":"b","exercises":[{"id":"i","exerciseId":"ex-1","supersetGroup":"g","plannedSets":[{"id":"s"}]}]}"""
        val out = org.json.JSONObject(EditorBlockOps.freshIds(j)!!)
        org.junit.Assert.assertNotEquals("b", out.getString("id"))
        val it = out.getJSONArray("exercises").getJSONObject(0)
        org.junit.Assert.assertNotEquals("i", it.getString("id"))
        org.junit.Assert.assertEquals("ex-1", it.getString("exerciseId"))
        org.junit.Assert.assertFalse(it.has("supersetGroup"))
        org.junit.Assert.assertNotEquals("s", it.getJSONArray("plannedSets").getJSONObject(0).getString("id"))
    }
    @org.junit.Test fun templateKeepsRepeatedMovementsAndRejectsLadder() {
        val cat = listOf(ExerciseEntry("ex-t", "Thruster", true, true))
        val t = dev.repera.domain.CatalogWods.seed().first { it.format != dev.repera.domain.WodFormat.LADDER && it.movements.size > 1 }
        val info = EditorBlockOps.templateToBlockInfo(t, cat)!!
        org.junit.Assert.assertEquals(t.movements.size, info.entries.size)
        val ladder = EditorBlockOps.templateToBlockInfo(dev.repera.domain.CatalogWods.template("21-15-9-thruster-bjo")!!, cat)
        org.junit.Assert.assertEquals(6, ladder.entries.size)
        org.junit.Assert.assertEquals("ladder", ladder.format)
        org.junit.Assert.assertNull(ladder.ladderScheme)
        org.junit.Assert.assertEquals(listOf(21, 21, 15, 15, 9, 9), ladder.entries.map { it.quantity })
    }
}

class LadderTemplateExecutionTest {
    @org.junit.Test fun ladderTemplateAssemblesSixMovementsWithOwnReps() {
        val info = EditorBlockOps.templateToBlockInfo(
            dev.repera.domain.CatalogWods.template("21-15-9-thruster-bjo")!!, emptyList())
        val block = org.json.JSONObject(info.sourceJson!!).put("kind", "wod")
            .put("movements", org.json.JSONArray(info.entries.map { org.json.JSONObject(it.sourceJson!!) }))
        org.junit.Assert.assertTrue(WodSessionAssembler.supports(block))
        val out = org.json.JSONArray()
        WodSessionAssembler.append(block, org.json.JSONArray(), out)
        org.junit.Assert.assertEquals(6, out.length())
        val reps = (0 until 6).map { out.getJSONObject(it).getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps") }
        org.junit.Assert.assertEquals(listOf(21, 21, 15, 15, 9, 9), reps)
        org.junit.Assert.assertEquals("ladder", out.getJSONObject(0).getString("wodFormat"))
    }

    @Test fun moveActionTargetsAreExplicitNeighbourIndexes() {
        assertEquals(listOf("Mover abajo" to 1), moveActionTargets(0, 3))
        assertEquals(listOf("Mover arriba" to 0, "Mover abajo" to 2), moveActionTargets(1, 3))
        assertEquals(listOf("Mover arriba" to 1), moveActionTargets(2, 3))
        assertEquals(emptyList<Pair<String, Int>>(), moveActionTargets(0, 1))
    }

    @Test fun neighbourTargetsReorderWithoutGeometry() {
        val arr = org.json.JSONArray(listOf("a", "b", "c"))
        val (_, up) = moveActionTargets(2, 3).first()
        assertTrue(EditorBlockOps.reorder(arr, 2, up))
        assertEquals("[\"a\",\"c\",\"b\"]", arr.toString())
        val (_, down) = moveActionTargets(0, 3).first()
        assertTrue(EditorBlockOps.moveBlock(arr, 0, down))
        assertEquals("[\"c\",\"a\",\"b\"]", arr.toString())
    }
}
