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
 @Test fun caloriesDomainUsesPeriodAndPreviewPadding() {
  val day=LocalDate.of(2026,10,27)
  val days=listOf(day.minusDays(6),day)
  val real=ProgressPlotAxis.domain(days,dev.repera.domain.ProgressTimeRange.WEEK,true,day,false)
  assertEquals(LocalDate.of(2026,10,26).toEpochDay().toDouble(),real.first,0.001)
  assertEquals(day.toEpochDay().toDouble(),real.second,0.001)
  val teaser=ProgressPlotAxis.domain(days,dev.repera.domain.ProgressTimeRange.WEEK,true,day,true)
  assertEquals(days.first().toEpochDay()-0.5,teaser.first,0.001)
  assertEquals(day.toEpochDay()+0.5,teaser.second,0.001)
  assertEquals(118.0,ProgressPlotAxis.kcalMax(listOf(ProgressDayPoint(day,100.0)),false),0.001)
  assertEquals(128.0,ProgressPlotAxis.kcalMax(listOf(ProgressDayPoint(day,100.0)),true),0.001)
 }
}
