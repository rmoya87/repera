package dev.repera.mobile

import org.json.*
import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test

class WeeklyScheduleActionsTest {
    private fun fixture(): JSONObject = JSONObject("""{
      "routines":[{"id":"past","title":"Anterior","scheduledDate":"2026-10-18","scheduledTimeMinutes":600,"progression":"double","isFavorite":true,
        "blocks":[{"id":"block","kind":"strength","exercises":[{"id":"entry","exerciseId":"catalog","quantityUnit":"reps","supersetGroup":"legacy","plannedSets":[{"id":"set","targetReps":5,"targetWeightKg":60,"targetRir":2}]}],
         "movements":[{"id":"move","exerciseId":"catalog","name":"Test","explicitPlannedSets":[{"id":"wodset","targetReps":10}]}]}]},
        {"id":"weekly","title":"Semanal","weekday":1,"blocks":[]},
        {"id":"library","title":"Plantilla","blocks":[]}],
      "rotation":{"routineIds":["weekly"]},"workouts":[{"id":"history"}],"activeSession":{"id":"active"}}
    """)
    @Test fun isoWeekSundayCopiesDeepIdsPreservingCatalogAndPrescriptions() {
        val state = fixture()
        assertEquals(1, WeeklyScheduleActions.copyPreviousWeek(state, LocalDate.of(2026,10,25)))
        val copy=state.getJSONArray("routines").getJSONObject(3)
        assertEquals("2026-10-25",copy.getString("scheduledDate"))
        assertFalse(copy.getBoolean("isFavorite"));assertTrue(copy.isNull("weekday"))
        assertEquals(600,copy.getInt("scheduledTimeMinutes"));assertEquals("double",copy.getString("progression"))
        val b=copy.getJSONArray("blocks").getJSONObject(0)
        val e=b.getJSONArray("exercises").getJSONObject(0)
        val set=e.getJSONArray("plannedSets").getJSONObject(0)
        assertNotEquals("past",copy.getString("id"));assertNotEquals("block",b.getString("id"))
        assertNotEquals("entry",e.getString("id"));assertNotEquals("set",set.getString("id"))
        assertEquals("catalog",e.getString("exerciseId"));assertTrue(e.isNull("supersetGroup"))
        assertEquals(60,set.getInt("targetWeightKg"));assertEquals(2,set.getInt("targetRir"))
        val m=b.getJSONArray("movements").getJSONObject(0)
        assertNotEquals("move",m.getString("id"));assertNotEquals("wodset",m.getJSONArray("explicitPlannedSets").getJSONObject(0).getString("id"))
        assertEquals("set",state.getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").getJSONObject(0).getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getString("id"))
        assertEquals(0,WeeklyScheduleActions.copyPreviousWeek(state,LocalDate.of(2026,10,25)))
    }
    @Test fun occupiedDateSkipsEvenWithRecurringScheduleOnSameWeekday() {
        val state=fixture()
        state.getJSONArray("routines").put(JSONObject().put("id","occupied").put("title","Ocupado").put("scheduledDate","2026-10-25"))
        assertEquals(0,WeeklyScheduleActions.copyPreviousWeek(state,LocalDate.of(2026,10,25)))
    }
    @Test fun weekBoundariesNeverCopyThisWeekOrEarlierWeeks() {
        val state=fixture()
        assertEquals(0,WeeklyScheduleActions.copyPreviousWeek(state,LocalDate.of(2026,10,18)))
        assertEquals(0,WeeklyScheduleActions.copyPreviousWeek(state,LocalDate.of(2026,11,2)))
        assertEquals(1,WeeklyScheduleActions.copyPreviousWeek(state,LocalDate.of(2026,10,19)))
    }
    @Test fun clearUnassignsTemplatesButRetainsDatedHistoryActiveAndFavorites() {
        val state=fixture();val before=JSONObject(state.toString())
        WeeklyScheduleActions.clear(state)
        assertEquals(3,state.getJSONArray("routines").length());assertTrue(state.isNull("rotation"))
        assertTrue(state.getJSONArray("routines").getJSONObject(1).isNull("weekday"))
        assertEquals(before.getJSONArray("routines").getJSONObject(0).toString(),state.getJSONArray("routines").getJSONObject(0).toString())
        assertEquals(before.getJSONArray("workouts").toString(),state.getJSONArray("workouts").toString())
        assertEquals(before.getJSONObject("activeSession").toString(),state.getJSONObject("activeSession").toString())
    }
}
