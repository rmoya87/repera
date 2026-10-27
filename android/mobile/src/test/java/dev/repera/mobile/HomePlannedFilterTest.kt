package dev.repera.mobile
import java.time.LocalDate
import java.time.ZoneId
import org.junit.Assert.*
import org.junit.Test
class HomePlannedFilterTest {
    private val zone = ZoneId.of("Europe/Madrid")
    private fun entry(id: String, routine: String?, finished: String?) =
        WorkoutHistoryEntry(id = id, title = "t", startedAt = "", results = emptyList(), movements = emptyList(), finishedAtIso = finished, routineId = routine)
    @Test fun liveSportSessionCountsOnStartDayNotFinishDay() {
        val live = entry("l", "r5", "2026-10-27T00:30:00Z").copy(liveSportID = "running", startedAtIso = "2026-10-26T22:30:00Z")
        assertEquals(setOf("r5"), HomePlannedFilter.completedRoutineIds(listOf(live), LocalDate.of(2026, 10, 26), ZoneId.of("UTC")))
        assertEquals(emptySet<String>(), HomePlannedFilter.completedRoutineIds(listOf(live), LocalDate.of(2026, 10, 27), ZoneId.of("UTC")))
    }
    private val day = LocalDate.of(2026, 10, 26)
    @Test fun completedIdsUseFinishedWorkoutsOnThatLocalDayOnly() {
        val ids = HomePlannedFilter.completedRoutineIds(listOf(
            entry("a", "r1", "2026-10-26T10:00:00Z"), entry("b", "r2", "2026-10-25T10:00:00Z"),
            entry("c", "r3", null), entry("d", null, "2026-10-26T10:00:00Z")), day, zone)
        assertEquals(setOf("r1"), ids)
    }
    @Test fun activeRoutineHiddenOnlyOnToday() {
        val planned = listOf("r1", "r2", "r3")
        assertEquals(listOf("r1", "r3"), HomePlannedFilter.visible(planned, { it }, setOf("r2"), "r9", day, day.plusDays(1)))
        assertEquals(listOf("r3"), HomePlannedFilter.visible(planned, { it }, setOf("r2"), "r1", day, day))
        assertEquals(listOf("r1", "r3"), HomePlannedFilter.visible(planned, { it }, setOf("r2"), "r1", day, day.minusDays(1)))
    }
}
