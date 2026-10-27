package dev.repera.domain
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import java.time.Instant
class WatchPlanExecutionTest {
    private fun plan()=JSONObject().put("id","prescription").put("routineId","routine")
        .put("startedAt","2026-10-25T00:00:00Z").put("title","Plan")
        .put("exercises",JSONArray().put(JSONObject().put("plannedSets",JSONArray().put(JSONObject().put("targetReps",5)))))
    @Test fun executionStartsAtTapWithFreshIdentityAndLeavesPrescriptionUnchanged() {
        val source=plan();val before=source.toString();val now=Instant.parse("2026-10-26T04:45:00Z")
        val a=WatchPlanExecution.begin(source,"execution-a",now)
        val b=WatchPlanExecution.begin(source,"execution-b",now.plusSeconds(60))
        assertEquals(before,source.toString());assertNotEquals(a.getString("id"),b.getString("id"))
        assertEquals(now.toString(),a.getString("startedAt"));assertEquals("counting",a.getString("phase"))
        assertEquals("routine",a.getString("routineId"))
        assertEquals(5,a.getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
    }
    @Test fun recordedWorkCannotBeRecycledAsFreshPrescription() {
        val source=plan();source.getJSONArray("exercises").getJSONObject(0).put("loggedSets",JSONArray().put(JSONObject().put("reps",5)))
        assertTrue(runCatching {WatchPlanExecution.begin(source,"new")}.isFailure)
    }
}
