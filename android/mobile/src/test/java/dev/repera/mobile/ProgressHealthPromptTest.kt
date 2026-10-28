package dev.repera.mobile
import dev.repera.domain.*
import org.junit.Assert.*
import org.junit.Test
class ProgressHealthPromptTest {
 private fun charts(hr:Int,cal:Int)=ProgressPreparedCharts(ProgressTimeRange.WEEK,true,
  List(hr){HeartRatePlotPoint(java.time.LocalDate.of(2026,1,1).plusDays(it.toLong()),50.0,60.0,70.0)},List(cal){ProgressDayPoint(java.time.LocalDate.of(2026,1,1).plusDays(it.toLong()),100.0)},0.0,null,ProgressSeriesGranularity.DAY)
 @Test fun onlyCheckedStatesProduceAPrompt() {
  assertEquals(ProgressHealthPromptKind.NOT_AUTHORIZED,ProgressHealthPrompt.kind(HealthAccessState.NOT_GRANTED,null))
  assertEquals(ProgressHealthPromptKind.NOT_AUTHORIZED,ProgressHealthPrompt.kind(HealthAccessState.NOT_GRANTED,charts(0,0)))
  assertEquals(ProgressHealthPromptKind.UNAVAILABLE,ProgressHealthPrompt.kind(HealthAccessState.UNAVAILABLE,charts(0,0)))
 }
 @Test fun pendingCheckAndGrantedWithoutDataSayNothing() {
  assertEquals(ProgressHealthPromptKind.NONE,ProgressHealthPrompt.kind(HealthAccessState.UNKNOWN,null))
  assertEquals(ProgressHealthPromptKind.NONE,ProgressHealthPrompt.kind(HealthAccessState.UNKNOWN,charts(0,0)))
  assertEquals(ProgressHealthPromptKind.NONE,ProgressHealthPrompt.kind(HealthAccessState.GRANTED,charts(0,0)))
 }
 @Test fun existingSeriesSuppressThePrompt() {
  assertEquals(ProgressHealthPromptKind.NONE,ProgressHealthPrompt.kind(HealthAccessState.NOT_GRANTED,charts(1,0)))
  assertEquals(ProgressHealthPromptKind.NONE,ProgressHealthPrompt.kind(HealthAccessState.NOT_GRANTED,charts(0,1)))
 }
}
