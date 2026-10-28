package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** Ensayos de fallo/replay del diario de reset sobre puertos en memoria (sin Android, sin cuentas). */
class ResetCoordinatorTest {
    private class Crash : RuntimeException()
    private class Fake(
        var state: JSONObject?, var intent: String? = null, var casOk: Boolean = true,
        var crashAfter: String? = null
    ) : ResetPorts {
        val tombstones = linkedSetOf<String>()
        private fun maybeCrash(step: String) { if (crashAfter == step) { crashAfter = null; throw Crash() } }
        override fun loadIntent() = intent
        override fun storeIntent(json: String) { intent = json; maybeCrash("intent") }
        override fun clearIntent() { intent = null; maybeCrash("clear") }
        override fun readState() = state?.let { JSONObject(it.toString()) }
        override fun saveState(state: JSONObject): Boolean {
            if (!casOk) return false
            this.state = JSONObject(state.toString()); maybeCrash("save"); return true
        }
        override fun noteDeleted(id: String) { tombstones += id; maybeCrash("tomb:" + tombstones.size) }
    }
    private fun st() = JSONObject()
        .put("exercises", JSONArray().put(JSONObject().put("id", "e1")))
        .put("routines", JSONArray().put(JSONObject().put("id", "r1")))
        .put("workouts", JSONArray().put(JSONObject().put("id", "w1")).put(JSONObject().put("id", "w2")))
        .put("bodyWeights", JSONArray())
        .put("activeSession", JSONObject().put("id", "s1"))
    private fun stateIds(f: Fake) = UserDataReset.discardedIds(f.state!!).toSet()

    @Test fun happyPathTombstonesAfterSaveAndClearsIntent() {
        val f = Fake(st())
        assertEquals(ResetCoordinator.Outcome.Done, ResetCoordinator(f).reset("x"))
        assertEquals(setOf("w1", "w2", "s1"), f.tombstones)
        assertNull(f.intent); assertTrue(stateIds(f).isEmpty())
        assertEquals(1, f.state!!.getJSONArray("exercises").length())
    }

    @Test fun casFailureWritesNoTombstoneAndKeepsHistory() {
        val f = Fake(st(), casOk = false)
        assertEquals(ResetCoordinator.Outcome.CasFailedNothingChanged, ResetCoordinator(f).reset("x"))
        assertTrue(f.tombstones.isEmpty()); assertNull(f.intent)
        assertEquals(setOf("w1", "w2", "s1"), stateIds(f))
    }

    @Test fun crashAtEveryStepConvergesAfterRecoverAndInvariantsHold() {
        for (step in listOf("intent", "save", "tomb:1", "tomb:2", "tomb:3", "clear")) {
            val f = Fake(st(), crashAfter = step)
            assertTrue(step, runCatching { ResetCoordinator(f).reset("x") }.exceptionOrNull() is Crash)
            // Invariante en cualquier punto: nunca hay tombstone si el snapshot aun conserva los ids.
            assertFalse(step, f.tombstones.isNotEmpty() && stateIds(f).isNotEmpty())
            val c = ResetCoordinator(f)
            if (f.intent != null) assertEquals(step, setOf("w1", "w2", "s1"), c.protectedIds())
            c.recover(); c.recover() // idempotente
            assertNull(step, f.intent)
            if (step == "intent") {
                assertTrue(step, f.tombstones.isEmpty()); assertEquals(setOf("w1", "w2", "s1"), stateIds(f))
            } else {
                assertEquals(step, setOf("w1", "w2", "s1"), f.tombstones); assertTrue(stateIds(f).isEmpty())
            }
        }
    }

    @Test fun secondResetWhileIntentPendingIsRefused() {
        val f = Fake(st(), crashAfter = "save")
        runCatching { ResetCoordinator(f).reset("x") }
        assertEquals(ResetCoordinator.Outcome.PendingRecoveryRequired, ResetCoordinator(f).reset("y"))
    }

    @Test fun historyReappearingAfterSaveIsReportedNotDeletedAgain() {
        val f = Fake(st(), crashAfter = "save")
        runCatching { ResetCoordinator(f).reset("x") }
        f.state!!.put("workouts", JSONArray().put(JSONObject().put("id", "w1"))) // otro dispositivo restauro w1
        val r = ResetCoordinator(f).recover()
        assertEquals(ResetCoordinator.Recovery.ResurrectedNeedsDecision(setOf("w1")), r)
        assertNotNull(f.intent); assertTrue(f.tombstones.isEmpty())
    }

