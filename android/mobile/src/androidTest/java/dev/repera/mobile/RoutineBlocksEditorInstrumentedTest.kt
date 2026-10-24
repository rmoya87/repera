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
}
