package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Espejo del comportamiento de isWorkoutFavorite/toggleWorkoutFavorite (Apple c5aae1cc). */
class WorkoutFavoriteSupportTest {

    private fun stateWith(workouts: JSONArray, routines: JSONArray) =
        JSONObject().put("workouts", workouts).put("routines", routines)

    private fun routine(id: String, favorite: Boolean) =
        JSONObject().put("id", id).put("title", "Rutina $id").put("isFavorite", favorite)

    private fun session(id: String, routineId: String? = null, favoriteRoutineId: String? = null, withExercise: Boolean = true): JSONObject {
        val s = JSONObject().put("id", id).put("title", "Entreno $id")
        routineId?.let { s.put("routineId", it) }
        favoriteRoutineId?.let { s.put("favoriteRoutineId", it) }
        if (withExercise) s.put("exercises", JSONArray().put(JSONObject()
            .put("id", "entry-1").put("blockId", "block-1").put("blockKind", "strength")
            .put("exercise", JSONObject().put("id", "ex-1").put("name", "Press banca"))
            .put("loggedSets", JSONArray().put(JSONObject().put("id", "set-1").put("reps", 8)))))
        return s
    }

    @Test fun favoriteViaFavoriteRoutineIdWins() {
        val state = stateWith(
            JSONArray().put(session("w1", routineId = "r-old", favoriteRoutineId = "r-fav")),
            JSONArray().put(routine("r-old", false)).put(routine("r-fav", true)))
        assertTrue(WorkoutFavoriteSupport.isWorkoutFavorite(state, "w1"))
    }

    @Test fun favoriteViaRoutineIdWhenNoFavoriteRoutineId() {
        val state = stateWith(
            JSONArray().put(session("w1", routineId = "r1")),
            JSONArray().put(routine("r1", true)))
        assertTrue(WorkoutFavoriteSupport.isWorkoutFavorite(state, "w1"))
        state.getJSONArray("routines").getJSONObject(0).put("isFavorite", false)
        assertFalse(WorkoutFavoriteSupport.isWorkoutFavorite(state, "w1"))
    }

    @Test fun toggleFlipsLinkedRoutineWithoutTouchingSchedule() {
        val state = stateWith(
            JSONArray().put(session("w1", routineId = "r1")),
            JSONArray().put(routine("r1", false)))
        assertTrue(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "w1"))
        assertTrue(state.getJSONArray("routines").getJSONObject(0).getBoolean("isFavorite"))
        assertTrue(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "w1"))
        assertFalse(state.getJSONArray("routines").getJSONObject(0).getBoolean("isFavorite"))
    }

    @Test fun looseSessionCreatesTemplateOnceAndKeepsItsId() {
        val state = stateWith(JSONArray().put(session("w1")), JSONArray())
        assertTrue(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "w1"))
        val routines = state.getJSONArray("routines")
        assertEquals(1, routines.length())
        val template = routines.getJSONObject(0)
        assertTrue(template.getBoolean("isFavorite"))
        assertEquals("Entreno w1", template.getString("title"))
        val favoriteId = state.getJSONArray("workouts").getJSONObject(0).getString("favoriteRoutineId")
        assertEquals(template.getString("id"), favoriteId)
        // Segundo toque: desmarca la MISMA plantilla, no crea otra.
        assertTrue(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "w1"))
        assertEquals(1, state.getJSONArray("routines").length())
        assertFalse(template.getBoolean("isFavorite"))
        assertFalse(WorkoutFavoriteSupport.isWorkoutFavorite(state, "w1"))
    }

    @Test fun sessionWithoutBlocksCreatesNoEmptyTemplate() {
        val state = stateWith(JSONArray().put(session("w1", withExercise = false)), JSONArray())
        assertFalse(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "w1"))
        assertEquals(0, state.getJSONArray("routines").length())
    }

    @Test fun unknownSessionIsNoOp() {
        val state = stateWith(JSONArray(), JSONArray())
        assertFalse(WorkoutFavoriteSupport.isWorkoutFavorite(state, "nope"))
        assertFalse(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "nope"))
    }

    @Test fun liveSportSessionCreatesSportFavoriteNotEmptyRoutine() {
        val session = JSONObject()
            .put("id", "live-1")
            .put("title", "Carrera parque")
            .put("liveSportID", "running")
        val state = stateWith(JSONArray().put(session), JSONArray())
        assertTrue(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "live-1"))
        assertEquals(0, state.getJSONArray("routines").length())
        val sports = state.getJSONArray("favoriteSportActivities")
        assertEquals(1, sports.length())
        assertEquals("running", sports.getJSONObject(0).getString("sportID"))
        assertEquals("Carrera parque", sports.getJSONObject(0).getString("title"))
        assertTrue(WorkoutFavoriteSupport.isWorkoutFavorite(state, "live-1"))
        assertEquals(1, WorkoutFavoriteSupport.favoriteCount(state))
        // Segundo toque quita el favorito de deporte.
        assertTrue(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "live-1"))
        assertEquals(0, sports.length())
        assertFalse(WorkoutFavoriteSupport.isWorkoutFavorite(state, "live-1"))
    }

    @Test fun liveSportFavoriteRespectsQuota() {
        val session = JSONObject()
            .put("id", "live-2")
            .put("title", "Bici")
            .put("liveSportID", "cycling")
        val state = stateWith(JSONArray().put(session), JSONArray())
        assertFalse(WorkoutFavoriteSupport.toggleWorkoutFavorite(state, "live-2", allowNewFavorite = false))
        assertFalse(state.has("favoriteSportActivities") &&
            state.getJSONArray("favoriteSportActivities").length() > 0)
    }

    @Test fun removeFavoriteSportActivityById() {
        val state = stateWith(JSONArray(), JSONArray())
        state.put("favoriteSportActivities", JSONArray().put(JSONObject()
            .put("id", "fav-1").put("sourceWorkoutId", "w1")
            .put("sportID", "running").put("title", "Run")))
        assertTrue(WorkoutFavoriteSupport.removeFavoriteSportActivity(state, "fav-1"))
        assertEquals(0, state.getJSONArray("favoriteSportActivities").length())
    }
}
