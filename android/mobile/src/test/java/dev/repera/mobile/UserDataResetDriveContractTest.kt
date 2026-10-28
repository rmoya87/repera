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
 * Ensayos (Drive simulado en memoria, sin red ni cuentas) del contrato de reset ANTES de exponer "Borrar todo".
 * Las pruebas *Characterization* documentan huecos reales del diseno actual (revision +1 sin epoca de reset):
 * no son garantias; cuando exista epoca deben cambiar de aserto.
 */
class UserDataResetDriveContractTest {
    private class FakeDrive(var bytes: ByteArray?, var failPatch: Boolean = false) : Interceptor {
        var patches = 0
        override fun intercept(chain: Interceptor.Chain): Response {
            val req = chain.request(); val url = req.url.toString()
            fun ok(b: ByteArray, withEtag: Boolean = false): Response {
                val builder = Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(200).message("OK")
                    .body(b.toResponseBody("application/json".toMediaType()))
                if (withEtag) builder.header("ETag", "\"etag-rev1\"")
                return builder.build()
            }
            return when {
                req.method == "GET" && url.contains("alt=media") -> ok(bytes!!, withEtag = true)
                req.method == "GET" -> ok((if (bytes == null) """{"files":[]}""" else """{"files":[{"id":"f1","name":"app_state.json"}]}""").toByteArray())
                req.method == "PATCH" -> {
                    patches++
                    if (failPatch) Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(500).message("err")
                        .body("".toResponseBody(null)).build()
                    else { val b = okio.Buffer(); req.body!!.writeTo(b); bytes = b.readByteArray(); ok(ByteArray(0)) }
                }
                else -> error("peticion inesperada")
            }
        }
    }
    private class FakeLocal(var bytes: ByteArray?) : SnapshotStorage {
        override fun read() = bytes
        override fun write(bytes: ByteArray) { this.bytes = bytes }
        override fun preserveRemoteBackup(bytes: ByteArray) {}
        override fun readMirrorProvenance() = emptyMap<String, String>()
    }

    private fun workout(id: String) = JSONObject().put("id", id).put("title", "W$id")
        .put("finishedAt", "2026-10-01T10:00:00Z").put("exercises", JSONArray())
    private fun doc(ids: List<String>, rev: Int, updated: String = "2026-10-02T00:00:00Z", writer: String = "dev"): JSONObject {
        val ex = JSONArray(java.io.File("src/main/assets/catalog_seed.json").readText())
        return JSONObject().put("exercises", ex).put("routines", JSONArray().put(JSONObject().put("id", "r1")))
            .put("workouts", JSONArray().also { a -> ids.forEach { a.put(workout(it)) } })
            .put("bodyWeights", JSONArray().put(JSONObject().put("id", "b1"))).put("favoriteTimers", JSONArray())
            .put("settings", JSONObject().put("k", 1)).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", rev).put("updatedAt", updated).put("lastWriterDeviceId", writer)
    }
    /** Lo que deja WorkoutRepository.resetUserData sobre el documento (clear + save con revision+1). */
    private fun afterReset(d: JSONObject, at: String = "2026-10-26T09:00:00Z"): ByteArray {
        UserDataReset.clear(d)
        d.put("syncRevision", d.getInt("syncRevision") + 1).put("updatedAt", at).put("lastWriterDeviceId", "me")
        return d.toString().toByteArray()
    }
    private fun ids(b: ByteArray?): Set<String> = JSONObject(String(b!!)).getJSONArray("workouts").let { a ->
        (0 until a.length()).map { a.getJSONObject(it).getString("id") }.toSet() }
    private fun svc(d: FakeDrive, l: FakeLocal) = DriveSnapshotService("t", l, OkHttpClient.Builder().addInterceptor(d).build())

    @Test fun singleDeviceInSyncResetUploadsEmptyHistory() {
        val drive = FakeDrive(doc(listOf("a", "b"), 5).toString().toByteArray())
        val local = FakeLocal(afterReset(doc(listOf("a", "b"), 5)))
        assertEquals(DriveSnapshotService.Outcome.Uploaded, svc(drive, local).synchronize())
        assertEquals(emptySet<String>(), ids(drive.bytes))
    }

