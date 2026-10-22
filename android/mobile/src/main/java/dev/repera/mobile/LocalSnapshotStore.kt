package dev.repera.mobile

import android.content.Context
import android.util.AtomicFile
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest

/**
 * Account-isolated local-first storage. No Google token is written to disk.
 * State payload stays in ReperaDomain's JSON field schema.
 */
class LocalSnapshotStore(context: Context, uniqueGoogleId: String) {
    private val folder = File(context.filesDir, "users/" + sha256(uniqueGoogleId))
        .apply { mkdirs() }
    private val stateFile = AtomicFile(File(folder, "app_state.json"))
    private val backup = File(folder, "previous_app_state.json")
    private val remoteBackup = AtomicFile(File(folder, "remote_before_upload.json"))

    @Synchronized fun read(): ByteArray? =
        if (stateFile.exists()) stateFile.openRead().use { it.readBytes() } else null

    @Synchronized fun write(bytes: ByteArray) {
        validate(bytes)
        val existing = read()
        if (existing != null && !existing.contentEquals(bytes)) backup.writeBytes(existing)
        val stream = stateFile.startWrite()
        try {
            stream.write(bytes)
            stateFile.finishWrite(stream)
        } catch (error: Exception) {
            stateFile.failWrite(stream)
            throw error
        }
    }

    /** Safeguard a remote document before replacing it with a newer local revision. */
    @Synchronized fun preserveRemoteBackup(bytes: ByteArray) {
        validate(bytes)
        val stream = remoteBackup.startWrite()
        try {
            stream.write(bytes)
            remoteBackup.finishWrite(stream)
        } catch (error: Exception) {
            remoteBackup.failWrite(stream)
            throw error
        }
    }

    fun snapshotRevision(): Int? = read()?.let { JSONObject(String(it, Charsets.UTF_8)).optInt("syncRevision", 0) }

    companion object {
        /** A corrupted or incomplete download is never allowed to replace local history. */
        fun validate(bytes: ByteArray) {
            require(bytes.isNotEmpty() && bytes.size <= 128 * 1024 * 1024) { "Tamaño de estado no válido" }
            val state = JSONObject(String(bytes, Charsets.UTF_8))
            require(state.has("workouts") && state.get("workouts") is org.json.JSONArray)
            require(state.has("routines") && state.get("routines") is org.json.JSONArray)
            require(state.has("exercises") && state.get("exercises") is org.json.JSONArray)
            require(state.optInt("syncRevision", 0) >= 0)
        }

        private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
    }
}
