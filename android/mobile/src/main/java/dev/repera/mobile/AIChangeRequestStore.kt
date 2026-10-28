package dev.repera.mobile

import android.content.Context
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Cambios propuestos por la IA sobre entrenos y ejercicios personalizados.
 * Port 1:1 de AIChangeRequestStore.swift (iOS): la IA nunca muta por su
 * cuenta; cada cambio se aplica localmente solo tras el consentimiento del
 * deportista, con verificación de revisión contra athlete_workout_mirror y
 * replay de ACKs persistidos (un borrado no se repite tras un corte de red).
 */
class AIChangeRequestStore(
    context: Context,
    private val userId: String,
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(20, TimeUnit.SECONDS).build(),
    private val stillAuthorized:()->Boolean={true}
) {
    private val prefs = context.getSharedPreferences(
        "repera.ai.change.acks.$userId", Context.MODE_PRIVATE)

    private fun authorize() = check(stillAuthorized()) {"La cuenta cambió durante el acceso IA"}
    private fun executeAuthorized(request:Request):okhttp3.Response {
        authorize()
        val response=http.newCall(request).execute()
        try {authorize()} catch(error:Exception) {response.close();throw error}
        return response
    }

    data class Change(
        val id: String,
        val operation: String,
        val targetId: String?,
        val expectedUpdatedAt: String?,
        val payload: JSONObject,
        val createdAt: String?
    ) {
        val summary: String
            get() = when (operation) {
                "update_workout" -> "Corregir: " +
                    payload.optString("workoutTitle", "entrenamiento")
                "delete_workout" -> "Eliminar: " +
                    payload.optString("workoutTitle", "entrenamiento registrado")
                "create_exercise" -> "Añadir ejercicio: " +
                    payload.optString("name")
                "update_exercise" -> "Editar ejercicio personalizado: " +
                    payload.optString("name")
                "delete_exercise" -> "Eliminar ejercicio: " +
                    payload.optString("name", "personalizado")
                else -> "Cambio solicitado"
            }
        val isDestructive: Boolean
            get() = operation == "delete_workout" || operation == "delete_exercise"
    }

    sealed class RefreshResult {
        data class Loaded(val pending: List<Change>) : RefreshResult()
        data class Failed(val message: String) : RefreshResult()
    }

    sealed class DecideResult {
        data object Applied : DecideResult()
        data object Rejected : DecideResult()
        data class Failed(val message: String) : DecideResult()
    }

    fun refresh(session: SupabaseIdentity.Session): RefreshResult {
        return try {
            authorize()
            check(session.userId==userId) {"La cuenta no corresponde a las solicitudes IA"}
            val url = BuildConfig.SUPABASE_URL +
                "/rest/v1/ai_athlete_change_requests" +
                "?select=id,operation,target_id,expected_updated_at,payload,created_at" +
                "&owner_id=eq.$userId&status=eq.pending&order=created_at&limit=100"
            val request = Request.Builder().url(url)
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .get().build()
            val rows = executeAuthorized(request).use { response ->
                val body = response.body.string()
                authorize()
                if (!response.isSuccessful)
                    throw IllegalStateException("HTTP " + response.code)
                JSONArray(body)
            }
            // Replay de ACKs: el cambio local se aplicó pero faltó confirmarlo.
            val awaiting = awaitingAck()
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                val id = row.getString("id")
                if (awaiting.contains(id)) {
                    runCatching {
                        decideRemote(session, id, "applied",
                            "Aplicado localmente tras consentimiento")
                        removeAck(id)
                    }
                }
            }
            val pending = (0 until rows.length())
                .map { rows.getJSONObject(it) }
                .filter { !awaiting.contains(it.getString("id")) }
                .map { row ->
                    Change(
                        id = row.getString("id"),
                        operation = row.getString("operation"),
                        targetId = row.optString("target_id").ifBlank { null },
                        expectedUpdatedAt = row.optString("expected_updated_at")
                            .ifBlank { null },
                        payload = row.optJSONObject("payload") ?: JSONObject(),
                        createdAt = row.optString("created_at").ifBlank { null }
                    )
                }
            RefreshResult.Loaded(pending)
        } catch (error: Exception) {
            RefreshResult.Failed("No se pudieron recuperar los cambios propuestos: " +
                (error.localizedMessage ?: ""))
        }
    }

    fun decide(session: SupabaseIdentity.Session, change: Change,
               approve: Boolean, repository: WorkoutRepository,
               mirror: WorkoutMirrorStore): DecideResult {
        return try {
            authorize()
            check(session.userId==userId) {"La cuenta no corresponde a las solicitudes IA"}
            if(change.id in awaitingAck()) {
                decideRemote(session,change.id,"applied","Aplicado localmente tras consentimiento")
                removeAck(change.id)
                return DecideResult.Applied
            }
            if (!approve) {
                decideRemote(session, change.id, "rejected",
                    "Rechazado por el deportista")
                return DecideResult.Rejected
            }
            when (change.operation) {
                "update_workout", "delete_workout" -> {
                    val targetId = change.targetId
                        ?: return DecideResult.Failed(
                            "El entrenamiento ya no está disponible en este dispositivo.")
                    val local = repository.finishedWorkoutsSnapshot()
                        .firstOrNull { it.optString("id") == targetId }
                        ?: return DecideResult.Failed(
                            "El entrenamiento ya no está disponible en este dispositivo.")
                    val localDigest=WorkoutMirrorStore.canonicalDigest(local)
                    // Revisión remota: la IA razonó sobre esta versión exacta.
                    val expected = change.expectedUpdatedAt
                        ?: return DecideResult.Failed(
                            "La revisión del entrenamiento cambió. Rechaza la solicitud y pide una nueva.")
                    val remote = fetchMirrorRevision(session, targetId)
                        ?: return DecideResult.Failed(
                            "La revisión del entrenamiento cambió. Rechaza la solicitud y pide una nueva.")
                    val remoteUpdated = parseInstant(remote.first)
                        ?: return DecideResult.Failed(
                            "La revisión del entrenamiento cambió. Rechaza la solicitud y pide una nueva.")
                    val expectedInstant = parseInstant(expected)
                        ?: return DecideResult.Failed(
                            "La revisión del entrenamiento cambió. Rechaza la solicitud y pide una nueva.")
                    if (remote.second != null ||
                        kotlin.math.abs(remoteUpdated.toEpochMilli() -
                            expectedInstant.toEpochMilli()) >= 20) {
                        return DecideResult.Failed(
                            "La revisión del entrenamiento cambió. Rechaza la solicitud y pide una nueva.")
                    }
                    authorize()
                    if (change.operation == "delete_workout") {
                        authorize()
                        repository.deleteWorkout(targetId,expectedLocalDigest=localDigest)
                    } else {
                        val patches = parseSetChanges(change.payload)
                        authorize()
                        repository.applyAIWorkoutPatch(targetId,
                            change.payload.optString("title").ifBlank { null },
                            patches,expectedLocalDigest=localDigest)
                    }
                }
                "create_exercise", "update_exercise", "delete_exercise" -> {
                    val p = change.payload
                    authorize()
                    when (change.operation) {
                        "create_exercise" -> {
                            val name = p.optString("name")
                            val muscle = p.optString("muscleGroup")
                            if (name.isBlank() || muscle.isBlank() ||
                                !repository.addCustomExercise(
                                    change.id, name, muscle,
                                    p.optString("equipment").ifBlank { null },
                                    p.optString("targetMuscle").ifBlank { null },
                                    p.optStringList("secondaryMuscles"))) {
                                return DecideResult.Failed(
                                    "El límite de ejercicios personalizados impide crear este ejercicio.")
                            }
                        }
                        "update_exercise" -> {
                            val id = change.targetId
                            val name = p.optString("name")
                            val muscle = p.optString("muscleGroup")
                            if (id == null || name.isBlank() || muscle.isBlank() ||
                                !repository.updateCustomExercise(
                                    id, name, muscle,
                                    p.optString("equipment").ifBlank { null },
                                    p.optString("targetMuscle").ifBlank { null },
                                    p.optStringList("secondaryMuscles"))) {
                                return DecideResult.Failed(
                                    "El ejercicio personalizado ya no existe.")
                            }
                        }
                        else -> {
                            val id = change.targetId
                            if (id == null || !repository.deleteCustomExercise(id)) {
                                return DecideResult.Failed(
                                    "El ejercicio personalizado ya no existe.")
                            }
                        }
                    }
                    // La operación nativa ya se hizo: un fallo del espejo no
                    // puede re-ejecutar un borrado en el siguiente intento.
                    runCatching { syncCustomExercises(session, repository) }
                }
                else -> return DecideResult.Failed("Cambio no reconocido.")
            }
            queueAck(change.id)
            decideRemote(session, change.id, "applied",
                "Aplicado localmente tras consentimiento")
            removeAck(change.id)
            DecideResult.Applied
        } catch (error: Exception) {
            DecideResult.Failed("No se pudo confirmar el cambio: " +
                (error.localizedMessage ?: ""))
        }
    }

    /** Espejo SOLO de ejercicios personalizados (catálogo global inmutable). */
    fun syncCustomExercises(session: SupabaseIdentity.Session,
                            repository: WorkoutRepository): Boolean {
        return try {
            authorize()
            check(session.userId==userId) {"La cuenta no corresponde a las solicitudes IA"}
            val custom = repository.customExercisesSnapshot()
            if (custom.size > 1000) return false
            val rows = JSONArray()
            custom.forEach { exercise ->
                rows.put(JSONObject()
                    .put("owner_id", userId)
                    .put("exercise_id", exercise.getString("id"))
                    .put("name", exercise.optString("name"))
                    .put("muscle_group", exercise.optString("muscleGroup"))
                    .put("equipment", exercise.optString("equipment")
                        .ifBlank { null })
                    .put("target_muscle", exercise.optString("targetMuscle")
                        .ifBlank { null })
                    .put("secondary_muscles", JSONArray().also { out ->
                        exercise.optJSONArray("secondaryMuscles")?.let { arr ->
                            for (j in 0 until arr.length()) out.put(arr.getString(j))
                        }
                    })
                    .put("updated_at", Instant.now().toString()))
            }
            var offset = 0
            while (offset < rows.length()) {
                val batch = JSONArray()
                var end = offset
                while (end < rows.length() && end < offset + 40) {
                    batch.put(rows.getJSONObject(end)); end++
                }
                val url = BuildConfig.SUPABASE_URL +
                    "/rest/v1/athlete_custom_exercise_mirror" +
                    "?on_conflict=owner_id,exercise_id"
                val request = Request.Builder().url(url)
                    .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                    .header("Authorization", "Bearer " + session.accessToken)
                    .header("Content-Type", "application/json")
                    .header("Prefer", "resolution=merge-duplicates")
                    .post(batch.toString()
                        .toRequestBody("application/json".toMediaType()))
                    .build()
                executeAuthorized(request).use { response ->
                    if (!response.isSuccessful)
                        throw IllegalStateException("HTTP " + response.code)
                }
                offset = end
            }
            // Borra del espejo los que ya no existen localmente.
            val storedUrl = BuildConfig.SUPABASE_URL +
                "/rest/v1/athlete_custom_exercise_mirror" +
                "?select=exercise_id&owner_id=eq.$userId&limit=1001"
            val storedRequest = Request.Builder().url(storedUrl)
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .get().build()
            val stored = executeAuthorized(storedRequest).use { response ->
                val body = response.body.string()
                authorize()
                if (!response.isSuccessful)
                    throw IllegalStateException("HTTP " + response.code)
                JSONArray(body)
            }
            if (stored.length() > 1000) return false
            val localIds = custom.map { it.getString("id") }.toSet()
            for (i in 0 until stored.length()) {
                val remoteId = stored.getJSONObject(i).getString("exercise_id")
                if (!localIds.contains(remoteId)) {
                    val deleteUrl = BuildConfig.SUPABASE_URL +
                        "/rest/v1/athlete_custom_exercise_mirror" +
                        "?owner_id=eq.$userId&exercise_id=eq.$remoteId"
                    val deleteRequest = Request.Builder().url(deleteUrl)
                        .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                        .header("Authorization", "Bearer " + session.accessToken)
                        .delete().build()
                    executeAuthorized(deleteRequest).use { response ->
                        if (!response.isSuccessful)
                            throw IllegalStateException("HTTP " + response.code)
                    }
                }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun fetchMirrorRevision(session: SupabaseIdentity.Session,
                                    id: String): Pair<String?, String?>? {
        val url = BuildConfig.SUPABASE_URL + "/rest/v1/athlete_workout_mirror" +
            "?select=updated_at,deleted_at&owner_id=eq.$userId&id=eq.$id"
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        executeAuthorized(request).use { response ->
            val body = response.body.string()
            authorize()
            if (!response.isSuccessful || JSONArray(body).length() == 0) return null
            val row = JSONArray(body).getJSONObject(0)
            return row.optString("updated_at").ifBlank { null } to
                row.optString("deleted_at").ifBlank { null }
        }
    }

    private fun decideRemote(session: SupabaseIdentity.Session, id: String,
                             status: String, message: String) {
        val url = BuildConfig.SUPABASE_URL +
            "/rest/v1/ai_athlete_change_requests" +
            "?id=eq.$id&owner_id=eq.$userId&status=eq.pending"
        val payload = JSONObject()
            .put("status", status)
            .put("decided_at", Instant.now().toString())
            .put("decision_message", message)
        val request = Request.Builder().url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .header("Prefer", "return=minimal")
            .patch(payload.toString().toRequestBody("application/json".toMediaType()))
            .build()
        executeAuthorized(request).use { response ->
            if (!response.isSuccessful)
                throw IllegalStateException("HTTP " + response.code)
        }
    }

    private fun parseSetChanges(payload: JSONObject):
            List<WorkoutRepository.AISetPatch> {
        val changes = payload.optJSONArray("setChanges") ?: return emptyList()
        return (0 until changes.length()).map { i ->
            val c = changes.getJSONObject(i)
            WorkoutRepository.AISetPatch(
                exerciseEntryId = c.getString("exerciseEntryId"),
                loggedSetId = c.getString("loggedSetId"),
                reps = c.optInt("reps").takeIf {
                    c.has("reps") && !c.isNull("reps") },
                weightKg = c.optDouble("weightKg").takeIf {
                    c.has("weightKg") && !c.isNull("weightKg") },
                rir = c.optDouble("rir").takeIf {
                    c.has("rir") && !c.isNull("rir") },
                clearWeight = c.optBoolean("clearWeight", false),
                clearRir = c.optBoolean("clearRir", false))
        }
    }

    private fun awaitingAck(): Set<String> = synchronized(ackLock) {
        prefs.getStringSet("acks", emptySet())?.toSet() ?: emptySet()
    }

    private fun queueAck(id: String) = synchronized(ackLock) {
        saveAcks(awaitingAck()+id)
    }

    private fun removeAck(id: String) = synchronized(ackLock) {
        saveAcks(awaitingAck()-id)
    }

    private fun saveAcks(set: Set<String>) {
        check(prefs.edit().putStringSet("acks", set).commit()) {"No se pudo guardar la confirmación pendiente"}
    }

    companion object {
        private val ackLock=Any()
        internal fun parseInstant(value: String?): Instant? {
            if (value.isNullOrBlank()) return null
            var v = value.replace(" ", "T")
            // Postgres puede emitir el offset corto (+00); ISO-8601 exige +00:00.
            if (Regex("[+-]\\d{2}$").containsMatchIn(v)) v += ":00"
            return runCatching { Instant.parse(v) }.getOrNull()
        }

        private fun JSONObject.optStringList(key: String): List<String> =
            optJSONArray(key)?.let { arr ->
                (0 until arr.length()).map { arr.getString(it) }
            } ?: emptyList()
    }
}
