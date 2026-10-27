package dev.repera.domain
import org.junit.Assert.assertEquals
import org.junit.Test

class WearBlockStartsTest {
    @Test fun consecutiveSameBlockCollapses() = assertEquals(listOf(0, 2, 3), WearBlockStarts.of(listOf("a", "a", "b", "c", "c")))
    @Test fun missingIdsAlwaysStartNewEntries() = assertEquals(listOf(0, 1, 2, 3), WearBlockStarts.of(listOf(null, null, "a", null)))
    @Test fun nonConsecutiveRepeatStartsAgain() = assertEquals(listOf(0, 1, 2), WearBlockStarts.of(listOf("a", "b", "a")))
    @Test fun emptyIsEmpty() = assertEquals(emptyList<Int>(), WearBlockStarts.of(emptyList()))
}

class WatchPlanSelectTest {
    private fun session(index: Int, phase: String) = org.json.JSONObject()
        .put("exercises", org.json.JSONArray().put(org.json.JSONObject()).put(org.json.JSONObject()).put(org.json.JSONObject()))
        .put("currentIndex", index).put("phase", phase)
    @Test fun jumpSetsIndexAndReadyWithoutTouchingExercises() {
        val s = session(0, "counting")
        val r = WatchPlanExecution.select(s, 2)!!
        assertEquals(2, r.getInt("currentIndex")); assertEquals("ready", r.getString("phase"))
        assertEquals(0, s.getInt("currentIndex"))
        assertEquals(s.getJSONArray("exercises").toString(), r.getJSONArray("exercises").toString())
    }
    @Test fun outOfRangeOrAlreadyCurrentReadyIsNoop() {
        assertEquals(null, WatchPlanExecution.select(session(0, "counting"), 3))
        assertEquals(null, WatchPlanExecution.select(session(0, "counting"), -1))
        assertEquals(null, WatchPlanExecution.select(session(1, "ready"), 1))
        assertEquals("ready", WatchPlanExecution.select(session(1, "counting"), 1)!!.getString("phase"))
    }
}
