package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WODScoreScalingTest {
    private fun block() = JSONObject()
        .put("id", "w1").put("kind", "wod").put("wodFormat", "amrap")
    private fun session() = JSONObject().put("wodResults", JSONArray().put(
        JSONObject().put("id", "w1").put("format", "amrap")
            .put("totalReps", 3).put("roundsCompleted", 8)
    ))

    @Test fun explicitRxAndScaleArePersistedAndCanBeCleared() {
        val original = session()
        val rx = CompletedWorkoutEditing.changingScoreScale(original, block(), true)
        assertTrue(rx.getJSONArray("wodResults").getJSONObject(0).getBoolean("isRx"))
        assertFalse(original.getJSONArray("wodResults").getJSONObject(0).has("isRx"))

        val scaled = CompletedWorkoutEditing.changingScoreScale(rx, block(), false)
        assertFalse(scaled.getJSONArray("wodResults").getJSONObject(0).getBoolean("isRx"))
        val unknown = CompletedWorkoutEditing.changingScoreScale(scaled, block(), null)
        assertFalse(unknown.getJSONArray("wodResults").getJSONObject(0).has("isRx"))
        assertEquals(3, unknown.getJSONArray("wodResults").getJSONObject(0).getInt("totalReps"))
    }

    @Test fun togglingRxWithoutAnExistingResultDoesNotFabricateAScore() {
        val empty = JSONObject().put("wodResults", JSONArray())
        val updated = CompletedWorkoutEditing.changingScoreScale(empty, block(), true)
        assertEquals(0, updated.getJSONArray("wodResults").length())
    }
}
