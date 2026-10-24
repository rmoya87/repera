package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId

/** Mapeo y filtrado del espejo de calendario IA (AITrainingContextStore). */
class AITrainingContextStoreTest {

    private val zone: ZoneId = ZoneId.of("Europe/Madrid")
    private val today: LocalDate = LocalDate.of(2026, 10, 24)

    private fun catalog(): List<JSONObject> = listOf(
        JSONObject().put("id", "ex-1").put("name", "Sentadilla")
            .put("catalogId", "squat"),
        JSONObject().put("id", "ex-2").put("name", "Carrera")
    )

    private fun strengthRoutine(id: String): JSONObject {
        val set = JSONObject().put("id", "s1").put("targetReps", 5)
            .put("targetWeightKg", 100.0).put("targetRir", 2.0)
        val entry = JSONObject().put("id", "e1").put("exerciseId", "ex-1")
            .put("plannedSets", JSONArray().put(set))
        val block = JSONObject().put("kind", "strength").put("title", "Fuerza")
            .put("exercises", JSONArray().put(entry))
        return JSONObject().put("id", id).put("title", "Pierna")
            .put("weekday", 6).put("scheduledTimeMinutes", 1080)
            .put("blocks", JSONArray().put(block))
    }

    private fun wodRoutine(id: String, date: LocalDate): JSONObject {
        val movement = JSONObject().put("id", "m1").put("exerciseId", "ex-2")
            .put("name", "Carrera").put("distanceMeters", 400)
        val block = JSONObject().put("kind", "wod").put("title", "WOD")
            .put("wodFormat", "amrap").put("timeCapMinutes", 12)
            .put("movements", JSONArray().put(movement))
        return JSONObject().put("id", id).put("title", "Metcon")
            .put("scheduledDate", date.atStartOfDay(zone).toInstant().toString())
            .put("blocks", JSONArray().put(block))
    }

    @Test
    fun strengthRoutineMapsCatalogAndPlannedSets() {
        val items = AITrainingContextStore.buildItems(
            listOf(strengthRoutine("r1")), catalog(), today, zone)
        assertEquals(1, items.length())
        val item = items.getJSONObject(0)
        assertEquals("r1", item.getString("routineId"))
        assertEquals(6, item.getInt("weekday"))
        assertEquals(1080, item.getInt("scheduledTimeMinutes"))
        assertFalse(item.has("scheduledDate"))
        val block = item.getJSONArray("blocks").getJSONObject(0)
        assertEquals("strength", block.getString("kind"))
        val exercise = block.getJSONArray("strengthExercises").getJSONObject(0)
        assertEquals("Sentadilla", exercise.getString("name"))
        assertEquals("squat", exercise.getString("catalogKey"))
        val set = exercise.getJSONArray("plannedSets").getJSONObject(0)
        assertEquals(5, set.getInt("reps"))
        assertEquals(100.0, set.getDouble("weightKg"), 0.0)
        assertEquals(2.0, set.getDouble("rir"), 0.0)
        assertFalse(set.getBoolean("percent1RMIsMinimum"))
        assertFalse(set.has("percent1RM"))
    }

    @Test
    fun wodRoutineMapsMovementsAndScheduleDateAsLocalDay() {
        val items = AITrainingContextStore.buildItems(
            listOf(wodRoutine("r2", today.plusDays(3))), catalog(), today, zone)
        assertEquals(1, items.length())
        val item = items.getJSONObject(0)
        assertEquals(today.plusDays(3).toString(), item.getString("scheduledDate"))
        assertFalse(item.has("weekday"))
        val block = item.getJSONArray("blocks").getJSONObject(0)
        assertEquals("amrap", block.getString("wodFormat"))
        assertEquals(12, block.getInt("timeCapMinutes"))
        val movement = block.getJSONArray("movements").getJSONObject(0)
        assertEquals("Carrera", movement.getString("name"))
        assertEquals(400, movement.getInt("distanceMeters"))
        assertFalse(movement.has("catalogKey"))
        assertFalse(movement.has("reps"))
    }

    @Test
    fun unscheduledAndOutOfHorizonRoutinesAreExcluded() {
        val unscheduled = JSONObject().put("id", "r3").put("title", "Libre")
            .put("blocks", JSONArray())
        val past = wodRoutine("r4", today.minusDays(1))
        val beyond = wodRoutine("r5",
            today.plusDays(AITrainingContextStore.HORIZON_DAYS + 1))
        val edge = wodRoutine("r6", today.plusDays(AITrainingContextStore.HORIZON_DAYS))
        val items = AITrainingContextStore.buildItems(
            listOf(unscheduled, past, beyond, edge), catalog(), today, zone)
        assertEquals(1, items.length())
        assertEquals("r6", items.getJSONObject(0).getString("routineId"))
    }

    @Test
    fun unknownExerciseGetsFallbackNameWithoutCatalogKey() {
        val set = JSONObject().put("targetReps", 8)
        val entry = JSONObject().put("exerciseId", "ex-borrado")
            .put("plannedSets", JSONArray().put(set))
        val block = JSONObject().put("kind", "strength").put("title", "t")
            .put("exercises", JSONArray().put(entry))
        val routine = JSONObject().put("id", "r7").put("title", "t")
            .put("weekday", 1).put("blocks", JSONArray().put(block))
        val items = AITrainingContextStore.buildItems(
            listOf(routine), catalog(), today, zone)
        val exercise = items.getJSONObject(0).getJSONArray("blocks")
            .getJSONObject(0).getJSONArray("strengthExercises").getJSONObject(0)
        assertEquals("Ejercicio sin catálogo", exercise.getString("name"))
        assertFalse(exercise.has("catalogKey"))
    }
}
