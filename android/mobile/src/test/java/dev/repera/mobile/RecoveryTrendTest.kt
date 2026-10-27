package dev.repera.mobile
import dev.repera.domain.*
import java.time.*
import org.junit.Assert.*
import org.junit.Test
class RecoveryTrendTest {
 @Test fun noFutureMorningOrUnobservedSleepPointIsCreated() {
  val zone=ZoneId.of("Europe/Madrid");val day=LocalDate.of(2026,10,26)
  val nights=listOf(RecoverySleepNight(day.minusDays(1),8.0,1.0,1.0),RecoverySleepNight(day,7.0,1.0,1.0))
  val activity=listOf(RecoveryEngine.ObservedActivity(day.minusDays(2).atTime(10,0).atZone(zone).toInstant().toEpochMilli(),30.0,true))
  val before=RecoveryTrend.points(nights,emptyList(),emptyList(),activity,day.atTime(6,59).atZone(zone).toInstant(),zone)
  assertEquals(listOf(day.minusDays(1)),before.map {it.day})
  val after=RecoveryTrend.points(nights,emptyList(),emptyList(),activity,day.atTime(7,0).atZone(zone).toInstant(),zone)
  assertEquals(2,after.size)
  assertTrue(RecoveryTrend.points(emptyList(),emptyList(),emptyList(),emptyList(),Instant.now(),zone).isEmpty())
 }
}
