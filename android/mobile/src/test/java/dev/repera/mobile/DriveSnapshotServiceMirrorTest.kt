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
    private class FakeDrive(
        var bytes: ByteArray?,
        var failPatch: Boolean = false,
        var preconditionFailPatch: Boolean = false,
        /** ETag original del archivo leído (formato Drive con comillas). */
        var etag: String = "\"etag-rev1\""
    ) : Interceptor {
        var patches = 0
        var lastIfMatch: String? = null
        var beforeDownload:(()->Unit)?=null
        override fun intercept(chain: Interceptor.Chain): Response {
            val req = chain.request()
            val url = req.url.toString()
            fun ok(body: ByteArray, withEtag: Boolean = false): Response {
                val builder = Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(200).message("OK")
                    .body(body.toResponseBody("application/json".toMediaType()))
                if (withEtag) builder.header("ETag", etag)
                return builder.build()
            }
            return when {
                req.method == "GET" && url.contains("alt=media") -> {
                    beforeDownload?.invoke()
                    ok(bytes!!, withEtag = true)
                }
                // Listado sin `etag`: If-Match usa solo el ETag del GET media.
                req.method == "GET" -> ok((if (bytes == null) """{"files":[]}""" else
                    """{"files":[{"id":"f1","name":"app_state.json"}]}"""
                    ).toByteArray())
                req.method == "PATCH" -> {
                    patches++
                    lastIfMatch = req.header("If-Match")
                    when {
                        preconditionFailPatch ->
                            Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(412).message("Precondition Failed")
                                .body("".toResponseBody(null)).build()
                        failPatch ->
                            Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(500).message("err")
                                .body("".toResponseBody(null)).build()
                        else -> {
                            val b = okio.Buffer(); req.body!!.writeTo(b); bytes = b.readByteArray(); ok(ByteArray(0))
                        }
                    }
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
        val ex = JSONArray(java.io.File("src/main/assets/catalog_seed.json").readText())
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

    @Test fun recoveredWorkoutMissingFromDriveIsNotUploadedAndKeepsLocalAndConflict() {
        val n = workout("new", finished = "2026-10-20T10:00:00Z")
        val localBytes = doc(listOf(n), 1)
        val drive = FakeDrive(doc(listOf(workout("old")), 7, listOf("r")))
        val remoteBefore = drive.bytes!!.copyOf()
        val local = FakeLocal(localBytes, prov(n))
        assertEquals(DriveSnapshotService.Outcome.Conflict, svc(drive, local).synchronize())
        assertEquals(0, drive.patches)
        assertTrue(drive.bytes!!.contentEquals(remoteBefore))
        assertTrue(local.bytes!!.contentEquals(localBytes))
    }

    @Test fun downloadIsIdempotentOnRepeat() {
        val a = workout("a")
        val drive = FakeDrive(doc(listOf(a, workout("b")), 7))
        val local = FakeLocal(doc(listOf(a), 1), prov(a))
        val failing = FakeLocal(local.bytes, local.prov)
        assertEquals(DriveSnapshotService.Outcome.Downloaded, svc(drive, failing).synchronize())
        assertEquals(setOf("a", "b"), ids(failing.bytes))
        // idempotente: repetir con el resultado ya local no cambia nada
        assertEquals(DriveSnapshotService.Outcome.Unchanged, svc(drive, failing).synchronize())
    }

    @Test fun independentLocalDataStillRaisesConflict() {
        val a = workout("a")
        val drive = FakeDrive(doc(listOf(workout("b")), 7))
        val local = FakeLocal(doc(listOf(a), 1, routines = listOf("mine")), prov(a))
        assertEquals(DriveSnapshotService.Outcome.Conflict, svc(drive, local).synchronize())
        assertEquals(0, drive.patches)
    }

    @Test fun workoutDeletedLocallyAfterRecoveryNeverReachesDrive() {
        val a = workout("a"); val b = workout("b")
        val drive = FakeDrive(doc(listOf(workout("old")), 7))
        val local = FakeLocal(doc(listOf(a), 1), prov(a, b)) // b se recuperó y luego se borró en local
        assertEquals(DriveSnapshotService.Outcome.Conflict, svc(drive, local).synchronize())
        assertEquals(setOf("old"), ids(drive.bytes))
        assertEquals(0, drive.patches)
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
    private fun virgin():ByteArray=JSONObject(String(doc(emptyList(),0))).put("updatedAt","1970-01-01T00:00:00Z")
        .put("lastWriterDeviceId","").toString().toByteArray()
    @Test fun realCurrentBootstrapDownloadsHistoryInsteadOfFalselyConflicting() {
        val drive=FakeDrive(doc(listOf(workout("saved")),7))
        val local=FakeLocal(virgin(),emptyMap())
        assertEquals(DriveSnapshotService.Outcome.Downloaded,svc(drive,local).synchronize())
        assertEquals(0,drive.patches)
        assertEquals(setOf("saved"),ids(local.bytes))
    }
    @Test fun favoriteEditIsNotVirginAndEqualVersionKeepsBothCopies() {
        val favorite=JSONObject(String(virgin()))
        favorite.getJSONArray("exercises").getJSONObject(0).put("isFavorite",true)
        val localBytes=favorite.toString().toByteArray()
        val remote=JSONObject(String(virgin())).put("settings",JSONObject().put("privateChoice",true)).toString().toByteArray()
        val drive=FakeDrive(remote);val local=FakeLocal(localBytes,emptyMap())
        assertEquals(DriveSnapshotService.Outcome.Conflict,svc(drive,local).synchronize())
        assertArrayEquals(localBytes,local.bytes);assertArrayEquals(remote,drive.bytes)
        assertEquals(0,drive.patches)
    }
    @Test fun localChangeDuringDownloadIsNotOverwritten() {
        val drive=FakeDrive(doc(listOf(workout("saved")),7))
        val local=FakeLocal(virgin(),emptyMap())
        val edited=JSONObject(String(virgin())).put("settings",JSONObject().put("weightIncrementKg",5.0)).toString().toByteArray()
        drive.beforeDownload={local.bytes=edited}
        assertEquals(DriveSnapshotService.Outcome.Conflict,svc(drive,local).synchronize())
        assertArrayEquals(edited,local.bytes);assertEquals(0,drive.patches)
    }
    @Test fun bootstrapCreatedWhileEmptyLocalDownloadRunsIsPreserved() {
        val drive=FakeDrive(doc(listOf(workout("saved")),7));val local=FakeLocal(null,emptyMap())
        val created=doc(listOf(workout("mine")),1)
        drive.beforeDownload={local.bytes=created}
        assertEquals(DriveSnapshotService.Outcome.Conflict,svc(drive,local).synchronize())
        assertArrayEquals(created,local.bytes)
    }
    @Test fun accountRevokedDuringDownloadDoesNotReplaceLocalState() {
        val start=virgin();val drive=FakeDrive(doc(listOf(workout("saved")),7));val local=FakeLocal(start,emptyMap())
        var authorized=true
        drive.beforeDownload={authorized=false}
        val service=DriveSnapshotService("t",local,OkHttpClient.Builder().addInterceptor(drive).build(),{authorized})
        assertTrue(runCatching {service.synchronize()}.isFailure)
        assertArrayEquals(start,local.bytes);assertEquals(0,drive.patches)
    }
    @Test fun revokedSyncMakesNoNetworkRequest() {
        val drive=FakeDrive(doc(listOf(workout("saved")),7));val start=virgin();val local=FakeLocal(start,emptyMap())
        val service=DriveSnapshotService("t",local,OkHttpClient.Builder().addInterceptor(drive).build(),{false})
        assertTrue(runCatching {service.synchronize()}.isFailure)
        assertArrayEquals(start,local.bytes);assertEquals(0,drive.patches)
    }

    @Test fun concurrentRemoteChangeReturnsPreconditionFailedWithoutClobber() {
        // Mismo conjunto de IDs (no Conflict por historiales divergentes); gana
        // la revisión local y el PATCH choca con If-Match → PreconditionFailed.
        val shared = listOf(workout("a"))
        val localDoc = doc(shared, 9)
        val remoteDoc = doc(shared, 3)
        val drive = FakeDrive(remoteDoc, preconditionFailPatch = true, etag = "\"etag-rev-a\"")
        val local = FakeLocal(localDoc, emptyMap())
        val remoteBefore = drive.bytes!!.copyOf()
        assertEquals(DriveSnapshotService.Outcome.PreconditionFailed, svc(drive, local).synchronize())
        assertEquals(1, drive.patches)
        assertEquals("\"etag-rev-a\"", drive.lastIfMatch)
        assertTrue(drive.bytes!!.contentEquals(remoteBefore))
        assertTrue(local.bytes!!.contentEquals(localDoc))
    }
}
