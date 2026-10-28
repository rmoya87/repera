package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
import java.time.*
class BodyWeightHealthIdentityTest {
 @Test fun retriesAndEditsShareDayKeyButAccountsAndDaysDoNot() {
  val zone=ZoneId.of("Europe/Madrid");val time=Instant.parse("2026-10-25T09:00:00Z").toEpochMilli()
  val key=BodyWeightHealthIdentity.recordId("account-a",time,zone)
  assertEquals(key,BodyWeightHealthIdentity.recordId("account-a",time+3600000,zone))
  assertNotEquals(key,BodyWeightHealthIdentity.recordId("account-b",time,zone))
  assertNotEquals(key,BodyWeightHealthIdentity.recordId("account-a",time+86400000,zone))
  assertFalse(key.contains("account-a"))
 }
 @Test fun localDayAndDstBoundaryAreUsedNotUtcPrefix() {
  val zone=ZoneId.of("Europe/Madrid")
  assertTrue(BodyWeightHealthIdentity.recordId("a",Instant.parse("2026-10-24T22:30:00Z").toEpochMilli(),zone).endsWith(":2026-10-25"))
  assertEquals(BodyWeightHealthIdentity.recordId("a",Instant.parse("2026-10-25T00:30:00Z").toEpochMilli(),zone),
   BodyWeightHealthIdentity.recordId("a",Instant.parse("2026-10-25T01:30:00Z").toEpochMilli(),zone))
 }
}
