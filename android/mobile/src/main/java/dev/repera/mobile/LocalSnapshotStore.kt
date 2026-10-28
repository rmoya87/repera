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
class LocalSnapshotStore(context: Context, uniqueGoogleId: String) : SnapshotStorage {
    private val folder = File(context.filesDir, "users/" + sha256(uniqueGoogleId))
        .apply { mkdirs() }
    private val stateLock=locks.computeIfAbsent(folder.absolutePath) {Any()}
    private val stateFile = AtomicFile(File(folder, "app_state.json"))
    private val backup = File(folder, "previous_app_state.json")
    private val remoteBackup = AtomicFile(File(folder, "remote_before_upload.json"))

    override fun read(): ByteArray? = synchronized(stateLock) {
        // openRead recovers an interrupted AtomicFile write, even if base is absent.
        try {stateFile.openRead().use {it.readBytes()}} catch(_:java.io.FileNotFoundException) {null}
    }

    override fun replaceIfUnchanged(expected:ByteArray?,replacement:ByteArray):Boolean = synchronized(stateLock) {
        val current=read()
        if(!(current==null && expected==null || current!=null && expected!=null && current.contentEquals(expected))) return@synchronized false
        write(replacement)
        true
    }

    override fun write(bytes: ByteArray) = synchronized(stateLock) {
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
    override fun preserveRemoteBackup(bytes: ByteArray) = synchronized(stateLock) {
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

    private val provenanceFile = AtomicFile(File(folder, "mirror_recovered.json"))

    /** Provenance must survive interruption; loss must never turn edited local history into pristine. */
    override fun readMirrorProvenance(): Map<String, String> = synchronized(stateLock) {
        runCatching {
            val json=provenanceFile.openRead().bufferedReader().use {JSONObject(it.readText())}
            json.keys().asSequence().associateWith {json.getString(it)}
        }.getOrDefault(emptyMap())
    }

    fun addMirrorProvenance(entries: Map<String, String>) = synchronized(stateLock) {
        val merged=readMirrorProvenance()+entries
        val stream=provenanceFile.startWrite()
        try {
            stream.write(JSONObject(merged).toString().toByteArray(Charsets.UTF_8))
            provenanceFile.finishWrite(stream)
        } catch(error:Exception) {
            provenanceFile.failWrite(stream)
            throw error
        }
    }

    fun snapshotRevision(): Int? = read()?.let { JSONObject(String(it, Charsets.UTF_8)).optInt("syncRevision", 0) }

    companion object {
        private val locks=java.util.concurrent.ConcurrentHashMap<String,Any>()
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
