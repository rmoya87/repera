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
}
