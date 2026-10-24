package dev.repera.mobile

import android.content.Context
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.concurrent.TimeUnit

/**
 * Espejo de calendario de planificación para la IA
 * (athlete_training_calendar_snapshots). Port de AITrainingContextStore.swift
 * (iOS): estrictamente deportivo y de bajo detalle — nunca notas privadas,
 * ubicaciones, rutas, Salud ni medidas corporales.
 *
 * El móvil sigue siendo la fuente autoritativa: este store sólo PUBLICA una
 * foto del horizonte de 90 días cuando el contenido cambia (huella SHA-256
 * sobre el JSON canónico, igual que el .sortedKeys + comparación de iOS).
 * Un fallo de red nunca bloquea la planificación local.
 */
class AITrainingContextStore(
    context: Context,
    private val userId: String,
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(30, TimeUnit.SECONDS).build()
) {
    private val prefs = context.getSharedPreferences(
        "repera.ai-context.$userId", Context.MODE_PRIVATE)

    data class Result(
        val ok: Boolean,
        val items: Int = 0,
        val uploaded: Boolean = false,
        val unchanged: Boolean = false,
        val error: String? = null
    )

    fun sync(session: SupabaseIdentity.Session,
             repository: WorkoutRepository,
             today: LocalDate = LocalDate.now(),
             zone: ZoneId = ZoneId.systemDefault()): Result {
        return try {
            val items = buildItems(repository.routinesSnapshot(),
                repository.exercisesSnapshot(), today, zone)
            if (items.length() > MAX_ITEMS) {
                return Result(ok = false, items = items.length(),
                    error = "Demasiados entrenos planificados para el espejo IA")
            }
            val timeZone = zone.id
            val digest = WorkoutMirrorStore.canonicalDigest(
                JSONObject().put("items", items).put("tz", timeZone))
            if (prefs.getString(KEY_DIGEST, null) == digest) {
                return Result(ok = true, items = items.length(), unchanged = true)
            }
            val horizonEnd = today.plusDays(HORIZON_DAYS)
            val row = JSONObject()
                .put("owner_id", userId)
                .put("items", items)
                .put("horizon_start", today.toString())
                .put("horizon_end", horizonEnd.toString())
                .put("time_zone", timeZone)
                .put("updated_at", Instant.now().toString())
            upsert(session, JSONArray().put(row))
            prefs.edit().putString(KEY_DIGEST, digest).apply()
            Result(ok = true, items = items.length(), uploaded = true)
        } catch (error: Exception) {
            Result(ok = false,
                error = "La sincronización del contexto IA está pendiente: " +
                    (error.localizedMessage ?: ""))
        }
    }

    private fun upsert(session: SupabaseIdentity.Session, rows: JSONArray) {
        val url = BuildConfig.SUPABASE_URL +
            "/rest/v1/athlete_training_calendar_snapshots?on_conflict=owner_id"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .header("Prefer", "resolution=merge-duplicates")
            .post(rows.toString().toRequestBody("application/json".toMediaType()))
            .build()
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful)
                throw IllegalStateException("HTTP " + response.code)
        }
    }

    companion object {
        private const val KEY_DIGEST = "snapshot_digest"
        internal const val MAX_ITEMS = 500
        internal const val HORIZON_DAYS = 90L

        private fun JSONObject.putOpt(key: String, value: Any?): JSONObject {
            if (value != null) put(key, value)
            return this
        }

        private fun JSONObject.optDoubleOrNull(key: String): Double? =
            if (has(key) && !isNull(key)) getDouble(key) else null

        private fun JSONObject.optIntOrNull(key: String): Int? =
            if (has(key) && !isNull(key)) getInt(key) else null

        /** Items del snapshot con la forma exacta del wire de iOS
         *  (claves camelCase, nulos omitidos como hace JSONEncoder). */
        internal fun buildItems(
            routines: List<JSONObject>,
            catalog: List<JSONObject>,
            today: LocalDate,
            zone: ZoneId
        ): JSONArray {
            val horizonEnd = today.plusDays(HORIZON_DAYS)
            val byId = catalog.associateBy { it.optString("id") }
            val items = JSONArray()
            for (routine in routines) {
                val scheduledRaw = routine.optString("scheduledDate")
                    .takeIf { it.isNotBlank() }
                val weekday = routine.optIntOrNull("weekday")
                if (scheduledRaw == null && weekday == null) continue
                // Fecha pura "yyyy-MM-dd" (actual) o instant ISO (snapshots antiguos).
                val scheduledDay = scheduledRaw?.let {
                    runCatching {
                        Instant.parse(it).atZone(zone).toLocalDate()
                    }.getOrNull()
                        ?: runCatching { LocalDate.parse(it.take(10)) }.getOrNull()
                }
                if (scheduledRaw != null && (scheduledDay == null ||
                        scheduledDay.isBefore(today) ||
                        scheduledDay.isAfter(horizonEnd))) continue

                val blocks = JSONArray()
                val routineBlocks = routine.optJSONArray("blocks") ?: JSONArray()
                for (b in 0 until routineBlocks.length()) {
                    val block = routineBlocks.getJSONObject(b)
                    val strength = JSONArray()
                    val blockExercises = block.optJSONArray("exercises")
                    if (blockExercises != null) {
                        for (e in 0 until blockExercises.length()) {
                            val entry = blockExercises.getJSONObject(e)
                            val movement = byId[entry.optString("exerciseId")]
                            val plannedSets = JSONArray()
                            val sets = entry.optJSONArray("plannedSets")
                                ?: JSONArray()
                            for (s in 0 until sets.length()) {
                                val set = sets.getJSONObject(s)
                                plannedSets.put(JSONObject()
                                    .put("reps", set.optInt("targetReps", 1))
                                    .putOpt("weightKg",
                                        set.optDoubleOrNull("targetWeightKg"))
                                    .putOpt("rir",
                                        set.optDoubleOrNull("targetRir"))
                                    .putOpt("percent1RM",
                                        set.optDoubleOrNull("targetPercent1RM"))
                                    .put("percent1RMIsMinimum",
                                        set.optBoolean(
                                            "targetPercent1RMIsMinimum", false)))
                            }
                            strength.put(JSONObject()
                                .put("name", movement?.optString("name")
                                    ?.takeIf { it.isNotBlank() }
                                    ?: "Ejercicio sin catálogo")
                                .putOpt("catalogKey",
                                    movement?.optString("catalogId")
                                        ?.takeIf { it.isNotBlank() })
                                .put("plannedSets", plannedSets))
                        }
                    }
                    val moves = JSONArray()
                    val blockMovements = block.optJSONArray("movements")
                    if (blockMovements != null) {
                        for (m in 0 until blockMovements.length()) {
                            val move = blockMovements.getJSONObject(m)
                            val movement = move.optString("exerciseId")
                                .takeIf { it.isNotBlank() }?.let { byId[it] }
                            moves.put(JSONObject()
                                .put("name", move.optString("name"))
                                .putOpt("catalogKey",
                                    movement?.optString("catalogId")
                                        ?.takeIf { it.isNotBlank() })
                                .putOpt("reps", move.optIntOrNull("reps"))
                                .putOpt("distanceMeters",
                                    move.optIntOrNull("distanceMeters"))
                                .putOpt("calories",
                                    move.optIntOrNull("calories")))
                        }
                    }
                    blocks.put(JSONObject()
                        .put("kind", block.optString("kind"))
                        .put("title", block.optString("title"))
                        .putOpt("wodFormat", block.optString("wodFormat")
                            .takeIf { it.isNotBlank() })
                        .put("strengthExercises", strength)
                        .put("movements", moves)
                        .putOpt("rounds", block.optIntOrNull("rounds"))
                        .putOpt("timeCapMinutes",
                            block.optIntOrNull("timeCapMinutes")))
                }
                items.put(JSONObject()
                    .put("routineId", routine.optString("id"))
                    .put("title", routine.optString("title"))
                    .putOpt("scheduledDate", scheduledDay?.toString())
                    .putOpt("weekday", weekday)
                    .putOpt("scheduledTimeMinutes",
                        routine.optIntOrNull("scheduledTimeMinutes"))
                    .put("blocks", blocks))
            }
            return items
        }
    }
}
