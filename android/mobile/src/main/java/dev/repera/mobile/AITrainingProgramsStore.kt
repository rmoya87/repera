package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Programas mult semana propuestos por la IA (athlete_training_programs).
 * Port de AITrainingProgramsView.swift (iOS): lectura y aceptación/pausa del
 * marco de programa; las propuestas diarias viven aparte y nunca se
 * sobrescriben en silencio. El cambio de estado va protegido por revision
 * (la IA razonó sobre esa versión exacta).
 */
class AITrainingProgramsStore(
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(20, TimeUnit.SECONDS).build()
) {
    data class Phase(
        val title: String,
        val weeks: Int,
        val focus: String,
        val targetSessionsPerWeek: Int,
        val progressionRule: String
    )

    data class Program(
        val id: String,
        val title: String,
        val primaryGoal: String,
        val startDate: String,
        val startTimeZone: String?,
        val durationWeeks: Int,
        val phases: List<Phase>,
        val status: String,
        val revision: Int
    ) {
        val statusLabel: String
            get() = when (status) {
                "proposed" -> "Propuesto"
                "active" -> "Activo"
                "paused" -> "En pausa"
                "completed" -> "Completado"
                "cancelled" -> "Cancelado"
                else -> status
            }
    }

    sealed class LoadResult {
        data class Loaded(val programs: List<Program>) : LoadResult()
        data class Failed(val message: String) : LoadResult()
    }

    fun refresh(session: SupabaseIdentity.Session): LoadResult {
        val url = BuildConfig.SUPABASE_URL +
            "/rest/v1/athlete_training_programs" +
            "?select=id,title,primary_goal,start_date,start_time_zone," +
            "duration_weeks,phases,status,revision" +
            "&owner_id=eq.${session.userId}&order=start_date.desc&limit=100"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        return try {
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful) {
                    return LoadResult.Failed(
                        "No se pudieron cargar los programas: HTTP " +
                            response.code)
                }
                LoadResult.Loaded(parsePrograms(JSONArray(body)))
            }
        } catch (error: Exception) {
            LoadResult.Failed("No se pudieron cargar los programas: " +
                (error.localizedMessage ?: ""))
        }
    }

    /** Activa/pausa con guarda de revisión. null = éxito. */
    fun changeStatus(session: SupabaseIdentity.Session,
                     program: Program, status: String): String? {
        val url = BuildConfig.SUPABASE_URL +
            "/rest/v1/athlete_training_programs" +
            "?owner_id=eq.${session.userId}&id=eq.${program.id}" +
            "&revision=eq.${program.revision}"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .header("Prefer", "return=minimal")
            .patch(JSONObject().put("status", status).toString()
                .toRequestBody("application/json".toMediaType()))
            .build()
        return try {
            http.newCall(request).execute().use { response ->
                if (response.isSuccessful) null
                else "No se pudo actualizar el programa: HTTP " + response.code
            }
        } catch (error: Exception) {
            "No se pudo actualizar el programa: " +
                (error.localizedMessage ?: "")
        }
    }

    companion object {
        internal fun parsePrograms(rows: JSONArray): List<Program> =
            (0 until rows.length()).map { i ->
                val row = rows.getJSONObject(i)
                val phases = row.optJSONArray("phases")?.let { arr ->
                    (0 until arr.length()).map { j ->
                        val p = arr.getJSONObject(j)
                        Phase(
                            title = p.optString("title"),
                            weeks = p.optInt("weeks"),
                            focus = p.optString("focus"),
                            targetSessionsPerWeek =
                                p.optInt("target_sessions_per_week"),
                            progressionRule = p.optString("progression_rule"))
                    }
                } ?: emptyList()
                Program(
                    id = row.getString("id"),
                    title = row.optString("title"),
                    primaryGoal = row.optString("primary_goal"),
                    startDate = row.optString("start_date"),
                    startTimeZone = row.optString("start_time_zone")
                        .ifBlank { null },
                    durationWeeks = row.optInt("duration_weeks"),
                    phases = phases,
                    status = row.optString("status"),
                    revision = row.optInt("revision"))
            }
    }
}
