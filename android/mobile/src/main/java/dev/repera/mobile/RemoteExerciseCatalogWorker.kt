package dev.repera.mobile

import android.content.Context
import android.util.AtomicFile
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.time.Instant
import java.util.UUID
import java.util.concurrent.TimeUnit

/**
 * Global read-only editorial feed, separate from private athlete state and Drive.
 * Network/JSON/file work always happens on Dispatchers.IO (never Compose's UI thread).
 * A headless worker writes ONLY the catalog cache; history is merged after normal
 * account hydration so a background sync cannot overwrite a user's workout.
 */
internal class RemoteExerciseCatalog(private val context: Context) {
    private val cache = AtomicFile(File(context.filesDir, "exercise_catalog_remote_v1.json"))
    private val http = OkHttpClient.Builder().callTimeout(25, TimeUnit.SECONDS).build()

    private fun readCache(): JSONObject = runCatching {
        if (cache.baseFile.exists())
            cache.openRead().use { JSONObject(String(it.readBytes(), Charsets.UTF_8)) }
        else JSONObject()
    }.getOrDefault(JSONObject())
        .apply {
            if (!has("entries")) put("entries", JSONObject())
            if (!has("localIDs")) put("localIDs", JSONObject())
        }

    private fun commitCache(data: JSONObject) {
        val stream = cache.startWrite()
        try {
            stream.write(data.toString().toByteArray(Charsets.UTF_8))
            cache.finishWrite(stream)
        } catch (error: Exception) {
            cache.failWrite(stream)
            throw error
        }
    }

