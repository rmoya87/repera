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
    @Test fun twoSessionsOnSameSourceDayBothCopyAndOccupiedIsSnapshotted() {
        val state=fixture()
        state.getJSONArray("routines").put(JSONObject().put("id","past2").put("title","Segundo").put("scheduledDate","2026-10-18").put("blocks",JSONArray()))
        assertEquals(2,WeeklyScheduleActions.copyPreviousWeek(state,LocalDate.of(2026,10,25)))
    }
    @Test fun removeScheduledFavoriteKeepsTemplateOtherwiseDeletes() {
        val state=fixture()
        val routines=state.getJSONArray("routines")
        // "past" is dated and favorite -> kept, unscheduled
        assertTrue(WeeklyScheduleActions.removeScheduled(state,"past"))
        assertEquals(3,routines.length());assertTrue(routines.getJSONObject(0).isNull("scheduledDate"))
        routines.put(JSONObject().put("id","oneoff").put("title","Suelto").put("scheduledDate","2026-10-26").put("isFavorite",false))
        assertTrue(WeeklyScheduleActions.removeScheduled(state,"oneoff"))
        assertEquals(3,routines.length())
        // weekday-only: unassign weekday, template stays
        assertTrue(WeeklyScheduleActions.removeScheduled(state,"weekly"))
        assertEquals(3,routines.length());assertFalse(routines.getJSONObject(1).has("weekday"))
        assertEquals("weekly",routines.getJSONObject(1).getString("id"));assertEquals("Semanal",routines.getJSONObject(1).getString("title"))
        assertTrue(routines.getJSONObject(1).has("blocks"))
        // history and active session untouched
        assertEquals("history",state.getJSONArray("workouts").getJSONObject(0).getString("id"))
        assertEquals("active",state.getJSONObject("activeSession").getString("id"))
        // template without schedule / unknown id: no change
        assertFalse(WeeklyScheduleActions.removeScheduled(state,"library"))
        assertFalse(WeeklyScheduleActions.removeScheduled(state,"nope"))
    }
    @Test fun preparedLegacyMigrationIsIdempotentKeepsHistoryAndIsNotWired() {
        val state=fixture()
        val before=state.getJSONArray("workouts").toString()+state.getJSONObject("activeSession").toString()
        // 2026-10-26 is Monday; weekday 1 -> 2026-10-26
        assertTrue(WeeklyScheduleActions.migrateLegacyWeekly(state,LocalDate.of(2026,10,28)))
        val routines=state.getJSONArray("routines")
        assertEquals(4,routines.length())
        val migrated=routines.getJSONObject(1)
        assertEquals("weekly",migrated.getString("id"));assertEquals("2026-10-26",migrated.getString("scheduledDate"))
        assertFalse(migrated.has("weekday"));assertFalse(migrated.getBoolean("isFavorite"))
        val template=routines.getJSONObject(3)
        assertNotEquals("weekly",template.getString("id"));assertTrue(template.isNull("scheduledDate"));assertEquals("Semanal",template.getString("title"))
        assertEquals(before,state.getJSONArray("workouts").toString()+state.getJSONObject("activeSession").toString())
        assertFalse(WeeklyScheduleActions.migrateLegacyWeekly(state,LocalDate.of(2026,10,28)))
        assertEquals(4,routines.length())
    }
    @Test fun preparedLegacyMigrationSkipsOccupiedDateButStillClearsWeekday() {
        val state=fixture()
        state.getJSONArray("routines").put(JSONObject().put("id","occ").put("title","Ocupado").put("scheduledDate","2026-10-26"))
        assertTrue(WeeklyScheduleActions.migrateLegacyWeekly(state,LocalDate.of(2026,10,26)))
        val routines=state.getJSONArray("routines")
        assertEquals(4,routines.length())
        assertFalse(routines.getJSONObject(1).has("weekday"));assertTrue(routines.getJSONObject(1).isNull("scheduledDate"))
        // the ORIGINAL object (same id, title, blocks, favorite flag) stays as an unscheduled template; only the weekday is lost
        val original=routines.getJSONObject(1)
        assertEquals("weekly",original.getString("id"));assertEquals("Semanal",original.getString("title"));assertTrue(original.has("blocks"))
    }
    @Test fun clearWeekRemovesDatedOfThatWeekOnlyKeepsFavoritesAsTemplates() {
        val state=fixture()
        val r=state.getJSONArray("routines")
        r.put(JSONObject().put("id","in").put("title","Dentro").put("scheduledDate","2026-10-21").put("isFavorite",false))
        r.put(JSONObject().put("id","next").put("title","Otra").put("scheduledDate","2026-10-27").put("isFavorite",false))
        assertEquals(1,WeeklyScheduleActions.clearWeek(state,LocalDate.of(2026,10,19)))  // week 19-25 holds only "in"; "past"(18) and "next"(27) are other weeks
        val after=state.getJSONArray("routines");val ids=(0 until after.length()).map{after.getJSONObject(it).getString("id")}
        assertFalse("in" in ids);assertTrue("next" in ids);assertTrue("weekly" in ids);assertTrue("library" in ids)
    }
    @Test fun clearWeekFavoriteBecomesUnscheduledTemplate() {
        val state=fixture()
        assertEquals(1,WeeklyScheduleActions.clearWeek(state,LocalDate.of(2026,10,18)))  // 2026-10-18 is Sunday of week 12-18; "past" is favorite
        val past=state.getJSONArray("routines").getJSONObject(0)
        assertEquals("past",past.getString("id"));assertTrue(past.isNull("scheduledDate"));assertTrue(past.getBoolean("isFavorite"))
        assertEquals(0,WeeklyScheduleActions.clearWeek(state,LocalDate.of(2026,10,18)))
        assertEquals("history",state.getJSONArray("workouts").getJSONObject(0).getString("id"))
    }
    @Test fun combinedClearOfADistantWeekStillWipesLegacyRecurrenceAndRotationGlobally() {
        // Documents the KNOWN legacy global effect of WorkoutRepository.clearScheduledWeek (clearWeek + clear):
        // clearing a week with no dated routines (Mar 2027) still removes weekday recurrence and rotation everywhere.
        val state=fixture()
        assertEquals(0,WeeklyScheduleActions.clearWeek(state,LocalDate.of(2027,3,1)))
        WeeklyScheduleActions.clear(state)
        val routines=state.getJSONArray("routines")
        assertFalse(routines.getJSONObject(1).has("weekday"));assertTrue(state.isNull("rotation"))
        assertEquals("2026-10-18",routines.getJSONObject(0).getString("scheduledDate")) // dated routine of another week kept
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
    @Test fun weekdayAssignmentUnassignsOtherTemplatesButKeepsDatedTrainingAndContents() {
        val state=fixture()
        state.getJSONArray("routines").put(JSONObject().put("id","dated-legacy").put("scheduledDate","2026-10-26").put("weekday",1))
        val before=state.getJSONArray("routines").getJSONObject(0).toString()
        WeeklyScheduleActions.makeWeekdayExclusive(state,"library",1)
        assertTrue(state.getJSONArray("routines").getJSONObject(1).isNull("weekday"))
        assertEquals(1,state.getJSONArray("routines").getJSONObject(3).getInt("weekday"))
        assertEquals(before,state.getJSONArray("routines").getJSONObject(0).toString())
        assertEquals("history",state.getJSONArray("workouts").getJSONObject(0).getString("id"))
    }
    @Test fun assigningSameTemplateIsIdempotent() {
        val state=fixture()
        WeeklyScheduleActions.makeWeekdayExclusive(state,"weekly",1)
        val once=state.toString()
        WeeklyScheduleActions.makeWeekdayExclusive(state,"weekly",1)
        assertEquals(once,state.toString())
        assertEquals(1,state.getJSONArray("routines").getJSONObject(1).getInt("weekday"))
    }
    @Test fun assignTemplateToDateAddsIndependentCopyWithoutTouchingRecurrence() {
        val state=fixture()
        val before=state.getJSONArray("routines").toString()
        val id1=WeeklyScheduleActions.assignTemplateToDate(state,"past",LocalDate.of(2026,10,28))
        val id2=WeeklyScheduleActions.assignTemplateToDate(state,"past",LocalDate.of(2026,10,28))
        assertNotNull(id1);assertNotEquals(id1,id2)
        val all=state.getJSONArray("routines")
        assertEquals(5,all.length())
        // original routines are byte-identical, weekly (weekday 1) and rotation untouched
        assertEquals(JSONArray(before).toString(),JSONArray().apply {for(i in 0 until 3) put(all.getJSONObject(i))}.toString())
        assertEquals(1,all.getJSONObject(1).getInt("weekday"));assertEquals("weekly",state.getJSONObject("rotation").getJSONArray("routineIds").getString(0))
        val copy=all.getJSONObject(3)
        assertEquals("2026-10-28",copy.getString("scheduledDate"));assertFalse(copy.getBoolean("isFavorite"));assertTrue(copy.isNull("weekday"))
        assertEquals(600,copy.getInt("scheduledTimeMinutes"));assertEquals("double",copy.getString("progression"))
        val e=copy.getJSONArray("blocks").getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
        assertNotEquals("entry",e.getString("id"));assertEquals("catalog",e.getString("exerciseId"))
        assertNull(WeeklyScheduleActions.assignTemplateToDate(state,"missing",LocalDate.of(2026,10,28)))
        assertEquals(5,state.getJSONArray("routines").length())
    }
}
