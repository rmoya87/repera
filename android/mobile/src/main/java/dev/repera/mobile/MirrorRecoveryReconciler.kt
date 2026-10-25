package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject

/**
 * Primera sincronización con Drive cuando el estado local es SOLO "catálogo virgen + entrenos recuperados del espejo
 * (Supabase), sin editar". En ese caso exacto el local no contiene historial independiente: es lo mismo que habría
 * ocurrido si Drive hubiera sincronizado primero. NO relaja la detección de conflictos: cualquier otra diferencia local
 * (rutinas, sesión activa, ajustes, pesos, entreno recuperado y luego editado, entreno no recuperado, catálogo distinto)
 * devuelve [Result.NotApplicable] y sigue el camino normal con su Conflict.
 *
 * Resultado: se toma el documento de Drive y se re-funden (solo añadir) los entrenos recuperados que Drive no tiene,
 * con revisión superior para que local gane y suba; así una descarga nunca descarta entrenos recuperados.
 */
internal object MirrorRecoveryReconciler {
    sealed interface Result {
        data object NotApplicable : Result
        /** Drive ya contiene todo lo recuperado: basta descargar. */
        data object UseRemote : Result
        /** Documento fusionado (Drive + recuperados ausentes), listo para escribir en local y subir. */
        class Merged(val bytes: ByteArray) : Result
    }

    fun reconcile(
        local: ByteArray, remote: ByteArray, provenance: Map<String, String>, nowIso: String
    ): Result {
        if (provenance.isEmpty()) return Result.NotApplicable
        val l = JSONObject(String(local, Charsets.UTF_8))
        val r = JSONObject(String(remote, Charsets.UTF_8))
        if (!isPristineExceptWorkouts(l)) return Result.NotApplicable
        val localWorkouts = l.optJSONArray("workouts") ?: JSONArray()
        if (localWorkouts.length() == 0) return Result.NotApplicable
        for (i in 0 until localWorkouts.length()) {
            val w = localWorkouts.getJSONObject(i)
            val expected = provenance[w.optString("id")] ?: return Result.NotApplicable
            if (WorkoutMirrorStore.canonicalDigest(w) != expected) return Result.NotApplicable
        }
        val remoteWorkouts = r.optJSONArray("workouts") ?: JSONArray()
        val remoteById = (0 until remoteWorkouts.length()).map { remoteWorkouts.getJSONObject(it) }.associateBy { it.optString("id") }
        // Misma ID con contenido distinto en Drive y local: incertidumbre -> camino normal (conflicto/copias), nunca elegir aquí.
        for (i in 0 until localWorkouts.length()) {
            val w = localWorkouts.getJSONObject(i)
            val other = remoteById[w.optString("id")] ?: continue
            if (WorkoutMirrorStore.canonicalDigest(other) != WorkoutMirrorStore.canonicalDigest(w)) return Result.NotApplicable
        }
        val remoteIds = remoteById.keys
        val extras = (0 until localWorkouts.length()).map { localWorkouts.getJSONObject(it) }
            .filter { it.optString("id") !in remoteIds }
        if (extras.isEmpty()) return Result.UseRemote
        val all = (0 until remoteWorkouts.length()).map { remoteWorkouts.getJSONObject(it) } + extras
        val sorted = all.sortedByDescending { it.optString("finishedAt").ifBlank { it.optString("startedAt") } }
        val merged = JSONObject(r.toString())
        merged.put("workouts", JSONArray().also { out -> sorted.forEach { out.put(JSONObject(it.toString())) } })
        merged.put("syncRevision", r.optInt("syncRevision", 0) + 1)
        merged.put("updatedAt", nowIso)
        merged.put("lastWriterDeviceId", l.optString("lastWriterDeviceId"))
        return Result.Merged(merged.toString().toByteArray(Charsets.UTF_8))
    }

    /** Como isVirgin de DriveSnapshotService, ignorando workouts y los tres campos de versión que cada save() actualiza. */
    internal fun isPristineExceptWorkouts(state: JSONObject): Boolean {
        fun emptyArray(key: String) = state.optJSONArray(key)?.length() == 0
        fun emptyObject(key: String) = state.optJSONObject(key)?.length() == 0
        val exercises = state.optJSONArray("exercises") ?: return false
        return emptyArray("routines") && emptyArray("bodyWeights") && emptyArray("favoriteTimers") &&
            emptyObject("settings") && emptyObject("exerciseLoadPrefs") &&
            state.optJSONObject("activeSession") == null &&
            (exercises.length() == 196 || exercises.length() == 278 || exercises.length() == 280) &&
            (0 until exercises.length()).none { exercises.getJSONObject(it).optBoolean("isCustom") }
    }
}
