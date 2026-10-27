package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
import java.time.*
class DailyHeartRatesTest {
 @Test fun midnightAndDstUseEachSampleTimeNotRecordStart() {
  val zone=ZoneId.of("Europe/Madrid");val day=LocalDate.of(2026,10,25)
  val points=DailyHeartRates.points(listOf(day.atStartOfDay(zone).minusMinutes(1).toInstant().toEpochMilli() to 70.0,
   day.atStartOfDay(zone).plusMinutes(1).toInstant().toEpochMilli() to 50.0,
   day.atTime(3,0).atZone(zone).toInstant().toEpochMilli() to 60.0),zone)
  assertEquals(2,points.size);assertEquals(day.minusDays(1),points.first().date)
  assertEquals(70.0,points.first().avgBpm,0.001);assertEquals(55.0,points.last().avgBpm,0.001)
  assertEquals(50.0,points.last().minBpm,0.001);assertEquals(60.0,points.last().maxBpm,0.001)
 }
}
