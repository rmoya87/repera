package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Editor de rutinas: formatos WOD más allá del subconjunto inicial. */
@RunWith(AndroidJUnit4::class)
class RoutineFormatsInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val pull = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Dominadas").put("muscleGroup", "Espalda")
        val state = JSONObject().put("exercises", JSONArray().put(pull))
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    private fun firstBlock(local: LocalSnapshotStore): JSONObject =
        JSONObject(String(local.read()!!)).getJSONArray("routines")
            .getJSONObject(0).getJSONArray("blocks").getJSONObject(0)

    private fun exerciseId(local: LocalSnapshotStore): String =
        JSONObject(String(local.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")

    @Test fun ladderWritesRepSchemeOnEveryMovement() {
        val (repo, local) = repo()
        repo.createRoutine("Escalera", "ladder",
            listOf(RoutineDraftEntry(exerciseId(local), 21)),
            timeCapMinutes = 20, ladderScheme = listOf(21, 15, 9))
        val block = firstBlock(local)
        assertEquals("ladder", block.getString("wodFormat"))
        val scheme = block.getJSONArray("movements").getJSONObject(0)
            .getJSONArray("repScheme")
        assertEquals(listOf(21, 15, 9),
            (0 until scheme.length()).map { scheme.getInt(it) })
        assertEquals(20, block.getInt("timeCapMinutes"))
        assertFalse(block.has("rounds"))
        val active = repo.startRoutine(
            JSONObject(String(local.read()!!)).getJSONArray("routines")
                .getJSONObject(0).getString("id"))
        // plannedSets deriva del repScheme (21-15-9), no del reps suelto.
        assertEquals("ladder", active.wod!!.format)
    }

    @Test fun deathByKeepsIntervalAndCapture() {
        val (repo, local) = repo()
        repo.createRoutine("Death by", "deathBy",
            listOf(RoutineDraftEntry(exerciseId(local), 2)),
            timeCapMinutes = 30, emomIntervalSeconds = 60)
        val block = firstBlock(local)
        assertEquals("deathBy", block.getString("wodFormat"))
        assertEquals(60, block.getInt("emomIntervalSeconds"))
        assertFalse(block.has("rounds"))
    }

    @Test fun roundsForQualityKeepsRoundsWithoutWorkRest() {
        val (repo, local) = repo()
        repo.createRoutine("RFQ", "roundsForQuality",
            listOf(RoutineDraftEntry(exerciseId(local), 8)), rounds = 4)
        val block = firstBlock(local)
        assertEquals("roundsForQuality", block.getString("wodFormat"))
        assertEquals(4, block.getInt("rounds"))
        assertFalse(block.has("workSeconds"))
    }

    @Test fun chipperAfapPartnerAndMaxEffortAreAccepted() {
        for (kind in listOf("chipper", "afap", "partner", "maxEffort")) {
            val (repo, local) = repo()
            repo.createRoutine("Fmt $kind", kind,
                listOf(RoutineDraftEntry(exerciseId(local), 10)),
                timeCapMinutes = 15, rounds = 3)
            val block = firstBlock(local)
            assertEquals(kind, block.getString("wodFormat"))
            if (kind == "partner") assertEquals(3, block.getInt("rounds"))
            else assertFalse("$kind no debe llevar rounds", block.has("rounds"))
        }
    }

    @Test fun buyInCashOutStaysRejectedAndLadderValidates() {
        val (repo, local) = repo()
        assertThrows(IllegalArgumentException::class.java) {
            repo.createRoutine("BICO", "buyInCashOut",
                listOf(RoutineDraftEntry(exerciseId(local), 10)))
        }
        assertThrows(IllegalArgumentException::class.java) {
            repo.createRoutine("Mala", "ladder",
                listOf(RoutineDraftEntry(exerciseId(local), 21)),
                ladderScheme = listOf(21))
        }
    }
}
