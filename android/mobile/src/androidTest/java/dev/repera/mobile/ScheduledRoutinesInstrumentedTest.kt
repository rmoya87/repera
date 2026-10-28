package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.TimeZone
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

    /** Snapshots antiguos guardaban scheduledDate como Instant: el día civil
     *  mostrado debe respetar la zona del dispositivo (significado Apple de la
     *  fecha). Caso cruzando medianoche: 2026-11-04T23:30Z es 5 nov en Madrid
     *  pero 4 nov en UTC. */
    @Test fun legacyInstantScheduledDateKeepsCivilDayPerTimezone() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, user)
        val state = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
        val exId = state.getJSONArray("exercises").getJSONObject(0).getString("id")
        val repo = WorkoutRepository(context, user)
        val routineId = repo.createRoutine("Día legado", "strength",
            listOf(RoutineDraftEntry(exId, 6, 2)),
            schedule = RoutineSchedule(scheduledDate = "2026-11-05"))
        // Reescribe como lo escribía la versión antigua (instant).
        val raw = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
        (0 until raw.getJSONArray("routines").length())
            .map { raw.getJSONArray("routines").getJSONObject(it) }
            .single { it.getString("id") == routineId }
            .put("scheduledDate", "2026-11-04T23:30:00Z")
        LocalSnapshotStore(context, user).write(raw.toString().toByteArray())

        val previous = TimeZone.getDefault()
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Europe/Madrid"))
            assertEquals("2026-11-05",
                StateOverview.fromBytes(LocalSnapshotStore(context, user).read())!!
                    .routineEntries.single().scheduledDate)
            TimeZone.setDefault(TimeZone.getTimeZone("UTC"))
            assertEquals("2026-11-04",
                StateOverview.fromBytes(LocalSnapshotStore(context, user).read())!!
                    .routineEntries.single().scheduledDate)
        } finally {
            TimeZone.setDefault(previous)
        }
    }

    /** La fecha pura "yyyy-MM-dd" es fecha civil: se muestra igual en cualquier
     *  zona, sin desplazamiento de día ni en UTC+14. */
    @Test fun plainDateScheduledDateIsZoneIndependent() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, user)
        val state = JSONObject(String(LocalSnapshotStore(context, user).read()!!))
        val exId = state.getJSONArray("exercises").getJSONObject(0).getString("id")
        val repo = WorkoutRepository(context, user)
        repo.createRoutine("Día puro", "strength",
            listOf(RoutineDraftEntry(exId, 6, 2)),
            schedule = RoutineSchedule(scheduledDate = "2026-11-05"))
        val previous = TimeZone.getDefault()
        try {
            for (zone in listOf("UTC", "Europe/Madrid", "Pacific/Kiritimati", "Pacific/Auckland")) {
                TimeZone.setDefault(TimeZone.getTimeZone(zone))
                assertEquals("2026-11-05",
                    StateOverview.fromBytes(LocalSnapshotStore(context, user).read())!!
                        .routineEntries.single().scheduledDate)
            }
        } finally {
            TimeZone.setDefault(previous)
        }
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
