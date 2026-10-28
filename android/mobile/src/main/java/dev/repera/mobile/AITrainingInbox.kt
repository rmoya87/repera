package dev.repera.mobile

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
 * Bandeja de planes de IA: el servidor (MCP/entrenador) solo escribe planes
 * pendientes; esta clase los traduce a los mismos modelos nativos que Diario
 * e Inicio usan. Port 1:1 de AITrainingInboxStore.swift (iOS).
 *
 * Foreground Realtime notifications trigger this full synchronization;
 * sign-in and refresh also reconcile pending plans. Delivery remains unverified end to end.
 */
internal class AITrainingInbox(
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(20, TimeUnit.SECONDS).build(),
    private val stillAuthorized: () -> Boolean = { true }
) {
    data class Result(
        val imported: Int,
        val pending: Int,
        val conflicts: List<String>,
        val lastImportedTitle: String?,
        val error: String?
    )

    private fun authorize() = check(stillAuthorized()) {"La cuenta cambió durante la sincronización IA"}

    private class ImportError(message: String) : Exception(message)

    fun sync(session: SupabaseIdentity.Session,
             repository: WorkoutRepository): Result {
        return try {
            authorize()
            val uid = session.userId
            val rows = fetchPending(session, uid)
            var imported = 0
            val reasons = mutableListOf<String>()
            var lastTitle: String? = null
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                val day = row.optString("scheduled_date")
                try {
                    authorize()
                    importPlan(row, session, uid, repository)
                    imported += 1
                    lastTitle = row.optString("title")
                } catch (error: Exception) {
                    reasons.add("$day: ${error.localizedMessage}")
                }
            }
            Result(
                imported = imported,
                pending = maxOf(0, rows.length() - imported),
                conflicts = reasons,
                lastImportedTitle = lastTitle,
                error = if (reasons.isEmpty()) null
                    else "Hay ${reasons.size} planes de IA pendientes de revisión."
            )
        } catch (error: Exception) {
            Result(0, 0, emptyList(), null,
                "No se pudieron sincronizar los planes de IA: " +
                    (error.localizedMessage ?: ""))
        }
    }

    private fun fetchPending(session: SupabaseIdentity.Session,
                             uid: String): JSONArray {
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/ai_training_plans" +
            "?select=id,title,scheduled_date,scheduled_time_minutes,scheduled_at,scheduled_time_zone,payload" +
            "&owner_id=eq.$uid&status=eq.pending&order=scheduled_date&limit=200"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        authorize()
        http.newCall(request).execute().use { response ->
            authorize()
            val body = response.body.string()
            authorize()
            if (!response.isSuccessful)
                throw IllegalStateException("HTTP " + response.code)
            return JSONArray(body)
        }
    }

    private fun markApplied(session: SupabaseIdentity.Session,
                            uid: String, planId: String) {
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/ai_training_plans" +
            "?owner_id=eq.$uid&id=eq.$planId&status=eq.pending"
        val payload = JSONObject()
            .put("status", "applied")
            .put("applied_at", Instant.now().toString())
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .header("Prefer", "return=minimal")
            .patch(payload.toString().toRequestBody("application/json".toMediaType()))
            .build()
        authorize()
        http.newCall(request).execute().use { response ->
            authorize()
            if (!response.isSuccessful)
                throw IllegalStateException("HTTP " + response.code)
        }
    }

    /** Port de AITrainingInboxStore.sync por plan: dedupe por día, idempotencia
     * por id, ACK atómico status=pending -> applied. */
    private fun importPlan(row: JSONObject, session: SupabaseIdentity.Session,
                           uid: String, repository: WorkoutRepository) {
        authorize()
        val zone = ZoneId.systemDefault()
        val date: LocalDate = run {
            val at = row.optString("scheduled_at")
            if (at.isNotBlank()) {
                Instant.parse(at).atZone(zone).toLocalDate()
            } else {
                parseDay(row.optString("scheduled_date"))
            }
        }
        val planId = row.getString("id")
        val existing = repository.routinesSnapshot()
        val sameDayOther = existing.any { routine ->
            routine.optString("id") != planId &&
                routine.optString("scheduledDate").take(10) == date.toString()
        }
        if (sameDayOther) {
            throw ImportError("ya existe un entreno para ese día.")
        }
        // Idempotencia: un sync anterior pudo guardar la rutina y perder el ACK.
        if (existing.none { it.optString("id") == planId }) {
            val timeMinutes: Int? = run {
                val at = row.optString("scheduled_at")
                if (at.isNotBlank()) {
                    val local = Instant.parse(at).atZone(zone)
                    local.hour * 60 + local.minute
                } else if (row.has("scheduled_time_minutes") &&
                    !row.isNull("scheduled_time_minutes")) {
                    row.optInt("scheduled_time_minutes")
                } else null
            }
            authorize()
            repository.importAiRoutine(planId,
                RoutineSchedule(scheduledDate=date.toString(),timeMinutes=timeMinutes),
                stillAuthorized=stillAuthorized) {resolver ->buildRoutine(row,resolver)}
        }
        authorize()
        markApplied(session, uid, planId)
    }

    private fun parseDay(value: String): LocalDate {
        val parts = value.split("-").mapNotNull { it.toIntOrNull() }
        if (parts.size != 3 || parts[0] !in 2020..2100) {
            throw ImportError("La fecha de la planificación no es válida.")
        }
        return runCatching { LocalDate.of(parts[0], parts[1], parts[2]) }
            .getOrElse { throw ImportError("La fecha de la planificación no es válida.") }
    }

    private fun planned(sets: JSONArray): List<dev.repera.domain.PlannedSet> {
        if (sets.length() == 0 || sets.length() > 30)
            throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
        return (0 until sets.length()).map { i ->
            val set = sets.getJSONObject(i)
            val reps = set.optInt("reps")
            val weight = if (set.has("weightKg") && !set.isNull("weightKg"))
                set.optDouble("weightKg") else null
            val rir = if (set.has("rir") && !set.isNull("rir"))
                set.optDouble("rir") else null
            val pct = if (set.has("percent1RM") && !set.isNull("percent1RM"))
                set.optDouble("percent1RM") else null
            if (reps !in 1..5000 || (weight != null && (!weight.isFinite() || weight < 0)) ||
                (rir != null && (!rir.isFinite() || rir !in 0.0..10.0)) ||
                (pct != null && (!pct.isFinite() || pct !in 1.0..150.0))) {
                throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
            }
            dev.repera.domain.PlannedSet(
                targetReps = reps,
                targetWeightKg = weight,
                targetRir = rir,
                targetPercent1RM = pct,
                targetPercent1RMIsMinimum = set.optBoolean(
                    "percent1RMIsMinimum", false))
        }
    }

    internal fun buildRoutine(row: JSONObject,
            resolveExercise: (String, String?) -> String):
            Pair<String, List<dev.repera.domain.RoutineBlock>> {
        // Complete structural parsing before the resolver may create local
        // exercises. A structurally malformed later block must not leave orphans.
        parseRoutine(row) { _, _ -> "validation-only" }
        return parseRoutine(row,resolveExercise)
    }

    private fun parseRoutine(row: JSONObject,
            resolveExercise: (String, String?) -> String):
            Pair<String, List<dev.repera.domain.RoutineBlock>> {
        val payload = row.getJSONObject("payload")
        val title = row.optString("title").trim()
        if (payload.optInt("schemaVersion") != 1 || title.isEmpty())
            throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
        val inputBlocks = payload.getJSONArray("blocks")
        if (inputBlocks.length() !in 1..12)
            throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
        val blocks = mutableListOf<dev.repera.domain.RoutineBlock>()
        for (i in 0 until inputBlocks.length()) {
            val b = inputBlocks.getJSONObject(i)
            val blockTitle = b.optString("title")
            if (blockTitle.isEmpty())
                throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
            val exercises = b.optJSONArray("exercises") ?: JSONArray()
            val movements = b.optJSONArray("movements") ?: JSONArray()
            when (b.optString("kind")) {
                "strength" -> {
                    if (exercises.length() == 0 || movements.length() > 0)
                        throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
                    val entries = (0 until exercises.length()).map { j ->
                        val entry = exercises.getJSONObject(j)
                        val name = entry.optString("name")
                        if (name.isEmpty())
                            throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
                        val exerciseId = resolveExercise(
                            name, entry.optString("catalogKey").ifBlank { null })
                        dev.repera.domain.RoutineExercise(
                            exerciseId = exerciseId,
                            plannedSets = planned(entry.getJSONArray("plannedSets")),
                            restSeconds = entry.optInt("restSeconds")
                                .takeIf { entry.has("restSeconds") &&
                                    !entry.isNull("restSeconds") })
                    }
                    blocks.add(dev.repera.domain.RoutineBlock.strength(
                        title = blockTitle, exercises = entries))
                }
                "wod" -> {
                    val format = dev.repera.domain.WODFormat.entries
                        .firstOrNull { it.raw == b.optString("wodFormat") }
                    if (exercises.length() > 0 || movements.length() == 0 ||
                        format == null) {
                        throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
                    }
                    val moves = (0 until movements.length()).map { j ->
                        val m = movements.getJSONObject(j)
                        val name = m.optString("name")
                        if (name.isEmpty())
                            throw ImportError("El entrenamiento recibido no cumple el formato Repera.")
                        val isRest = m.optBoolean("isRest", false)
                        val exerciseId = if (isRest) null
                            else resolveExercise(
                                name, m.optString("catalogKey").ifBlank { null })
                        dev.repera.domain.WODMovement(
                            exerciseId = exerciseId,
                            name = name,
                            reps = m.optInt("reps").takeIf {
                                m.has("reps") && !m.isNull("reps") },
                            repScheme = m.optJSONArray("repScheme")?.let { scheme ->
                                (0 until scheme.length()).map { scheme.getInt(it) }
                            },
                            distanceMeters = m.optInt("distanceMeters").takeIf {
                                m.has("distanceMeters") && !m.isNull("distanceMeters") },
                            calories = m.optInt("calories").takeIf {
                                m.has("calories") && !m.isNull("calories") },
                            weightMaleKg = m.optDouble("weightMaleKg").takeIf {
                                m.has("weightMaleKg") && !m.isNull("weightMaleKg") },
                            weightFemaleKg = m.optDouble("weightFemaleKg").takeIf {
                                m.has("weightFemaleKg") && !m.isNull("weightFemaleKg") },
                            isRest = isRest,
                            restSeconds = m.optInt("restSeconds").takeIf {
                                m.has("restSeconds") && !m.isNull("restSeconds") },
                            scaleAlternative = m.optString("scaleAlternative")
                                .ifBlank { null },
                            explicitPlannedSets = m.optJSONArray("explicitPlannedSets")
                                ?.let { planned(it) })
                    }
                    val block = dev.repera.domain.RoutineBlock(
                        title = blockTitle,
                        kind = dev.repera.domain.RoutineBlockKind.WOD,
                        movements = moves,
                        wodFormat = format,
                        timeCapMinutes = b.optInt("timeCapMinutes").takeIf {
                            b.has("timeCapMinutes") && !b.isNull("timeCapMinutes") },
                        emomIntervalSeconds = b.optInt("emomIntervalSeconds").takeIf {
                            b.has("emomIntervalSeconds") && !b.isNull("emomIntervalSeconds") },
                        rounds = b.optInt("rounds").takeIf {
                            b.has("rounds") && !b.isNull("rounds") },
                        workSeconds = b.optInt("workSeconds").takeIf {
                            b.has("workSeconds") && !b.isNull("workSeconds") },
                        restSeconds = b.optInt("restSeconds").takeIf {
                            b.has("restSeconds") && !b.isNull("restSeconds") },
                        restBetweenRoundsSeconds = b.optInt("restBetweenRoundsSeconds")
                            .takeIf { b.has("restBetweenRoundsSeconds") &&
                                !b.isNull("restBetweenRoundsSeconds") },
                        wodNotes = b.optString("wodNotes").ifBlank { null })
                    block.deriveEmomRoundsIfNeeded()
                    blocks.add(block)
                }
                else -> throw ImportError(
                    "El entrenamiento recibido no cumple el formato Repera.")
            }
        }
        return title to blocks
    }

}
