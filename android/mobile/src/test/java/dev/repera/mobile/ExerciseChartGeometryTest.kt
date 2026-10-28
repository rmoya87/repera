package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class ExerciseChartGeometryTest {
 @Test fun domainMatchesCutPaddingAndCeilingHalf() {
  assertEquals(78.4,ExerciseChartGeometry.bounds(listOf(80.0,100.0),null).first,0.001)
  assertEquals(101.6,ExerciseChartGeometry.bounds(listOf(80.0,100.0),null).second,0.001)
  assertEquals(55.2,ExerciseChartGeometry.bounds(listOf(80.0,100.0),120.0).first,0.001)
  assertEquals(124.8,ExerciseChartGeometry.bounds(listOf(80.0,100.0),120.0).second,0.001)
  assertEquals(0.0,ExerciseChartGeometry.bounds(emptyList(),null).first,0.001)
 }
 @Test fun temporalSpacingAndSelectionUseObservationDatesNotRowIndex() {
  val p=listOf(0L,10L,100L).map {ExerciseProgressPoint(it,80.0,80.0,8)}
  assertEquals(0.1f,ExerciseChartGeometry.fraction(p,1),0.001f)
  assertEquals(1,ExerciseChartGeometry.nearest(p,0.3f))
  assertEquals(2,ExerciseChartGeometry.nearest(p,0.95f))
 }
}
