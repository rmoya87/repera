package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import dev.repera.domain.CloudHistoryConflict
import java.io.ByteArrayOutputStream
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.util.concurrent.TimeUnit
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

/**
 * Drive appDataFolder via a short-lived AuthorizationClient OAuth access token.
 * No broad Google Drive scope, service-role key, or persistent bearer token.
 */
class DriveSnapshotService(
    private val token: String,
    private val local: SnapshotStorage,
    private val client: OkHttpClient = OkHttpClient.Builder().callTimeout(45, TimeUnit.SECONDS).build(),
    private val stillAuthorized:()->Boolean = {true}
) {
    sealed interface Outcome {
        data object Empty : Outcome
        data object Unchanged : Outcome
        data object Uploaded : Outcome
        data object Downloaded : Outcome
        data object Conflict : Outcome
        /** Remoto cambió entre lectura y PATCH (If-Match 412). */
        data object PreconditionFailed : Outcome
    }

    class PreconditionFailedException(message: String = "Google Drive HTTP 412") :
        IllegalStateException(message)

    fun synchronize(): Outcome = CloudSyncGate.driveSync { synchronizeInternal() }

    private fun checkAuthority() {check(stillAuthorized()) {"La cuenta cambió durante la sincronización de Drive"}}
    private fun applyDownload(expected:ByteArray?,remote:ByteArray):Outcome {
        checkAuthority()
        return if(local.replaceIfUnchanged(expected,remote)) Outcome.Downloaded else Outcome.Conflict
    }

    private fun synchronizeInternal(): Outcome {
        checkAuthority()
        val remoteMeta = findSingleFile()
        val remoteId = remoteMeta?.id
        val localBytes = local.read()
        // ETag de la versión leída (cabecera HTTP del GET media; fallback listado).
        val remoteDownload = remoteId?.let { downloadMedia(it) }
        val remoteBytes = remoteDownload?.body
        val readEtag = remoteDownload?.etag ?: remoteMeta?.etag
        if (localBytes == null && remoteBytes == null) return Outcome.Empty
        if (localBytes == null && remoteBytes != null) {
            return applyDownload(localBytes,remoteBytes)
        }
        if (localBytes != null && remoteBytes == null) {
            create(localBytes)
            return Outcome.Uploaded
        }
        check(localBytes != null && remoteBytes != null && remoteId != null)
        LocalSnapshotStore.validate(localBytes)
        LocalSnapshotStore.validate(remoteBytes)
        if (localBytes.contentEquals(remoteBytes)) return Outcome.Unchanged
        // A freshly created catalog cannot supersede an existing athlete history,
        // even if that history uses the legacy revision=0 or distant-past date.
        if (isVirgin(localBytes) && !isVirgin(remoteBytes)) {
            return applyDownload(localBytes,remoteBytes)
        }
        if (!isVirgin(localBytes) && isVirgin(remoteBytes)) {
            local.preserveRemoteBackup(remoteBytes)
            return uploadWithMatch(remoteId, localBytes, readEtag)
        }
        // Local = catálogo virgen + entrenos recuperados del espejo sin editar: no es historial independiente.
        // Cualquier otra diferencia local cae al camino normal (con su Conflict).
        when (MirrorRecoveryReconciler.reconcile(
            localBytes, remoteBytes, local.readMirrorProvenance(), Instant.now().toString())) {
            MirrorRecoveryReconciler.Result.UseRemote -> { return applyDownload(localBytes,remoteBytes) }
            MirrorRecoveryReconciler.Result.NotApplicable -> Unit
        }
        if (divergentTraining(localBytes, remoteBytes)) return Outcome.Conflict

        val localVersion = version(localBytes)
        val remoteVersion = version(remoteBytes)
        // Preserve conflicting histories instead of overwriting distinct concurrent edits.
        if (localVersion == remoteVersion) return Outcome.Conflict

        val localWins = compareValues(localVersion, remoteVersion) > 0
        return if (localWins) {
            local.preserveRemoteBackup(remoteBytes)
            uploadWithMatch(remoteId, localBytes, readEtag)
        } else {
            // Compare under the storage lock: never replace edits made during the Drive request.
            applyDownload(localBytes,remoteBytes)
        }
    }

    private fun uploadWithMatch(
        id: String,
        bytes: ByteArray,
        etag: String?
    ): Outcome {
        return try {
            update(id, bytes, etag)
            Outcome.Uploaded
        } catch (_: PreconditionFailedException) {
            Outcome.PreconditionFailed
        }
    }

    /**
     * Only CatalogBootstrap's exact untouched sentinel is disposable.
     * A legacy iOS backup can have revision 0 and no workouts while still holding
     * a body-weight log, preferences or custom exercises: never discard it.
     */
    private fun isVirgin(bytes: ByteArray): Boolean =
        PristineCatalogState.virgin(JSONObject(String(bytes, Charsets.UTF_8)))

    /** Two independent edits must never silently overwrite each other. */
    private fun divergentTraining(local: ByteArray, remote: ByteArray): Boolean {
        val a = JSONObject(String(local, Charsets.UTF_8))
        val b = JSONObject(String(remote, Charsets.UTF_8))
        fun ids(json: JSONObject): Set<String> {
            return listOf("workouts", "routines").flatMap { field ->
                val array = json.optJSONArray(field) ?: JSONArray()
                (0 until array.length()).map { field + ":" + array.getJSONObject(it).getString("id") }
            }.toSet()
        }
        return CloudHistoryConflict.requiresManualResolution(
            ids(a), ids(b),
            a.optJSONObject("activeSession")?.toString(),
            b.optJSONObject("activeSession")?.toString()
        )
    }

    private data class Version(val revision: Int, val instant: Instant, val writer: String)

    private fun version(bytes: ByteArray): Version {
        val json = JSONObject(String(bytes, Charsets.UTF_8))
        val instant = runCatching {
            Instant.parse(json.optString("updatedAt"))
        }.getOrDefault(Instant.EPOCH)
        return Version(json.optInt("syncRevision", 0), instant, json.optString("lastWriterDeviceId"))
    }

    /** Same revision → timestamp → writer order as iOS SyncConflictResolver. */
    private fun compareValues(a: Version, b: Version): Int {
        val revision = a.revision.compareTo(b.revision)
        if (revision != 0) return revision
        val instant = a.instant.compareTo(b.instant)
        return if (instant != 0) instant else a.writer.compareTo(b.writer)
    }

    private data class RemoteFile(val id: String, val etag: String?)
    private data class MediaDownload(val body: ByteArray, val etag: String?)

    private fun findSingleFile(): RemoteFile? {
        val url = "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder" +
            "&fields=nextPageToken%2Cfiles(id%2Cname%2Cetag)&pageSize=100" +
            "&q=" + encode("name = 'app_state.json' and trashed = false")
        val result = JSONObject(String(request("GET", url), Charsets.UTF_8))
        val files = result.optJSONArray("files") ?: JSONArray()
        require(files.length() <= 1 && !result.has("nextPageToken")) {
            "Varias copias remotas: resolver antes de sincronizar"
        }
        if (files.length() != 1) return null
        val file = files.getJSONObject(0)
        return RemoteFile(
            id = file.getString("id"),
            etag = file.optString("etag").takeIf { it.isNotBlank() && it != "null" }
        )
    }

    /** Descarga el contenido y conserva el ETag original de la respuesta HTTP. */
    private fun downloadMedia(id: String): MediaDownload {
        val payload = requestWithEtag(
            "GET",
            "https://www.googleapis.com/drive/v3/files/" + encode(id) + "?alt=media"
        )
        return MediaDownload(payload.body, payload.etag)
    }

    private fun create(bytes: ByteArray) {
        LocalSnapshotStore.validate(bytes)
        val boundary = "repera_" + System.nanoTime()
        val media = ByteArrayOutputStream()
        media.write(("--" + boundary + "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n" +
            "{\"name\":\"app_state.json\",\"parents\":[\"appDataFolder\"]}\r\n").toByteArray())
        media.write(("--" + boundary + "\r\nContent-Type: application/json\r\n\r\n").toByteArray())
        media.write(bytes)
        media.write(("\r\n--" + boundary + "--\r\n").toByteArray())
        request("POST", "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart",
            "multipart/related; boundary=$boundary", media.toByteArray())
    }

    private fun update(id: String, bytes: ByteArray, etag: String? = null) {
        val headers = linkedMapOf<String, String>()
        // If-Match compara la etiqueta de entidad del archivo (ETag), no headRevisionId.
        if (!etag.isNullOrBlank()) {
            headers["If-Match"] = etag
        }
        request(
            "PATCH",
            "https://www.googleapis.com/upload/drive/v3/files/" + encode(id) + "?uploadType=media",
            "application/json",
            bytes,
            headers
        )
    }

    private data class HttpPayload(val body: ByteArray, val etag: String?)

    private fun request(
        method: String,
        path: String,
        contentType: String? = null,
        bytes: ByteArray? = null,
        extraHeaders: Map<String, String> = emptyMap()
    ): ByteArray = requestWithEtag(method, path, contentType, bytes, extraHeaders).body

    private fun requestWithEtag(
        method: String,
        path: String,
        contentType: String? = null,
        bytes: ByteArray? = null,
        extraHeaders: Map<String, String> = emptyMap()
    ): HttpPayload {
        checkAuthority()
        val body = bytes?.toRequestBody((contentType ?: "application/octet-stream").toMediaType())
        val builder = Request.Builder()
            .url(path)
            .header("Authorization", "Bearer $token")
            .method(method, body)
        extraHeaders.forEach { (k, v) -> builder.header(k, v) }
        val request = builder.build()
        client.newCall(request).execute().use { response ->
            if (response.code == 412) {
                throw PreconditionFailedException()
            }
            if (!response.isSuccessful) {
                throw IllegalStateException("Google Drive HTTP " + response.code)
            }
            val received = response.body?.bytes() ?: byteArrayOf()
            // Conservar el formato original del ETag (incluidas comillas si las trae).
            val etag = response.header("ETag")?.takeIf { it.isNotBlank() }
                ?: response.header("Etag")?.takeIf { it.isNotBlank() }
            checkAuthority()
            return HttpPayload(received, etag)
        }
    }

    private fun encode(s: String): String =
        URLEncoder.encode(s, StandardCharsets.UTF_8.name())
}
