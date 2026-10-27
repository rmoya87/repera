package dev.repera.mobile
import dev.repera.domain.*
import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test
class SleepPeriodSummaryTest {
 @Test fun fallbackIsExplicitAndAveragesDoNotMixInvisibleRange() {
  val today=LocalDate.of(2026,10,26)
  val history=listOf(RecoverySleepNight(today.minusDays(10),8.0,1.0,2.0),RecoverySleepNight(today,6.0,1.0,1.0))
  val current=SleepPeriodSummary.forRange(history,ProgressTimeRange.TODAY,today,true)
  assertFalse(current.outsideRange);assertEquals(6.0,current.hours!!,0.001)
  val fallback=SleepPeriodSummary.forRange(history,ProgressTimeRange.TODAY,today.plusDays(1),true)
  assertTrue(fallback.outsideRange);assertEquals(7.0,fallback.hours!!,0.001);assertEquals(4.5,fallback.light,0.001)
 }
}
