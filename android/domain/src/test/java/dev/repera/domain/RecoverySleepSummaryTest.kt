package dev.repera.domain
import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test
class RecoverySleepSummaryTest {
 @Test fun oldOrFutureNightsNeverBecomeCurrentAdvice() {
  val today=LocalDate.of(2026,10,26)
  val zone=java.time.ZoneId.of("Europe/Madrid")
  val now=today.atStartOfDay(zone).toInstant()
  fun night(day:LocalDate)=RecoverySleepNight(day,8.0,1.0,1.0)
  assertNull(RecoverySleepSummary.lastNight(listOf(night(today.minusDays(3))),now,zone))
  assertNull(RecoverySleepSummary.lastNight(listOf(night(today.plusDays(1))),now,zone))
  assertNull(RecoverySleepSummary.lastNight(listOf(night(today.minusDays(2))),now,zone))
  assertNull(RecoverySleepSummary.lastNight(emptyList(),now,zone))
 }
 @Test fun cycleIntervalsUseObservedDaysExclusiveEndAndSafeExpansionCap() {
  val zone=java.time.ZoneId.of("Europe/Madrid")
  val first=LocalDate.of(2026,10,24)
  val start=first.atStartOfDay(zone).toInstant()
  val end=first.plusDays(2).atStartOfDay(zone).toInstant()
  assertEquals(listOf(first,first.plusDays(1)),observedMenstrualDays(start,end,zone))
  assertEquals(listOf(first),observedMenstrualDays(start,start,zone))
  assertEquals(11,observedMenstrualDays(start,start.plusSeconds(30L*86400),zone).size)
 }
 @Test fun twoCalendarDaysAgoExpiresAfterActual48HourBoundary() {
  val zone=java.time.ZoneId.of("Europe/Madrid")
  val day=LocalDate.of(2026,10,24)
  val night=RecoverySleepNight(day,8.0,1.0,1.0)
  val exact=day.atStartOfDay(zone).toInstant().plusSeconds(48L*3600)
  assertNotNull(RecoverySleepSummary.lastNight(listOf(night),exact,zone))
  assertNull(RecoverySleepSummary.lastNight(listOf(night),exact.plusSeconds(1),zone))
  // Fall-back weekend has 49 elapsed hours between these two local midnights.
  assertNull(RecoverySleepSummary.lastNight(listOf(night),day.plusDays(2).atStartOfDay(zone).toInstant(),zone))
 }
}
