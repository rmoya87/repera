package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
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
class DriveSnapshotService(private val token: String, private val local: LocalSnapshotStore) {
    private val client = OkHttpClient.Builder()
        .callTimeout(45, TimeUnit.SECONDS)
        .build()

    sealed interface Outcome {
        data object Empty : Outcome
        data object Unchanged : Outcome
        data object Uploaded : Outcome
        data object Downloaded : Outcome
        data object Conflict : Outcome
    }

    fun synchronize(): Outcome {
        val remoteId = findSingleFile()
        val localBytes = local.read()
        val remoteBytes = remoteId?.let { request(
            "GET", "https://www.googleapis.com/drive/v3/files/" + encode(it) + "?alt=media"
        ) }
        if (localBytes == null && remoteBytes == null) return Outcome.Empty
        if (localBytes == null && remoteBytes != null) {
            local.write(remoteBytes)
            return Outcome.Downloaded
        }
        if (localBytes != null && remoteBytes == null) {
            create(localBytes)
            return Outcome.Uploaded
        }
        check(localBytes != null && remoteBytes != null && remoteId != null)
        LocalSnapshotStore.validate(localBytes)
        LocalSnapshotStore.validate(remoteBytes)
        if (localBytes.contentEquals(remoteBytes)) return Outcome.Unchanged

        val localVersion = version(localBytes)
        val remoteVersion = version(remoteBytes)
        // Preserve conflicting histories instead of overwriting distinct concurrent edits.
        if (localVersion == remoteVersion) return Outcome.Conflict

        val localWins = compareValues(localVersion, remoteVersion) > 0
        return if (localWins) {
            local.preserveRemoteBackup(remoteBytes)
            update(remoteId, localBytes)
            Outcome.Uploaded
        } else {
            local.write(remoteBytes) // preserves prior local document as recovery backup
            Outcome.Downloaded
        }
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

    private fun findSingleFile(): String? {
        val url = "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder" +
            "&fields=nextPageToken%2Cfiles(id%2Cname)&pageSize=100" +
            "&q=" + encode("name = 'app_state.json' and trashed = false")
        val result = JSONObject(String(request("GET", url), Charsets.UTF_8))
        val files = result.optJSONArray("files") ?: JSONArray()
        require(files.length() <= 1 && !result.has("nextPageToken")) {
            "Varias copias remotas: resolver antes de sincronizar"
        }
        return if (files.length() == 1) files.getJSONObject(0).getString("id") else null
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

    private fun update(id: String, bytes: ByteArray) {
        request("PATCH", "https://www.googleapis.com/upload/drive/v3/files/" +
            encode(id) + "?uploadType=media", "application/json", bytes)
    }

    private fun request(
        method: String, path: String, contentType: String? = null, bytes: ByteArray? = null
    ): ByteArray {
        val body = bytes?.toRequestBody((contentType ?: "application/octet-stream").toMediaType())
        val request = Request.Builder()
            .url(path)
            .header("Authorization", "Bearer $token")
            .method(method, body)
            .build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IllegalStateException("Google Drive HTTP " + response.code)
            }
            return response.body?.bytes() ?: byteArrayOf()
        }
    }

    private fun encode(s: String): String =
        URLEncoder.encode(s, StandardCharsets.UTF_8.name())
}
