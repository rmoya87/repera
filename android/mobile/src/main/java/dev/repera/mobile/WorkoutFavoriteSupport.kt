package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Port de ReperaStore.isWorkoutFavorite / toggleWorkoutFavorite (Apple c5aae1cc +
 * favoriteSportActivities). El favorito de un entreno completado se mantiene tras
 * cerrar y reabrir el detalle; marca o desmarca SIN modificar la programación
 * original. Las sesiones Comenzar (liveSportID) guardan un acceso reutilizable al
 * deporte en `favoriteSportActivities`, nunca una rutina vacía.
 *
 * Límite más conservador que Apple (abierto) para plantillas de fuerza: Apple
 * crea siempre plantilla aunque la sesión no produzca bloques; aquí, como en el
 * flujo saveAsFavorite ya portado, no se crea plantilla vacía.
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

    private fun sportFavorites(state: JSONObject): JSONArray {
        val existing = state.optJSONArray("favoriteSportActivities")
        if (existing != null) return existing
        return JSONArray().also { state.put("favoriteSportActivities", it) }
    }

    /** Rutinas ★ + actividades Comenzar (paridad favoriteCount iOS). */
    fun favoriteCount(state: JSONObject): Int {
        val routines = state.optJSONArray("routines")
        var count = 0
        if (routines != null) {
            for (i in 0 until routines.length()) {
                if (routines.getJSONObject(i).optBoolean("isFavorite")) count++
            }
        }
        count += state.optJSONArray("favoriteSportActivities")?.length() ?: 0
        return count
    }

    fun listFavoriteSportActivities(state: JSONObject): List<FavoriteSportActivity> {
        val arr = state.optJSONArray("favoriteSportActivities") ?: return emptyList()
        return (0 until arr.length()).mapNotNull { i ->
            val o = arr.optJSONObject(i) ?: return@mapNotNull null
            val id = o.optString("id").takeIf { it.isNotBlank() } ?: return@mapNotNull null
            val sportID = o.optString("sportID").takeIf { it.isNotBlank() } ?: return@mapNotNull null
            FavoriteSportActivity(
                id = id,
                sourceWorkoutId = o.optString("sourceWorkoutId"),
                sportID = sportID,
                title = o.optString("title").ifBlank { "Mi actividad" }
            )
        }
    }

    fun removeFavoriteSportActivity(state: JSONObject, id: String): Boolean {
        val arr = state.optJSONArray("favoriteSportActivities") ?: return false
        for (i in 0 until arr.length()) {
            if (arr.getJSONObject(i).optString("id") == id) {
                arr.remove(i)
                return true
            }
        }
        return false
    }

    /** isWorkoutFavorite iOS: sport favorites → favoriteRoutineId → routineId. */
    fun isWorkoutFavorite(state: JSONObject, id: String): Boolean {
        val sports = state.optJSONArray("favoriteSportActivities")
        if (sports != null) {
            for (i in 0 until sports.length()) {
                if (sports.getJSONObject(i).optString("sourceWorkoutId") == id) return true
            }
        }
        val session = findWorkout(state, id) ?: return false
        session.optString("favoriteRoutineId").takeIf { it.isNotBlank() }?.let { fid ->
            return findRoutine(state, fid)?.optBoolean("isFavorite") == true
        }
        val routineId = session.optString("routineId").takeIf { it.isNotBlank() } ?: return false
        return findRoutine(state, routineId)?.optBoolean("isFavorite") == true
    }

    /**
     * toggleWorkoutFavorite iOS. [allowNewFavorite] aplica solo al crear un
     * favorito nuevo (cupo Gratis); quitar siempre está permitido.
     * Devuelve true si hubo cambio que persistir.
     */
    fun toggleWorkoutFavorite(
        state: JSONObject,
        id: String,
        allowNewFavorite: Boolean = true
    ): Boolean {
        val session = findWorkout(state, id) ?: return false
        val sports = sportFavorites(state)
        for (i in 0 until sports.length()) {
            if (sports.getJSONObject(i).optString("sourceWorkoutId") == session.optString("id")) {
                sports.remove(i)
                return true
            }
        }
        val sportID = session.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" }
        if (sportID != null) {
            // Legacy: favorito vía rutina vinculada a un live sport → desmarcar.
            val legacyIds = listOfNotNull(
                session.optString("favoriteRoutineId").takeIf { it.isNotBlank() },
                session.optString("routineId").takeIf { it.isNotBlank() }
            )
            for (rid in legacyIds) {
                val linked = findRoutine(state, rid) ?: continue
                if (linked.optBoolean("isFavorite")) {
                    linked.put("isFavorite", false)
                    return true
                }
            }
            if (!allowNewFavorite) return false
            sports.put(
                JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("sourceWorkoutId", session.optString("id"))
                    .put("sportID", sportID)
                    .put("title", session.optString("title").ifBlank { "Mi actividad" })
            )
            return true
        }
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
        if (!allowNewFavorite) return false
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

/** Acceso reutilizable a un deporte de Comenzar (paridad FavoriteSportActivity iOS). */
data class FavoriteSportActivity(
    val id: String,
    val sourceWorkoutId: String,
    val sportID: String,
    val title: String
)
