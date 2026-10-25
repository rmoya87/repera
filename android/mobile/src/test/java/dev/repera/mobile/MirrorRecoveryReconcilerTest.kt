package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Recuperación del espejo -> primera sincronización con Drive. Datos sintéticos, sin red ni cuentas. */
class MirrorRecoveryReconcilerTest {
    private fun workout(id: String, finished: String = "2026-10-01T10:00:00Z") =
        JSONObject().put("id", id).put("title", "W$id").put("finishedAt", finished).put("exercises", JSONArray())

    private fun doc(workouts: List<JSONObject>, rev: Int, routines: List<String> = emptyList(),
                    settings: JSONObject = JSONObject(), active: JSONObject? = null): JSONObject {
        val ex = JSONArray(); repeat(196) { ex.put(JSONObject().put("id", "e$it").put("name", "E$it")) }
        return JSONObject().put("exercises", ex)
            .put("routines", JSONArray().also { a -> routines.forEach { a.put(JSONObject().put("id", it)) } })
            .put("workouts", JSONArray().also { a -> workouts.forEach { a.put(it) } })
            .put("bodyWeights", JSONArray()).put("favoriteTimers", JSONArray())
            .put("settings", settings).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", rev).put("updatedAt", "2026-10-02T00:00:00Z").put("lastWriterDeviceId", "dev-local")
            .apply { if (active != null) put("activeSession", active) }
    }
    private fun bytes(j: JSONObject) = j.toString().toByteArray(Charsets.UTF_8)
    private fun prov(vararg w: JSONObject) = w.associate { it.getString("id") to WorkoutMirrorStore.canonicalDigest(it) }
    private val now = "2026-10-25T05:00:00Z"

    @Test fun subsetOfDriveJustDownloads() {
        val a = workout("a")
        val r = MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(a), 1)),
            bytes(doc(listOf(a, workout("b")), 7, routines = listOf("r"))), prov(a), now)
        assertTrue(r is MirrorRecoveryReconciler.Result.UseRemote)
    }

    @Test fun recoveredWorkoutMissingFromDriveIsNotUploadedAutomatically() {
        val n = workout("new", "2026-10-20T10:00:00Z")
        val r = MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(n), 1)),
            bytes(doc(listOf(workout("old")), 7, routines = listOf("r"))), prov(n), now)
        assertEquals(MirrorRecoveryReconciler.Result.NotApplicable, r)
    }

    @Test fun sameIdWithDifferentContentDeclines() {
        val a = workout("a"); val edited = JSONObject(a.toString()).put("title", "otro")
        assertEquals(MirrorRecoveryReconciler.Result.NotApplicable, MirrorRecoveryReconciler.reconcile(
            bytes(doc(listOf(a), 1)), bytes(doc(listOf(edited), 7)), prov(a), now))
    }

    @Test fun anyIndependentLocalChangeKeepsTheNormalConflictPath() {
        val a = workout("a"); val remote = bytes(doc(listOf(workout("b")), 7))
        val na = MirrorRecoveryReconciler.Result.NotApplicable
        // rutina local, ajustes, sesión activa
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(a), 1, routines = listOf("mine"))), remote, prov(a), now))
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(a), 1, settings = JSONObject().put("x", 1))), remote, prov(a), now))
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(a), 1, active = JSONObject().put("id", "s"))), remote, prov(a), now))
        // entreno propio no recuperado
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(a, workout("mine")), 1)), remote, prov(a), now))
        // entreno recuperado y luego editado
        val edited = JSONObject(a.toString()).put("title", "editado")
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(edited), 1)), remote, prov(a), now))
        // sin procedencia o sin entrenos
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(listOf(a), 1)), remote, emptyMap(), now))
        assertEquals(na, MirrorRecoveryReconciler.reconcile(bytes(doc(emptyList(), 1)), remote, prov(a), now))
    }
}
