package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Editor de contenido de rutinas: sustitución multi-bloque con fidelidad
 *  JSON compartida con iOS (kind / wodFormat / params / movimientos). */
@RunWith(AndroidJUnit4::class)
class RoutineBlocksEditorInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val pull = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Dominadas").put("muscleGroup", "Espalda")
        val row = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Remo con barra").put("muscleGroup", "Espalda")
        val state = JSONObject()
            .put("exercises", JSONArray().put(pull).put(row))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    private fun exerciseIds(local: LocalSnapshotStore): Pair<String, String> {
        val exercises = JSONObject(String(local.read()!!)).getJSONArray("exercises")
        return exercises.getJSONObject(0).getString("id") to
            exercises.getJSONObject(1).getString("id")
    }

    private fun routine(local: LocalSnapshotStore): JSONObject =
        JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0)

    @Test fun replaceBlocksKeepsIdentityTitleAndScheduleAndWritesMultiBlock() {
        val (repo, local) = repo()
        val (pullId, rowId) = exerciseIds(local)
        repo.createRoutine("Sesión del lunes", "forTime",
            listOf(RoutineDraftEntry(pullId, 30)),
            schedule = RoutineSchedule(weekday = 1, timeMinutes = 600))
        val before = routine(local)
        val id = before.getString("id")

        repo.replaceRoutineBlocks(id, listOf(
            RoutineBlockDraft(title = "Buy-in", format = "buyInCashOut",
                entries = listOf(RoutineDraftEntry(rowId, 500)),
                timeCapMinutes = 5),
            RoutineBlockDraft(title = "Fuerza", format = "strength",
                entries = listOf(RoutineDraftEntry(pullId, 5, sets = 5, weightKg = 20.0)))
        ))

        val after = routine(local)
        assertEquals(id, after.getString("id"))
        assertEquals("Sesión del lunes", after.getString("title"))
        assertEquals(1, after.getInt("weekday"))
        assertEquals(600, after.getInt("scheduledTimeMinutes"))
        val blocks = after.getJSONArray("blocks")
        assertEquals(2, blocks.length())
        val buyIn = blocks.getJSONObject(0)
        assertEquals("wod", buyIn.getString("kind"))
        assertEquals("buyInCashOut", buyIn.getString("wodFormat"))
        assertEquals("Buy-in", buyIn.getString("title"))
        assertEquals(5, buyIn.getInt("timeCapMinutes"))
        val movement = buyIn.getJSONArray("movements").getJSONObject(0)
        assertEquals(rowId, movement.getString("exerciseId"))
        assertEquals("Remo con barra", movement.getString("name"))
        assertEquals(500, movement.getInt("reps"))
        val strength = blocks.getJSONObject(1)
        assertEquals("strength", strength.getString("kind"))
        val planned = strength.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets")
        assertEquals(5, planned.length())
        assertEquals(5, planned.getJSONObject(0).getInt("targetReps"))
        assertEquals(20.0, planned.getJSONObject(0).getDouble("targetWeightKg"), 0.001)
    }

    @Test fun replaceBlocksValidates() {
        val (repo, local) = repo()
        val (pullId, _) = exerciseIds(local)
        repo.createRoutine("Base", "strength",
            listOf(RoutineDraftEntry(pullId, 5, sets = 3)))
        val id = routine(local).getString("id")
        assertThrows(IllegalArgumentException::class.java) {
            repo.replaceRoutineBlocks(id, emptyList())
        }
        assertThrows(IllegalArgumentException::class.java) {
            repo.replaceRoutineBlocks(id, listOf(
                RoutineBlockDraft(format = "forTime", entries = emptyList())))
        }
        assertThrows(IllegalArgumentException::class.java) {
            repo.replaceRoutineBlocks(id, listOf(
                RoutineBlockDraft(format = "forTime", entries = listOf(
                    RoutineDraftEntry(pullId, 10), RoutineDraftEntry(pullId, 5)))))
        }
        assertThrows(IllegalStateException::class.java) {
            repo.replaceRoutineBlocks(UUID.randomUUID().toString(), listOf(
                RoutineBlockDraft(format = "strength",
                    entries = listOf(RoutineDraftEntry(pullId, 5)))))
        }
        // La rutina original queda intacta tras los rechazos.
        assertEquals("Base", routine(local).getString("title"))
        assertEquals(1, routine(local).getJSONArray("blocks").length())
    }

    @Test fun replaceBlocksWritesEmomDerivedCapAndTabataFields() {
        val (repo, local) = repo()
        val (pullId, _) = exerciseIds(local)
        repo.createRoutine("Base", "amrap", listOf(RoutineDraftEntry(pullId, 10)))
        val id = routine(local).getString("id")
        repo.replaceRoutineBlocks(id, listOf(
            RoutineBlockDraft(format = "emom",
                entries = listOf(RoutineDraftEntry(pullId, 10)),
                rounds = 10, emomIntervalSeconds = 60),
            RoutineBlockDraft(format = "tabata",
                entries = listOf(RoutineDraftEntry(pullId, 8)),
                rounds = 8, workSeconds = 20, restSeconds = 10)
        ))
        val blocks = routine(local).getJSONArray("blocks")
        val emom = blocks.getJSONObject(0)
        assertEquals(10, emom.getInt("timeCapMinutes"))
        assertEquals(60, emom.getInt("emomIntervalSeconds"))
        assertEquals(10, emom.getInt("rounds"))
        val tabata = blocks.getJSONObject(1)
        assertEquals(20, tabata.getInt("workSeconds"))
        assertEquals(10, tabata.getInt("restSeconds"))
    }

    /** Snapshot antiguo con campos WOD que el borrador simple no modela. Editar y guardar
     *  sin tocar la prescripción conserva ids, REST, peso M, escala, notas y repScheme. */
    @Test fun planEditorRoundTripKeepsIdsAndWodFields() {
        val (repo, local) = repo()
        val (pullId, rowId) = exerciseIds(local)
        val state = JSONObject(String(local.read()!!))
        val wod = JSONObject("""{"id":"blk-w","title":"W","kind":"wod","wodFormat":"amrap","timeCapMinutes":12,"movements":[
            {"id":"mv-1","exerciseId":"$pullId","name":"Dominadas","isRest":false,"reps":10,"repScheme":[10,8],
             "weightFemaleKg":30,"scaleAlternative":"banda","notes":"estrictas","explicitPlannedSets":[{"id":"ps-1","targetReps":10},{"id":"ps-2","targetReps":8}]},
            {"id":"mv-r","name":"REST","isRest":true,"restSeconds":90}]}""")
        val str = JSONObject("""{"id":"blk-s","title":"S","kind":"strength","exercises":[
            {"id":"it-1","exerciseId":"$rowId","restSeconds":120,"quantityUnit":"reps","plannedSets":[
              {"id":"sp-1","targetReps":5,"targetWeightKg":60,"targetRir":2},{"id":"sp-2","targetReps":3,"targetWeightKg":70}]}]}""")
        state.getJSONArray("routines").put(JSONObject().put("id", "r1").put("title", "Plan")
            .put("blocks", JSONArray().put(wod).put(str)).put("progression", "off").put("isFavorite", false))
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        // Drafts como los produce el editor sin cambios del usuario.
        val drafts = listOf(
            RoutineBlockDraft(blockId = "blk-w", sourceJson = wod.toString(), title = "W", format = "amrap",
                entries = listOf(
                    RoutineDraftEntry(pullId, 10, itemId = "mv-1", sourceJson = wod.getJSONArray("movements").getJSONObject(0).toString()),
                    RoutineDraftEntry("", 1, itemId = "mv-r", sourceJson = wod.getJSONArray("movements").getJSONObject(1).toString()))),
            RoutineBlockDraft(blockId = "blk-s", sourceJson = str.toString(), title = "S", format = "strength",
                entries = listOf(RoutineDraftEntry(rowId, 5, sets = 2, weightKg = 60.0, itemId = "it-1",
                    sourceJson = str.getJSONArray("exercises").getJSONObject(0).toString(),
                    plannedSets = listOf(PlannedSetDraft(5, 60.0, 2.0, "sp-1"), PlannedSetDraft(3, 70.0, null, "sp-2"))))))
        repo.replaceRoutineBlocks("r1", drafts)
        val after = JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getJSONArray("blocks")
        assertEquals("blk-w", after.getJSONObject(0).getString("id"))
        val mv = after.getJSONObject(0).getJSONArray("movements")
        val m = mv.getJSONObject(0)
        assertEquals("mv-1", m.getString("id")); assertEquals(30.0, m.getDouble("weightFemaleKg"), 0.0)
        assertEquals("banda", m.getString("scaleAlternative")); assertEquals("estrictas", m.getString("notes"))
        assertEquals(2, m.getJSONArray("repScheme").length()); assertEquals("ps-2", m.getJSONArray("explicitPlannedSets").getJSONObject(1).getString("id"))
        assertTrue(mv.getJSONObject(1).getBoolean("isRest")); assertEquals(90, mv.getJSONObject(1).getInt("restSeconds"))
        val item = after.getJSONObject(1).getJSONArray("exercises").getJSONObject(0)
        assertEquals("it-1", item.getString("id")); assertEquals(120, item.getInt("restSeconds"))
        assertEquals("sp-1", item.getJSONArray("plannedSets").getJSONObject(0).getString("id"))
        assertEquals(2.0, item.getJSONArray("plannedSets").getJSONObject(0).getDouble("targetRir"), 0.0)
        assertEquals(3, item.getJSONArray("plannedSets").getJSONObject(1).getInt("targetReps"))
    }

    /** Cambiar la prescripción descarta series explícitas y esquema, pero conserva escala/notas/peso M. */
    @Test fun planEditorChangingQuantityDropsOnlyPrescription() {
        val (repo, local) = repo()
        val (pullId, _) = exerciseIds(local)
        val state = JSONObject(String(local.read()!!))
        val mvJson = JSONObject("""{"id":"mv-1","exerciseId":"$pullId","name":"Dominadas","isRest":false,"reps":10,"repScheme":[10,8],
            "weightFemaleKg":30,"scaleAlternative":"banda","explicitPlannedSets":[{"id":"ps-1","targetReps":10}]}""")
        val wod = JSONObject().put("id", "blk-w").put("title", "W").put("kind", "wod").put("wodFormat", "amrap")
            .put("timeCapMinutes", 12).put("movements", JSONArray().put(mvJson))
        state.getJSONArray("routines").put(JSONObject().put("id", "r1").put("title", "Plan")
            .put("blocks", JSONArray().put(wod)).put("progression", "off").put("isFavorite", false))
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        repo.replaceRoutineBlocks("r1", listOf(RoutineBlockDraft(blockId = "blk-w", sourceJson = wod.toString(), title = "W",
            format = "amrap", entries = listOf(RoutineDraftEntry(pullId, 15, itemId = "mv-1", sourceJson = mvJson.toString())))))
        val m = JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0)
            .getJSONArray("blocks").getJSONObject(0).getJSONArray("movements").getJSONObject(0)
        assertEquals(15, m.getInt("reps")); assertFalse(m.has("repScheme")); assertFalse(m.has("explicitPlannedSets"))
        assertEquals("banda", m.getString("scaleAlternative")); assertEquals("mv-1", m.getString("id"))
    }
}
