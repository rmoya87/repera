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
 * huellas SHA-256, tombstones con outbox persistente, paginación de 200 y
 * payload privatizado (nunca notas, valoraciones, ubicación, GPS ni Salud).
 *
 * No portado en este chunk (siguiente): recuperación remota→local de entrenos
 * desconocidos (segundo dispositivo), backfill de snapshots de bloques legacy
 * (requiere SyncConflictResolver) y los toggles de compartir por centro.
 * Divergencia consciente y temporal, reportada al coordinador.
 */
class WorkoutMirrorStore(
    context: Context,
    private val userId: String,
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(30, TimeUnit.SECONDS).build()
) {
    private val prefs = context.getSharedPreferences(
        "repera.mirror.$userId", Context.MODE_PRIVATE)

    data class Result(
        val ok: Boolean,
        val mirroredCount: Int = 0,
        val uploaded: Int = 0,
        val tombstoned: Int = 0,
        val error: String? = null
    )

    /** Llamar ANTES de borrar un entreno: el tombstone sobrevive a cortes. */
    fun noteDeleted(id: String) {
        val pending = pendingDeletes().toMutableSet()
        if (pending.add(id)) {
            prefs.edit().putStringSet(KEY_DELETED, pending).apply()
        }
    }

    fun pendingDeletes(): Set<String> =
        prefs.getStringSet(KEY_DELETED, emptySet()) ?: emptySet()

    private fun fingerprints(): MutableMap<String, String> {
        val raw = prefs.getString(KEY_FINGERPRINTS, null) ?: return mutableMapOf()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return mutableMapOf()
        val map = mutableMapOf<String, String>()
        json.keys().forEach { map[it] = json.getString(it) }
        return map
    }

    private fun saveFingerprints(map: Map<String, String>) {
        val json = JSONObject()
        map.forEach { (k, v) -> json.put(k, v) }
        prefs.edit().putString(KEY_FINGERPRINTS, json.toString()).apply()
    }

    fun sync(session: SupabaseIdentity.Session,
             repository: WorkoutRepository): Result {
        return try {
            val remote = fetchRemote(session)
            val seen = fingerprints()
            val existing = remote.associateBy { it.getString("id") }
            val deletionIDs = pendingDeletes()

            // 1) Tombstones: propagan borrados aunque se hicieran sin red.
            var tombstoned = 0
            if (deletionIDs.isNotEmpty()) {
                val rows = JSONArray()
                deletionIDs.forEach { id ->
                    rows.put(JSONObject()
                        .put("id", id)
                        .put("owner_id", userId)
                        .put("title", "Entrenamiento eliminado")
                        .put("payload", JSONObject())
                        .put("deleted_at", Instant.now().toString())
                        .put("updated_at", Instant.now().toString()))
                }
                upsert(session, rows)
                tombstoned = rows.length()
                prefs.edit().putStringSet(KEY_DELETED, emptySet()).apply()
                deletionIDs.forEach { seen.remove(it) }
            }

            // 2) Subida de entrenos terminados nuevos o editados.
            //    Un registro remoto que este dispositivo nunca ha visto NO se
            //    sobrescribe (puede venir editado de otro dispositivo).
            val uploads = JSONArray()
            val digests = mutableMapOf<String, String>()
            for (workout in repository.finishedWorkoutsSnapshot()) {
                val id = workout.optString("id")
                if (id.isBlank() || deletionIDs.contains(id)) continue
                val remoteRow = existing[id]
                if (remoteRow != null && !remoteRow.isNull("deleted_at")) continue
                val clean = privatize(workout)
                val checksum = canonicalDigest(clean)
                if (remoteRow != null && seen[id] == null) {
                    // Primera sincronización de este dispositivo: no pisar.
                    seen[id] = checksum
                    continue
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
            saveFingerprints(seen)
            val mirrored = (remote.filter { it.isNull("deleted_at") }
                .map { it.getString("id") }.toSet() +
                (0 until uploads.length()).map {
                    uploads.getJSONObject(it).getString("id")
                }).size
            Result(ok = true, mirroredCount = mirrored,
                uploaded = uploaded, tombstoned = tombstoned)
        } catch (error: Exception) {
            Result(ok = false,
                error = "La sincronización con Supabase está pendiente: " +
                    (error.localizedMessage ?: ""))
        }
    }

    private fun fetchRemote(session: SupabaseIdentity.Session): List<JSONObject> {
        val rows = mutableListOf<JSONObject>()
        var offset = 0
        while (offset < 20_000) {
            val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_mirror" +
                "?select=id,payload,deleted_at&owner_id=eq.$userId" +
                "&order=finished_at.desc&limit=200&offset=$offset"
            val request = Request.Builder().url(url)
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .get().build()
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful)
                    throw IllegalStateException("HTTP " + response.code)
                val page = JSONArray(body)
                for (i in 0 until page.length()) rows.add(page.getJSONObject(i))
                if (page.length() < 200) return rows
                offset += page.length()
            }
        }
        return rows
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
            http.newCall(request).execute().use { response ->
                if (!response.isSuccessful)
                    throw IllegalStateException("HTTP " + response.code)
            }
            offset = end
        }
    }

    companion object {
        private const val KEY_FINGERPRINTS = "fingerprints"
        private const val KEY_DELETED = "deleted"

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
