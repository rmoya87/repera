package dev.repera.mobile

import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/**
 * DriveSnapshotService contra un Drive simulado en memoria (interceptor de OkHttp, sin red ni OAuth) y
 * almacenamiento local simulado. Cubre recuperación del espejo -> primera sincronización. NO sustituye E2E.
 */
class DriveSnapshotServiceMirrorTest {
    private class FakeDrive(var bytes: ByteArray?, var failPatch: Boolean = false) : Interceptor {
        var patches = 0
        override fun intercept(chain: Interceptor.Chain): Response {
            val req = chain.request()
            val url = req.url.toString()
            fun ok(body: ByteArray) = Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(200).message("OK")
                .body(body.toResponseBody("application/json".toMediaType())).build()
            return when {
                req.method == "GET" && url.contains("alt=media") -> ok(bytes!!)
                req.method == "GET" -> ok((if (bytes == null) """{"files":[]}""" else """{"files":[{"id":"f1","name":"app_state.json"}]}""").toByteArray())
                req.method == "PATCH" -> {
                    patches++
                    if (failPatch) Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(500).message("err")
                        .body("".toResponseBody(null)).build()
                    else { val b = okio.Buffer(); req.body!!.writeTo(b); bytes = b.readByteArray(); ok(ByteArray(0)) }
                }
                else -> error("petición inesperada: ${req.method} $url")
            }
        }
    }
    private class FakeLocal(var bytes: ByteArray?, var prov: Map<String, String>) : SnapshotStorage {
        var backups = 0
        override fun read() = bytes
        override fun write(bytes: ByteArray) { this.bytes = bytes }
        override fun preserveRemoteBackup(bytes: ByteArray) { backups++ }
        override fun readMirrorProvenance() = prov
    }

    private fun workout(id: String, title: String = "W$id", finished: String = "2026-10-01T10:00:00Z") =
        JSONObject().put("id", id).put("title", title).put("finishedAt", finished).put("exercises", JSONArray())
    private fun doc(workouts: List<JSONObject>, rev: Int, routines: List<String> = emptyList()): ByteArray {
        val ex = JSONArray(); repeat(196) { ex.put(JSONObject().put("id", "e$it").put("name", "E$it")) }
        return JSONObject().put("exercises", ex)
            .put("routines", JSONArray().also { a -> routines.forEach { a.put(JSONObject().put("id", it)) } })
            .put("workouts", JSONArray().also { a -> workouts.forEach { a.put(it) } })
            .put("bodyWeights", JSONArray()).put("favoriteTimers", JSONArray())
            .put("settings", JSONObject()).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", rev).put("updatedAt", "2026-10-02T00:00:00Z").put("lastWriterDeviceId", "dev")
            .toString().toByteArray(Charsets.UTF_8)
    }
    private fun prov(vararg w: JSONObject) = w.associate { it.getString("id") to WorkoutMirrorStore.canonicalDigest(it) }
    private fun svc(drive: FakeDrive, local: FakeLocal) =
        DriveSnapshotService("t", local, OkHttpClient.Builder().addInterceptor(drive).build())
    private fun ids(bytes: ByteArray?): Set<String> = JSONObject(String(bytes!!)).getJSONArray("workouts").let { a ->
        (0 until a.length()).map { a.getJSONObject(it).getString("id") }.toSet() }

    @Test fun subsetRecoveredFromMirrorDownloadsDriveWithoutUpload() {
        val a = workout("a")
        val drive = FakeDrive(doc(listOf(a, workout("b")), 7, listOf("r")))
        val local = FakeLocal(doc(listOf(a), 1), prov(a))
        assertEquals(DriveSnapshotService.Outcome.Downloaded, svc(drive, local).synchronize())
        assertEquals(0, drive.patches)
        assertEquals(setOf("a", "b"), ids(local.bytes))
    }

    @Test fun recoveredWorkoutMissingFromDriveIsUploadedAndNextSyncIsUnchanged() {
        val n = workout("new", finished = "2026-10-20T10:00:00Z")
        val drive = FakeDrive(doc(listOf(workout("old")), 7, listOf("r")))
        val local = FakeLocal(doc(listOf(n), 1), prov(n))
        assertEquals(DriveSnapshotService.Outcome.Uploaded, svc(drive, local).synchronize())
        assertEquals(setOf("old", "new"), ids(drive.bytes))
        assertTrue(local.bytes!!.contentEquals(drive.bytes!!))
        assertEquals(1, local.backups)
        assertEquals(DriveSnapshotService.Outcome.Unchanged, svc(drive, local).synchronize())
    }

    @Test fun failedUploadThenRetryConvergesWithoutConflictOrLoss() {
        val n = workout("new"); val old = workout("old")
        val drive = FakeDrive(doc(listOf(old), 7), failPatch = true)
        val local = FakeLocal(doc(listOf(n), 1), prov(n))
        assertThrows(IllegalStateException::class.java) { svc(drive, local).synchronize() }
        assertEquals(setOf("old", "new"), ids(local.bytes))   // local ya tiene ambos; Drive no cambió
        assertEquals(setOf("old"), ids(drive.bytes))
        drive.failPatch = false
        assertEquals(DriveSnapshotService.Outcome.Uploaded, svc(drive, local).synchronize())
        assertEquals(setOf("old", "new"), ids(drive.bytes))
    }

    @Test fun independentLocalDataStillRaisesConflict() {
        val a = workout("a")
        val drive = FakeDrive(doc(listOf(workout("b")), 7))
        val local = FakeLocal(doc(listOf(a), 1, routines = listOf("mine")), prov(a))
        assertEquals(DriveSnapshotService.Outcome.Conflict, svc(drive, local).synchronize())
        assertEquals(0, drive.patches)
    }

    @Test fun workoutDeletedLocallyAfterRecoveryIsNotReAdded() {
        val a = workout("a"); val b = workout("b")
        val drive = FakeDrive(doc(listOf(workout("old")), 7))
        val local = FakeLocal(doc(listOf(a), 1), prov(a, b)) // b se recuperó y luego se borró en local
        svc(drive, local).synchronize()
        assertEquals(setOf("old", "a"), ids(drive.bytes))
    }

    @Test fun sameIdWithDifferentContentIsNotMergedByTheReconciler() {
        val a = workout("a")
        val driveCopy = workout("a", title = "editado en otro dispositivo")
        val drive = FakeDrive(doc(listOf(driveCopy), 7))
        val local = FakeLocal(doc(listOf(a), 1), prov(a))
        // El reconciliador declina: sigue el camino normal (aquí gana la versión remota, sin subir nada).
        assertEquals(DriveSnapshotService.Outcome.Downloaded, svc(drive, local).synchronize())
        assertEquals(0, drive.patches)
        assertEquals("editado en otro dispositivo",
            JSONObject(String(local.bytes!!)).getJSONArray("workouts").getJSONObject(0).getString("title"))
    }
}
