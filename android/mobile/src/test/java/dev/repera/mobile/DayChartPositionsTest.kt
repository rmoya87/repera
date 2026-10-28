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
 @Test fun tickStrideMatchesSourceGranularity() {
  val days=(0..19).map {LocalDate.of(2026,10,1).plusDays(it.toLong())}
  val result=ProgressPlotAxis.ticks(days,dev.repera.domain.ProgressTimeRange.MONTH,dev.repera.domain.ProgressSeriesGranularity.DAY)
  assertEquals(listOf(0,3,6,9,12,15,18,19).map {days[it]},result)
  assertEquals(days.take(7),ProgressPlotAxis.ticks(days.take(7),dev.repera.domain.ProgressTimeRange.WEEK,dev.repera.domain.ProgressSeriesGranularity.DAY))
 }
 @Test fun cardioDomainPadsExtremaAndClampsLow() {
  val day=LocalDate.of(2026,10,27)
  val points=listOf(dev.repera.domain.HeartRatePlotPoint(day,60.0,100.0,150.0))
  assertEquals(48.0,cardioPlotBounds(points,false).first,0.001)
  assertEquals(164.0,cardioPlotBounds(points,false).second,0.001)
  assertEquals(42.0,cardioPlotBounds(points,true).first,0.001)
  assertEquals(172.0,cardioPlotBounds(points,true).second,0.001)
  assertEquals(60.0 to 160.0,cardioPlotBounds(emptyList(),false))
 }
 @Test fun greedyDateLabelsUseMeasuredWidthsAndKeepBounds() {
  val labels=greedyPlotDateLabels(listOf(Triple("a",0f,20f),Triple("long",25f,40f),Triple("b",80f,20f)),100f)
  assertEquals(listOf("a","b"),labels.map {it.text})
  assertEquals(0f,labels.first().left,0.001f)
  assertTrue(labels.last().left+labels.last().width<=100f)
  assertTrue(greedyPlotDateLabels(listOf(Triple("too long",20f,80f)),40f).isEmpty())
 }
 @Test fun weeklyGranularityLabelsUseDayAndMonthEvenInsideWeekRange() {
  val charts=ProgressPreview.charts(LocalDate.of(2026,10,27),true).copy(
   range=dev.repera.domain.ProgressTimeRange.WEEK,
   granularity=dev.repera.domain.ProgressSeriesGranularity.WEEK)
  assertEquals("d MMM",progressPlotDatePattern(charts))
 }
 @Test fun datePatternMatrixMatchesSourceGranularityPrecedence() {
  val base=ProgressPreview.charts(LocalDate.of(2026,10,27),true)
  for(range in dev.repera.domain.ProgressTimeRange.entries) {
   assertEquals("d MMM",progressPlotDatePattern(base.copy(range=range,granularity=dev.repera.domain.ProgressSeriesGranularity.WEEK)))
   assertEquals("MMM yy",progressPlotDatePattern(base.copy(range=range,granularity=dev.repera.domain.ProgressSeriesGranularity.MONTH)))
   val expected=if(range in listOf(dev.repera.domain.ProgressTimeRange.TODAY,dev.repera.domain.ProgressTimeRange.WEEK)) "EEE" else "d MMM"
   assertEquals(expected,progressPlotDatePattern(base.copy(range=range,granularity=dev.repera.domain.ProgressSeriesGranularity.DAY)))
  }
 }
}
