package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Port de ReperaStore.isWorkoutFavorite / toggleWorkoutFavorite (Apple c5aae1cc).
 * El favorito de un entreno completado se mantiene tras cerrar y reabrir el
 * detalle; marca o desmarca SIN modificar la programación original. Las sesiones
 * sueltas conservan el ID de su plantilla favorita (favoriteRoutineId) para no
 * duplicarla.
 *
 * Límite más conservador que Apple (abierto): Apple crea siempre plantilla aunque
 * la sesión no produzca bloques (con un bloque strength vacío por defecto); aquí,
 * como en el flujo saveAsFavorite ya portado, no se crea plantilla vacía.
 */
internal object WorkoutFavoriteSupport {

    private fun findWorkout(state: JSONObject, id: String): JSONObject? {
        val workouts = state.optJSONArray("workouts") ?: return null
        for (i in 0 until workouts.length()) {
            val w = workouts.getJSONObject(i)
            if (w.optString("id") == id) return w
        }
        return null
    }

    private fun findRoutine(state: JSONObject, id: String): JSONObject? {
        val routines = state.optJSONArray("routines") ?: return null
        for (i in 0 until routines.length()) {
            val r = routines.getJSONObject(i)
            if (r.optString("id") == id) return r
        }
        return null
    }

    /** isWorkoutFavorite iOS: favoriteRoutineId → rutina.isFavorite; si no, routineId. */
    fun isWorkoutFavorite(state: JSONObject, id: String): Boolean {
        val session = findWorkout(state, id) ?: return false
        session.optString("favoriteRoutineId").takeIf { it.isNotBlank() }?.let { fid ->
            return findRoutine(state, fid)?.optBoolean("isFavorite") == true
        }
        val routineId = session.optString("routineId").takeIf { it.isNotBlank() } ?: return false
        return findRoutine(state, routineId)?.optBoolean("isFavorite") == true
    }

    /** toggleWorkoutFavorite iOS. Devuelve true si hubo cambio que persistir. */
    fun toggleWorkoutFavorite(state: JSONObject, id: String): Boolean {
        val session = findWorkout(state, id) ?: return false
        session.optString("favoriteRoutineId").takeIf { it.isNotBlank() }?.let { fid ->
            val routine = findRoutine(state, fid) ?: return false
            routine.put("isFavorite", !routine.optBoolean("isFavorite"))
            return true
        }
        session.optString("routineId").takeIf { it.isNotBlank() }?.let { rid ->
            val routine = findRoutine(state, rid) ?: return false
            routine.put("isFavorite", !routine.optBoolean("isFavorite"))
            return true
        }
        // Sesión suelta: plantilla favorita nueva desde la sesión, sin duplicarla.
        val src = CompletedWorkoutEditing.blocksFrom(session, null)
        val copy = JSONArray()
        for (k in 0 until src.length())
            EditorBlockOps.freshIds(src.getJSONObject(k).toString())?.let { copy.put(JSONObject(it)) }
        if (copy.length() == 0) return false
        val routines = state.optJSONArray("routines") ?: return false
        val templateId = UUID.randomUUID().toString()
        val title = session.optString("title").ifBlank { "Favorito" }
        routines.put(JSONObject()
            .put("id", templateId).put("title", title).put("blocks", copy)
            .put("progression", "off").put("isFavorite", true))
        session.put("favoriteRoutineId", templateId)
        return true
    }
}
