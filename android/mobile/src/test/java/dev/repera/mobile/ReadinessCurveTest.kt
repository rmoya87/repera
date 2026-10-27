package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class ReadinessCurveTest {
 @Test fun noCurveWithoutTwoActualObservations() {
  assertTrue(ReadinessCurve.segments(emptyList()).isEmpty())
  assertTrue(ReadinessCurve.segments(listOf(ReadinessCurve.Point(0f,5f))).isEmpty())
 }
 @Test fun preservesEveryObservedEndpointAndContinuousJoins() {
  val points=listOf(ReadinessCurve.Point(0f,1f),ReadinessCurve.Point(1f,8f),ReadinessCurve.Point(5f,6f))
  val out=ReadinessCurve.segments(points)
  assertEquals(2,out.size)
  assertEquals(points[0],out[0].start)
  assertEquals(points[1],out[0].end)
  assertEquals(out[0].end,out[1].start)
  assertEquals(points[2],out[1].end)
  assertEquals(1f/6f,out[0].control1.x,0.0001f)
 }
}
