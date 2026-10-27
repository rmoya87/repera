package dev.repera.mobile
import dev.repera.domain.ProgressDayPoint
import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test
class DayChartPositionsTest {
 @Test fun missingDaysKeepCalendarDistanceAndNearestSelection() {
  val day=LocalDate.of(2026,10,1)
  val points=listOf(0L,1L,10L).map {ProgressDayPoint(day.plusDays(it),50.0)}
  assertEquals(day.plusDays(5),DayChartPositions.midpoint(points))
  assertEquals(0.1f,DayChartPositions.fraction(points,1),0.001f)
  assertEquals(1,DayChartPositions.nearest(points,0.2f))
  assertEquals(2,DayChartPositions.nearest(points,0.9f))
  assertEquals(0.5f,DayChartPositions.fraction(points.take(1),0),0.001f)
 }
}
