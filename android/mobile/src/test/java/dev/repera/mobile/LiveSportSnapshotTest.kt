package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class LiveSportSnapshotTest {
    private fun activity(id: Int) = JSONObject().put("id", "$id").put("title", "Carrera $id")
        .put("phase", "finished").put("liveSportID", "running")
        .put("startedAt", "2026-10-25T09:00:00Z").put("finishedAt", "2026-10-25T10:00:00Z")
        .put("activeDurationSeconds", 1800.0).put("recordedDistanceMeters", 5000.0)

    @Test fun usesEntireArchiveNotTwentyRecentCards() {
        val array = JSONArray(); repeat(25) { array.put(activity(it)) }
        assertEquals(25, LiveSportSnapshot.sessions(JSONObject().put("workouts", array)).size)
    }
    @Test fun excludesUnfinishedAndClassicSessions() {
        val array = JSONArray().put(activity(1).put("phase", "active"))
            .put(activity(2).put("finishedAt", JSONObject.NULL))
            .put(activity(3).put("liveSportID", JSONObject.NULL)).put(activity(4))
        assertEquals(listOf("4"), LiveSportSnapshot.sessions(JSONObject().put("workouts", array)).map { it.id })
    }
    @Test fun onlyMeasuredHealthValuesSurvive() {
        val s = activity(1).put("appleActiveEnergyKcal", JSONObject.NULL)
            .put("appleAverageHeartRateBpm", 146.0)
        val a = LiveSportSnapshot.sessions(JSONObject().put("workouts", JSONArray().put(s))).single()
        assertNull(a.activeEnergyKcal); assertEquals(146.0, a.averageHeartRateBpm!!, 0.0)
        assertNull(a.liveRouteID)
    }
}
