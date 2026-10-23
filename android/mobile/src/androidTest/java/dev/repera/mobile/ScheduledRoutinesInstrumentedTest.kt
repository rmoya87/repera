package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class ScheduledRoutinesInstrumentedTest {
    @Test fun singleDayRoutineAppearsOnTheActualDateAndNeverAsWeeklyPlan() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, user)
        val state = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
        val id = state.getJSONArray("exercises").getJSONObject(0).getString("id")
        val repo = WorkoutRepository(context, user)
        val scheduled = repo.createRoutine("Día concreto", "strength",
            listOf(RoutineDraftEntry(id, 6, 2)), schedule = RoutineSchedule(
                scheduledDate = "2026-11-05", timeMinutes = 465))
        val after = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
        val routine = after.getJSONArray("routines").getJSONObject(0)
        assertEquals(scheduled, routine.getString("id"))
        assertTrue(routine.has("scheduledDate"))
        assertFalse(routine.has("weekday"))
        assertEquals(465, routine.getInt("scheduledTimeMinutes"))
        val overview = StateOverview.fromBytes(LocalSnapshotStore(context, user).read())!!
        assertEquals("2026-11-05", overview.routineEntries.single().scheduledDate)
        assertNull(overview.routineEntries.single().weekday)
    }

    @Test fun weeklyRoutineUsesIsoWeekdayAndNoSpecificDate() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, user)
        val state = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
        val id = state.getJSONArray("exercises").getJSONObject(0).getString("id")
        val repo = WorkoutRepository(context, user)
        repo.createRoutine("Miércoles", "strength",
            listOf(RoutineDraftEntry(id, 8, 2)), schedule = RoutineSchedule(weekday = 3))
        val saved = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
            .getJSONArray("routines").getJSONObject(0)
        assertEquals(3, saved.getInt("weekday"))
        assertFalse(saved.has("scheduledDate"))
        assertEquals(3, StateOverview.fromBytes(LocalSnapshotStore(context, user).read())!!
            .routineEntries.single().weekday)
    }
}
