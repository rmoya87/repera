package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class UserDataResetTest {
    private fun state() = JSONObject()
        .put("exercises", JSONArray().put(JSONObject().put("id", "e1")))
        .put("routines", JSONArray().put(JSONObject().put("id", "r1")))
        .put("workouts", JSONArray().put(JSONObject().put("id", "w1")).put(JSONObject().put("id", "w2")))
        .put("bodyWeights", JSONArray().put(JSONObject().put("id", "b1")))
        .put("activeSession", JSONObject().put("id", "s1"))
        .put("settings", JSONObject().put("x", 1))

    @Test fun clearKeepsCatalogAndSettingsAndEmptiesUserData() {
        val s = state()
        UserDataReset.clear(s)
        assertEquals(1, s.getJSONArray("exercises").length())
        assertEquals(1, s.getJSONObject("settings").getInt("x"))
        assertEquals(0, s.getJSONArray("routines").length())
        assertEquals(0, s.getJSONArray("workouts").length())
        assertEquals(0, s.getJSONArray("bodyWeights").length())
        assertFalse(s.has("activeSession"))
    }

    @Test fun workoutIdsListedBeforeClearForTombstones() {
        assertEquals(listOf("w1", "w2"), UserDataReset.workoutIds(state()))
        assertEquals(emptyList<String>(), UserDataReset.workoutIds(JSONObject()))
    }

    @Test fun discardedIdsIncludeActiveSessionOnceAndNoBlank() {
        assertEquals(listOf("w1", "w2", "s1"), UserDataReset.discardedIds(state()))
        val dup = state().also { it.getJSONObject("activeSession").put("id", "w1") }
        assertEquals(listOf("w1", "w2"), UserDataReset.discardedIds(dup))
        assertEquals(emptyList<String>(), UserDataReset.discardedIds(JSONObject().put("activeSession", JSONObject().put("id", ""))))
    }
}
