package dev.repera.mobile

import android.content.Context
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Espejo privado de entrenos terminados (athlete_workout_mirror).
 * Port del núcleo de BusinessWorkoutSyncStore.swift (iOS): subida con
 * huellas SHA-256, DELETE físico con cola temporal offline, paginación de 200 y
 * payload privatizado (nunca notas, valoraciones, ubicación, GPS ni Salud).
 *
 * Incluye recuperación remota→local de entrenos desconocidos (segundo
 * dispositivo) y backfill seguro de snapshots de bloques legacy
 * (canRestoreMissingBlockSnapshot, port de SyncConflictResolver).
 * Pendiente: toggles de compartir por centro (athlete_workout_sharing).
 */
class WorkoutMirrorStore(
    context: Context,
    private val userId: String,
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(30, TimeUnit.SECONDS).build(),
    private val stillAuthorized: () -> Boolean = { true }
) {
    private fun authorize() = check(stillAuthorized()) {"La cuenta cambió durante la sincronización del espejo"}
    private val appContext = context.applicationContext
    private val prefs = context.getSharedPreferences(
        "repera.mirror.$userId", Context.MODE_PRIVATE)

    data class Result(
        val ok: Boolean,
        val mirroredCount: Int = 0,
        val uploaded: Int = 0,
        val tombstoned: Int = 0,
        val recovered: Int = 0,
        val restoredBlockSnapshots: Int = 0,
        val error: String? = null
    )

    init {
        // Migrate older installations: never retain a permanent list of deleted IDs.
        prefs.edit().remove(KEY_DELETED_HISTORY).apply()
    }

    /** Queue the server DELETE only after the local snapshot commit succeeds. */
    fun noteDeleted(id: String) = synchronized(deletionLock) {
        require(runCatching { java.util.UUID.fromString(id) }.isSuccess)
        // Cola de DELETE y protección breve frente a snapshots tardíos del reloj:
        // ambos en una única transacción de SharedPreferences. Tras ACK remoto
        // se retira la cola, pero un reloj desconectado no puede reabrir el UUID.
        val now = System.currentTimeMillis()
        val recent = (recentlyDeleted(now) + (id to (now + REPLAY_GUARD_MS)))
            .entries.sortedByDescending { it.value }.take(REPLAY_GUARD_MAX)
        val json = JSONObject()
        recent.forEach { (workoutId, expiresAt) -> json.put(workoutId, expiresAt) }
        check(prefs.edit()
            .putStringSet(KEY_DELETED, pendingDeletes() + id)
            .putString(KEY_REPLAY_GUARD, json.toString())
            .commit()) {
            "No se pudo encolar la eliminación remota pendiente"
        }
    }

    /** Ventana acotada de anti-replay Wear, no un histórico permanente de borrados. */
    private fun recentlyDeleted(now: Long): Map<String, Long> {
        val raw = prefs.getString(KEY_REPLAY_GUARD, null) ?: return emptyMap()
        val parsed = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return parsed.keys().asSequence().mapNotNull { id ->
            val expiresAt = parsed.optLong(id, 0)
            if (expiresAt > now && expiresAt <= now + REPLAY_GUARD_MS) id to expiresAt
            else null
        }.take(REPLAY_GUARD_MAX).toMap()
    }

    fun pendingDeletes(): Set<String> = synchronized(deletionLock) {
        prefs.getStringSet(KEY_DELETED, emptySet())?.toSet() ?: emptySet()
    }

    /** Compatibility alias: only unacknowledged operations are retained. */
    fun deletedIds():Set<String> = pendingDeletes()

    /** Local snapshots are keyed by Google identity, while Supabase mirrors are
     * keyed by auth.users.id. Move only PENDING deletes after authenticated
     * binding, then remove the obsolete Google-keyed operation queue.
     */
    internal fun importPendingFrom(source: WorkoutMirrorStore) {
        if (source.userId == userId) return
        authorize()
        val sourceIDs = source.pendingDeletes()
        if (sourceIDs.isEmpty()) return
        check(prefs.edit().putStringSet(KEY_DELETED, pendingDeletes() + sourceIDs).commit()) {
            "No se pudo transferir el borrado pendiente al usuario remoto"
        }
        source.acknowledgeDeletes(sourceIDs)
    }

    /** Diario de reset (ResetCoordinator): persistencia sincrona por cuenta. */
    fun loadResetIntent(): String? = synchronized(deletionLock) { prefs.getString(KEY_RESET_INTENT, null) }
    fun storeResetIntent(json: String) = synchronized(deletionLock) {
        check(prefs.edit().putString(KEY_RESET_INTENT, json).commit()) {"No se pudo guardar la intencion de reset"}
    }
    fun clearResetIntent() = synchronized(deletionLock) {
        check(prefs.edit().remove(KEY_RESET_INTENT).commit()) {"No se pudo borrar la intencion de reset"}
    }

    /** Pending deletes, unfinished reset and bounded protection from stale Wear snapshots. */
    fun blockedIds(): Set<String> = synchronized(deletionLock) {
        pendingDeletes() + recentlyDeleted(System.currentTimeMillis()).keys +
            (loadResetIntent()?.let { runCatching {
            val a = JSONObject(it).getJSONArray("ids"); (0 until a.length()).map { i -> a.getString(i) }
        }.getOrDefault(emptyList()) } ?: emptyList())
    }

    internal fun acknowledgeDeletes(ids:Set<String>) = synchronized(deletionLock) {
        // A concurrent new deletion must survive the network ACK.
        val remaining = pendingDeletes() - ids
        val edit = prefs.edit().remove(KEY_DELETED_HISTORY)
        if (remaining.isEmpty()) edit.remove(KEY_DELETED)
        else edit.putStringSet(KEY_DELETED, remaining)
        check(edit.commit()) { "No se pudo confirmar el borrado remoto" }
    }

    private fun fingerprints(): MutableMap<String, String> {
        val raw = prefs.getString(KEY_FINGERPRINTS, null) ?: return mutableMapOf()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return mutableMapOf()
        val map = mutableMapOf<String, String>()
        json.keys().forEach { map[it] = json.getString(it) }
        return map
    }

    private fun saveFingerprints(map: Map<String, String>) {
        authorize()
        val json = JSONObject()
        map.forEach { (k, v) -> json.put(k, v) }
        prefs.edit().putString(KEY_FINGERPRINTS, json.toString()).apply()
    }

    fun sync(session: SupabaseIdentity.Session,
             repository: WorkoutRepository): Result {
        return try {
            authorize()
            check(session.userId==userId) {"La cuenta no corresponde al espejo"}
            repository.recoverPendingReset()
            repository.transferPendingMirrorDeletesTo(this)
            // Physical DELETE first: a stale remote row must never be recovered
            // between a user's local deletion and the server acknowledgement.
            val deletionIDs = pendingDeletes()
            for (id in deletionIDs) {
                authorize()
                deleteRemote(session, id)
                acknowledgeDeletes(setOf(id))
            }
            val existing = fetchRemoteIndex(session)
            val seen = fingerprints()
            deletionIDs.forEach { seen.remove(it) }
            // On another phone, already-mirrored IDs that vanished on the
            // server are deleted, not new uploads. Keep no deleted-ID ledger.
            val removedRemoteIDs = repository.finishedWorkoutsSnapshot()
                .map { it.optString("id") }
                .filter { it.isNotBlank() && it in seen && it !in existing }
                .toSet()
            if (removedRemoteIDs.isNotEmpty()) {
                val purged = repository.purgePreviouslyMirroredMissingRemotely(removedRemoteIDs)
                if (purged > 0) DriveSyncWorker.syncNow(appContext)
                removedRemoteIDs.forEach { seen.remove(it) }
            }

            // Payload sólo donde una decisión lo necesita: remotos nunca vistos
            // (recuperación) y locales cuyo remoto no consta idéntico.
            val localDigests = repository.finishedWorkoutsSnapshot()
                .associate { it.optString("id") to canonicalDigest(privatize(it)) }
            val payloads = fetchPayloads(session,
                payloadIdsNeeded(existing, localDigests, seen, deletionIDs))

            // 0) Recuperación remota→local: un segundo dispositivo puede
            //    tener entrenos que este aún no conoce. Sólo IDs nunca
            //    vistos, no borrados y con payload íntegro.
            val recoveredCount=CloudSyncGate.recoverUnlessDrive {
                authorize()
                val localIds=repository.finishedWorkoutsSnapshot().map {it.optString("id")}.toSet()
                val recovered=selectRecoverable(payloads.values.toList(),localIds,blockedIds()+repository.mirrorBlockedIds(),seen)
                if(recovered.isEmpty()) 0 else {
                    authorize()
                    repository.recordMirrorRecovered(recovered.associate {it.getString("id") to canonicalDigest(it)})
                    authorize()
                    val merged=repository.mergeRecoveredWorkoutsFromSupabase(recovered)
                    recovered.forEach {seen[it.getString("id")]=canonicalDigest(it)}
                    saveFingerprints(seen)
                    merged
                }
            } ?: 0

            // 1) Already physically deleted above (no empty remote rows).
            val deletedCount = deletionIDs.size

            // 2) Subida de entrenos terminados nuevos o editados.
            //    Un registro remoto que este dispositivo nunca ha visto NO se
            //    sobrescribe (puede venir editado de otro dispositivo).
            val uploads = JSONArray()
            val digests = mutableMapOf<String, String>()
            var restoredBlocks = 0
            val blockedNow = blockedIds() + repository.mirrorBlockedIds()
            for (workout in repository.finishedWorkoutsSnapshot()) {
                val id = workout.optString("id")
                if (id.isBlank() || id in blockedNow) continue
                val remoteRow = existing[id]
                if (remoteRow != null && !remoteRow.isNull("deleted_at")) continue
                val clean = privatize(workout)
                val checksum = canonicalDigest(clean)
                if (remoteRow != null && seen[id] == null) {
                    // Primera sincronización de este dispositivo: no pisar un
                    // remoto quizá editado en otro dispositivo. Única excepción
                    // segura: restaurar el snapshot de bloques que falta en un
                    // WOD legacy cuando TODO lo demás coincide (iOS
                    // SyncConflictResolver.canRestoreMissingBlockSnapshot).
                    val remotePayload = payloads[id]?.optJSONObject("payload")
                    if (remotePayload == null ||
                        !canRestoreMissingBlockSnapshot(clean, remotePayload)) {
                        seen[id] = checksum
                        continue
                    }
                    restoredBlocks += 1
                }
                if (remoteRow != null && seen[id] == checksum) continue
                uploads.put(JSONObject()
                    .put("id", id)
                    .put("owner_id", userId)
                    .put("title", workout.optString("title").take(200))
                    .put("started_at", workout.optString("startedAt")
                        .ifBlank { null })
                    .put("finished_at", workout.optString("finishedAt")
                        .ifBlank { null })
                    .put("payload", clean)
                    .put("updated_at", Instant.now().toString()))
                digests[id] = checksum
            }
            var uploaded = 0
            var offset = 0
            while (offset < uploads.length()) {
                val batch = JSONArray()
                var end = offset
                while (end < uploads.length() && end < offset + 30) {
                    batch.put(uploads.getJSONObject(end)); end++
                }
                upsert(session, batch)
                for (i in 0 until batch.length()) {
                    val id = batch.getJSONObject(i).getString("id")
                    digests[id]?.let { seen[id] = it }
                }
                saveFingerprints(seen)
                uploaded += batch.length()
                offset = end
            }
            // The fingerprint cache covers LIVE remote rows only, not deletions.
            val liveIDs = existing.keys + (0 until uploads.length()).map {
                uploads.getJSONObject(it).getString("id")
            }
            seen.keys.retainAll(liveIDs)
            saveFingerprints(seen)
            val mirrored = (existing.values.filter { it.isNull("deleted_at") }
                .map { it.getString("id") }.toSet() +
                (0 until uploads.length()).map {
                    uploads.getJSONObject(it).getString("id")
                }).size
            Result(ok = true, mirroredCount = mirrored,
                uploaded = uploaded, tombstoned = deletedCount,
                recovered = recoveredCount,
                restoredBlockSnapshots = restoredBlocks)
        } catch (error: Exception) {
            Result(ok = false,
                error = "La sincronización en la nube está pendiente: " +
                    (error.localizedMessage ?: ""))
        }
    }

    private fun deleteRemote(session: SupabaseIdentity.Session, id: String) {
        val safeId = java.util.UUID.fromString(id).toString()
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_mirror" +
            "?owner_id=eq.$userId&id=eq.$safeId"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .delete().build()
        authorize()
        http.newCall(request).execute().use { response ->
            authorize()
            check(response.isSuccessful) {
                "No se pudo eliminar el entrenamiento remoto: HTTP ${response.code}"
            }
        }
    }

    /**
     * Existencia remota sin payload, paginada por la clave primaria inmutable:
     * sin tope de filas y sin que una edición concurrente salte el cursor y
     * parezca un borrado. Se detiene sólo con página vacía (max-rows menor).
     */
    private fun fetchRemoteIndex(session: SupabaseIdentity.Session): Map<String, JSONObject> {
        val rows = linkedMapOf<String, JSONObject>()
        var after: String? = null
        while (true) {
            val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_mirror" +
                "?select=id,deleted_at&owner_id=eq.$userId" +
                (after?.let { "&id=gt.$it" } ?: "") +
                "&order=id.asc&limit=$INDEX_PAGE_SIZE"
            val page = getArray(session, url)
            if (page.length() == 0) return rows
            for (i in 0 until page.length()) {
                val row = page.getJSONObject(i)
                rows[row.getString("id")] = row
            }
            after = java.util.UUID.fromString(page.getJSONObject(page.length() - 1).getString("id")).toString()
        }
    }

    private fun fetchPayloads(session: SupabaseIdentity.Session, ids: List<String>): Map<String, JSONObject> {
        val rows = mutableMapOf<String, JSONObject>()
        for (chunk in ids.chunked(PAYLOAD_CHUNK)) {
            val list = chunk.joinToString(",") { java.util.UUID.fromString(it).toString() }
            val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_mirror" +
                "?select=id,payload,deleted_at&owner_id=eq.$userId&id=in.($list)"
            val page = getArray(session, url)
            for (i in 0 until page.length()) {
                val row = page.getJSONObject(i)
                rows[row.getString("id")] = row
            }
        }
        return rows
    }

    private fun getArray(session: SupabaseIdentity.Session, url: String): JSONArray {
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        authorize()
        http.newCall(request).execute().use { response ->
            authorize()
            val body = response.body.string().orEmpty()
            authorize()
            if (!response.isSuccessful) throw IllegalStateException("HTTP " + response.code)
            return JSONArray(body)
        }
    }

    private fun upsert(session: SupabaseIdentity.Session, rows: JSONArray) {
        if (rows.length() == 0) return
        var offset = 0
        while (offset < rows.length()) {
            val batch = JSONArray()
            var end = offset
            while (end < rows.length() && end < offset + 40) {
                batch.put(rows.getJSONObject(end)); end++
            }
            val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_mirror"
            val request = Request.Builder().url(url)
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .header("Content-Type", "application/json")
                .header("Prefer", "resolution=merge-duplicates")
                .post(batch.toString().toRequestBody("application/json".toMediaType()))
                .build()
            authorize()
            http.newCall(request).execute().use { response ->
                authorize()
                if (!response.isSuccessful)
                    throw IllegalStateException("HTTP " + response.code)
            }
            offset = end
        }
    }

    /** Consentimiento independiente y revocable por centro (iOS
     *  refreshSharing): qué centros vinculados pueden leer resultados. */
    fun refreshSharing(session: SupabaseIdentity.Session): Map<String, Boolean> {
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_sharing" +
            "?select=org_id,enabled&athlete_id=eq.$userId"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        authorize()
        http.newCall(request).execute().use { response ->
            authorize()
            if (!response.isSuccessful)
                throw IllegalStateException("HTTP " + response.code)
            val rows = JSONArray(response.body.string().orEmpty())
            val map = mutableMapOf<String, Boolean>()
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                map[row.getString("org_id")] = row.optBoolean("enabled", false)
            }
            return map
        }
    }

    /** iOS setSharing: exige estar vinculado y activo en el centro. */
    fun setSharing(session: SupabaseIdentity.Session, orgId: String,
                   enabled: Boolean, athleteCenterIds: Set<String>): String? {
        if (!athleteCenterIds.contains(orgId)) {
            return "Debes estar vinculado y activo en el centro para " +
                "compartir tus resultados."
        }
        val row = JSONObject()
            .put("athlete_id", userId)
            .put("org_id", orgId)
            .put("enabled", enabled)
            .put("updated_at", Instant.now().toString())
        val url = BuildConfig.SUPABASE_URL +
            "/rest/v1/athlete_workout_sharing?on_conflict=athlete_id,org_id"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .header("Prefer", "resolution=merge-duplicates")
            .post(JSONArray().put(row).toString()
                .toRequestBody("application/json".toMediaType()))
            .build()
        return try {
            authorize()
            http.newCall(request).execute().use { response ->
                authorize()
                if (response.isSuccessful) null
                else "No se ha podido cambiar el permiso de compartir " +
                    "resultados: HTTP " + response.code
            }
        } catch (error: Exception) {
            "No se ha podido cambiar el permiso de compartir resultados: " +
                (error.localizedMessage ?: "")
        }
    }

    companion object {
        private val deletionLock=Any()
        private const val INDEX_PAGE_SIZE = 1000
        private const val PAYLOAD_CHUNK = 50

        /** Remotos vivos cuyo payload hace falta: nunca vistos sin copia local, o
         *  con copia local cuya huella no coincide con la última subida. */
        internal fun payloadIdsNeeded(
            existing: Map<String, JSONObject>, localDigests: Map<String, String>,
            seen: Map<String, String>, deletionIDs: Set<String>
        ): List<String> = existing.values
            .filter { it.isNull("deleted_at") || !it.has("deleted_at") }
            .map { it.getString("id") }
            .filter { id ->
                id !in deletionIDs && localDigests[id].let { local ->
                    if (local != null) seen[id] != local else seen[id] == null
                }
            }
        /** Filas recuperables: nunca vistas y sin DELETE pendiente; filas legacy se ignoran. */
        internal fun selectRecoverable(
            remote: List<JSONObject>, localIds: Set<String>, deletionIDs: Set<String>, seen: Map<String, String>
        ): List<JSONObject> {
            val out = mutableListOf<JSONObject>()
            for (row in remote) {
                if (!row.isNull("deleted_at") && row.has("deleted_at")) continue
                val id = row.optString("id")
                if (id.isBlank() || localIds.contains(id) || deletionIDs.contains(id) || seen[id] != null) continue
                val payload = row.optJSONObject("payload") ?: continue
                if (payload.optString("id") != id || payload.isNull("finishedAt") || !payload.has("finishedAt")) continue
                out.add(payload)
            }
            return out
        }

        private const val KEY_FINGERPRINTS = "fingerprints"
        private const val KEY_RESET_INTENT = "reset-intent"
        private const val KEY_DELETED = "deleted"
        private const val KEY_DELETED_HISTORY = "deleted-history" // legacy: removed on init
        private const val KEY_REPLAY_GUARD = "recent-stale-wear-sessions"
        private val REPLAY_GUARD_MS = TimeUnit.DAYS.toMillis(30)
        private const val REPLAY_GUARD_MAX = 256

        private val PRIVATE_KEYS = listOf(
            "notes", "sessionReview", "locationPin", "routePoints",
            "healthKitWorkoutUUID", "appleActiveEnergyKcal",
            "appleAverageHeartRateBpm", "appleHealthProvenance",
            "appleDurationSeconds"
        )

        /** Supabase sólo recibe planificación, ejercicio, series y resultados. */
        internal fun privatize(workout: JSONObject): JSONObject {
            val clean = JSONObject(workout.toString())
            PRIVATE_KEYS.forEach { clean.remove(it) }
            return clean
        }

        /** Port de SyncConflictResolver.canRestoreMissingBlockSnapshot:
         * sólo los bloques persistidos en el entreno local pueden enriquecer
         * un espejo legacy sin ellos; todo lo demás debe coincidir exacto. */
        internal fun canRestoreMissingBlockSnapshot(
            localClean: JSONObject, remoteClean: JSONObject): Boolean {
            val blocks = localClean.optJSONArray("routineBlocks")
                ?: return false
            if (blocks.length() == 0) return false
            val remoteBlocks = remoteClean.optJSONArray("routineBlocks")
            if (remoteBlocks != null && remoteBlocks.length() > 0) return false
            val candidate = JSONObject(remoteClean.toString())
            candidate.put("routineBlocks", JSONArray(blocks.toString()))
            return canonicalDigest(candidate) == canonicalDigest(localClean)
        }

        /** SHA-256 sobre JSON canónico (claves ordenadas, sin espacios):
         * equivalente al JSONEncoder(.sortedKeys) + SHA256 de iOS. */
        internal fun canonicalDigest(workout: JSONObject): String {
            val bytes = canonical(workout).toByteArray(Charsets.UTF_8)
            val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
            return digest.joinToString("") { "%02x".format(it) }
        }

        private fun canonical(value: Any?): String = when (value) {
            null, JSONObject.NULL -> "null"
            is JSONObject -> {
                val keys = value.keys().asSequence().toList().sorted()
                keys.joinToString(",", "{", "}") { key ->
                    JSONObject.quote(key) + ":" + canonical(value.get(key))
                }
            }
            is JSONArray -> (0 until value.length()).joinToString(",", "[", "]") {
                canonical(value.get(it))
            }
            is String -> JSONObject.quote(value)
            is Boolean, is Int, is Long -> value.toString()
            is Double, is Float -> {
                // Forma corta determinista (60.0 -> "60"); las huellas son por
                // dispositivo, no hace falta igualdad byte a byte con iOS.
                val d = (value as Number).toDouble()
                if (d.isFinite()) d.toBigDecimal().stripTrailingZeros().toPlainString()
                else "null"
            }
            else -> JSONObject.quote(value.toString())
        }
    }
}
