package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject

/**
 * Paridad Apple ReperaStore.resetUserData: conserva el catalogo de ejercicios
 * y vacia rutinas, entrenos, peso y sesion activa. Funcion pura sobre el
 * estado local; no toca Drive, espejo, colas ni sensores (eso lo orquesta
 * WorkoutRepository.resetUserData y sigue abierto, ver PARITY_DELTA).
 */
object UserDataReset {
    /** Ids de entrenos que necesitan tombstone antes de vaciar el archivo. */
    fun workoutIds(state: JSONObject): List<String> {
        val workouts = state.optJSONArray("workouts") ?: return emptyList()
        return (0 until workouts.length()).mapNotNull {
            workouts.optJSONObject(it)?.optString("id")?.takeIf { id -> id.isNotBlank() }
        }
    }

    /**
     * Ids que deben quedar en deletedIds() antes de vaciar: entrenos terminados MAS la sesion activa.
     * adoptWearSession rechaza ids de deletedIds(), asi un set/sesion en cola en el reloj no recrea la sesion
     * descartada (sin tocar el protocolo Wear). Contrapartida: noteDeleted tambien encola un tombstone remoto
     * para esa sesion no terminada.
     */
    fun discardedIds(state: JSONObject): List<String> =
        (workoutIds(state) + listOfNotNull(
            state.optJSONObject("activeSession")?.optString("id")?.takeIf { it.isNotBlank() }
        )).distinct()

    /** Vacia en el sitio los datos de usuario; deja exercises y settings intactos. */
    fun clear(state: JSONObject) {
        state.put("routines", JSONArray())
        state.put("workouts", JSONArray())
        state.put("bodyWeights", JSONArray())
        state.remove("activeSession")
    }
}
