package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class ChartSelectionStepTest {
 @Test fun steps() {
  assertNull(ChartSelectionStep.step(null,1,0))
  assertEquals(4,ChartSelectionStep.step(null,-1,5)); assertEquals(4,ChartSelectionStep.step(null,1,5))
  assertEquals(3,ChartSelectionStep.step(4,-1,5)); assertEquals(0,ChartSelectionStep.step(0,-1,5)); assertEquals(4,ChartSelectionStep.step(4,1,5))
  assertEquals(2,ChartSelectionStep.step(7,-2,5)) // stale index is clamped first
 }
}
