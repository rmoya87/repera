package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/**
 * COMPILADO, NO EJECUTADO (sin dispositivo). Puertos reales del reset con almacenes reales (prefs + snapshot local),
 * cuenta sintetica aleatoria, sin red ni cuentas reales. La invariante del coordinador puro NO sustituye a esto.
 */
@RunWith(AndroidJUnit4::class)
class ResetJournalPortsInstrumentedTest {
    private val ctx get() = InstrumentationRegistry.getInstrumentation().targetContext
    private fun seeded(user: String): Pair<LocalSnapshotStore, String> {
        val press = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Press banca").put("muscleGroup", "Pecho").put("equipment", "Barra")
        val local = LocalSnapshotStore(ctx, user)
        local.write(JSONObject().put("exercises", JSONArray().put(press))
            .put("routines", JSONArray()).put("workouts", JSONArray()).put("syncRevision", 0)
            .toString().toByteArray(Charsets.UTF_8))
        return local to press.getString("id")
    }

    @Test fun successfulResetTombstonesAfterSaveAndClearsIntent() {
        val user = UUID.randomUUID().toString()
        val (local, ex) = seeded(user)
        val repo = WorkoutRepository(ctx, user)
        repo.startQuickLog(ex); repo.logCurrentSet(10, 60.0); repo.finish()
        repo.startQuickLog(ex)
        assertEquals(ResetCoordinator.Outcome.Done, repo.resetUserDataJournaledForTests("t"))
        val mirror = WorkoutMirrorStore(ctx, user)
        assertNull(mirror.loadResetIntent())
        assertEquals(2, mirror.pendingDeletes().size)
        val s = JSONObject(String(local.read()!!))
        assertEquals(0, s.getJSONArray("workouts").length()); assertTrue(s.isNull("activeSession") || !s.has("activeSession"))
        assertEquals(1, s.getJSONArray("exercises").length())
    }

    @Test fun casFailureAtSaveLeavesNoTombstoneAndNoIntent() {
        val user = UUID.randomUUID().toString()
        val (local, ex) = seeded(user)
        var armed = false; var calls = 0
        val repo = WorkoutRepository(ctx, user) {
            // llamada 1 = loadOrNull, 2 = save: escritor concurrente justo antes del CAS
            if (armed && ++calls == 2) {
                val s = JSONObject(String(local.read()!!)); s.put("syncRevision", s.optInt("syncRevision") + 1)
                local.write(s.toString().toByteArray(Charsets.UTF_8))
            }
            true
        }
        repo.startQuickLog(ex); repo.logCurrentSet(10, 60.0); repo.finish()
        armed = true
        assertEquals(ResetCoordinator.Outcome.CasFailedNothingChanged, repo.resetUserDataJournaledForTests("t"))
        armed = false
        val mirror = WorkoutMirrorStore(ctx, user)
        assertTrue(mirror.pendingDeletes().isEmpty()); assertNull(mirror.loadResetIntent())
        assertEquals(1, JSONObject(String(local.read()!!)).getJSONArray("workouts").length())
    }

    @Test fun blockedIdsIncludeIntentAndRecoverPromotesAfterSimulatedCrash() {
        val user = UUID.randomUUID().toString()
        val (local, ex) = seeded(user)
        val repo = WorkoutRepository(ctx, user)
        repo.startQuickLog(ex); repo.logCurrentSet(10, 60.0); repo.finish()
        val id = JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0).getString("id")
        val mirror = WorkoutMirrorStore(ctx, user)
        mirror.storeResetIntent(JSONObject().put("resetId", "t").put("ids", JSONArray().put(id)).toString())
        assertTrue(id in mirror.blockedIds()); assertFalse(id in mirror.deletedIds())
        // snapshot aun conserva el id: intencion sin guardar -> se descarta sin tombstone
        assertEquals(ResetCoordinator.Recovery.DiscardedUnsavedIntent, repo.recoverPendingReset())
        assertTrue(mirror.pendingDeletes().isEmpty())
    }
}

/**
 * COMPILADO, NO EJECUTADO. Alcance por cuenta e identidad. Hallazgo por lectura de codigo: WorkoutRepository usa
 * WorkoutMirrorStore(context, googleUniqueId) y MainActivity sincroniza con WorkoutMirrorStore(context, supabaseUserId):
 * dos archivos de prefs distintos ("repera.mirror.<id>"). El segundo test lo caracteriza (preexistente, no corregido).
 */
@RunWith(AndroidJUnit4::class)
class ResetJournalAccountScopeInstrumentedTest {
    private val ctx get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun intentOfOneAccountNeverBlocksOrRecoversForAnother() {
        val a = UUID.randomUUID().toString(); val b = UUID.randomUUID().toString()
        WorkoutMirrorStore(ctx, a).storeResetIntent(JSONObject().put("resetId", "t").put("ids", JSONArray().put("w1")).toString())
        assertTrue("w1" in WorkoutMirrorStore(ctx, a).blockedIds())
        assertFalse("w1" in WorkoutMirrorStore(ctx, b).blockedIds())
        assertNull(WorkoutMirrorStore(ctx, b).loadResetIntent())
        WorkoutMirrorStore(ctx, a).clearResetIntent()
    }

    @Test fun characterizationRepositoryAndSyncMirrorUseDifferentPrefsWhenIdsDiffer() {
        val googleId = UUID.randomUUID().toString(); val supabaseId = UUID.randomUUID().toString()
        val press = JSONObject().put("id", UUID.randomUUID().toString()).put("name", "P").put("muscleGroup", "Pecho").put("equipment", "Barra")
        val local = LocalSnapshotStore(ctx, googleId)
        local.write(JSONObject().put("exercises", JSONArray().put(press)).put("routines", JSONArray())
            .put("workouts", JSONArray()).put("syncRevision", 0).toString().toByteArray(Charsets.UTF_8))
        val repo = WorkoutRepository(ctx, googleId)
        repo.startQuickLog(press.getString("id")); repo.logCurrentSet(10, 60.0); repo.finish()
        val id = JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0).getString("id")
        repo.deleteWorkout(id)
        assertTrue(id in WorkoutMirrorStore(ctx, googleId).pendingDeletes())
        // Lo que lee el sync de MainActivity (clave = id Supabase): vacio.
        assertTrue(WorkoutMirrorStore(ctx, supabaseId).pendingDeletes().isEmpty())
    }
}
