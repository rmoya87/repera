package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class CompleteHistoryOrderTest {
 @Test fun fullArchiveDoesNotStopAtTwentyAndUsesFinishDateWithExternalActivities() {
  val local=(0..24).map {i ->WorkoutHistoryEntry("s$i","S$i","date",emptyList(),emptyList(),startedAtIso="2026-10-20T09:00:00Z",finishedAtIso="2026-10-20T10:00:00Z")}
  val draft=WorkoutHistoryEntry("draft","Draft","date",emptyList(),emptyList())
  val health=ExternalHealthHistoryEntry("health","Paseo",java.time.Instant.parse("2026-10-25T10:00:00Z").toEpochMilli(),0,30.0,"synthetic")
  val rows=CompleteHistoryOrder.rows(local+draft,listOf(health))
  assertEquals(26,rows.size);assertEquals("health-health",rows.first().id)
  assertEquals(25,rows.count {it.local!=null});assertFalse(rows.any {it.id=="local-draft"})
 }
}
