package dev.repera.domain
import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test
class WeeklyWorkoutProgressTest {
    private val day=LocalDate.of(2026,10,26)
    @Test fun datedPlanTakesPriorityOverRecurringWeekdayAndCountsAreNotDays() {
        val days=WeeklyWorkoutProgress.days(day,true,mapOf(day to 2),listOf(
            WeeklyWorkoutProgress.Plan(day.plusDays(1),1),WeeklyWorkoutProgress.Plan(isoWeekday=5)))
        assertEquals(day,days.first().date);assertEquals(2,days.first().completedCount)
        assertFalse(days.first().planned);assertTrue(days[1].planned);assertTrue(days[4].planned)
        assertEquals(2,days.sumOf {it.completedCount});assertEquals(1,days.count {it.completedCount>0})
    }
    @Test fun sundayStartAndOutOfWeekDatesNeverLeakIntoSelectedWeek() {
        val days=WeeklyWorkoutProgress.days(day,false,mapOf(day.minusDays(8) to 3),listOf(
            WeeklyWorkoutProgress.Plan(day.plusWeeks(1)),WeeklyWorkoutProgress.Plan(isoWeekday=7)))
        assertEquals(LocalDate.of(2026,10,25),days.first().date)
        assertTrue(days.first().planned);assertEquals(0,days.sumOf {it.completedCount})
        assertEquals(1,days.count {it.planned})
    }
}