    @Test fun nothingToResetIsNoOp() {
        val empty = JSONObject().put("exercises", JSONArray()).put("routines", JSONArray()).put("workouts", JSONArray()).put("bodyWeights", JSONArray())
        val f = Fake(empty)
        assertEquals(ResetCoordinator.Outcome.NothingToReset, ResetCoordinator(f).reset("x"))
        assertNull(f.intent)
    }

    @Test fun epochPolicyIsOnlyASimulation() {
        assertEquals(ResetEpochPolicy.Winner.Local, ResetEpochPolicy.resolve(2, 1))
        assertEquals(ResetEpochPolicy.Winner.Remote, ResetEpochPolicy.resolve(1, 2))
        assertEquals(ResetEpochPolicy.Winner.UseRevisionRule, ResetEpochPolicy.resolve(0, 0))
    }

    @Test fun unreadableStateKeepsIntentAndWritesNoTombstone() {
        val f = Fake(st(), crashAfter = "save")
        runCatching { ResetCoordinator(f).reset("x") }
        f.state = null
        assertEquals(ResetCoordinator.Recovery.StateUnavailableKeptIntent, ResetCoordinator(f).recover())
        assertNotNull(f.intent); assertTrue(f.tombstones.isEmpty())
    }

    @Test fun resetAndRecoverRacingNeverTombstoneWhileIdsStillInSnapshot() {
        repeat(300) {
            val violations = java.util.concurrent.atomic.AtomicInteger()
            val f = object : ResetPorts {
                @Volatile var state: JSONObject? = st()
                @Volatile var intent: String? = null
                val tombstones = java.util.concurrent.ConcurrentHashMap.newKeySet<String>()
                override fun loadIntent() = intent
                override fun storeIntent(json: String) { Thread.yield(); intent = json }
                override fun clearIntent() { Thread.yield(); intent = null }
                override fun readState() = state?.let { JSONObject(it.toString()) }
                override fun saveState(state: JSONObject): Boolean { Thread.yield(); this.state = JSONObject(state.toString()); return true }
                override fun noteDeleted(id: String) {
                    if (UserDataReset.discardedIds(state!!).isNotEmpty()) violations.incrementAndGet()
                    Thread.yield(); tombstones += id
                }
            }
            val t1 = Thread { ResetCoordinator(f).reset("x") }
            val t2 = Thread { repeat(20) { ResetCoordinator(f).recover(); Thread.yield() } }
            t1.start(); t2.start(); t1.join(); t2.join()
            ResetCoordinator(f).recover()
            assertEquals(0, violations.get())
            assertNull(f.intent)
            assertEquals(setOf("w1", "w2", "s1"), f.tombstones.toSet())
            assertTrue(UserDataReset.discardedIds(f.state!!).isEmpty())
        }
    }

    @Test fun recoverWithADifferentSnapshotNeverTouchesOtherData() {
        val f = Fake(st(), crashAfter = "save")
        runCatching { ResetCoordinator(f).reset("x") }
        // El snapshot pasa a ser otro historial (p. ej. Drive de otra cuenta/dispositivo) sin los ids de la intencion.
        f.state = JSONObject().put("exercises", JSONArray()).put("routines", JSONArray())
            .put("workouts", JSONArray().put(JSONObject().put("id", "other1"))).put("bodyWeights", JSONArray())
        val before = f.state.toString()
        ResetCoordinator(f).recover()
        assertEquals(before, f.state.toString())
        assertEquals(setOf("w1", "w2", "s1"), f.tombstones) // solo los ids de la intencion, nunca "other1"
    }

    @Test fun corruptIntentIsKeptWithoutThrowingOrDeleting() {
        val f = Fake(st(), intent = "{not json")
        assertEquals(ResetCoordinator.Recovery.CorruptIntentKept, ResetCoordinator(f).recover())
        assertEquals("{not json", f.intent); assertTrue(f.tombstones.isEmpty())
        assertTrue(ResetCoordinator(f).protectedIds().isEmpty())
        assertEquals(ResetCoordinator.Outcome.PendingRecoveryRequired, ResetCoordinator(f).reset("x"))
    }
}