    private fun fetch(path: String, accessToken: String): JSONArray {
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/rest/v1/" + path)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer $accessToken")
            .header("Accept", "application/json")
            .get().build()
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful)
                throw IllegalStateException("Catálogo remoto HTTP ${response.code}")
            return JSONArray(response.body?.string() ?: error("Respuesta vacía"))
        }
    }

    @Synchronized
    fun refresh(accessToken: String): Boolean {
        require(accessToken.isNotBlank())
        val latest = fetch("mobile_exercise_catalog_events?select=id&order=id.desc&limit=1", accessToken)
        if (latest.length() == 0) return false
        val head = latest.getJSONObject(0).getLong("id")
        var working = readCache()
        var cursor = working.optLong("revision", 0)
        if (cursor > head) {
            working = JSONObject().put("entries", JSONObject()).put("localIDs", JSONObject())
            cursor = 0
        }
        if (cursor == head) return false
        val entries = working.getJSONObject("entries")
        while (cursor < head) {
            val page = fetch(
                "mobile_exercise_catalog_events?select=id,catalog_key,operation,payload" +
                    "&id=gt.$cursor&id=lte.$head&order=id.asc&limit=150",
                accessToken
            )
            check(page.length() > 0) { "Faltan páginas del catálogo remoto" }
            for (index in 0 until page.length()) {
                val event = page.getJSONObject(index)
                val next = event.getLong("id")
                if (next <= cursor) continue
                val key = event.getString("catalog_key")
                when (event.getString("operation")) {
                    "upsert" -> {
                        val item = event.optJSONObject("payload")
                        require(item != null && item.optString("name").isNotBlank())
                        entries.put(key, JSONObject(item.toString()))
                    }
                    "delete" -> {
                        val item = entries.optJSONObject(key) ?: JSONObject()
                            .put("name", key.removePrefix("catalog:"))
                            .put("category", "Fuerza")
                        item.put("is_active", false)
                        entries.put(key, item)
                    }
                    else -> error("Operación del catálogo no admitida")
                }
                cursor = next
            }
        }
        working.put("revision", cursor)
        commitCache(working) // atomic: no partial cursor after a failed page
        return true
    }

    /**
     * Merge after CatalogRefreshMigration.ensure. Preserve existing exercise UUID,
     * favorites and private entries. No historical workout, routine or set is edited.
     * This method is called only from the account-load IO dispatcher.
     */
    @Synchronized
    fun applyToAccount(googleId: String): Boolean {
        val cached = readCache()
        if (cached.optLong("revision", 0) == 0L) return false
        val entries = cached.getJSONObject("entries")
        val ids = cached.getJSONObject("localIDs")
        val local = LocalSnapshotStore(context, googleId)
        val bytes = local.read() ?: return false
        val state = JSONObject(String(bytes, Charsets.UTF_8))
        val catalog = state.getJSONArray("exercises")
        val byId = mutableMapOf<String, JSONObject>()
        val byName = mutableMapOf<String, JSONObject>()
        val byNativeId = mutableMapOf<String, JSONObject>()
        for (i in 0 until catalog.length()) {
            val item = catalog.getJSONObject(i)
            if (item.optBoolean("isCustom")) continue
            byId[item.optString("id")] = item
            byName[normalize(item.optString("name"))] = item
            item.optString("catalogId").takeIf { it.isNotBlank() }?.let {
                byNativeId[it] = item
            }
        }
        var changed = false
        val keys = entries.keys().asSequence().toList().sorted()
        for (key in keys) {
            val remote = entries.getJSONObject(key)
            val publishedName = remote.optString("name").ifBlank { key.removePrefix("catalog:") }
            val nativeID = remote.optString("native_catalog_id")
            val originalName = key.removePrefix("catalog:")
            val current = byId[ids.optString(key)]
                ?: byNativeId[nativeID]
                ?: byName[normalize(originalName)]
                ?: byName[normalize(publishedName)]
            val id = current?.optString("id")?.takeIf { it.isNotBlank() }
                ?: ids.optString(key).takeIf { it.isNotBlank() }
                ?: deterministicUUID(key)
            if (ids.optString(key) != id) ids.put(key, id)
            val exercise = current ?: JSONObject()
                .put("id", id).put("isCustom", false).put("isFavorite", false)
            val original = exercise.toString()
            exercise.put("name", publishedName)
            exercise.put("isCatalogArchived", !remote.optBoolean("is_active", true))
            if (nativeID.isNotBlank()) exercise.put("catalogId", nativeID)
            val primary = remote.optJSONArray("primary_muscles") ?: JSONArray()
            val secondary = remote.optJSONArray("secondary_muscles") ?: JSONArray()
            if (primary.length() > 0) {
                exercise.put("primaryRegions", JSONArray(primary.toString()))
                exercise.put("targetMuscle", primary.getString(0))
            }
            if (secondary.length() > 0) {
                exercise.put("secondaryRegions", JSONArray(secondary.toString()))
                exercise.put("secondaryMuscles", JSONArray(secondary.toString()))
            }
            for ((source, target) in listOf(
                "description" to "detailDescription",
                "body_part" to "bodyPart",
                "muscle_group" to "muscleGroup"
            )) if (!remote.isNull(source) && remote.has(source))
                exercise.put(target, remote.get(source))
            val steps = remote.optJSONArray("instructions")
            if (steps != null && steps.length() > 0)
                exercise.put("instructions", JSONArray(steps.toString()))
            if (!remote.isNull("equipment_override") && remote.has("equipment_override"))
                exercise.put("equipment", remote.getString("equipment_override"))
            else if (!exercise.has("equipment")) {
                val eq = remote.optJSONArray("equipment") ?: JSONArray()
                if (eq.length() > 0) exercise.put("equipment",
                    (0 until eq.length()).joinToString(", ") { eq.getString(it) })
            }
            val sport = remote.optString("sport_tag").ifBlank { remote.optString("category") }
            if (sport == "Fuerza" || sport.isBlank()) exercise.remove("sportTag")
            else exercise.put("sportTag", sport)
            if (current == null) {
                catalog.put(exercise)
                changed = true
            } else if (original != exercise.toString()) {
                changed = true
            }
            byId[id] = exercise
            byName[normalize(publishedName)] = exercise
            if (nativeID.isNotBlank()) byNativeId[nativeID] = exercise
        }
        // Cache the resolved legacy UUID mapping before publishing private state.
        cached.put("localIDs", ids)
        commitCache(cached)
        if (!changed) return false
        state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
        state.put("updatedAt", Instant.now().toString())
        state.put("lastWriterDeviceId", "android-catalog-remote")
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return true
    }

    private fun normalize(s: String): String =
        java.text.Normalizer.normalize(s.trim().lowercase(), java.text.Normalizer.Form.NFD)
            .replace(Regex("\\p{M}+"), "")

    private fun deterministicUUID(key: String): String {
        val hash = MessageDigest.getInstance("SHA-256")
            .digest(("com.app.repera.remote-catalog.v1:" + key).toByteArray(Charsets.UTF_8))
            .copyOf(16)
        hash[6] = ((hash[6].toInt() and 15) or 0x50).toByte()
        hash[8] = ((hash[8].toInt() and 63) or 0x80).toByte()
        val hex = hash.joinToString("") { "%02x".format(it) }
        return UUID.fromString(
            "${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-" +
                "${hex.substring(16, 20)}-${hex.substring(20, 32)}"
        ).toString()
    }
}

internal class RemoteExerciseCatalogWorker(
    context: Context, params: WorkerParameters
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val session = SessionStore(applicationContext).load() ?: return@withContext Result.success()
        // Never ask for login or rotate a refresh token in a headless worker.
        // At next foreground the normal identity store handles refresh safely.
        if (session.expiresWithin(120)) return@withContext Result.success()
        runCatching {
            RemoteExerciseCatalog(applicationContext).refresh(session.accessToken)
        }.fold(
            onSuccess = { Result.success() },
            onFailure = { if (runAttemptCount < 3) Result.retry() else Result.success() }
        )
    }

    companion object {
        private const val TASK = "repera_public_exercise_catalog"
        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            val request = PeriodicWorkRequestBuilder<RemoteExerciseCatalogWorker>(
                6, TimeUnit.HOURS
            ).setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 20, TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                TASK, ExistingPeriodicWorkPolicy.KEEP, request
            )
        }
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(TASK)
        }
    }
}