    @Test fun uploadFailureKeepsLocalResetAndRetryConverges() {
        val drive = FakeDrive(doc(listOf("a"), 5).toString().toByteArray(), failPatch = true)
        val local = FakeLocal(afterReset(doc(listOf("a"), 5)))
        val before = local.bytes!!.copyOf()
        assertTrue(runCatching { svc(drive, local).synchronize() }.isFailure)
        assertTrue(local.bytes!!.contentEquals(before))
        assertEquals(setOf("a"), ids(drive.bytes))
        drive.failPatch = false
        assertEquals(DriveSnapshotService.Outcome.Uploaded, svc(drive, local).synchronize())
        assertEquals(emptySet<String>(), ids(drive.bytes))
        assertEquals(DriveSnapshotService.Outcome.Unchanged, svc(drive, local).synchronize())
    }

    @Test fun characterizationOtherDeviceWithHigherRevisionResurrectsHistory() {
        // Hueco conocido: sin epoca de reset, una revision remota mayor gana y restaura entrenos.
        val drive = FakeDrive(doc(listOf("a", "b", "c"), 9, writer = "other").toString().toByteArray())
        val local = FakeLocal(afterReset(doc(listOf("a", "b"), 5)))
        assertEquals(DriveSnapshotService.Outcome.Downloaded, svc(drive, local).synchronize())
        assertEquals(setOf("a", "b", "c"), ids(local.bytes))
    }

    @Test fun characterizationEqualRevisionWithOtherWriterIsConflictNotResolved() {
        val drive = FakeDrive(doc(listOf("a", "b"), 6, "2026-10-26T09:00:00Z", "me").toString().toByteArray())
        val local = FakeLocal(afterReset(doc(listOf("a", "b"), 5)))
        val outcome = svc(drive, local).synchronize()
        assertTrue(outcome == DriveSnapshotService.Outcome.Unchanged || outcome == DriveSnapshotService.Outcome.Conflict)
        assertTrue(drive.patches == 0 || outcome != DriveSnapshotService.Outcome.Conflict)
    }

    @Test fun remoteOnlyNewWorkoutFromOtherDeviceDoesNotBlockLocalResetWhenLocalRevisionWins() {
        val drive = FakeDrive(doc(listOf("a", "b", "new"), 5, writer = "other").toString().toByteArray())
        val local = FakeLocal(afterReset(doc(listOf("a", "b"), 5)))
        assertEquals(DriveSnapshotService.Outcome.Uploaded, svc(drive, local).synchronize())
        // Entreno "new" se pierde de Drive sin aviso: otro limite a decidir (se borro algo que este dispositivo nunca vio).
        assertEquals(emptySet<String>(), ids(drive.bytes))
    }

    @Test fun mirrorSelectionNeverRecoversTombstonedIdsButDoesIfTombstonesWereNotWritten() {
        fun row(id: String) = JSONObject().put("id", id).put("payload",
            JSONObject().put("id", id).put("finishedAt", "2026-10-01T10:00:00Z"))
        val remote = listOf(row("a"), row("b"))
        assertTrue(WorkoutMirrorStore.selectRecoverable(remote, emptySet(), setOf("a", "b"), emptyMap()).isEmpty())
        // Corte entre guardar el snapshot vacio y escribir tombstones: resucitan (por eso se escriben ANTES, con el riesgo inverso).
        assertEquals(2, WorkoutMirrorStore.selectRecoverable(remote, emptySet(), emptySet(), emptyMap()).size)
    }

    @Test fun resetRoundTripIsDeterministicOnRepeat() {
        val once = doc(listOf("a"), 5); UserDataReset.clear(once)
        val twice = JSONObject(once.toString()); UserDataReset.clear(twice)
        assertEquals(once.toString(), twice.toString())
        assertEquals(1, once.getJSONObject("settings").getInt("k"))
    }
}
