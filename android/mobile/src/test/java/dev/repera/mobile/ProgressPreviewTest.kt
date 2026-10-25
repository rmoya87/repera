package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
import java.time.LocalDate
class ProgressPreviewTest {
 @Test fun previewIsFixedAppleSampleWithoutPrivateInputs() {
  val date=LocalDate.of(2026,10,25);val charts=ProgressPreview.charts(date,true)
  assertEquals(7,charts.heartRate.size);assertEquals(7,charts.calories.size)
  assertEquals(date,charts.heartRate.last().day);assertEquals(108.0,charts.heartRate.first().avgBpm,0.0)
  assertEquals(320.0,charts.calories.first().value,0.0)
  assertEquals(75.1,ProgressPreview.weight(date).first().value,0.0)
  assertTrue(charts.heartRate.all {it.minBpm<it.avgBpm && it.maxBpm>it.avgBpm})
 }
}
