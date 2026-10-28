package dev.repera.mobile

import dev.repera.domain.RoutineBlockKind
import dev.repera.domain.WODFormat
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/** Validación del payload de ai_training_plans (port de AITrainingInboxStore). */
class AITrainingInboxTest {

    private val inbox = AITrainingInbox()
    private val resolver: (String, String?) -> String = { name, key ->
        key ?: "resolved-$name"
    }

    private fun plan(payload: JSONObject, title: String = "Fuerza 5x5") =
        JSONObject()
            .put("id", "plan-1")
            .put("title", title)
            .put("payload", payload)

    private fun strengthPayload(): JSONObject {
        val sets = JSONArray()
            .put(JSONObject().put("reps", 5).put("weightKg", 80.0).put("rir", 2.0))
            .put(JSONObject().put("reps", 5).put("percent1RM", 75.0)
                .put("percent1RMIsMinimum", true))
        val exercise = JSONObject()
            .put("name", "Sentadilla trasera")
            .put("catalogKey", "back_squat")
            .put("restSeconds", 120)
            .put("plannedSets", sets)
        val block = JSONObject()
            .put("kind", "strength")
            .put("title", "Bloque A")
            .put("exercises", JSONArray().put(exercise))
        return JSONObject()
            .put("schemaVersion", 1)
            .put("blocks", JSONArray().put(block))
    }

    @Test
    fun strengthPlanParsesSetsRirAndPercent() {
        val (title, blocks) = inbox.buildRoutine(plan(strengthPayload()), resolver)
        assertEquals("Fuerza 5x5", title)
        assertEquals(1, blocks.size)
        val block = blocks[0]
        assertEquals(RoutineBlockKind.STRENGTH, block.kind)
        val exercise = block.exercises.single()
        assertEquals("back_squat", exercise.exerciseId)
        assertEquals(120, exercise.restSeconds)
        assertEquals(2, exercise.plannedSets.size)
        assertEquals(80.0, exercise.plannedSets[0].targetWeightKg!!, 0.001)
        assertEquals(2.0, exercise.plannedSets[0].targetRir!!, 0.001)
        assertEquals(75.0, exercise.plannedSets[1].targetPercent1RM!!, 0.001)
        assertTrue(exercise.plannedSets[1].targetPercent1RMIsMinimum)
    }

    @Test
    fun rejectsWrongSchemaVersion() {
        val payload = strengthPayload().put("schemaVersion", 2)
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(payload), resolver)
        }
    }

    @Test
    fun rejectsEmptyBlocks() {
        val payload = JSONObject().put("schemaVersion", 1)
            .put("blocks", JSONArray())
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(payload), resolver)
        }
    }

    @Test
    fun rejectsEmptyTitle() {
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(strengthPayload(), title = "  "), resolver)
        }
    }

    @Test
    fun rejectsOutOfRangeRepsAndRir() {
        val bad = strengthPayload()
        val sets = bad.getJSONArray("blocks").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets")
        sets.put(JSONObject().put("reps", 5001))
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(bad), resolver)
        }
        val bad2 = strengthPayload()
        bad2.getJSONArray("blocks").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets")
            .put(JSONObject().put("reps", 5).put("rir", 11.0))
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(bad2), resolver)
        }
    }

    @Test
    fun rejectsStrengthBlockWithMovements() {
        val payload = strengthPayload()
        payload.getJSONArray("blocks").getJSONObject(0)
            .put("movements", JSONArray().put(JSONObject().put("name", "x")))
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(payload), resolver)
        }
    }

    @Test
    fun wodPlanParsesFormatAndMovements() {
        val movement = JSONObject()
            .put("name", "Power clean")
            .put("reps", 6)
            .put("weightMaleKg", 50.0)
            .put("weightFemaleKg", 35.0)
        val rest = JSONObject()
            .put("name", "Descanso")
            .put("isRest", true)
            .put("restSeconds", 60)
        val block = JSONObject()
            .put("kind", "wod")
            .put("title", "Metcon")
            .put("wodFormat", "forTime")
            .put("rounds", 4)
            .put("timeCapMinutes", 12)
            .put("movements", JSONArray().put(movement).put(rest))
        val payload = JSONObject().put("schemaVersion", 1)
            .put("blocks", JSONArray().put(block))
        val (_, blocks) = inbox.buildRoutine(plan(payload, "WOD del día"), resolver)
        val parsed = blocks.single()
        assertEquals(RoutineBlockKind.WOD, parsed.kind)
        assertEquals(WODFormat.FOR_TIME, parsed.wodFormat)
        assertEquals(4, parsed.rounds)
        assertEquals(2, parsed.movements.size)
        assertEquals("resolved-Power clean", parsed.movements[0].exerciseId)
        assertEquals(6, parsed.movements[0].reps)
        assertTrue(parsed.movements[1].isRest)
    }

    @Test
    fun emomBlockDerivesRounds() {
        val movement = JSONObject().put("name", "Remo").put("calories", 12)
        val block = JSONObject()
            .put("kind", "wod")
            .put("title", "EMOM")
            .put("wodFormat", "emom")
            .put("timeCapMinutes", 12)
            .put("emomIntervalSeconds", 60)
            .put("movements", JSONArray().put(movement))
        val payload = JSONObject().put("schemaVersion", 1)
            .put("blocks", JSONArray().put(block))
        val (_, blocks) = inbox.buildRoutine(plan(payload), resolver)
        val parsed = blocks.single()
        assertEquals(WODFormat.EMOM, parsed.wodFormat)
        assertNotNull(parsed.rounds)
        assertEquals(12, parsed.rounds)
    }

    @Test
    fun rejectsWodWithoutFormat() {
        val movement = JSONObject().put("name", "Remo").put("calories", 12)
        val block = JSONObject()
            .put("kind", "wod")
            .put("title", "Metcon")
            .put("movements", JSONArray().put(movement))
        val payload = JSONObject().put("schemaVersion", 1)
            .put("blocks", JSONArray().put(block))
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(payload), resolver)
        }
    }
    @Test fun invalidLaterBlockNeverCallsMutatingCatalogResolver() {
        val payload=strengthPayload()
        payload.getJSONArray("blocks").put(JSONObject().put("kind","unknown").put("title","Invalid"))
        var calls=0
        assertThrows(Exception::class.java) {
            inbox.buildRoutine(plan(payload)) {_,_ ->calls++;"would-create"}
        }
        assertEquals(0,calls)
    }

    @Test fun validPayloadResolvesEachExerciseOnlyAfterValidation() {
        var calls=0
        val (_,blocks)=inbox.buildRoutine(plan(strengthPayload())) {_,_ ->calls++;"real-id"}
        assertEquals(1,calls);assertEquals("real-id",blocks.single().exercises.single().exerciseId)
    }
}
