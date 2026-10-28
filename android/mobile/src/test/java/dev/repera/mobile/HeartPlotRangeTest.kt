package dev.repera.mobile
import dev.repera.domain.HeartRatePlotPoint
import java.time.LocalDate
import org.junit.Test
import org.junit.Assert.*
class HeartPlotRangeTest {
 @Test fun interiorDayMayContainBothExtrema() {
  val day=LocalDate.of(2026,10,25)
  val points=listOf(HeartRatePlotPoint(day,80.0,100.0,120.0),
   HeartRatePlotPoint(day.plusDays(1),45.0,110.0,180.0),
   HeartRatePlotPoint(day.plusDays(2),90.0,105.0,130.0))
  assertEquals(45.0 to 180.0,heartPlotRange(points))
  assertNull(heartPlotRange(emptyList()))
 }
}
